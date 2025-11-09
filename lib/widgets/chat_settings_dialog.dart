import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:forui/forui.dart';
import '../models/chat_settings.dart';
import '../providers/chat_settings_provider.dart';
import '../services/toast_service.dart';
import '../widgets/ui/app_select.dart';
import '../widgets/ui/app_button.dart';
import '../widgets/ui/app_text_field.dart';

class ChatSettingsDialog extends StatefulWidget {
  final ChatSettingsProvider? provider;
  const ChatSettingsDialog({super.key, this.provider});

  @override
  State<ChatSettingsDialog> createState() => _ChatSettingsDialogState();
}

class _ChatSettingsDialogState extends State<ChatSettingsDialog> {
  late ChatSettings _tempSettings;
  ChatSettingsProvider? _provider;
  bool _hasProvider = false;
  // Initialize immediately to avoid LateInitializationError on hot reload
  final TextEditingController _maxTokensController = TextEditingController();
  // Forui slider controllers
  late final FContinuousSliderController _temperatureController;
  late final FContinuousSliderController _topPController;

  @override
  void initState() {
    super.initState();
    try {
      _provider = widget.provider ?? context.read<ChatSettingsProvider>();
      _tempSettings = _provider?.settings ?? const ChatSettings();
      _hasProvider = _provider != null;
    } catch (_) {
      _provider = null;
      _tempSettings = const ChatSettings();
      _hasProvider = false;
    }
    // Ensure controller reflects current settings
    _maxTokensController.text = _tempSettings.maxTokens.toString();
    // Initialize Forui slider controllers with current settings values
    // Temperature internal slider domain 0-1 maps to 0-2 real value
    _temperatureController = FContinuousSliderController(
      allowedInteraction: FSliderInteraction.slide,
      selection: FSliderSelection(max: _tempSettings.temperature / 2.0),
    );
    _topPController = FContinuousSliderController(
      allowedInteraction: FSliderInteraction.slide,
      selection: FSliderSelection(max: _tempSettings.topP),
    );
    // Listen for slider changes to keep _tempSettings in sync
    _temperatureController.addListener(() {
      final raw = _extractSelectionValue(_temperatureController.selection);
      if (raw != null) {
        final mapped = raw * 2.0; // map back to 0-2 temperature range
        if (mapped != _tempSettings.temperature) {
          setState(
            () => _tempSettings = _tempSettings.copyWith(temperature: mapped),
          );
        }
      }
    });
    _topPController.addListener(() {
      final raw = _extractSelectionValue(_topPController.selection);
      if (raw != null && raw != _tempSettings.topP) {
        setState(() => _tempSettings = _tempSettings.copyWith(topP: raw));
      }
    });
  }

  @override
  void dispose() {
    _maxTokensController.dispose();
    _temperatureController.dispose();
    _topPController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FDialog(
      direction: Axis.horizontal,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              FIcons.settings,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure AI model parameters',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(FIcons.x),
          ),
        ],
      ),
      body: SizedBox(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_hasProvider)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: FBadge(
                    style: FBadgeStyle.secondary(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          FIcons.shieldAlert,
                          size: 16,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Provider unavailable - changes won\'t persist',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              _buildModelProviderSection(),
              const SizedBox(height: 16),
              _buildModelSelectSection(),
              const SizedBox(height: 16),
              _buildTemperatureSection(),
              const SizedBox(height: 16),
              _buildTopPSection(),
              const SizedBox(height: 16),
              _buildMaxTokensSection(),
              const SizedBox(height: 16),
              _buildDebugSection(),
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          label: 'Reset',
          onPressed: _resetToDefaults,
          style: FButtonStyle.outline(),
        ),
        AppButton(
          label: 'Cancel',
          style: FButtonStyle.ghost(),
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Save Settings',
          onPressed: _hasProvider ? _saveSettings : null,
        ),
      ],
    );
  }

  Widget _buildModelProviderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        AppSelect(
          label: const Text('Model Provider'),
          itemsList: ChatSettings.availableProviders,
          value: _tempSettings.modelProvider,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _tempSettings = _tempSettings.copyWith(modelProvider: value);
              });
            }
          },
          prefixIcon: const Icon(FIcons.globe),
          clearable: false,
        ),
      ],
    );
  }

  Widget _buildModelSelectSection() {
    final models = ChatSettings.availableModels;
    final map = {for (final m in models) _getModelDisplayName(m): m};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        AppSelect(
          label: const Text('Model'),
          itemsMap: map,
          value: _tempSettings.model,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _tempSettings = _tempSettings.copyWith(model: value);
              });
            }
          },
          prefixIcon: const Icon(FIcons.cpu),
          clearable: false,
        ),
      ],
    );
  }

  Widget _buildTemperatureSection() {
    // Updated to use native Forui FSlider label/description pattern (removing manual header UI)
    return FSlider(
      controller: _temperatureController,
      tooltipBuilder: (style, value) {
        final hex = (value % 100) * 2.0;
        return Text(hex.toStringAsFixed(2));
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              FIcons.trash,
              size: 14,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Temperature: ${_tempSettings.temperature.toStringAsFixed(1)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      description: const Text(
        'Controls randomness / creativity. Lower is focused, higher is diverse.',
      ),
      marks: const [
        FSliderMark(value: 0, label: Text('0')), // 0
        FSliderMark(value: 0.25, tick: false), // 0.5
        FSliderMark(value: 0.5, label: Text('1')), // 1.0
        FSliderMark(value: 0.75, tick: false), // 1.5
        FSliderMark(value: 1, label: Text('2')), // 2.0
      ],
    );
  }

  Widget _buildTopPSection() {
    // Updated to use native Forui FSlider label/description pattern
    return FSlider(
      controller: _topPController,
      tooltipBuilder: (style, value) {
        final hex = (value % 100);
        return Text(hex.toStringAsFixed(2));
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.tertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              FIcons.activity,
              size: 14,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Top P: ${_tempSettings.topP.toStringAsPrecision(2)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      description: const Text(
        'Nucleus sampling probability. Lower narrows selection; higher broadens.',
      ),
      marks: const [
        FSliderMark(value: 0, label: Text('0')),
        FSliderMark(value: 0.25, tick: false),
        FSliderMark(value: 0.5, label: Text('0.5')),
        FSliderMark(value: 0.75, tick: false),
        FSliderMark(value: 1, label: Text('1.0')),
      ],
    );
  }

  Widget _buildMaxTokensSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        AppTextField(
          controller: _maxTokensController,
          label: const Text('Maximum Tokens'),
          hintText: 'e.g. 1024',
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(FIcons.hash),
          suffixIcon: const Icon(FIcons.textInitial),
        ),
        const SizedBox(height: 4),
        Text(
          'Maximum number of tokens the model may generate (1 - 8192).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDebugSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            FIcons.code,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FSwitch(
                value: _tempSettings.debug,
                onChange: (value) => setState(
                  () => _tempSettings = _tempSettings.copyWith(debug: value),
                ),
                label: Text(
                  'Debug Mode',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Use mock responses for testing instead of calling the actual model.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _resetToDefaults() {
    setState(() {
      _tempSettings = const ChatSettings();
      // Reset slider controllers to default selections too
      _temperatureController.selection = FSliderSelection(
        max: _tempSettings.temperature / 2.0,
      );
      _topPController.selection = FSliderSelection(max: _tempSettings.topP);
    });
  }

  /// Get a shorter, more readable display name for model dropdown
  String _getModelDisplayName(String model) {
    // Create shorter display names for long model names
    final modelMappings = {
      'qwen/qwen3-32b': 'Qwen3 32B',
      'deepseek-r1-distill-llama-70b': 'DeepSeek R1 70B',
      'gemma2-9b-it': 'Gemma2 9B',
      'compound-beta': 'Compound Beta',
      'llama-3.1-8b-instant': 'Llama 3.1 8B Instant',
      'llama-3.3-70b-versatile': 'Llama 3.3 70B',
      'meta-llama/llama-4-maverick-17b-128e-instruct': 'Llama 4 Maverick 17B',
      'meta-llama/llama-4-scout-17b-16e-instruct': 'Llama 4 Scout 17B',
      'meta-llama/llama-guard-4-12b': 'Llama Guard 4 12B',
      'openai/gpt-oss-120b': 'GPT OSS 120B',
    };

    return modelMappings[model] ?? model;
  }

  void _saveSettings() {
    // parse max tokens field before saving
    final tokens = int.tryParse(_maxTokensController.text.trim());
    if (tokens != null && tokens > 0 && tokens <= 8192) {
      _tempSettings = _tempSettings.copyWith(maxTokens: tokens);
    }
    // Ensure latest slider values are captured (in case listener missed last frame)
    final double? rawTemp = _extractSelectionValue(
      _temperatureController.selection,
    ); // 0-1
    final double? rawTopP = _extractSelectionValue(
      _topPController.selection,
    ); // 0-1
    _tempSettings = _tempSettings.copyWith(
      temperature: rawTemp != null ? rawTemp * 2.0 : _tempSettings.temperature,
      topP: rawTopP ?? _tempSettings.topP,
    );
    if (_hasProvider && _provider != null) {
      _provider!.updateSettings(_tempSettings);
    } else {
      ToastService.showWarning(
        'Settings cannot be saved - provider not available',
        context: context,
      );
    }
    Navigator.of(context).pop();
  }

  // --- Helpers ---
  // Safely extract a numeric value from the slider selection object regardless of internal field name.
  double? _extractSelectionValue(dynamic selection) {
    if (selection == null) return null;
    // Probe known property names manually (avoids reflective string interpolation).
    try {
      final v = (selection as dynamic).max;
      if (v is num) return v.toDouble();
    } catch (_) {}
    try {
      final v = (selection as dynamic).end;
      if (v is num) return v.toDouble();
    } catch (_) {}
    try {
      final v = (selection as dynamic).value;
      if (v is num) return v.toDouble();
    } catch (_) {}
    try {
      final v = (selection as dynamic).upper;
      if (v is num) return v.toDouble();
    } catch (_) {}
    try {
      final v = (selection as dynamic).current;
      if (v is num) return v.toDouble();
    } catch (_) {}
    // Fallback: try call() if selection itself is numeric-like
    try {
      if (selection is num) return selection.toDouble();
    } catch (_) {}
    return null;
  }
}
