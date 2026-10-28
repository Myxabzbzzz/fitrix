import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Bottom sheet with 1-10 and the "reps left in the tank" caption. The
/// pick is saved at once; Done closes the sheet.
Future<void> showRpePicker(
  BuildContext context, {
  required int setNumber,
  required int? initial,
  required ValueChanged<int> onPick,
}) {
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _RpeSheet(
      setNumber: setNumber,
      initial: initial,
      onPick: onPick,
    ),
  );
}

class _RpeSheet extends StatefulWidget {
  final int setNumber;
  final int? initial;
  final ValueChanged<int> onPick;

  const _RpeSheet({
    required this.setNumber,
    required this.initial,
    required this.onPick,
  });

  @override
  State<_RpeSheet> createState() => _RpeSheetState();
}

class _RpeSheetState extends State<_RpeSheet> {
  late int? _rpe = widget.initial;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.workoutRpeTitle(widget.setNumber).toUpperCase(),
              style:
                  AppText.captionStrong.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            RpeScale(
              keyPrefix: 'rpePick',
              selected: _rpe,
              onPick: (n) {
                setState(() => _rpe = n);
                widget.onPick(n);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _rpe == null
                  ? l10n.workoutOverallHint
                  : l10n.workoutRpeCaption(_rpe!, 10 - _rpe!),
              style: AppText.body14.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.workoutKeyboardDone,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row of the numbers 1-10; the picked one is filled with the accent.
class RpeScale extends StatelessWidget {
  final String keyPrefix;
  final int? selected;
  final ValueChanged<int> onPick;
  final Color? cellColor;

  const RpeScale({
    super.key,
    required this.keyPrefix,
    required this.selected,
    required this.onPick,
    this.cellColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      children: [
        for (var n = 1; n <= 10; n++) ...[
          if (n > 1) const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: GestureDetector(
              key: ValueKey('$keyPrefix-$n'),
              onTap: () => onPick(n),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected == n
                      ? palette.accent
                      : cellColor ?? palette.sheetTile,
                  borderRadius: AppRadius.smAll,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$n',
                    style: AppText.headingS.copyWith(
                      color: selected == n
                          ? palette.onAccent
                          : palette.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
