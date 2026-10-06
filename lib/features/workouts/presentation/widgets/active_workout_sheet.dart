import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/elapsed_time_text.dart';

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
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    ref.listen(activeWorkoutExpandedProvider, (_, expanded) {
      _settle(expanded);
    });

    final workout = ref.watch(activeWorkoutProvider);
    _visible = workout != null;
    if (workout == null) return const SizedBox.shrink();

    final palette = AppPalette.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    // Built once per data change and reused on every animation frame.
    final table = _SetsTable(workout: workout);

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
                      color: palette.sheet,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(25)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 15,
                          offset: Offset(0, -2),
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
              ],
            );
          },
        );
      },
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final ActiveWorkout workout;

  /// 0 = collapsed, 1 = expanded; sizes interpolate in between.
  final double t;

  const _SheetHeader({required this.workout, required this.t});

  static const double expandedHeight = 96;

  static double heightAt(double t) =>
      ui.lerpDouble(ActiveWorkoutSheet.collapsedHeight, expandedHeight, t)!;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    double lerp(double a, double b) => ui.lerpDouble(a, b, t)!;

    return SizedBox(
      width: double.infinity,
      height: heightAt(t),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 2,
              color: palette.textPrimary,
            ),
            SizedBox(height: lerp(8, 14)),
            Text(
              workout.template.name,
              style: TextStyle(
                fontSize: lerp(16, 24),
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            ElapsedTimeText(
              startedAt: workout.startedAt,
              style: TextStyle(
                fontSize: lerp(10, 14),
                fontWeight: FontWeight.w500,
                color: palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetsTable extends ConsumerWidget {
  final ActiveWorkout workout;

  const _SetsTable({required this.workout});

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish workout?'),
        content: Text(
          workout.completedSets == 0
              ? 'No sets are checked off, so this workout won\'t be saved.'
              : '${workout.completedSets} of ${workout.totalSets} sets '
                  'completed. The workout will be saved to your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    ref.read(activeWorkoutExpandedProvider.notifier).state = false;
    final saved = ref.read(activeWorkoutProvider.notifier).finish();
    if (saved) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Workout saved to My progress')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final notifier = ref.read(activeWorkoutProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      children: [
        if (workout.exercises.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No exercises yet. Add some with "Edit" on the workout card.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
        for (var e = 0; e < workout.exercises.length; e++) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 12, 9, 6),
            child: Text(
              workout.exercises[e].name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
          ),
          const _TableHeader(),
          for (var s = 0; s < workout.exercises[e].sets.length; s++)
            _SetRow(
              key: ValueKey('set-$e-$s'),
              index: s,
              set: workout.exercises[e].sets[s],
              onToggle: () => notifier.toggleSet(e, s),
              onKgChanged: (kg) => notifier.setKg(e, s, kg),
              onRepsChanged: (reps) => notifier.setReps(e, s, reps),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => notifier.addSet(e),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add set'),
              style: TextButton.styleFrom(foregroundColor: palette.accent),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => _finish(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Finish workout'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Column widths follow the design: Set · Previous · Kg · Reps · Status.
const _colSet = 44.0;
const _colCell = 64.0;
const _colStatus = 52.0;

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final style = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: palette.textPrimary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: _colSet,
            child: Text('Set', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text('Previous', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: _colCell,
            child: Text.rich(
              TextSpan(
                text: 'Kg',
                children: [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: palette.accent),
                  ),
                ],
              ),
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: _colCell,
            child: Text('Reps', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: _colStatus,
            child: Text('Status', style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int index;
  final WorkoutSet set;
  final VoidCallback onToggle;
  final ValueChanged<double> onKgChanged;
  final ValueChanged<int> onRepsChanged;

  const _SetRow({
    super.key,
    required this.index,
    required this.set,
    required this.onToggle,
    required this.onKgChanged,
    required this.onRepsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: palette.textPrimary,
    );

    Widget cell({required double width, required Widget child, Color? color}) =>
        Container(
          width: width,
          height: 29,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color ?? palette.tableCell,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: _colSet,
            child: Center(
              child: cell(
                width: 36,
                child: Text('${index + 1}', style: textStyle),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${formatKg(set.previousKg)} kg × ${set.previousReps}',
              textAlign: TextAlign.center,
              style: textStyle.copyWith(fontSize: 11),
            ),
          ),
          cell(
            width: _colCell,
            child: _NumberField(
              initialValue: '${formatKg(set.kg)} kg',
              decimal: true,
              style: textStyle,
              onChanged: (value) {
                final kg = double.tryParse(value.replaceAll(',', '.'));
                if (kg != null) onKgChanged(kg);
              },
            ),
          ),
          const SizedBox(width: 12),
          cell(
            width: _colCell,
            child: _NumberField(
              initialValue: '${set.reps}',
              decimal: false,
              style: textStyle,
              onChanged: (value) {
                final reps = int.tryParse(value);
                if (reps != null) onRepsChanged(reps);
              },
            ),
          ),
          SizedBox(
            width: _colStatus,
            child: Center(
              child: _CheckButton(done: set.done, onToggle: onToggle),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Status" cell: fills with the accent colour and pops when a set is
/// checked off or unchecked, with a light haptic tap.
class _CheckButton extends StatefulWidget {
  final bool done;
  final VoidCallback onToggle;

  const _CheckButton({required this.done, required this.onToggle});

  @override
  State<_CheckButton> createState() => _CheckButtonState();
}

class _CheckButtonState extends State<_CheckButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: Motion.medium,
    value: 1,
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween:
          Tween(begin: 1.0, end: 0.82).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.82, end: 1.12)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.12, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOut)),
      weight: 30,
    ),
  ]).animate(_pop);

  @override
  void didUpdateWidget(_CheckButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.done != widget.done && !Motion.reduced(context)) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final duration = Motion.of(context, Motion.fast);
    final done = widget.done;

    return Semantics(
      button: true,
      checked: done,
      label: 'Set done',
      child: GestureDetector(
        onTap: _onTap,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: duration,
            curve: Motion.curve,
            width: 29,
            height: 29,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? palette.accent : palette.tableCell,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                end: done ? Colors.white : palette.textPrimary,
              ),
              duration: duration,
              builder: (context, color, _) =>
                  Icon(Icons.check, size: 18, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact numeric input that sits inside a table cell. The " kg" suffix in
/// the initial value is stripped when the field gains focus.
class _NumberField extends StatefulWidget {
  final String initialValue;
  final bool decimal;
  final TextStyle style;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.initialValue,
    required this.decimal,
    required this.style,
    required this.onChanged,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      final text = _controller.text;
      if (_focusNode.hasFocus) {
        _controller.text = text.replaceAll(' kg', '');
        _controller.selection =
            TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      } else if (widget.decimal && text.isNotEmpty && !text.endsWith(' kg')) {
        _controller.text = '$text kg';
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textAlign: TextAlign.center,
      style: widget.style,
      keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(widget.decimal ? r'[0-9.,]' : r'[0-9]'),
        ),
      ],
      decoration: const InputDecoration.collapsed(
        hintText: '',
        filled: false,
      ),
      onChanged: widget.onChanged,
    );
  }
}
