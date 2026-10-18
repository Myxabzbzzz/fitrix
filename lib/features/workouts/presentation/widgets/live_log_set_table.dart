import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/widgets/active_workout_sheet.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Six-column grid: Set · Previous · Kg · Reps · RPE · check.
const _colSet = 28.0;
const _colRpe = 36.0;
const _colCheck = 36.0;
const _gap = AppSpacing.xxs;

class SetTableHeader extends StatelessWidget {
  const SetTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final style = AppText.microStrong.copyWith(color: palette.textSecondary);
    Widget hd(String text) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text.toUpperCase(), style: style),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          SizedBox(
              width: _colSet, child: Center(child: hd(l10n.workoutColSet))),
          const SizedBox(width: _gap),
          Expanded(child: Center(child: hd(l10n.workoutColPrevious))),
          const SizedBox(width: _gap),
          Expanded(child: Center(child: hd(l10n.workoutColKg))),
          const SizedBox(width: _gap),
          Expanded(child: Center(child: hd(l10n.workoutColReps))),
          const SizedBox(width: _gap),
          SizedBox(
              width: _colRpe, child: Center(child: hd(l10n.workoutColRpe))),
          const SizedBox(width: _gap),
          const SizedBox(width: _colCheck),
        ],
      ),
    );
  }
}

class SetTableRow extends StatelessWidget {
  /// 1-based number among working sets; null for a warm-up ("W").
  final int? label;
  final WorkoutSet set;
  final VoidCallback onToggle;
  final VoidCallback onRpe;
  final Key rpeKey;
  final ValueChanged<double> onKgChanged;
  final ValueChanged<int> onRepsChanged;

  const SetTableRow({
    super.key,
    required this.label,
    required this.set,
    required this.onToggle,
    required this.onRpe,
    required this.rpeKey,
    required this.onKgChanged,
    required this.onRepsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
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

    final hasPrevious =
        !set.warmup && (set.previousKg > 0 || set.previousReps > 0);
    final rpeText = set.rpe == null ? '—' : '${set.rpe}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: _colSet,
            child: cell(
              plain: true,
              child: Text(
                label == null ? 'W' : '$label',
                style: textStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: label == null ? palette.accent : palette.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: cell(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  hasPrevious
                      ? '${formatKg(set.previousKg)}×${set.previousReps}'
                      : '—',
                  style: textStyle.copyWith(color: palette.textSecondary),
                ),
              ),
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: cell(
              child: _NumberField(
                initialValue: formatKg(set.kg),
                decimal: true,
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
            width: _colRpe,
            child: set.warmup
                ? const SizedBox(height: 32)
                : GestureDetector(
                    key: rpeKey,
                    onTap: onRpe,
                    behavior: HitTestBehavior.opaque,
                    child: cell(
                      child: Text(
                        rpeText,
                        style: textStyle.copyWith(
                          color: set.rpe == null
                              ? palette.textSecondary
                              : palette.textPrimary,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: _gap),
          SizedBox(
            width: _colCheck,
            child: Center(
              child: _CheckButton(
                label: label == null
                    ? l10n.workoutSetDone(0)
                    : l10n.workoutSetDone(label!),
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
  final String label;
  final bool done;
  final VoidCallback onToggle;

  const _CheckButton({
    required this.label,
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

    return Semantics(
      button: true,
      checked: done,
      label: widget.label,
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

/// Compact numeric input that sits inside a table cell; selects all on focus.
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
      if (_focusNode.hasFocus) {
        _controller.selection =
            TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      }
    });
  }

  @override
  void didUpdateWidget(_NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The row can show another set after warm-ups, a swap or a removal;
    // follow the model unless the user is typing here.
    if (!_focusNode.hasFocus && _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
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
      scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20 + kDoneBarHeight),
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
