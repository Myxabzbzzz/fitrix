import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/elapsed_time_text.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_widgets.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The active workout, shown above the tab bar on every tab.
///
/// Collapsed it's the "Chest and biceps · 1h 43m 22s" mini bar from the
/// design; tapping the header toggles it, and dragging the header moves the
/// sheet with the finger and snaps open or closed on release (by position,
/// or by direction for a quick fling).
class ActiveWorkoutSheet extends ConsumerStatefulWidget {
  const ActiveWorkoutSheet({super.key});

  static const double collapsedHeight = 64;

  /// Release speed (px/s) above which the drag direction decides the snap,
  /// regardless of how far the sheet was dragged.
  static const double flingVelocity = 300;

  /// Key of the sheet's surface (for tests).
  static const surfaceKey = ValueKey('activeWorkoutSheetSurface');

  /// Key of the draggable header (for tests).
  static const headerKey = ValueKey('activeWorkoutSheetHeader');

  /// Keys of the restyled parts (for tests).
  static const handleKey = ValueKey('activeWorkoutHandle');
  static const timerKey = ValueKey('activeWorkoutTimer');
  static const captionKey = ValueKey('activeWorkoutSetsCaption');
  static const progressTrackKey = ValueKey('activeWorkoutProgressTrack');
  static const progressFillKey = ValueKey('activeWorkoutProgressFill');
  static const checkKey = ValueKey('activeWorkoutCheck');

  @override
  ConsumerState<ActiveWorkoutSheet> createState() => _ActiveWorkoutSheetState();
}

class _ActiveWorkoutSheetState extends ConsumerState<ActiveWorkoutSheet>
    with SingleTickerProviderStateMixin {
  /// 0 = collapsed mini bar, 1 = fully expanded.
  late final AnimationController _position;

  /// Pixels between the collapsed and expanded heights (from the last
  /// layout); converts finger movement into [_position] units.
  double _range = 1;

  /// Whether the sheet was on screen at the last build. A sheet that is
  /// just appearing (workout started) jumps straight to its rest position.
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _position = AnimationController(
      vsync: this,
      duration: Motion.medium,
      value: ref.read(activeWorkoutExpandedProvider) ? 1 : 0,
    );
    FocusManager.instance.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChange);
    _position.dispose();
    super.dispose();
  }

  /// Animates to the open or closed rest position.
  void _settle(bool expanded) {
    final target = expanded ? 1.0 : 0.0;
    if (!_visible || Motion.reduced(context)) {
      _position.value = target;
    } else {
      // 180–300 ms depending on how far is left to travel, so a short
      // snap-back after a small drag doesn't look abrupt.
      final distance = (target - _position.value).abs();
      _position.animateTo(
        target,
        duration: Duration(milliseconds: (180 + 120 * distance).round()),
        curve: Motion.curve,
      );
    }
  }

  void _setExpanded(bool value) {
    final notifier = ref.read(activeWorkoutExpandedProvider.notifier);
    if (notifier.state == value) {
      _settle(value); // e.g. dragged partway and released: snap back.
    } else {
      notifier.state = value; // the listener in build() settles.
    }
  }

  void _onDragStart(DragStartDetails details) => _position.stop();

  void _onDragUpdate(DragUpdateDetails details) {
    _position.value -= (details.primaryDelta ?? 0) / _range;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0; // + is downward
    final open = velocity.abs() > ActiveWorkoutSheet.flingVelocity
        ? velocity < 0
        : _position.value >= 0.5;
    _setExpanded(open);
  }

  bool _fieldFocused = false;

  /// True while a set field of this sheet has the keyboard.
  void _onFocusChange() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    final focused = focusContext != null &&
        focusContext.findAncestorStateOfType<_ActiveWorkoutSheetState>() ==
            this;
    if (focused != _fieldFocused && mounted) {
      setState(() => _fieldFocused = focused);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeWorkoutExpandedProvider, (_, expanded) {
      _settle(expanded);
    });

    final workout = ref.watch(activeWorkoutProvider);
    // A finished workout waiting on "Workout complete" is not editable.
    final awaitingSave =
        ref.watch(pendingCompletedWorkoutProvider.select((w) => w != null));
    _visible = workout != null && !awaitingSave;
    if (workout == null || awaitingSave) return const SizedBox.shrink();

    final palette = AppPalette.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    // Built once per data change and reused on every animation frame.
    final table = LiveLog(workout: workout, typing: _fieldFocused);

    return LayoutBuilder(
      builder: (context, constraints) {
        final expandedHeight = constraints.maxHeight - topInset - 12;
        _range =
            math.max(1, expandedHeight - ActiveWorkoutSheet.collapsedHeight);

        return AnimatedBuilder(
          animation: _position,
          builder: (context, _) {
            final t = _position.value.clamp(0.0, 1.0);
            // Build the table as soon as opening starts (not a frame later).
            final isOpen = t > 0 || _position.status == AnimationStatus.forward;

            // Children are keyed: the barrier and table come and go, and the
            // header must keep its element (and its in-progress drag).
            return Stack(
              children: [
                if (isOpen)
                  Positioned.fill(
                    key: const ValueKey('barrier'),
                    child: GestureDetector(
                      onTap: () => _setExpanded(false),
                      child: ColoredBox(
                        color: Color.fromRGBO(0, 0, 0, 0.2 * t),
                      ),
                    ),
                  ),
                Positioned(
                  key: const ValueKey('sheet'),
                  left: 14,
                  right: 14,
                  bottom: 0,
                  height: ui.lerpDouble(
                    ActiveWorkoutSheet.collapsedHeight,
                    expandedHeight,
                    t,
                  ),
                  child: Container(
                    key: ActiveWorkoutSheet.surfaceKey,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      // The sheet colour when collapsed; the page background
                      // when open so the exercise cards (sheet colour) read.
                      color: Color.lerp(palette.sheet, palette.background, t),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.lg),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.12),
                          blurRadius: 24,
                          offset: Offset(0, -6),
                        ),
                      ],
                    ),
                    // A Stack (not a Column) so the header can't overflow
                    // while the sheet moves between its two heights.
                    child: Stack(
                      children: [
                        if (isOpen)
                          Positioned.fill(
                            key: const ValueKey('table'),
                            top: _SheetHeader.heightAt(t),
                            child: Opacity(
                              opacity: (t * 2).clamp(0.0, 1.0),
                              child: table,
                            ),
                          ),
                        Positioned(
                          key: const ValueKey('header'),
                          top: 0,
                          left: 0,
                          right: 0,
                          child: GestureDetector(
                            key: ActiveWorkoutSheet.headerKey,
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _setExpanded(
                              !ref.read(activeWorkoutExpandedProvider),
                            ),
                            onVerticalDragStart: _onDragStart,
                            onVerticalDragUpdate: _onDragUpdate,
                            onVerticalDragEnd: _onDragEnd,
                            onVerticalDragCancel: () => _settle(
                              ref.read(activeWorkoutExpandedProvider),
                            ),
                            child: _SheetHeader(workout: workout, t: t),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_fieldFocused)
                  Positioned(
                    key: const ValueKey('keyboardDone'),
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    child: const _KeyboardDoneBar(),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Height of the Done bar above the keyboard.
const double kDoneBarHeight = 44;

/// Bar pinned to the top of the keyboard with a right-aligned Done button;
/// the numeric keypad has no return key on iOS.
class _KeyboardDoneBar extends StatelessWidget {
  const _KeyboardDoneBar();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: palette.sheet,
      child: Container(
        height: kDoneBarHeight,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: TextButton(
          onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Text(
            l10n.workoutKeyboardDone,
            style: AppText.bodyStrong.copyWith(color: palette.accent),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final ActiveWorkout workout;

  /// 0 = collapsed, 1 = expanded; sizes interpolate in between.
  final double t;

  const _SheetHeader({required this.workout, required this.t});

  static const double expandedHeight = 120;

  static double heightAt(double t) =>
      ui.lerpDouble(ActiveWorkoutSheet.collapsedHeight, expandedHeight, t)!;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final timerSize = ui.lerpDouble(AppText.micro.fontSize!, 44, t)!;

    return SizedBox(
      width: double.infinity,
      height: heightAt(t),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: ActiveWorkoutSheet.handleKey,
              width: 69,
              height: 2,
              decoration: BoxDecoration(
                color: palette.textPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              workout.template.name,
              style: AppText.headingS.copyWith(color: palette.textPrimary),
            ),
            ElapsedTimeText(
              key: ActiveWorkoutSheet.timerKey,
              startedAt: workout.startedAt,
              style: AppText.micro.copyWith(
                fontSize: timerSize,
                fontWeight: t > 0.5 ? FontWeight.w600 : FontWeight.w500,
                height: t > 0.5 ? 1.1 : 1.4,
                color: palette.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
