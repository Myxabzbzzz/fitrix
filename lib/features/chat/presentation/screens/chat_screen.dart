import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/widgets/felix_avatar.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/features/profile/presentation/widgets/about_me_labels.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/features/transition/presentation/screens/chat_transition_screen.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_auto_scroll.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_entrance.dart';
import 'package:fitrix/features/chat/presentation/widgets/quick_reply_chip.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

enum _OnboardingStep { goal, sports, frequency, level, done }

/// A quick reply: [label] in the app language is what the user sends (so
/// Felix answers in that language); [value] is the stable English answer
/// kept in the profile.
typedef _Reply = ({String value, String label});

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showQuickReplies = true;
  final ChatEntranceTracker _entrance = ChatEntranceTracker();

  final GlobalKey _startButtonKey = GlobalKey();
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;
  bool _animating = false;
  Offset? _buttonCenter;

  /// The chat opened at its newest message already (after a restart).
  bool _openedAtBottom = false;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _circleAnimation = CurvedAnimation(
      parent: _circleController,
      curve: Curves.easeInOut,
    );
    _circleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        context.go(AppRouter.transition);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  /// Which onboarding question the quick replies currently answer.
  _OnboardingStep _step = _OnboardingStep.goal;

  bool _sending = false;

  /// Sends [content]; a quick reply passes its stable [value] for the
  /// profile, a typed answer is kept as typed.
  Future<void> _sendMessage(String content,
      {bool isQuickReply = false, String? value}) async {
    final notifier = ref.read(chatMessagesProvider.notifier);
    final text = content.trim();
    if (text.isEmpty || _sending || !notifier.canSend) return;
    _sending = true;
    try {
      _messageController.clear();
      // A question isn't an answer: send it, stay on this step.
      final isAnswer = !text.endsWith('?');
      final answered = _step;
      // Saved before sending so Felix gets the answer with this very message.
      if (isAnswer) await _saveAnswer(answered, value ?? text);
      if (!mounted) return;
      final accepted = notifier.startSend(content, isQuickReply: isQuickReply);
      if (accepted && isAnswer) _advance();
    } finally {
      _sending = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_resumed) {
      _resumed = true;
      unawaited(_resume());
    }
  }

  bool _resumed = false;

  /// After a restart, continues from what the saved profile already has.
  Future<void> _resume() async {
    final saved = await ref.read(profileRepositoryProvider).getProfile();
    if (saved == null || !mounted || _sending) return;
    if (_step != _OnboardingStep.goal) return;
    final _OnboardingStep step;
    if (saved.experience.isNotEmpty) {
      step = _OnboardingStep.done;
    } else if (saved.sports.isNotEmpty) {
      step = _OnboardingStep.frequency;
    } else if (saved.goal.isNotEmpty) {
      step = _OnboardingStep.sports;
    } else {
      return;
    }
    setState(() {
      _step = step;
      _showQuickReplies = step != _OnboardingStep.done;
    });
  }

  static List<_Reply> _repliesFor(
          _OnboardingStep step, AppLocalizations l10n) =>
      switch (step) {
        _OnboardingStep.goal => [
            for (final goal in AppConstants.fitnessGoals)
              (value: goal, label: aboutMeGoalLabel(l10n, goal)),
          ],
        _OnboardingStep.sports => [
            (value: 'Gym', label: l10n.sportGym),
            (value: 'Fitness', label: l10n.sportFitness),
            (value: 'Cycling', label: l10n.sportCycling),
            (value: 'Skiing', label: l10n.onbSportSkiing),
            (value: 'Snowboarding', label: l10n.onbSportSnowboarding),
            (value: 'Football', label: l10n.sportFootball),
            (value: 'Running', label: l10n.sportRunning),
          ],
        _OnboardingStep.frequency => [
            (value: 'Once a week or less', label: l10n.onbFreqWeekly),
            (value: 'Almost every day', label: l10n.onbFreqDaily),
            (value: 'A few times a week', label: l10n.onbFreqFew),
            (value: 'Just starting out', label: l10n.onbFreqStarting),
          ],
        _OnboardingStep.level => [
            for (final level in const ['Beginner', 'Intermediate', 'Advanced'])
              (value: level, label: aboutMeLevelLabel(l10n, level)),
          ],
        _OnboardingStep.done => const [],
      };

  /// Keeps the goal, sport and level in the profile (not just in the chat
  /// history), so every Felix chat knows them. Quick replies keep their
  /// stable English values; typed answers are kept as typed.
  Future<void> _saveAnswer(_OnboardingStep step, String answer) async {
    final profile = ref.read(profileProvider.notifier);
    switch (step) {
      case _OnboardingStep.goal:
        await profile.saveAnswers(goal: answer);
      case _OnboardingStep.sports:
        await profile.saveAnswers(sports: [answer]);
      case _OnboardingStep.level:
        await profile.saveAnswers(experience: answer);
      case _OnboardingStep.frequency:
      case _OnboardingStep.done:
        return;
    }
    if (!mounted) return;
    // Uploaded in the background; retried later if offline.
    unawaited(ref.read(accountServiceProvider)?.profileChanged());
  }

  void _advance() {
    if (_step == _OnboardingStep.done) return;
    setState(() {
      _step = _OnboardingStep.values[_step.index + 1];
      _showQuickReplies = _step != _OnboardingStep.done;
    });
  }

  void _onStartPressed() {
    final renderBox =
        _startButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      _buttonCenter = Offset(
        position.dx + renderBox.size.width / 2,
        position.dy + renderBox.size.height / 2,
      );
    }
    setState(() => _animating = true);
    _circleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider);
    final isReplying =
        messagesAsync.valueOrNull?.any((m) => m.isStreaming) ?? false;

    ref.listen(chatMessagesProvider, (previous, next) {
      final messages = next.valueOrNull;
      if (messages != null) {
        followChatBottom(_scrollController, previous?.valueOrNull, messages);
      }
    });
    final size = MediaQuery.of(context).size;
    final diagonal = sqrt(size.width * size.width + size.height * size.height);
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: palette.border)),
        title: Row(
          children: [
            const FelixAvatar(size: 32),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.assistantName,
                  style: AppText.headingS.copyWith(color: palette.textPrimary),
                ),
                Text(
                  AppLocalizations.of(context).assistantSubtitle,
                  style: AppText.caption.copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    _entrance.sync(messages);
                    if (!_openedAtBottom) {
                      _openedAtBottom = true;
                      jumpChatToBottom(_scrollController);
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final showTimestamp =
                            index == 0 || _showsTimestamp(messages, index);

                        final next = index + 1 < messages.length
                            ? messages[index + 1]
                            : null;
                        final lastInGroup = next == null ||
                            next.sender != message.sender ||
                            _showsTimestamp(messages, index + 1);

                        return ChatEntrance(
                          key: ValueKey(message.id),
                          message: message,
                          delay: _entrance.take(message),
                          child: Column(
                            children: [
                              if (showTimestamp)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.sm),
                                  child: Text(
                                    DateFormat.yMMMd()
                                        .add_Hm()
                                        .format(message.timestamp),
                                    style: AppText.caption
                                        .copyWith(color: palette.textSecondary),
                                  ),
                                ),
                              ChatBubble(
                                message: message,
                                lastInGroup: lastInGroup,
                                onRetry: () => ref
                                    .read(chatMessagesProvider.notifier)
                                    .retry(),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child:
                        Text(AppLocalizations.of(context).chatError('$error')),
                  ),
                ),
              ),

              // Composer area: quick replies (or the Start button once the
              // conversation is complete) directly above the input.
              Column(
                key: const ValueKey('chat-composer'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  _animatedComposerSlot(
                    _showQuickReplies
                        ? _quickReplyBar(isReplying: isReplying)
                        // Start waits for Felix's last answer to finish.
                        : isReplying
                            ? const SizedBox(
                                key: ValueKey('start-pending'),
                                width: double.infinity)
                            : _buildStartButton(),
                  ),
                  // Onboarding is finished once Start shows; typing there
                  // would go nowhere.
                  if (_showQuickReplies)
                    _buildMessageInput(isReplying: isReplying),
                ],
              ),
            ],
          ),

          // Black circle expanding from Start button
          if (_animating)
            AnimatedBuilder(
              animation: _circleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: size,
                  painter: _CirclePainter(
                    progress: _circleAnimation.value,
                    color: ChatTransitionScreen.background,
                    center: _buttonCenter ??
                        Offset(size.width / 2, size.height - 100),
                    maxRadius: diagonal,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _quickReplyBar({required bool isReplying}) {
    final replies = _repliesFor(_step, AppLocalizations.of(context));
    return QuickReplyBar(
      replies: [for (final r in replies) r.label],
      hidden: isReplying,
      onTap: (label) => _sendMessage(
        label,
        isQuickReply: true,
        value: replies.firstWhere((r) => r.label == label).value,
      ),
    );
  }

  static bool _showsTimestamp(List<ChatMessage> messages, int index) =>
      index == 0 ||
      messages[index]
              .timestamp
              .difference(messages[index - 1].timestamp)
              .inMinutes >
          5;

  /// Animates the size change when the quick replies give way to Start;
  /// plain swap with reduced motion.
  Widget _animatedComposerSlot(Widget child) {
    if (Motion.reduced(context)) return child;
    return AnimatedSize(
      duration: Motion.medium,
      curve: Motion.curve,
      alignment: Alignment.bottomCenter,
      child: child,
    );
  }

  Widget _buildStartButton() {
    final button = SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: AppButton(
          key: _startButtonKey,
          label: AppLocalizations.of(context).chatStart,
          size: AppButtonSize.large,
          icon: Icons.arrow_forward,
          expand: true,
          onPressed: _animating ? null : _onStartPressed,
        ),
      ),
    );
    if (Motion.reduced(context)) {
      return KeyedSubtree(key: const ValueKey('start'), child: button);
    }
    // Fades in and slides up as it replaces the quick replies.
    return TweenAnimationBuilder<double>(
      key: const ValueKey('start'),
      tween: Tween(begin: 0, end: 1),
      duration: Motion.medium,
      curve: Motion.curve,
      child: button,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * AppSpacing.md),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMessageInput({required bool isReplying}) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Add button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: palette.border),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () {},
                color: palette.textSecondary,
                padding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Text Input
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).chatMessageHint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                onSubmitted: (value) => _sendMessage(value),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Microphone button
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.mic, size: 20),
                onPressed: () {},
                color: palette.textSecondary,
                padding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(width: AppSpacing.xs),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isReplying ? palette.border : palette.accent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward, size: 20),
                onPressed: isReplying
                    ? null
                    : () => _sendMessage(_messageController.text),
                color: palette.onAccent,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Offset center;
  final double maxRadius;

  _CirclePainter({
    required this.progress,
    required this.color,
    required this.center,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawCircle(center, progress * maxRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
