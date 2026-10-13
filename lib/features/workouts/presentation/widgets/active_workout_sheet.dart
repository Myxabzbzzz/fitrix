import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/elapsed_time_text.dart';
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
        height: 44,
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

class _SetsTable extends ConsumerWidget {
  final ActiveWorkout workout;

  const _SetsTable({required this.workout});

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.workoutFinishTitle),
          content: Text(
            workout.completedSets == 0
                ? l10n.workoutFinishNoSets
                : l10n.workoutFinishSummary(
                    workout.completedSets, workout.totalSets),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.workoutKeepGoing),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.workoutFinish),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final savedText = AppLocalizations.of(context).workoutSaved;
    ref.read(activeWorkoutExpandedProvider.notifier).state = false;
    final saved = ref.read(activeWorkoutProvider.notifier).finish();
    if (saved) {
      messenger.showSnackBar(
        SnackBar(content: Text(savedText)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final total = workout.totalSets;
    final done = workout.completedSets;

    // Tapping empty space drops the keyboard; buttons inside still win.
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
        children: [
          Center(
            child: Text(
              l10n.workoutSetsProgress(done, total),
              key: ActiveWorkoutSheet.captionKey,
              style: AppText.caption.copyWith(
                color: palette.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ProgressBar(fraction: total == 0 ? 0 : done / total),
          const SizedBox(height: AppSpacing.md),
          if (workout.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.workoutNoExercises,
                textAlign: TextAlign.center,
                style: AppText.body14.copyWith(color: palette.textSecondary),
              ),
            ),
          for (var e = 0; e < workout.exercises.length; e++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: palette.sheet,
                borderRadius: AppRadius.mdAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          workout.exercises[e].name,
                          style: AppText.headingS
                              .copyWith(color: palette.textPrimary),
                        ),
                      ),
                      Text(
                        l10n.workoutSetCount(workout.exercises[e].sets.length),
                        style: AppText.caption
                            .copyWith(color: palette.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
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
                      label: Text(l10n.workoutAddSet),
                      style: TextButton.styleFrom(
                        foregroundColor: palette.accent,
                        textStyle: AppText.captionStrong,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: l10n.workoutFinishButton,
            size: AppButtonSize.large,
            expand: true,
            onPressed: () => _finish(context, ref),
          ),
        ],
      ),
    );
  }
}

/// 6 px accent bar whose fill animates to [fraction] over 400 ms.
class _ProgressBar extends StatelessWidget {
  final double fraction;

  const _ProgressBar({required this.fraction});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      key: ActiveWorkoutSheet.progressTrackKey,
      height: 6,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.buttonMuted,
        borderRadius: AppRadius.fullAll,
      ),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: fraction.clamp(0.0, 1.0)),
        duration: Motion.of(context, Motion.slow),
        curve: Motion.curve,
        builder: (context, value, _) => FractionallySizedBox(
          widthFactor: value,
          child: DecoratedBox(
            key: ActiveWorkoutSheet.progressFillKey,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: AppRadius.fullAll,
            ),
          ),
        ),
      ),
    );
  }
}

/// Five-column grid: Set · Previous · Kg · Reps · check.
const _colSet = 28.0;
const _colCheck = 36.0;
const _gap = AppSpacing.xs;

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final style = AppText.microStrong.copyWith(color: palette.textSecondary);
    Widget hd(String text) =>
        Text(text, style: style, textAlign: TextAlign.center);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          SizedBox(width: _colSet, child: hd(l10n.workoutColSet)),
          const SizedBox(width: _gap),
          Expanded(child: hd(l10n.workoutColPrevious)),
          const SizedBox(width: _gap),
          Expanded(child: hd(l10n.workoutColKg)),
          const SizedBox(width: _gap),
          Expanded(child: hd(l10n.workoutColReps)),
          const SizedBox(width: _gap),
          const SizedBox(width: _colCheck),
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
    final kgSuffix = ' ${AppLocalizations.of(context).unitKg}';
    final textStyle = AppText.body14.copyWith(
      color: palette.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget cell({required Widget child, bool plain = false}) => Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: plain ? Colors.transparent : palette.tableCell,
            borderRadius: AppRadius.smAll,
          ),
          child: child,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: _colSet,
            child: cell(
              plain: true,
              child: Text(
                '${index + 1}',
                style: textStyle.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: cell(
              child: Text(
                '${formatKg(set.previousKg)}×${set.previousReps}',
                style: textStyle.copyWith(color: palette.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: cell(
              child: _NumberField(
                initialValue: '${formatKg(set.kg)}$kgSuffix',
                decimal: true,
                suffix: kgSuffix,
                style: textStyle,
                onChanged: (value) {
                  final kg = double.tryParse(value.replaceAll(',', '.'));
                  if (kg != null) onKgChanged(kg);
                },
              ),
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: cell(
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
          ),
          const SizedBox(width: _gap),
          SizedBox(
            width: _colCheck,
            child: Center(
              child: _CheckButton(
                index: index,
                done: set.done,
                onToggle: onToggle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The check cell: 32×32, fills with the accent when done. The icon pops
/// (scale 0.3 → 1 with a spring-like overshoot) only on the set whose
/// state just changed, with a light haptic tap.
class _CheckButton extends StatefulWidget {
  final int index;
  final bool done;
  final VoidCallback onToggle;

  const _CheckButton({
    required this.index,
    required this.done,
    required this.onToggle,
  });

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

  late final Animation<double> _scale = Tween<double>(begin: 0.3, end: 1)
      .animate(CurvedAnimation(parent: _pop, curve: Curves.easeOutBack));

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
    final done = widget.done;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      checked: done,
      label: l10n.workoutSetDone(widget.index + 1),
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedContainer(
          key: ActiveWorkoutSheet.checkKey,
          duration: Motion.of(context, Motion.fast),
          curve: Motion.curve,
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? palette.accent : palette.tableCell,
            borderRadius: AppRadius.smAll,
          ),
          child: ScaleTransition(
            scale: _scale,
            child: Icon(
              Icons.check,
              size: 18,
              color: done ? palette.onAccent : palette.textSecondary,
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

  /// Unit shown after the number while the field is not focused (e.g. " kg").
  final String suffix;
  final TextStyle style;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.initialValue,
    required this.decimal,
    this.suffix = '',
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
        _controller.text = text.replaceAll(widget.suffix, '');
        _controller.selection =
            TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      } else if (widget.decimal &&
          text.isNotEmpty &&
          !text.endsWith(widget.suffix)) {
        _controller.text = '$text${widget.suffix}';
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
