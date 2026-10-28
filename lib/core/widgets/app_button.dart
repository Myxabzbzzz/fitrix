import 'package:flutter/material.dart';
import 'package:fitrix/core/widgets/shrink_to_fit_text.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

enum AppButtonStyle { primary, secondary }

enum AppButtonSize { small, medium, large }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final AppButtonSize size;
  final IconData? icon;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.expand = false,
  });

  static const double pressedScale = 0.97;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final enabled = widget.onPressed != null;
    final primary = widget.style == AppButtonStyle.primary;
    final bg = primary ? palette.accent : palette.buttonMuted;
    final fg = primary ? palette.onAccent : palette.textPrimary;

    final (double height, double hPad, TextStyle base, BorderRadius radius) =
        switch (widget.size) {
      AppButtonSize.small => (
          24.0,
          AppSpacing.sm,
          AppText.captionStrong,
          AppRadius.smAll
        ),
      AppButtonSize.medium => (
          32.0,
          AppSpacing.md,
          AppText.headingS,
          AppRadius.smAll
        ),
      AppButtonSize.large => (
          48.0,
          AppSpacing.md,
          AppText.headingS,
          BorderRadius.circular(12)
        ),
    };

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: base.fontSize, color: fg),
          const SizedBox(width: AppSpacing.xxs),
        ],
        // A label that doesn't fit shrinks a little (not below 80 %), then
        // wraps to two lines, instead of losing its end to an ellipsis.
        Flexible(
          child: ShrinkToFitText(
            widget.label,
            textAlign: TextAlign.center,
            style: base.copyWith(color: fg),
          ),
        ),
      ],
    );

    return Semantics(
        button: true,
        enabled: enabled,
        container: true,
        label: widget.label,
        excludeSemantics: true,
        onTap: widget.onPressed,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: AnimatedScale(
            scale: _pressed ? AppButton.pressedScale : 1,
            duration: Motion.of(context, Motion.press),
            curve: Motion.curve,
            child: DecoratedBox(
              decoration: BoxDecoration(color: bg, borderRadius: radius),
              child: Material(
                type: MaterialType.transparency,
                borderRadius: radius,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onPressed,
                  onHighlightChanged: enabled ? _setPressed : null,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: height),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: Center(widthFactor: 1, child: content),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
