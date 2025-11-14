import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:forui/forui.dart';
import '../widgets/ui/ui_widgets.dart';
import 'package:uuid/uuid.dart';
import '../providers/patient_provider.dart';
import '../utils/token_expiration_handler.dart';
import '../utils/date_formatter.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen>
    with TokenExpirationHandler, SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _dobController = TextEditingController();
  late final FDateFieldController _fDateController;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _medicalHistoryController = TextEditingController();

  bool _isLoading = false;
  String? _selectedDateISO; // Store ISO format for API submission
  String? _selectedGender; // Store selected gender

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _fDateController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fDateController = FDateFieldController(vsync: this);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Generate UUID for patient ID
    final patientId = const Uuid().v4();

    final patient = await handleTokenExpiration(() async {
      final patientProvider = context.read<PatientProvider>();
      return await patientProvider.create(
        patientId,
        _nameController.text.trim(),
        _ageController.text.trim().isEmpty
            ? 0
            : int.parse(_ageController.text.trim()),
        _selectedGender ?? '',
        _heightController.text.trim(),
        _weightController.text.trim(),
        _selectedDateISO ?? '', // Use ISO format for API
        _medicalHistoryController.text.trim(),
      );
    });

    setState(() => _isLoading = false);

    if (mounted && patient != null) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  // Date selection is handled by the ForUI AppDateField and controller.

  void _cancelForm() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Widget _buildFormField(Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [field],
    );
  }

  // Input decoration helper removed; ForUI components manage styling.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FScaffold(
      header: FHeader(
        style: (style) => style.copyWith(
          titleTextStyle: style.titleTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        title: Center(child: Text('Add New Patient')),
        suffixes: [
          AppIconButton(
            icon: FIcons.x,
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
                  'Patient Information',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please fill in the patient details below',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 30),

                // Name Field (ForUI)
                _buildFormField(
                  FormField<String>(
                    validator: (_) {
                      if (_nameController.text.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                    builder: (state) => Column(
                      children: [
                        AppTextField(
                          label: Text('Full Name *'),
                          controller: _nameController,
                          hintText: 'Enter patient full name',
                          prefixIcon: const Icon(FIcons.user),
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              state.errorText!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        FormField<String>(
                          validator: (_) {
                            final value = _ageController.text.trim();
                            if (value.isNotEmpty) {
                              final age = int.tryParse(value);
                              if (age == null || age <= 0 || age > 150) {
                                return 'Please enter a valid age';
                              }
                            }
                            return null;
                          },
                          builder: (state) => Column(
                            children: [
                              AppTextField(
                                label: const Text('Age'),
                                controller: _ageController,
                                hintText: 'Enter patient age (optional)',
                                prefixIcon: const Icon(FIcons.calendar),
                                keyboardType: TextInputType.number,
                              ),
                              if (state.hasError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    state.errorText!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildFormField(
                        AppSelect(
                          label: const Text('Gender'),
                          itemsList: const ['Male', 'Female', 'Other'],
                          value: _selectedGender,
                          onChanged: (v) => setState(() => _selectedGender = v),
                          hint: 'Select gender (optional)',
                          prefixIcon: const Icon(FIcons.users),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Date of Birth Field (ForUI Date picker)
                // Use a FormField wrapper to integrate validation with the Form
                FormField<String>(
                  validator: (_) {
                    if (_selectedDateISO == null || _selectedDateISO!.isEmpty) {
                      return 'Date of birth is required';
                    }
                    return null;
                  },
                  builder: (state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppDateField(
                        controller: _fDateController,
                        onIsoChanged: (iso) {
                          setState(() => _selectedDateISO = iso);
                          state.didChange(iso);
                          // Keep a simple text field value for compatibility (optional)
                          _dobController.text = iso != null
                              ? DateFormatter.formatLongDate(
                                  DateTime.parse(iso),
                                )
                              : '';
                        },
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            state.errorText!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Height and Weight Row
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        AppTextField(
                          label: const Text('Height'),
                          controller: _heightController,
                          hintText: 'e.g., 175 cm',
                          prefixIcon: const Icon(FIcons.ruler),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFormField(
                        AppTextField(
                          label: const Text('Weight'),
                          controller: _weightController,
                          hintText: 'e.g., 70 kg',
                          prefixIcon: const Icon(FIcons.weight),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Medical History Field (ForUI)
                _buildFormField(
                  FormField<String>(
                    validator: (_) {
                      if (_medicalHistoryController.text.trim().isEmpty) {
                        return 'Medical history is required';
                      }
                      return null;
                    },
                    builder: (state) => Column(
                      children: [
                        AppTextField(
                          label: const Text('Medical History *'),
                          controller: _medicalHistoryController,
                          hintText: 'Enter relevant medical history',
                          prefixIcon: const Icon(FIcons.fileText),
                          maxLines: 4,
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              state.errorText!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
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
                        label: 'Add Patient',
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
}
