import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../services/toast_service.dart';

class FeedbackDialog extends StatefulWidget {
  final String messageId;
  final Function(String messageId, {String? feedback, int? stars})
  onSubmitFeedback;
  final String? initialFeedback;
  final int? initialStars;

  const FeedbackDialog({
    super.key,
    required this.messageId,
    required this.onSubmitFeedback,
    this.initialFeedback,
    this.initialStars,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  late TextEditingController _feedbackController;
  int _selectedStars = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController(
      text: widget.initialFeedback ?? '',
    );
    _selectedStars = widget.initialStars ?? 0;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_selectedStars == 0 && _feedbackController.text.trim().isEmpty) {
      ToastService.showError('Please provide a rating or feedback');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmitFeedback(
        widget.messageId,
        feedback: _feedbackController.text.trim().isNotEmpty
            ? _feedbackController.text.trim()
            : null,
        stars: _selectedStars > 0 ? _selectedStars : null,
      );

      if (mounted) {
        ToastService.showInfo('Feedback submitted successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError('Failed to submit feedback: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildStarRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating',
          style: FTheme.of(context).typography.sm.copyWith(
            fontWeight: FontWeight.w600,
            color: FTheme.of(context).colors.foreground,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            final isSelected = starNumber <= _selectedStars;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStars = starNumber == _selectedStars
                      ? 0
                      : starNumber;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  isSelected ? FIcons.star : FIcons.star,
                  color: isSelected
                      ? Colors.amber
                      : FTheme.of(context).colors.border,
                  size: 24,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          _selectedStars > 0 ? '$_selectedStars out of 5 stars' : 'Tap to rate',
          style: FTheme.of(context).typography.xs.copyWith(
            color: FTheme.of(context).colors.mutedForeground,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FDialog(
      direction: Axis.horizontal,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              FIcons.messageSquare,
              color: theme.colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provide Feedback',
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Help improve AI responses',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          FButton.icon(
            style: FButtonStyle.ghost(),
            onPress: () => Navigator.of(context).pop(),
            child: const Icon(FIcons.x),
          ),
        ],
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStarRating(),
            const SizedBox(height: 16),
            Text(
              'Additional Comments (Optional)',
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            FTextField(
              controller: _feedbackController,
              hint: 'Share your thoughts about this response...',
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        FButton(
          style: FButtonStyle.outline(),
          onPress: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FButton(
          onPress: _isSubmitting ? null : _submitFeedback,
          child: _isSubmitting
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Submitting...'),
                  ],
                )
              : const Text('Submit Feedback'),
        ),
      ],
    );
  }
}
