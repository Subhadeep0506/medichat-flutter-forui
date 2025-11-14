import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:forui/forui.dart';
import '../providers/current_patient_provider.dart';
import '../providers/current_case_provider.dart';
import 'patient_case_details_popover.dart';

class PatientCaseInfoSection extends StatelessWidget {
  final String patientId;
  final String caseId;

  const PatientCaseInfoSection({
    super.key,
    required this.patientId,
    required this.caseId,
  });

  @override
  Widget build(BuildContext context) {
    // Safely try to get the providers, return empty widget if not available
    try {
      final currentPatient = context
          .watch<CurrentPatientProvider>()
          .currentPatient;
      final currentCase = context.watch<CurrentCaseProvider>().currentCase;

      if (currentPatient == null || currentCase == null) {
        return const SizedBox.shrink();
      }

      return _buildInfoSection(context, currentPatient, currentCase);
    } catch (e) {
      // Providers not available in this context, return empty widget
      return const SizedBox.shrink();
    }
  }

  Widget _buildInfoSection(
    BuildContext context,
    dynamic currentPatient,
    dynamic currentCase,
  ) {
    final ftheme = FTheme.of(context);
    return Material(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          final maxHeight = MediaQuery.of(context).size.height * 0.7;
          showFDialog(
            context: context,
            builder: (ctx, style, animation) => ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: PatientCaseDetailsPopover(
                patient: currentPatient,
                medicalCase: currentCase,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ftheme.colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FIcons.shieldUser,
                  color: ftheme.colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentPatient.name,
                      style: ftheme.typography.base.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ftheme.colors.foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentCase.title,
                      style: ftheme.typography.sm.copyWith(
                        color: ftheme.colors.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                FIcons.arrowRight,
                size: 20,
                color: ftheme.colors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
