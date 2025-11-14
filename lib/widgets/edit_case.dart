import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../models/case.dart';
import '../providers/case_provider.dart';
import '../services/toast_service.dart';
import '../utils/token_expiration_handler.dart';
import 'ui/app_text_field.dart';
import 'ui/app_button.dart';
import 'ui/app_select.dart';
import '../utils/app_logger.dart';

class EditCaseDialog extends StatefulWidget {
  final MedicalCase medicalCase;
  final CaseProvider caseProvider;

  const EditCaseDialog({
    super.key,
    required this.medicalCase,
    required this.caseProvider,
  });

  @override
  State<EditCaseDialog> createState() => _EditCaseDialogState();
}

class _EditCaseDialogState extends State<EditCaseDialog>
    with TokenExpirationHandler {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final _tagController = TextEditingController();

  String? _selectedPriority;
  bool _isLoading = false;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    final medicalCase = widget.medicalCase;

    _titleController = TextEditingController(text: medicalCase.title);
    _descriptionController = TextEditingController(
      text: medicalCase.description,
    );
    _tags = List.from(medicalCase.tags ?? []);
    // Normalize priority case to match dropdown items
    _selectedPriority = _normalizePriority(medicalCase.priority);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Debug: Print tags before saving
      AppLogger.debug('Saving case with tags: $_tags');

      final success = await handleTokenExpiration(() async {
        return await widget.caseProvider.update(
          widget.medicalCase.id,
          widget.medicalCase.patientId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          tags: _tags,
        );
      });

      if (mounted) {
        if (success == true) {
          ToastService.showSuccess(
            'Case updated successfully',
            context: context,
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          ToastService.showError(
            'Failed to update case. Please try again.',
            context: context,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError('Failed to update case: $e', context: context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FDialog(
      direction: Axis.horizontal,
      title: Row(
        children: [
          Icon(
            FIcons.notebookPen,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Case',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Update case information',
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with validation
                FormField<String>(
                  validator: (_) {
                    if (_titleController.text.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                  builder: (state) => Column(
                    children: [
                      AppTextField(
                        controller: _titleController,
                        label: const Text('Case Title *'),
                        hintText: 'Enter case title',
                        prefixIcon: const Icon(FIcons.file),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              state.errorText!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Priority select
                AppSelect(
                  label: const Text('Priority'),
                  itemsList: const ['Low', 'Medium', 'High', 'Urgent'],
                  value: _selectedPriority,
                  onChanged: (v) => setState(() => _selectedPriority = v),
                  prefixIcon: const Icon(FIcons.flag),
                  hint: 'Select priority (optional)',
                ),
                const SizedBox(height: 12),

                // Description with validation
                FormField<String>(
                  validator: (_) {
                    if (_descriptionController.text.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                  builder: (state) => Column(
                    children: [
                      AppTextField(
                        controller: _descriptionController,
                        label: const Text('Description *'),
                        hintText: 'Enter detailed case description',
                        prefixIcon: const Icon(FIcons.notebookPen),
                        maxLines: 4,
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              state.errorText!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                _buildTagsSection(Theme.of(context)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          style: FButtonStyle.ghost(),
        ),
        AppButton(
          label: 'Save Changes',
          onPressed: _isLoading ? null : _save,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildTagsSection(ThemeData theme) {
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
                prefixIcon: const Icon(FIcons.tag),
              ),
            ),
            const SizedBox(width: 8),
            FButton.icon(
              style: FButtonStyle.outline(),
              onPress: () => _addTag(_tagController.text),
              child: const Icon(FIcons.plus),
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

  Widget _buildTagChip(String tag, ThemeData theme) {
    return FBadge(
      style: FBadgeStyle.secondary((style) {
        return style.copyWith(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          contentStyle: style.contentStyle
              .copyWith(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              )
              .call,
        );
      }),
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
            child: const Icon(FIcons.x, size: 14),
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

  String? _normalizePriority(String? priority) {
    if (priority == null) return null;
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return null; // Return null for unrecognized values
    }
  }
}
