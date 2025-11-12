import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:forui/forui.dart';
import '../providers/case_provider.dart';
import '../utils/token_expiration_handler.dart';
import '../widgets/ui/app_text_field.dart';
import '../widgets/ui/app_button.dart';
import '../widgets/ui/app_select.dart';
import '../widgets/styled_icon_button.dart';

class AddCaseScreen extends StatefulWidget {
  final String patientId;
  const AddCaseScreen({super.key, required this.patientId});

  @override
  State<AddCaseScreen> createState() => _AddCaseScreenState();
}

class _AddCaseScreenState extends State<AddCaseScreen>
    with TokenExpirationHandler {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();

  String? _selectedPriority;
  bool _isLoading = false;
  final List<String> _tags = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final caseId = const Uuid().v4();

    final success = await handleTokenExpiration(() async {
      final caseProvider = context.read<CaseProvider>();
      return await caseProvider.create(
        caseId,
        widget.patientId,
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        _tags,
        _selectedPriority ?? 'Medium',
      );
    });

    setState(() => _isLoading = false);

    if (mounted && success != null) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/patients/${widget.patientId}');
      }
    }
  }

  void _cancelForm() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/patients/${widget.patientId}');
    }
  }

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
        title: Center(
          child: Text(
            'Add New Case',
            style: TextStyle(color: theme.colors.foreground),
          ),
        ),
        suffixes: [
          StyledIconButton(
            icon: FIcons.x,
            tooltip: 'Cancel',
            margin: const EdgeInsets.all(8),
            onPressed: _cancelForm,
          ),
        ],
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Case Information',
                  style: theme.typography.xl2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please fill in the case details below',
                  style: theme.typography.base.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 30),

                // Case Title Field (with validation like patient form)
                FormField<String>(
                  validator: (_) {
                    if (_titleController.text.trim().isEmpty) {
                      return 'Case title is required';
                    }
                    return null;
                  },
                  builder: (state) => Column(
                    children: [
                      AppTextField(
                        controller: _titleController,
                        label: const Text('Case Title *'),
                        hintText: 'Enter a descriptive title for the case',
                        prefixIcon: Icon(FIcons.fileText),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            state.errorText!,
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.destructive,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Description Field
                FormField<String>(
                  validator: (_) {
                    if (_descriptionController.text.trim().isEmpty) {
                      return 'Case description is required';
                    }
                    return null;
                  },
                  builder: (state) => Column(
                    children: [
                      AppTextField(
                        controller: _descriptionController,
                        label: const Text('Case Description *'),
                        hintText: 'Enter detailed description of the case',
                        prefixIcon: Icon(FIcons.fileText),
                        maxLines: 6,
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            state.errorText!,
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.destructive,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Priority Field (ForUI Select)
                AppSelect(
                  label: const Text('Priority'),
                  hint: 'Select priority (optional)',
                  itemsList: const ['Low', 'Medium', 'High', 'Urgent'],
                  value: _selectedPriority,
                  onChanged: (val) => setState(() => _selectedPriority = val),
                  prefixIcon: Icon(FIcons.flag),
                  clearable: true,
                ),
                const SizedBox(height: 20),

                // Tags Section
                _buildTagsSection(),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        onPressed: _isLoading ? null : _cancelForm,
                        style: FButtonStyle.ghost(),
                        expand: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButton(
                        label: 'Add Case',
                        onPressed: _isLoading ? null : _submitForm,
                        isLoading: _isLoading,
                        expand: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    final theme = FTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AppTextField(
                controller: _tagController,
                label: const Text('Add Tag'),
                hintText: 'Add a tag...',
                prefixIcon: Icon(FIcons.tag),
              ),
            ),
            const SizedBox(width: 8),
            FButton.icon(
              style: FButtonStyle.outline(),
              onPress: () => _addTag(_tagController.text),
              child: Icon(FIcons.plus),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => _buildTagChip(tag, theme)).toList(),
          ),
      ],
    );
  }

  Widget _buildTagChip(String tag, FThemeData theme) {
    return FBadge(
      style: FBadgeStyle.secondary(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: Icon(FIcons.x, size: 14),
          ),
        ],
      ),
    );
  }

  void _addTag(String tagText) {
    final tag = tagText.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }
}
