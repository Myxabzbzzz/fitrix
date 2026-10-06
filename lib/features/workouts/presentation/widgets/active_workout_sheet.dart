import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/elapsed_time_text.dart';

/// The active workout, shown above the tab bar on every tab.
///
/// Collapsed it's the "Chest and biceps · 1h 43m 22s" mini bar from the
/// design; tapping or dragging it up expands it into the full sets table.
class ActiveWorkoutSheet extends ConsumerWidget {
  const ActiveWorkoutSheet({super.key});

  static const double collapsedHeight = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(activeWorkoutProvider);
    if (workout == null) return const SizedBox.shrink();

    final expanded = ref.watch(activeWorkoutExpandedProvider);
    final palette = AppPalette.of(context);
    final topInset = MediaQuery.of(context).padding.top;

    void setExpanded(bool value) =>
        ref.read(activeWorkoutExpandedProvider.notifier).state = value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final expandedHeight = constraints.maxHeight - topInset - 12;

        return Stack(
          children: [
            if (expanded)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setExpanded(false),
                  child: const ColoredBox(color: Color(0x33000000)),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: 14,
              right: 14,
              bottom: 0,
              height: expanded ? expandedHeight : collapsedHeight,
              child: Container(
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
                // A Stack (not a Column) so the header can't overflow while
                // the sheet animates between collapsed and expanded heights.
                child: Stack(
                  children: [
                    if (expanded)
                      Positioned.fill(
                        top: _SheetHeader.expandedHeight,
                        child: _SetsTable(workout: workout),
                      ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setExpanded(!expanded),
                        onVerticalDragEnd: (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          if (velocity < -200) setExpanded(true);
                          if (velocity > 200) setExpanded(false);
                        },
                        child: _SheetHeader(
                          workout: workout,
                          expanded: expanded,
                        ),
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
  }
}

class _SheetHeader extends StatelessWidget {
  final ActiveWorkout workout;
  final bool expanded;

  const _SheetHeader({required this.workout, required this.expanded});

  static const double expandedHeight = 96;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SizedBox(
      width: double.infinity,
      height: expanded ? expandedHeight : ActiveWorkoutSheet.collapsedHeight,
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
            SizedBox(height: expanded ? 14 : 8),
            Text(
              workout.template.name,
              style: TextStyle(
                fontSize: expanded ? 24 : 16,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            ElapsedTimeText(
              startedAt: workout.startedAt,
              style: TextStyle(
                fontSize: expanded ? 14 : 10,
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
              child: GestureDetector(
                onTap: onToggle,
                child: cell(
                  width: 29,
                  color: set.done ? palette.accent : null,
                  child: Icon(
                    Icons.check,
                    size: 18,
                    color: set.done ? Colors.white : palette.textPrimary,
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
