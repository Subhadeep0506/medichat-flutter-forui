import 'package:MediChat/widgets/ui/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';
import '../models/case.dart';
import '../utils/date_formatter.dart';

class CaseCard extends StatefulWidget {
  final MedicalCase medicalCase;
  final String patientId;
  final VoidCallback? onEdit;

  const CaseCard({
    super.key,
    required this.medicalCase,
    required this.patientId,
    this.onEdit,
  });

  @override
  State<CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<CaseCard> {
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
                    onTap: () => _navigateToChat(),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        _buildCaseAvatar(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.medicalCase.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              _buildCaseInfo(),
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
            child: _buildCaseDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getPriorityColor(widget.medicalCase.priority),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        _getPriorityIcon(widget.medicalCase.priority),
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildCaseInfo() {
    final List<String> infoItems = [];

    if (widget.medicalCase.priority != null) {
      infoItems.add(widget.medicalCase.priority!);
    }

    if (widget.medicalCase.createdAt != null) {
      infoItems.add(
        DateFormatter.formatDateTime(widget.medicalCase.createdAt!),
      );
    }

    return Row(
      children: [
        _buildPriorityBadge(),
        if (infoItems.length > 1) ...[
          const SizedBox(width: 8),
          Text(
            infoItems.skip(1).join(' • '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriorityBadge() {
    if (widget.medicalCase.priority == null) return const SizedBox();

    final priorityColor = _getPriorityColor(widget.medicalCase.priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priorityColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.medicalCase.priority!.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCaseDetails() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.medicalCase.description.isNotEmpty) ...[
            Text(
              'Description',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              widget.medicalCase.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
          ],
          if (widget.medicalCase.tags?.isNotEmpty ?? false) ...[
            Text(
              'Tags',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.medicalCase.tags!
                  .map(
                    (tag) => FBadge(
                      style: FBadgeStyle.secondary((style) {
                        return style.copyWith(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentStyle: style.contentStyle
                              .copyWith(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                              )
                              .call,
                        );
                      }),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.medicalCase.createdAt != null)
                Text(
                  'Created: ${DateFormatter.formatDateTime(widget.medicalCase.createdAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              AppButton(
                label: 'Chat',
                onPressed: _navigateToChat,
                leading: Icon(FIcons.messageSquare),
                style: FButtonStyle.secondary(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
      case 'urgent':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getPriorityIcon(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
      case 'urgent':
        return FIcons.triangleAlert;
      case 'medium':
        return FIcons.minus;
      case 'low':
        return FIcons.arrowDown;
      default:
        return FIcons.fileText;
    }
  }

  void _navigateToChat() {
    // Navigate to chat - session creation will be handled on the chat screen
    context.go(
      '/patients/${widget.patientId}/cases/${widget.medicalCase.id}/chat',
    );
  }
}
