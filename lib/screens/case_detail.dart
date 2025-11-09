import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:forui/forui.dart';
import '../providers/session_provider.dart';
import '../providers/case_provider.dart';
import '../widgets/styled_icon_button.dart';
import '../utils/token_expiration_handler.dart';

class CaseDetailScreen extends StatefulWidget {
  final String patientId;
  final String caseId;
  const CaseDetailScreen({
    super.key,
    required this.patientId,
    required this.caseId,
  });
  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen>
    with TokenExpirationHandler {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Provide patientId so remote session listing (which requires patient_id) succeeds
      handleTokenExpiration(() async {
        await context.read<SessionProvider>().refresh(
          widget.caseId,
          patientId: widget.patientId,
        );
      });
    });
  }

  Future<void> _startNewSession() async {
    final titleCtrl = TextEditingController();
    await showFDialog(
      context: context,
      builder: (ctx, style, animation) {
        final ftheme = FTheme.of(ctx);
        return FDialog(
          style: style,
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
                  FIcons.messageSquareText,
                  color: ftheme.colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'New Chat Session',
                  style: ftheme.typography.lg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ftheme.colors.foreground,
                  ),
                ),
              ),
              FButton.icon(
                style: FButtonStyle.ghost(),
                onPress: () => Navigator.pop(ctx),
                child: const Icon(FIcons.x),
              ),
            ],
          ),
          body: TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Session Title (optional)',
            ),
          ),
          actions: [
            FButton(
              style: FButtonStyle.outline(),
              onPress: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FButton(
              onPress: () async {
                final session = await handleTokenExpiration(() async {
                  return await context.read<SessionProvider>().create(
                    widget.caseId,
                    title: titleCtrl.text.trim().isEmpty
                        ? null
                        : titleCtrl.text.trim(),
                    patientId: widget.patientId,
                  );
                });
                if (context.mounted && session != null) {
                  Navigator.pop(ctx);
                  // Navigate directly to the new session
                  context.go(
                    '/patients/${widget.patientId}/cases/${widget.caseId}/sessions/${session.id}',
                  );
                }
              },
              child: const Text('Start Chat'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final caseObj = context.select<CaseProvider, dynamic>(
      (prov) => prov
          .casesFor(widget.patientId)
          .firstWhere((c) => c.id == widget.caseId),
    );
    return FScaffold(
      header: FHeader(
        style: (style) => style.copyWith(
          titleTextStyle: style.titleTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/patients/${widget.patientId}');
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(FIcons.arrowLeft),
              ),
            ),
            Flexible(
              child: Text(caseObj.title, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        suffixes: [
          FHeaderAction(
            icon: Icon(FIcons.messageSquarePlus),
            onPress: _startNewSession,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Case Details',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Title: ${caseObj.title}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          if (caseObj.description?.isNotEmpty == true) ...[
                            Text(
                              'Description:',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              caseObj.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat Sessions',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Start a new chat session to discuss this case with AI. Previous sessions can be accessed through the sidebar once you\'re in a chat.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _startNewSession,
                              icon: const Icon(FIcons.filePlus2),
                              label: const Text('Start New Chat Session'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: WidgetsBinding.instance.window.viewInsets.bottom + 20,
            child: StyledFloatingActionButton(
              icon: FIcons.messageSquarePlus,
              label: 'Start Chat',
              tooltip: 'Start New Chat Session',
              onPressed: _startNewSession,
            ),
          ),
        ],
      ),
    );
  }
}
