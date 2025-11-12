import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:forui/forui.dart';
import '../providers/loading_animation_provider.dart';
import '../utils/loading_animation_style.dart';
import '../widgets/app_loading_widget.dart';
import '../widgets/styled_icon_button.dart';

class LoadingAnimationSettingsScreen extends StatefulWidget {
  const LoadingAnimationSettingsScreen({super.key});

  @override
  State<LoadingAnimationSettingsScreen> createState() =>
      _LoadingAnimationSettingsScreenState();
}

class _LoadingAnimationSettingsScreenState
    extends State<LoadingAnimationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return FScaffold(
      header: FHeader(
        style: (style) => style.copyWith(
          titleTextStyle: style.titleTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        title: Row(
          children: [
            StyledIconButton(
              icon: FIcons.arrowLeft,
              tooltip: 'Back',
              margin: const EdgeInsets.all(8),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading Animation Settings',
              style: TextStyle(color: theme.colors.foreground),
            ),
            const Spacer(),
            FButton.icon(
              style: FButtonStyle.ghost(),
              onPress: () => _showResetDialog(context),
              child: const Icon(FIcons.refreshCw),
            ),
          ],
        ),
      ),
      child: Consumer<LoadingAnimationProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentPreviewCard(context, provider),
                const SizedBox(height: 12),
                _buildColorSettingsCard(context, provider),
                const SizedBox(height: 12),
                _buildAnimationStylesCard(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds a card showing the current loading animation
  Widget _buildCurrentPreviewCard(
    BuildContext context,
    LoadingAnimationProvider provider,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                        theme.colorScheme.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FIcons.eye,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Current Animation',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  const AppLoadingWidget.large(),
                  const SizedBox(height: 12),
                  Text(
                    provider.currentStyle.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.currentStyle.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the color configuration card
  Widget _buildColorSettingsCard(
    BuildContext context,
    LoadingAnimationProvider provider,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.secondary.withValues(alpha: 0.1),
                        theme.colorScheme.tertiary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FIcons.droplet,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Color Settings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Use Theme Color'),
              subtitle: const Text(
                'Use the app\'s primary color for animations',
              ),
              value: provider.useThemeColor,
              onChanged: (value) => provider.updateUseThemeColor(value),
              secondary: Icon(
                provider.useThemeColor ? FIcons.brush : FIcons.brushCleaning,
                color: theme.colorScheme.primary,
              ),
            ),
            if (!provider.useThemeColor) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Custom Color'),
                subtitle: Text('Tap to choose a custom color'),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(provider.customColorValue),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                trailing: const Icon(FIcons.pen),
                onTap: () => _showColorPicker(context, provider),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the animation styles selection card
  Widget _buildAnimationStylesCard(
    BuildContext context,
    LoadingAnimationProvider provider,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.tertiary.withValues(alpha: 0.1),
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FIcons.activity,
                    color: theme.colorScheme.tertiary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Animation Styles',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: LoadingAnimationStyle.values.length,
              itemBuilder: (context, index) {
                final style = LoadingAnimationStyle.values[index];
                final isSelected = provider.currentStyle == style;

                return _buildAnimationStyleTile(
                  context,
                  style,
                  isSelected,
                  () => provider.updateStyle(style),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an individual animation style tile
  Widget _buildAnimationStyleTile(
    BuildContext context,
    LoadingAnimationStyle style,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                    ],
                  )
                : null,
            color: isSelected
                ? null
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Create a temporary provider context for preview
              ChangeNotifierProvider<LoadingAnimationProvider>.value(
                value: LoadingAnimationProvider(
                  initialStyle: style,
                  initialUseThemeColor: true,
                  initialInitialized: true,
                ),
                child: const AppLoadingWidget(size: 32),
              ),
              const SizedBox(height: 8),
              Text(
                style.displayName,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a color picker dialog
  void _showColorPicker(
    BuildContext context,
    LoadingAnimationProvider provider,
  ) {
    final predefinedColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    showFDialog(
      context: context,
      builder: (ctx, style, animation) {
        final ftheme = FTheme.of(ctx);
        final maxHeight = MediaQuery.of(context).size.height * 0.7;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: FDialog(
            style: style.call,
            animation: animation,
            direction: Axis.horizontal,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ftheme.colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FIcons.palette,
                    color: ftheme.colors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose Color',
                    style: ftheme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ftheme.colors.foreground,
                    ),
                  ),
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  onPress: () => Navigator.of(ctx).pop(),
                  child: const Icon(FIcons.x),
                ),
              ],
            ),
            body: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: predefinedColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    provider.updateCustomColor(color.value);
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ftheme.colors.border.withValues(alpha: 0.3),
                      ),
                    ),
                    child: color.value == provider.customColorValue
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            actions: [
              FButton(
                style: FButtonStyle.outline(),
                onPress: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Shows the reset confirmation dialog
  void _showResetDialog(BuildContext context) {
    showFDialog(
      context: context,
      builder: (ctx, style, animation) {
        final ftheme = FTheme.of(ctx);
        final maxHeight = MediaQuery.of(context).size.height * 0.7;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: FDialog(
            style: style.call,
            animation: animation,
            direction: Axis.horizontal,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ftheme.colors.destructive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FIcons.shieldAlert,
                    color: ftheme.colors.destructive,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reset Settings',
                    style: ftheme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ftheme.colors.foreground,
                    ),
                  ),
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  onPress: () => Navigator.of(ctx).pop(),
                  child: const Icon(FIcons.x),
                ),
              ],
            ),
            body: const Text(
              'Are you sure you want to reset all loading animation settings to defaults?',
            ),
            actions: [
              FButton(
                style: FButtonStyle.outline(),
                onPress: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FButton(
                style: FButtonStyle.destructive(),
                onPress: () {
                  context.read<LoadingAnimationProvider>().resetToDefaults();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        );
      },
    );
  }
}
