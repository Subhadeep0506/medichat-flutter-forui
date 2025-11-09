// ChatSessionScreen – clean single implementation with safety badge & session management.
import 'package:MediChat/widgets/custom_text_field.dart';
import 'package:MediChat/widgets/styled_icon_button.dart';
import 'package:MediChat/widgets/ui/ui_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../models/session.dart';
import '../models/chat_settings.dart';
import '../providers/chat_provider.dart';
import '../providers/session_provider.dart';
import '../providers/chat_settings_provider.dart';
import '../providers/current_patient_provider.dart';
import '../providers/current_case_provider.dart';
import '../widgets/app_loading_widget.dart';
import '../providers/patient_provider.dart';
import '../providers/case_provider.dart';
import '../services/toast_service.dart';
import '../widgets/chat_settings_dialog.dart';
import '../widgets/patient_case_info_section.dart';
import '../utils/token_expiration_handler.dart';

class ChatSessionScreen extends StatefulWidget {
  final String patientId;
  final String caseId;
  final String sessionId;
  const ChatSessionScreen({
    super.key,
    required this.patientId,
    required this.caseId,
    required this.sessionId,
  });
  @override
  State<ChatSessionScreen> createState() => _ChatSessionScreenState();
}

class _ChatSessionScreenState extends State<ChatSessionScreen>
    with TokenExpirationHandler {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _init = false;
  bool _sidebarVisible = false; // controls visibility of the sessions sidebar

  @override
  void initState() {
    super.initState();
    _input.addListener(() {
      setState(() {}); // Rebuild to update send button state
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _init = true;
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          handleTokenExpiration(() async {
            await context.read<ChatProvider>().load(widget.sessionId);
            await context.read<SessionProvider>().refresh(
              widget.caseId,
              patientId: widget.patientId,
            );
          });

          // Set current patient and case for the sidebar
          final patientProvider = context.read<PatientProvider>();
          final caseProvider = context.read<CaseProvider>();
          final currentPatientProvider = context.read<CurrentPatientProvider>();
          final currentCaseProvider = context.read<CurrentCaseProvider>();

          final patient = patientProvider.getPatientById(widget.patientId);
          if (patient != null) {
            currentPatientProvider.setCurrentPatient(patient);
          }

          final medicalCase = caseProvider.getCaseById(
            widget.caseId,
            widget.patientId,
          );
          if (medicalCase != null) {
            currentCaseProvider.setCurrentCase(medicalCase);
          }
        }
      });
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();

    // Get chat settings
    final chatSettings = context.read<ChatSettingsProvider>().settings;

    await handleTokenExpiration(() async {
      await context.read<ChatProvider>().sendMessage(
        widget.sessionId,
        text,
        caseId: widget.caseId,
        patientId: widget.patientId,
        chatSettings: chatSettings.toQueryParameters(),
      );
    });
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 40));
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _showChatSettings() {
    // Try to get the provider instance to pass to the dialog
    ChatSettingsProvider? provider;
    try {
      provider = context.read<ChatSettingsProvider>();
    } catch (e) {
      // Provider not available, dialog will handle this
      provider = null;
    }

    showFDialog(
      context: context,
      builder: (ctx, style, animation) =>
          ChatSettingsDialog(provider: provider),
    );
  }

  Widget _buildSettingsButton() {
    // Using a simple approach instead of Consumer to avoid provider issues
    return Builder(
      builder: (context) {
        // Try to get the provider, if it fails, show a simple settings button
        try {
          final settingsProvider = context.watch<ChatSettingsProvider>();
          final isCustom = settingsProvider.settings != const ChatSettings();

          return Tooltip(
            message: isCustom ? 'Chat Settings (Custom)' : 'Chat Settings',
            child: Stack(
              children: [
                FButton.icon(
                  style: isCustom
                      ? FButtonStyle.outline()
                      : FButtonStyle.ghost(),
                  onPress: _showChatSettings,
                  child: Icon(FIcons.settings, size: 20),
                ),
                if (isCustom)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          );
        } catch (e) {
          // Fallback: simple settings button without provider dependency
          return Tooltip(
            message: 'Chat Settings',
            child: FButton.icon(
              style: FButtonStyle.ghost(),
              onPress: _showChatSettings,
              child: Icon(FIcons.settings, size: 20),
            ),
          );
        }
      },
    );
  }

  void _open(ChatSession s) {
    if (s.id == widget.sessionId) return;
    context.go(
      '/patients/${widget.patientId}/cases/${widget.caseId}/sessions/${s.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final chat = context.watch<ChatProvider>();
      final loading = chat.isLoading(widget.sessionId);
      final sending = chat.isSending(widget.sessionId);
      final messages = chat.messagesFor(widget.sessionId);
      final theme = FTheme.of(context);

      return FScaffold(
        childPad: false,
        header: FHeader(
          style: (style) => style.copyWith(
            titleTextStyle: style.titleTextStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          title: Row(
            children: [
              StyledIconButton(
                icon: FIcons.arrowLeft,
                onPressed: () => context.go('/patients/${widget.patientId}'),
                tooltip: 'Back to Patient',
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  FIcons.messageCircleMore,
                  size: 20,
                  color: theme.colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MediChat',
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: theme.colors.foreground,
                    ),
                  ),
                  Text(
                    'AI Medical Assistant',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FButton.icon(
                style: FButtonStyle.ghost(),
                onPress: () =>
                    setState(() => _sidebarVisible = !_sidebarVisible),
                child: Icon(
                  _sidebarVisible ? FIcons.menu : FIcons.menu,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              FButton.icon(
                style: FButtonStyle.ghost(),
                onPress: () => chat.forceRefresh(widget.sessionId),
                child: Icon(FIcons.refreshCw, size: 20),
              ),
            ],
          ),
        ),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: false,
          removeLeft: true,
          removeRight: true,
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: loading
                        ? const Center(child: AppLoadingWidget.large())
                        : _MessagesList(
                            controller: _scroll,
                            messages: messages,
                          ),
                  ),
                  // Chat input field
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: 8,
                        left: 8,
                        right: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Settings button
                          _buildSettingsButton(),
                          const SizedBox(width: 8),
                          // Input field
                          Expanded(
                            child: FTextField(
                              controller: _input,
                              hint: 'Type your medical question...',
                              maxLines: 1,
                              keyboardType: TextInputType.multiline,
                              onSubmit: (_) => _send(),
                              suffixBuilder: (context, state, enabled) =>
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: sending
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: AppLoadingWidget(size: 20),
                                          )
                                        : GestureDetector(
                                            onTap: _input.text.trim().isNotEmpty
                                                ? _send
                                                : null,
                                            child: Icon(
                                              FIcons.send,
                                              size: 20,
                                              color:
                                                  _input.text.trim().isNotEmpty
                                                  ? theme.colors.primary
                                                  : theme
                                                        .colors
                                                        .mutedForeground,
                                            ),
                                          ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Dimmer overlay when sidebar is visible
              if (_sidebarVisible)
                GestureDetector(
                  onTap: () => setState(() => _sidebarVisible = false),
                  child: Container(color: Colors.black.withValues(alpha: 0.3)),
                ),
              // Sidebar overlay
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: _sidebarVisible ? 0 : -320,
                top: 0,
                bottom: 0,
                width: 320,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.95),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    boxShadow: _sidebarVisible
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.shadow.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(4, 0),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(2, 0),
                            ),
                          ]
                        : null,
                  ),
                  child: _SessionsSidebar(
                    caseId: widget.caseId,
                    patientId: widget.patientId,
                    activeSessionId: widget.sessionId,
                    onOpen: _open,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Handle provider errors gracefully
      return FScaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error loading chat session',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              FButton(
                onPress: () => context.go('/patients/${widget.patientId}'),
                child: const Text('Back to Patient'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _MessagesList extends StatelessWidget {
  final ScrollController controller;
  final List<ChatMessage> messages;
  const _MessagesList({required this.controller, required this.messages});

  String _strip(String s) => s.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  @override
  Widget build(BuildContext context) {
    // Enhanced placeholder when there are no messages
    if (messages.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Determine if we have enough space for centered layout
          final bool hasEnoughSpace = constraints.maxHeight > 600;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: hasEnoughSpace ? constraints.maxHeight - 48 : 0,
              ),
              child: Column(
                mainAxisAlignment: hasEnoughSpace
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  if (!hasEnoughSpace) const SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(hasEnoughSpace ? 32 : 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          Theme.of(context).colorScheme.tertiaryContainer
                              .withValues(alpha: 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      FIcons.heartPulse,
                      size: hasEnoughSpace ? 64 : 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: hasEnoughSpace ? 24 : 16),
                  Text(
                    '🏥 Welcome to MediChat',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontSize: hasEnoughSpace ? null : 20,
                    ),
                  ),
                  SizedBox(height: hasEnoughSpace ? 12 : 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Your AI-powered medical assistant is ready to help. Ask questions about symptoms, treatments, or general health information.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.5,
                        fontSize: hasEnoughSpace ? null : 14,
                      ),
                    ),
                  ),
                  SizedBox(height: hasEnoughSpace ? 24 : 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              FIcons.info,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Quick Tips',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Describe symptoms clearly\n• Mention relevant medical history\n• Ask about treatment options\n• Request health tips',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!hasEnoughSpace) const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      controller: controller,
      // Remove top padding entirely to sit flush beneath header
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: messages.length,
      itemBuilder: (c, i) {
        final m = messages[i];
        if (m.role != ChatRole.user) {
          final content = m.content;
          final last = content.lastIndexOf('</think>');
          String? think;
          String answer;
          if (last != -1) {
            final before = content.substring(0, last);
            final after = content.substring(last + 8);
            final start = before.indexOf('<think>');
            if (start != -1) {
              think = before.substring(start + 7).trim();
            }
            answer = _strip(after.trim());
          } else {
            answer = _strip(content);
          }
          if (answer.isEmpty) answer = content;
          return _AIMessageBubble(
            answer: answer,
            think: think,
            pending: m.pending,
            original: m,
            isFirst: i == 0,
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                // Eliminate top margin for very first user message
                margin: EdgeInsets.fromLTRB(0, i == 0 ? 0 : 32, 0, 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: MarkdownBody(
                    data: m.content.trim().isEmpty ? '(empty)' : m.content,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                FIcons.user,
                size: 18,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AIMessageBubble extends StatefulWidget {
  final String answer;
  final String? think;
  final bool pending;
  final ChatMessage? original;
  final bool isFirst;
  const _AIMessageBubble({
    required this.answer,
    required this.think,
    required this.pending,
    this.original,
    this.isFirst = false,
  });

  @override
  State<_AIMessageBubble> createState() => _AIMessageBubbleState();
}

class _AIMessageBubbleState extends State<_AIMessageBubble> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final safetyScore = widget.original?.safetyScore;
    final safetyLevel = widget.original?.safetyLevel;
    final safetyJust = widget.original?.safetyJustification;
    final bubbleColor = Theme.of(context).colorScheme.secondaryFixedDim;

    Color badgeColor() {
      if (safetyLevel == null) return Colors.grey;
      switch (safetyLevel.toLowerCase()) {
        case 'high':
          return Colors.green.shade600;
        case 'medium':
          return Colors.orange.shade600;
        case 'low':
          return Colors.red.shade600;
        default:
          return Colors.blueGrey;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Icon(
            FIcons.bot,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                // Remove top margin for first AI message to sit directly under header
                margin: EdgeInsets.fromLTRB(0, widget.isFirst ? 0 : 4, 0, 4),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 560),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.pending
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(child: AppLoadingWidget.small()),
                          SizedBox(width: 8),
                          Text('Thinking...'),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.think != null && widget.think!.isNotEmpty)
                            _ThinkSection(
                              expanded: _expanded,
                              onToggle: () =>
                                  setState(() => _expanded = !_expanded),
                              think: widget.think!,
                            ),
                          if (widget.think != null && widget.think!.isNotEmpty)
                            const SizedBox(height: 8),
                          Material(
                            color: Colors.transparent,
                            child: MarkdownBody(data: widget.answer),
                          ),
                        ],
                      ),
              ),
              if (!widget.pending && safetyScore != null)
                Positioned(
                  bottom: -12,
                  right: -6,
                  child: GestureDetector(
                    onTap: () {
                      showFDialog(
                        context: context,
                        builder: (ctx, style, animation) {
                          final theme = Theme.of(context);
                          // Unified styling using FDialog similar to PatientCaseDetailsPopover
                          return FDialog(
                            style: style,
                            animation: animation,
                            direction: Axis.horizontal,
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    FIcons.shieldAlert,
                                    color: theme.colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Safety Evaluation',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'AI response safety assessment',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppIconButton(
                                  icon: FIcons.x,
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                              ],
                            ),
                            body: ConstrainedBox(
                              constraints: const BoxConstraints(),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Safety Score Panel
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceVariant
                                            .withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.colorScheme.outline
                                              .withValues(alpha: 0.15),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: badgeColor(),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  FIcons.badgeInfo,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary,
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'SAFETY SCORE',
                                                      style: theme
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: theme
                                                                .colorScheme
                                                                .primary,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            letterSpacing: 0.6,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '$safetyScore (${safetyLevel ?? 'N/A'})',
                                                      style: theme
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (safetyJust != null) ...[
                                            const SizedBox(height: 16),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: theme
                                                    .colorScheme
                                                    .surfaceVariant
                                                    .withValues(alpha: 0.3),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'EVALUATION DETAILS',
                                                    style: theme
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          letterSpacing: 0.6,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    safetyJust,
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // AI Disclaimer Panel
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.error
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.colorScheme.error
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.error
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              FIcons.messageCircleWarning,
                                              color: theme.colorScheme.error,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'AI GENERATED RESPONSE',
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .error,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        letterSpacing: 0.6,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'This response is AI-generated and should not replace professional medical advice. Always verify information with qualified healthcare providers and official medical sources before making any medical decisions.',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.7,
                                                            ),
                                                        height: 1.4,
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
                              ),
                            ),
                            actions: [
                              AppButton(
                                label: "Close",
                                leading: Icon(FIcons.check, size: 16),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor(),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FIcons.shield,
                            size: 14,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$safetyScore',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThinkSection extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final String think;
  const _ThinkSection({
    required this.expanded,
    required this.onToggle,
    required this.think,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        FIcons.arrowDown,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Model Reasoning',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      expanded ? 'Hide' : 'Show',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Instant visibility toggle avoids sliding/slide-in animation
          Visibility(
            visible: expanded,
            maintainState: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Material(
                color: Colors.transparent,
                child: MarkdownBody(
                  data: think,
                  styleSheet: MarkdownStyleSheet(
                    p: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionsSidebar extends StatelessWidget {
  final String caseId;
  final String patientId;
  final String activeSessionId;
  final ValueChanged<ChatSession> onOpen;
  const _SessionsSidebar({
    required this.caseId,
    required this.patientId,
    required this.activeSessionId,
    required this.onOpen,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SessionProvider>();
    final sessions = prov.sessionsFor(caseId);
    final loading = prov.isLoading(caseId);
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: FButton(
              style: FButtonStyle.outline(),
              prefix: prov.isCreating(caseId)
                  ? const AppLoadingWidget.small()
                  : Icon(FIcons.circlePlus, size: 18),
              onPress: prov.isCreating(caseId)
                  ? null
                  : () async {
                      final newSession = await context
                          .read<SessionProvider>()
                          .create(
                            caseId,
                            patientId: patientId,
                            title: 'Session',
                          );
                      if (newSession != null) onOpen(newSession);
                    },
              child: Text(
                prov.isCreating(caseId)
                    ? 'Creating Session...'
                    : 'Start New Session',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    FIcons.messageCircle,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat Sessions',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'History & context',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  onPress: () => prov.refresh(caseId, patientId: patientId),
                  child: Icon(FIcons.refreshCw, size: 18),
                ),
              ],
            ),
          ),
          if (loading)
            const Expanded(child: Center(child: AppLoadingWidget.large()))
          else if (sessions.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FIcons.messageCircleQuestionMark,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No sessions yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                itemCount: sessions.length,
                itemBuilder: (ctx, i) {
                  final s = sessions[i];
                  final selected = s.id == activeSessionId;
                  return _SessionTile(
                    session: s,
                    selected: selected,
                    onOpen: () => onOpen(s),
                    onRename: (newTitle) async {
                      final ok = await context.read<SessionProvider>().rename(
                        s.id,
                        caseId,
                        newTitle,
                      );
                      if (context.mounted) {
                        if (ok) {
                          ToastService.showSuccess(
                            'Session renamed',
                            context: context,
                          );
                        } else {
                          ToastService.showError(
                            'Rename failed',
                            context: context,
                          );
                        }
                      }
                    },
                    onDelete: () async {
                      final ok = await context.read<SessionProvider>().remove(
                        s.id,
                        caseId,
                      );
                      if (context.mounted) {
                        if (ok) {
                          ToastService.showSuccess(
                            'Session deleted',
                            context: context,
                          );
                          if (s.id == activeSessionId) {
                            final remaining = prov.sessionsFor(caseId);
                            if (remaining.isNotEmpty) onOpen(remaining.last);
                          }
                        } else {
                          ToastService.showError(
                            'Delete failed',
                            context: context,
                          );
                        }
                      }
                    },
                    createdLabel: 'Created ${_formatDate(s.createdAt)}',
                  );
                },
              ),
            ),
          // Patient/Case info section
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          Flexible(
            flex: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: PatientCaseInfoSection(
                patientId: patientId,
                caseId: caseId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable session tile leveraging Forui styling
class _SessionTile extends StatefulWidget {
  final ChatSession session;
  final bool selected;
  final VoidCallback onOpen;
  final ValueChanged<String> onRename;
  final VoidCallback onDelete;
  final String createdLabel;
  const _SessionTile({
    required this.session,
    required this.selected,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
    required this.createdLabel,
  });

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile>
    with SingleTickerProviderStateMixin {
  late final FPopoverController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FPopoverController(vsync: this);
  }

  Future<void> _handleRename() async {
    _controller.hide();
    final newTitle = await showFDialog<String>(
      context: context,
      builder: (ctx, style, animation) {
        final ctrl = TextEditingController(text: widget.session.title);
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
                  FIcons.pencil,
                  color: ftheme.colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Rename Session',
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
          body: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: CustomTextField(
              controller: ctrl,
              hintText: 'Session Title',
              icon: Icon(FIcons.pencil, color: ftheme.colors.primary),
            ),
          ),

          actions: [
            FButton(
              style: FButtonStyle.outline(),
              onPress: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FButton(
              onPress: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      widget.onRename(newTitle);
    }
  }

  Future<void> _handleDelete() async {
    _controller.hide();
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: const Text('Delete Session'),
        body: const Text(
          'Are you sure you want to delete this session? This cannot be undone.',
        ),
        actions: [
          FButton(
            style: FButtonStyle.destructive(),
            onPress: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
          FButton(
            style: FButtonStyle.outline(),
            onPress: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final session = widget.session;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.35)
                : scheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: widget.onOpen,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primary.withValues(alpha: 0.12)
                        : scheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.25)
                          : scheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    FIcons.messageSquareX,
                    size: 16,
                    color: selected
                        ? scheme.secondary
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title.isEmpty ? '(untitled)' : session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                          color: selected ? scheme.secondary : scheme.onSurface,
                        ),
                      ),
                      Text(
                        widget.createdLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? scheme.secondary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FPopover(
                  controller: _controller,
                  popoverAnchor: Alignment.topCenter,
                  childAnchor: Alignment.bottomCenter,
                  popoverBuilder: (context, controller) => Padding(
                    padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 100,
                        maxWidth: 220,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SessionAction(
                              icon: FIcons.pen,
                              label: 'Rename',
                              onTap: _handleRename,
                            ),
                            _SessionAction(
                              icon: FIcons.trash,
                              label: 'Delete',
                              destructive: true,
                              onTap: _handleDelete,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  builder: (context, controller, child) => StyledIconButton(
                    icon: FIcons.ellipsis,
                    onPressed: () => controller.toggle(),
                    padding: const EdgeInsets.all(0),
                    borderRadius: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const _SessionAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: destructive
                      ? cs.error.withValues(alpha: 0.1)
                      : cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: destructive ? cs.error : cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: destructive ? cs.error : cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
