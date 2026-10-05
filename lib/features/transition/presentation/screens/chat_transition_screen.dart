import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';

class ChatTransitionScreen extends StatefulWidget {
  const ChatTransitionScreen({super.key});

  @override
  State<ChatTransitionScreen> createState() => _ChatTransitionScreenState();
}

class _ChatTransitionScreenState extends State<ChatTransitionScreen>
    with TickerProviderStateMixin {
  late AnimationController _blackCircleController;
  late Animation<double> _blackCircleAnimation;

  late AnimationController _typewriterController;
  String _displayedText = '';
  static const String _fullText = 'Felix is ready.\nAre you?';

  bool _showButton = false;

  late AnimationController _whiteCircleController;
  late Animation<double> _whiteCircleAnimation;

  bool _phase1Done = true;

  final GlobalKey _buttonKey = GlobalKey();
  Offset? _buttonCenter;

  @override
  void initState() {
    super.initState();

    _blackCircleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _blackCircleAnimation = CurvedAnimation(
      parent: _blackCircleController,
      curve: Curves.easeInOut,
    );

    _typewriterController = AnimationController(
      duration: Duration(milliseconds: _fullText.length * 70),
      vsync: this,
    );
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
    _whiteCircleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        context.go(AppRouter.home);
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _typewriterController.forward();
    });
  }

  @override
  void dispose() {
    _blackCircleController.dispose();
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Typewriter text + button
          if (_phase1Done)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayedText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 40),
                    AnimatedOpacity(
                      opacity: _showButton ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: GestureDetector(
                        onTap: _showButton ? _onReady : null,
                        child: Container(
                          key: _buttonKey,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'I am ready',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
                    color: Colors.white,
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
