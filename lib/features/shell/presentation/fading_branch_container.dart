import 'package:flutter/material.dart';
import 'package:fitrix/core/animation/motion.dart';

/// Tab content container for the shell: like go_router's default indexed
/// stack (every branch keeps its state, inactive ones are offstage with
/// tickers paused), but switching tabs cross-fades briefly instead of
/// swapping instantly.
class FadingBranchContainer extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const FadingBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  static const Duration duration = Duration(milliseconds: 180);

  @override
  State<FadingBranchContainer> createState() => _FadingBranchContainerState();
}

class _FadingBranchContainerState extends State<FadingBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: FadingBranchContainer.duration,
    value: 1,
  )..addStatusListener((status) {
      // Fade done: the previous tab can go offstage.
      if (status == AnimationStatus.completed && _previousIndex != null) {
        setState(() => _previousIndex = null);
      }
    });
  late final Animation<double> _fadeIn =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<double> _fadeOut = ReverseAnimation(_fadeIn);

  int? _previousIndex;

  @override
  void didUpdateWidget(FadingBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;
    if (Motion.reduced(context)) {
      _previousIndex = null;
      _controller.value = 1;
      return;
    }
    _previousIndex = oldWidget.currentIndex;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _branch(i, widget.children[i]),
      ],
    );
  }

  Widget _branch(int index, Widget child) {
    final isCurrent = index == widget.currentIndex;
    final isLeaving = index == _previousIndex;
    // Keep the exact same wrapper structure for every branch in every state
    // so a branch's Navigator is never rebuilt from scratch.
    return Offstage(
      offstage: !isCurrent && !isLeaving,
      child: TickerMode(
        enabled: isCurrent,
        child: IgnorePointer(
          ignoring: !isCurrent,
          child: FadeTransition(
            opacity: isCurrent
                ? _fadeIn
                : isLeaving
                    ? _fadeOut
                    : kAlwaysCompleteAnimation,
            child: child,
          ),
        ),
      ),
    );
  }
}
