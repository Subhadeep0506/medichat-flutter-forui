import 'package:flutter/material.dart';

import 'package:forui/forui.dart';
import '../models/patient.dart';
import '../models/case.dart';
import '../widgets/ui/app_button.dart';

class PatientCaseDetailsPopover extends StatelessWidget {
  final Patient patient;
  final MedicalCase medicalCase;

  const PatientCaseDetailsPopover({
    super.key,
    required this.patient,
    required this.medicalCase,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return FDialog(
      direction: Axis.horizontal,
      title: Row(
        children: [
          _buildDialogIcon(
            context,
            FIcons.heartPlus,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient & Case Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Comprehensive patient record & current case context',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
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
      body: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth > 800 ? 640 : screenWidth * 0.95,
          maxHeight: screenHeight * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                context,
                'Patient Information',
                FIcons.shieldUser,
              ),
              const SizedBox(height: 8),
              _buildPatientInfo(context),
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'Medical Case', FIcons.clipboard),
              const SizedBox(height: 8),
              _buildCaseInfo(context),
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          label: 'Close',
          style: FButtonStyle.ghost(),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        _buildSectionIcon(
          context,
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPatientInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRowWithIcon(context, 'Name', patient.name, FIcons.user),
          _buildDoubleInfoRow(
            context,
            'Age',
            patient.age != null ? '${patient.age} years' : '-',
            FIcons.cake,
            'Gender',
            patient.gender ?? '-',
            FIcons.users,
          ),
          _buildInfoRowWithIcon(
            context,
            'Date of Birth',
            patient.dob != null ? _formatDateOfBirth(patient.dob!) : '-',
            FIcons.calendar,
          ),
          _buildDoubleInfoRow(
            context,
            'Height',
            patient.height ?? '-',
            FIcons.ruler,
            'Weight',
            patient.weight ?? '-',
            FIcons.weight,
          ),
          _buildInfoRowWithIcon(
            context,
            'Medical History',
            patient.medicalHistory?.isNotEmpty == true
                ? patient.medicalHistory!
                : '-',
            FIcons.clipboard,
            isMultiline: true,
          ),
          _buildInfoRowWithIcon(
            context,
            'Created Date',
            patient.createdAt != null ? _formatDate(patient.createdAt!) : '-',
            FIcons.calendar1,
          ),
          _buildInfoRowWithIcon(
            context,
            'Last Updated',
            patient.updatedAt != null ? _formatDate(patient.updatedAt!) : '-',
            FIcons.userPen,
          ),
        ],
      ),
    );
  }

  Widget _buildCaseInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDoubleInfoRow(
            context,
            'Case Title',
            medicalCase.title,
            FIcons.notebook,
            'Priority',
            medicalCase.priority ?? '-',
            FIcons.shieldAlert,
          ),
          _buildInfoRowWithIcon(
            context,
            'Description',
            medicalCase.description.isNotEmpty ? medicalCase.description : '-',
            FIcons.fileText,
            isMultiline: true,
          ),
          _buildTagsRow(
            context,
            'Case Tags',
            medicalCase.tags?.isNotEmpty == true ? medicalCase.tags! : [],
          ),
          Column(
            children: [
              _buildInfoRowWithIcon(
                context,
                'Created Date',
                medicalCase.createdAt != null
                    ? _formatDate(medicalCase.createdAt!)
                    : '-',
                FIcons.calendar1,
              ),
              _buildInfoRowWithIcon(
                context,
                'Last Updated',
                medicalCase.updatedAt != null
                    ? _formatDate(medicalCase.updatedAt!)
                    : '-',
                FIcons.calendarCheck,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithIcon(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInlineIcon(
            context,
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubleInfoRow(
    BuildContext context,
    String label1,
    String value1,
    IconData icon1,
    String label2,
    String value2,
    IconData icon2,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInlineIcon(
                  context,
                  icon1,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label1.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInlineIcon(
                  context,
                  icon2,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label2.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value2,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsRow(BuildContext context, String label, List<String> tags) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInlineIcon(
            context,
            FIcons.tags,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                tags.isEmpty
                    ? Text(
                        '-',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today (${date.day}/${date.month}/${date.year})';
    } else if (difference.inDays == 1) {
      return 'Yesterday (${date.day}/${date.month}/${date.year})';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago (${date.day}/${date.month}/${date.year})';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateOfBirth(String dobString) {
    try {
      // Parse API timestamp and extract date components to avoid timezone shifts
      // Handles formats like: 2005-12-15T18:30:00.000Z
      final parsed = DateTime.parse(dobString).toLocal();
      final dob = DateTime(parsed.year, parsed.month, parsed.day);

      final now = DateTime.now();
      final age =
          now.year -
          dob.year -
          (now.month < dob.month ||
                  (now.month == dob.month && now.day < dob.day)
              ? 1
              : 0);

      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${dob.day} ${months[dob.month - 1]} ${dob.year} (Age: $age)';
    } catch (e) {
      // If parsing fails, return the original string
      return dobString;
    }
  }

  // --- New styling helpers for consistency with ChatSettingsDialog ---
  Decoration _panelDecoration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: scheme.surfaceVariant.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: scheme.outline.withValues(alpha: 0.15),
        width: 1,
      ),
    );
  }

  Widget _buildDialogIcon(BuildContext context, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color ?? Theme.of(context).colorScheme.primary,
        size: 24,
      ),
    );
  }

  Widget _buildSectionIcon(
    BuildContext context,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 16,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildInlineIcon(BuildContext context, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 14,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
