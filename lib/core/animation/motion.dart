import 'package:flutter/widgets.dart';

/// Shared motion tokens. Everything stays short (150–400 ms) so animations
/// never hold up navigation or input.
abstract final class Motion {
  static const Duration press = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve curve = Curves.easeOutCubic;

  /// True when the platform asks for reduced motion
  /// (`MediaQuery.disableAnimations`). Animations should then be skipped.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when reduced motion is on.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}

/// Runs [action] once the enclosing route has finished its entrance
/// transition, or right away if it isn't animating in. Lets content (chart
/// draw-ins, progress fills) start once it's actually visible instead of
/// playing hidden under a page transition.
///
/// Returns a callback that cancels the pending action (call it in dispose).
VoidCallback afterRouteEntrance(BuildContext context, VoidCallback action) {
  final route = ModalRoute.of(context);
  var cancelled = false;
  VoidCallback? removeListener;

  void check() {
    if (cancelled) return;
    if (route != null && route.offstage) {
      // A pushed route spends its first frame offstage (for Hero
      // measurement) and then reports a completed animation; look again
      // once it is on stage.
      WidgetsBinding.instance.addPostFrameCallback((_) => check());
      return;
    }
    final animation = route?.animation;
    if (animation == null || animation.status != AnimationStatus.forward) {
      action();
      return;
    }
    void listener(AnimationStatus status) {
      if (status == AnimationStatus.forward) return;
      animation.removeStatusListener(listener);
      removeListener = null;
      if (status == AnimationStatus.completed) action();
    }

    animation.addStatusListener(listener);
    removeListener = () => animation.removeStatusListener(listener);
  }

  check();
  return () {
    cancelled = true;
    removeListener?.call();
  };
}

/// Fades and slides its child in once, when first inserted.
///
/// Only [animate] at creation time matters: rebuilding with new data (e.g. a
/// chat bubble growing token by token) never replays the entrance. Give it a
/// key that identifies the item so a *different* item at the same position
/// gets a fresh entrance.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final bool animate;

  /// Starting offset in logical pixels; slides to zero.
  final Offset offset;

  /// Starting scale; grows to 1.
  final double scale;
  final Alignment scaleAlignment;
  final Duration duration;

  /// Wait before starting (used to stagger a batch of items).
  final Duration delay;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.animate = true,
    this.offset = const Offset(0, 12),
    this.scale = 1,
    this.scaleAlignment = Alignment.center,
    this.duration = Motion.medium,
    this.delay = Duration.zero,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _progress;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) return;
    final total = widget.delay + widget.duration;
    final controller = AnimationController(vsync: this, duration: total);
    _controller = controller;
    _progress = CurvedAnimation(
      parent: controller,
      curve: Interval(
        widget.delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Motion.curve,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = _controller;
    if (controller == null ||
        controller.isAnimating ||
        controller.isCompleted) {
      return;
    }
    if (Motion.reduced(context)) {
      controller.value = 1;
    } else {
      controller.forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    if (progress == null) return widget.child;

    return AnimatedBuilder(
      animation: progress,
      child: widget.child,
      builder: (context, child) {
        // Same widget structure at every value (including the end) so the
        // child's state is never rebuilt from scratch.
        final t = progress.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: widget.offset * (1 - t),
            child: Transform.scale(
              scale: widget.scale + (1 - widget.scale) * t,
              alignment: widget.scaleAlignment,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
