import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';
import '../providers/session_provider.dart';
import '../widgets/app_loading_widget.dart';
import '../utils/token_expiration_handler.dart';

/// Wrapper screen that handles navigation to chat for a case.
/// It automatically gets or creates a session for the case and then
/// navigates to the chat session screen.
class CaseChatWrapperScreen extends StatefulWidget {
  final String patientId;
  final String caseId;

  const CaseChatWrapperScreen({
    super.key,
    required this.patientId,
    required this.caseId,
  });

  @override
  State<CaseChatWrapperScreen> createState() => _CaseChatWrapperScreenState();
}

class _CaseChatWrapperScreenState extends State<CaseChatWrapperScreen>
    with TokenExpirationHandler {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure the build is complete before navigating
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToSession();
    });
  }

  Future<void> _navigateToSession() async {
    if (_isNavigating || !mounted) return;

    setState(() {
      _isNavigating = true;
    });

    try {
      await handleTokenExpiration(() async {
        final sessionProvider = context.read<SessionProvider>();

        // First, try to refresh the sessions for this case
        await sessionProvider.refresh(
          widget.caseId,
          patientId: widget.patientId,
        );

        // Get the list of sessions for this case
        final sessions = sessionProvider.sessionsFor(widget.caseId);

        String? sessionId;

        if (sessions.isNotEmpty) {
          // Use the most recent session (last in the list)
          sessionId = sessions.last.id;
        } else {
          // No sessions exist, create a new one
          final newSession = await sessionProvider.create(
            widget.caseId,
            patientId: widget.patientId,
            title: 'New Chat Session',
          );

          if (newSession == null) {
            // Failed to create session
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to create chat session')),
              );
              // Go back to the previous screen
              context.pop();
            }
            return;
          }

          sessionId = newSession.id;
        }

        // Navigate to the chat session screen
        if (mounted) {
          context.go(
            '/patients/${widget.patientId}/cases/${widget.caseId}/sessions/$sessionId',
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat: ${e.toString()}')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLoadingWidget.large(),
            SizedBox(height: 16),
            Text('Loading chat session...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
