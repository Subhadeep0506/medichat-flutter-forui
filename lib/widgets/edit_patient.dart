import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../providers/patient_provider.dart';

import 'package:forui/forui.dart';
import 'ui/app_text_field.dart';
import 'ui/app_button.dart';
import 'ui/app_select.dart';
import 'ui/app_date_field.dart';
import '../utils/token_expiration_handler.dart';
import 'app_loading_widget.dart';

class EditPatientDialog extends StatefulWidget {
  final Patient patient;
  final PatientProvider patientProvider;

  const EditPatientDialog({
    super.key,
    required this.patient,
    required this.patientProvider,
  });

  @override
  State<EditPatientDialog> createState() => _EditPatientDialogState();
}

class _EditPatientDialogState extends State<EditPatientDialog>
    with TokenExpirationHandler, SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late final FDateFieldController _dateFieldController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _medicalHistoryController;
  final _tagController = TextEditingController();

  String? _selectedGender;
  bool _isLoading = false;
  List<String> _tags = [];
  String? _selectedDateISO; // Store ISO format for API submission

  @override
  void initState() {
    super.initState();
    final patient = widget.patient;

    _nameController = TextEditingController(text: patient.name);
    _ageController = TextEditingController(text: patient.age?.toString() ?? '');

    // Initialize date controller and keep ISO value for API submission
    DateTime? initialDate;
    if (patient.dob != null && patient.dob!.isNotEmpty) {
      _selectedDateISO =
          patient.dob; // Keep original format for potential re-submission
      try {
        final parsed = DateTime.parse(patient.dob!).toLocal();
        initialDate = parsed;
      } catch (e) {
        // Fallback to a reasonable default if parsing fails
        initialDate = DateTime.now().subtract(const Duration(days: 365 * 25));
      }
    } else {
      initialDate = DateTime.now().subtract(const Duration(days: 365 * 25));
    }

    _dateFieldController = FDateFieldController(
      vsync: this,
      initialDate: initialDate,
    );

    _heightController = TextEditingController(text: patient.height ?? '');
    _weightController = TextEditingController(text: patient.weight ?? '');
    _medicalHistoryController = TextEditingController(
      text: patient.medicalHistory ?? '',
    );
    _tags = List.from(patient.tags ?? []);
    // Normalize gender case to match dropdown items
    _selectedGender = _normalizeGender(patient.gender);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _dateFieldController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medicalHistoryController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await handleTokenExpiration(() async {
        await widget.patientProvider.update(
          widget.patient.id,
          name: _nameController.text.trim(),
          age: int.tryParse(_ageController.text.trim()),
          gender: _selectedGender,
          dob: (_selectedDateISO == null || _selectedDateISO!.isEmpty)
              ? null
              : _selectedDateISO,
          height: _heightController.text.trim().isEmpty
              ? null
              : _heightController.text.trim(),
          weight: _weightController.text.trim().isEmpty
              ? null
              : _weightController.text.trim(),
          medicalHistory: _medicalHistoryController.text.trim().isEmpty
              ? null
              : _medicalHistoryController.text.trim(),
          tags: _tags.isEmpty ? null : _tags,
        );
      });

      if (mounted) {
        Navigator.of(context).pop('success'); // Return success to parent
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop('error:$e'); // Return error to parent
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Forui dialog for consistent theming
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
              FIcons.idCard,
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
                  'Edit Patient',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Update patient information',
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
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: const Text('Full Name'),
                  hintText: 'Enter patient full name',
                  prefixIcon: const Icon(FIcons.user),
                  // Simple validation handled in _save via formKey
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _ageController,
                        label: const Text('Age'),
                        hintText: 'Enter age',
                        prefixIcon: const Icon(FIcons.cake),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppSelect(
                        label: const Text('Gender'),
                        itemsMap: const {
                          'Male': 'Male',
                          'Female': 'Female',
                          'Other': 'Other',
                        },
                        value: _selectedGender,
                        onChanged: (v) => setState(() => _selectedGender = v),
                        prefixIcon: const Icon(FIcons.users),
                        clearable: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date of birth field uses Forui's FDateField via AppDateField wrapper
                AppDateField(
                  controller: _dateFieldController,
                  onIsoChanged: (iso) => setState(() => _selectedDateISO = iso),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _heightController,
                        label: const Text('Height'),
                        hintText: 'cm',
                        prefixIcon: const Icon(FIcons.ruler),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _weightController,
                        label: const Text('Weight'),
                        hintText: 'kg',
                        prefixIcon: const Icon(FIcons.weight),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                AppTextField(
                  controller: _medicalHistoryController,
                  label: const Text('Medical History'),
                  hintText: 'Enter medical history and notes',
                  prefixIcon: const Icon(FIcons.fileText),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),

                // Actions are provided in the dialog's actions parameter below.
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
          leading: _isLoading ? const AppLoadingWidget.small() : null,
        ),
      ],
    );
  }

  String? _normalizeGender(String? gender) {
    if (gender == null) return null;
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return null; // Return null for unrecognized values
    }
  }
}
