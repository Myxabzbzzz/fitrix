import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';

/// Where each section was last opened from, keyed by route location.
///
/// A tile records its centre (in the coordinates of the navigator that will
/// host the new page) right before navigating, and the section's page
/// expands a circle from there. Entries persist so the reverse (back)
/// animation shrinks into the same tile.
abstract final class RevealOrigins {
  static final Map<String, Offset> _byLocation = {};

  static Offset? of(String location) => _byLocation[location];

  static void clear(String location) => _byLocation.remove(location);

  /// Records [tileContext]'s centre as the origin for [location].
  static void record(BuildContext tileContext, String location) {
    final box = tileContext.findRenderObject();
    final navigatorBox =
        Navigator.maybeOf(tileContext)?.context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      clear(location);
      return;
    }
    _byLocation[location] = box.localToGlobal(
      box.size.center(Offset.zero),
      ancestor: navigatorBox is RenderBox ? navigatorBox : null,
    );
  }
}

/// Opens [location] with a circle reveal expanding from the tile at
/// [tileContext].
void openWithReveal(BuildContext tileContext, String location) {
  RevealOrigins.record(tileContext, location);
  GoRouter.of(tileContext).go(location);
}

/// Page for a Home section: circle reveal from the tapped tile when there is
/// one, otherwise a short fade-and-rise. Reverses on back. On iOS it can
/// also be closed with a swipe from the left edge, like any iOS page.
Page<void> circleRevealPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final reduced = Motion.reduced(context);
  return _RevealPage(
    key: state.pageKey,
    name: state.name,
    location: state.matchedLocation,
    duration: reduced ? Duration.zero : Motion.slow,
    reverseDuration: reduced ? Duration.zero : Motion.medium,
    child: child,
  );
}

class _RevealPage extends Page<void> {
  const _RevealPage({
    super.key,
    super.name,
    required this.location,
    required this.duration,
    required this.reverseDuration,
    required this.child,
  });

  final String location;
  final Duration duration;
  final Duration reverseDuration;
  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => _RevealRoute(this);
}

/// Width of the strip along the left edge where a back swipe can start.
const double _backSwipeEdge = 20;

class _RevealRoute extends PageRoute<void> {
  _RevealRoute(_RevealPage page) : super(settings: page);

  _RevealPage get _page => settings as _RevealPage;

  /// True from the start of a back swipe until it settles: the page then
  /// slides with the finger instead of playing the circle reveal.
  final ValueNotifier<bool> _swiping = ValueNotifier(false);

  @override
  Duration get transitionDuration => _page.duration;

  @override
  Duration get reverseTransitionDuration => _page.reverseDuration;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      _page.child;

  /// A back swipe may start: iOS, fully shown, nothing blocks popping.
  bool _canSwipeBack(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS &&
      !isFirst &&
      isCurrent &&
      animation!.status == AnimationStatus.completed &&
      popDisposition == RoutePopDisposition.pop &&
      !navigator!.userGestureInProgress;

  /// A drag that started (a cancel before the start is ignored).
  bool _dragging = false;

  void _swipeStart() {
    _dragging = true;
    _swiping.value = true;
    navigator!.didStartUserGesture();
  }

  void _swipeUpdate(double fraction) {
    if (_dragging) controller!.value -= fraction;
  }

  /// Pops when dragged past half way or flung right (in screen widths per
  /// second), otherwise slides back into place.
  void _swipeEnd(double velocity) {
    if (!_dragging) return;
    _dragging = false;
    final controller = this.controller!;
    final pop = velocity.abs() >= 1 ? velocity > 0 : controller.value < 0.5;
    const curve = Curves.fastLinearToSlowEaseIn;
    final remaining = pop ? controller.value : 1 - controller.value;
    final duration = Duration(
      milliseconds: (remaining * 350).clamp(80, 350).round(),
    );

    void settle(AnimationStatus status) {
      if (status.isAnimating) return;
      controller.removeStatusListener(settle);
      navigator?.didStopUserGesture();
      if (!pop) _swiping.value = false;
    }

    if (pop) {
      navigator!.pop();
      controller.animateBack(0, duration: duration, curve: curve);
    } else {
      controller.animateTo(1, duration: duration, curve: curve);
    }
    if (controller.isAnimating) {
      controller.addStatusListener(settle);
    } else {
      settle(controller.status);
    }
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // The same widget structure in both modes, so the page keeps its state.
    return ValueListenableBuilder<bool>(
      valueListenable: _swiping,
      child: child,
      builder: (context, swiping, child) => _BackSwipe(
        // Stays on while swiping, or the drag would be cut off.
        enabled: swiping || _canSwipeBack(context),
        onStart: _swipeStart,
        onUpdate: _swipeUpdate,
        onEnd: _swipeEnd,
        child: _SwipeSlide(
          animation: animation,
          swiping: swiping,
          child: _revealTransition(
            context,
            // While swiping the page is shown whole and slides instead.
            swiping ? kAlwaysCompleteAnimation : animation,
            child!,
          ),
        ),
      ),
    );
  }

  Widget _revealTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    if (Motion.reduced(context)) return child;
    final origin = RevealOrigins.of(_page.location);
    if (origin == null) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Motion.curve,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.03), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    }
    return CircleRevealTransition(
      animation: animation,
      origin: origin,
      child: child,
    );
  }

  @override
  void dispose() {
    _swiping.dispose();
    super.dispose();
  }
}

/// Moves the page right by how far the back swipe has gone, with a soft
/// shadow on its left edge over the page underneath.
class _SwipeSlide extends StatelessWidget {
  const _SwipeSlide({
    required this.animation,
    required this.swiping,
    required this.child,
  });

  final Animation<double> animation;
  final bool swiping;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final width = MediaQuery.sizeOf(context).width;
        final dx = swiping ? (1 - animation.value) * width : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: swiping
                  ? const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 16,
                        offset: Offset(-4, 0),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// A strip along the left edge that turns horizontal drags into a back
/// swipe; [onUpdate] gets the drag as a fraction of the screen width and
/// [onEnd] the release velocity in screen widths per second.
class _BackSwipe extends StatelessWidget {
  const _BackSwipe({
    required this.enabled,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.child,
  });

  final bool enabled;
  final VoidCallback onStart;
  final ValueChanged<double> onUpdate;
  final ValueChanged<double> onEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final edge = math.max(_backSwipeEdge, MediaQuery.paddingOf(context).left);
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (enabled)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: edge,
            child: GestureDetector(
              key: const Key('back-swipe-edge'),
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) => onStart(),
              onHorizontalDragUpdate: (d) => onUpdate(d.delta.dx / width),
              onHorizontalDragEnd: (d) =>
                  onEnd(d.velocity.pixelsPerSecond.dx / width),
              onHorizontalDragCancel: () => onEnd(0),
            ),
          ),
      ],
    );
  }
}

/// Expands a filled circle (the tile colour) from [origin] to cover the
/// screen, revealing [child] inside it as it grows — the same language as
/// the onboarding circle transitions.
class CircleRevealTransition extends StatelessWidget {
  final Animation<double> animation;
  final Offset origin;
  final Widget child;

  const CircleRevealTransition({
    super.key,
    required this.animation,
    required this.origin,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final fill = AppPalette.of(context).tile;
    final radius = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic.flipped,
    );
    // The page fades in inside the circle once it has left the tile, so the
    // first frames read as the tile itself growing.
    final contentOpacity = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.25, 0.9, curve: Curves.easeOut),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final maxRadius = _farthestCorner(origin, size);

        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final r = radius.value * maxRadius;
            final done = animation.status == AnimationStatus.completed;
            return ClipPath(
              clipper: _CircleClipper(origin, r),
              // Once fully revealed, stop clipping (no extra layer).
              clipBehavior: done ? Clip.none : Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: fill),
                  Opacity(opacity: contentOpacity.value, child: child),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static double _farthestCorner(Offset p, Size size) => [
        p,
        Offset(size.width - p.dx, p.dy),
        Offset(p.dx, size.height - p.dy),
        Offset(size.width - p.dx, size.height - p.dy),
      ].map((o) => o.distance).reduce(math.max);
}

class _CircleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  _CircleClipper(this.center, this.radius);

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_CircleClipper old) =>
      old.center != center || old.radius != radius;
}
