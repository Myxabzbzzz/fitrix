import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

class ChatTransitionScreen extends ConsumerStatefulWidget {
  /// Deliberate exception to the palette rule: the onboarding chat's
  /// expanding "Start" circle must be exactly this color so the hand-off to
  /// this screen is seamless in both light and dark themes.
  static const background = Colors.black;
  static const foreground = Colors.white;

  const ChatTransitionScreen({super.key});

  @override
  ConsumerState<ChatTransitionScreen> createState() =>
      _ChatTransitionScreenState();
}

class _ChatTransitionScreenState extends ConsumerState<ChatTransitionScreen>
    with TickerProviderStateMixin {
  late AnimationController _typewriterController;
  String _displayedText = '';

  /// "Felix is ready. Are you?" in the app language, set once it is known.
  String _fullText = '';

  bool _showButton = false;

  late AnimationController _whiteCircleController;
  late Animation<double> _whiteCircleAnimation;

  final GlobalKey _buttonKey = GlobalKey();
  Offset? _buttonCenter;

  @override
  void initState() {
    super.initState();

    _typewriterController = AnimationController(vsync: this);
    _typewriterController.addListener(() {
      final charCount =
          (_typewriterController.value * _fullText.length).floor();
      if (charCount != _displayedText.length) {
        setState(() {
          _displayedText = _fullText.substring(0, charCount);
        });
      }
    });
    _typewriterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _showButton = true);
        });
      }
    });

    _whiteCircleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _whiteCircleAnimation = CurvedAnimation(
      parent: _whiteCircleController,
      curve: Curves.easeInOut,
    );
    _whiteCircleController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        // Read before completing: that redirects away from this screen.
        final account = ref.read(accountServiceProvider);
        // From now on the app opens straight to Home.
        try {
          await ref.read(appSessionProvider).completeOnboarding();
        } catch (e) {
          // No Home follows: nothing may be left for a later shell to pick up.
          ShellEntrance.handOff = null;
          debugPrint('Could not complete onboarding: $e');
          // Shrink the circle back so Go can be tapped again.
          if (!mounted) return;
          await _whiteCircleController.reverse();
          // Drops the dismissed circle, which would still take the taps.
          if (mounted) setState(() {});
          return;
        }
        // Home fades in from the white the circle ended on. Set only now,
        // right before Home is built.
        ShellEntrance.handOff = ChatTransitionScreen.foreground;
        // Mark the account as onboarded too (in the background; retried
        // until it lands, so a new device skips onboarding).
        unawaited(account?.profileChanged());
        if (mounted) context.go(AppRouter.home);
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _typewriterController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fullText.isEmpty) {
      _fullText = AppLocalizations.of(context).transitionReady;
      _typewriterController.duration =
          Duration(milliseconds: _fullText.length * 70);
    }
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    _whiteCircleController.dispose();
    super.dispose();
  }

  void _onReady() {
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      setState(() {
        _buttonCenter = Offset(
          position.dx + renderBox.size.width / 2,
          position.dy + renderBox.size.height / 2,
        );
      });
    }
    _whiteCircleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = sqrt(size.width * size.width + size.height * size.height);

    return Scaffold(
      backgroundColor: ChatTransitionScreen.background,
      body: Stack(
        children: [
          // Typewriter text + button
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _displayedText,
                    textAlign: TextAlign.center,
                    style: AppText.headingXL.copyWith(
                      color: ChatTransitionScreen.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AnimatedOpacity(
                    opacity: _showButton ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: GestureDetector(
                      onTap: _showButton ? _onReady : null,
                      child: Container(
                        key: _buttonKey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: ChatTransitionScreen.foreground,
                          borderRadius: AppRadius.lgAll,
                        ),
                        child: Text(
                          AppLocalizations.of(context).transitionGo,
                          style: AppText.headingS.copyWith(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Phase 4: White circle expanding from button
          if (_whiteCircleController.isAnimating ||
              _whiteCircleController.isCompleted)
            AnimatedBuilder(
              animation: _whiteCircleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: size,
                  painter: _CirclePainter(
                    progress: _whiteCircleAnimation.value,
                    color: ChatTransitionScreen.foreground,
                    center: _buttonCenter ??
                        Offset(size.width / 2, size.height / 2 + 50),
                    maxRadius: diagonal,
                  ),
                );
              },
            ),
        ],
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
