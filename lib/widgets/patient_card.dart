import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';
import '../models/patient.dart';

class PatientCard extends StatefulWidget {
  final Patient patient;
  final VoidCallback? onEdit;

  const PatientCard({super.key, required this.patient, this.onEdit});

  @override
  State<PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<PatientCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: FAccordion(
        children: [
          FAccordionItem(
            title: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.go('/patients/${widget.patient.id}'),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        _buildAvatar(context),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.patient.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              _buildPatientInfo(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.onEdit != null)
                  FButton.icon(
                    style: FButtonStyle.outline(),
                    onPress: widget.onEdit,
                    child: Icon(FIcons.pencil),
                  ),
              ],
            ),
            child: _buildPatientDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          widget.patient.name.isNotEmpty
              ? widget.patient.name[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    final List<String> infoItems = [];

    if (widget.patient.age != null) {
      infoItems.add('${widget.patient.age}y');
    }

    if (widget.patient.gender != null) {
      infoItems.add(widget.patient.gender!);
    }

    if (widget.patient.createdAt != null) {
      infoItems.add('Added recently');
    }

    return Text(infoItems.join(' • '), style: const TextStyle(fontSize: 12));
  }

  Widget _buildPatientDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient ID
          _buildDetailRow('Patient ID', widget.patient.id.toString()),

          // Age details
          if (widget.patient.age != null)
            _buildDetailRow('Age', '${widget.patient.age} years old'),

          // Gender
          if (widget.patient.gender != null)
            _buildDetailRow('Gender', widget.patient.gender!),

          // Medical History
          if (widget.patient.medicalHistory != null &&
              widget.patient.medicalHistory!.isNotEmpty)
            _buildDetailRow('Medical History', widget.patient.medicalHistory!),

          // Height
          if (widget.patient.height != null)
            _buildDetailRow('Height', '${widget.patient.height} cm'),

          // Weight
          if (widget.patient.weight != null)
            _buildDetailRow('Weight', '${widget.patient.weight} kg'),

          // Tags
          if (widget.patient.tags != null && widget.patient.tags!.isNotEmpty)
            _buildDetailRow('Tags', widget.patient.tags!.join(', ')),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FButton(
                  style: FButtonStyle.primary(),
                  onPress: () => context.go('/patients/${widget.patient.id}'),
                  child: const Text('View Full Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
