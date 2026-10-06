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
/// one, otherwise a short fade-and-rise. Reverses on back.
Page<void> circleRevealPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final reduced = Motion.reduced(context);
  final location = state.matchedLocation;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    child: child,
    transitionDuration: reduced ? Duration.zero : Motion.slow,
    reverseTransitionDuration: reduced ? Duration.zero : Motion.medium,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (Motion.reduced(context)) return child;
      final origin = RevealOrigins.of(location);
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
    },
  );
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
