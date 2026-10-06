import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitrix/core/theme/app_colors.dart';
import 'package:fitrix/core/theme/app_palette.dart';

/// Keeps only digits and at most [length] of them. A pasted code wins over
/// what was typed before ("12" + paste "Code: 345 678" → "345678").
class CodeDigitsFormatter extends TextInputFormatter {
  CodeDigitsFormatter(this.length);

  final int length;

  static String digitsOf(String text) => text.replaceAll(RegExp(r'\D'), '');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = digitsOf(newValue.text);
    if (digits.length > length) {
      final old = digitsOf(oldValue.text);
      digits = old.length >= length
          ? old.substring(0, length)
          : digits.substring(digits.length - length);
    }
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

/// A one-time code field drawn as separate boxes. One real text field sits
/// on top (invisible), so typing, deleting, pasting and the iOS / Android
/// "code from email" suggestions all work like in a normal field.
class CodeInput extends StatelessWidget {
  const CodeInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onCompleted,
    this.length = 6,
    this.enabled = true,
    this.readOnly = false,
    this.hasError = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onCompleted;
  final int length;
  final bool enabled;

  /// Ignores typing but keeps focus (and the keyboard) while a code is
  /// being checked, so a wrong code can be retyped right away.
  final bool readOnly;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SizedBox(
      height: 60,
      child: Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([controller, focusNode]),
            builder: (context, _) {
              final text = controller.text;
              return Row(
                children: [
                  for (var i = 0; i < length; i++) ...[
                    if (i > 0) SizedBox(width: i == length ~/ 2 ? 16 : 8),
                    Expanded(
                      child: _box(
                        palette,
                        digit: i < text.length ? text[i] : '',
                        active: focusNode.hasFocus &&
                            enabled &&
                            (i == text.length ||
                                (i == length - 1 && text.length == length)),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          Positioned.fill(
            child: TextField(
              key: const Key('code-input'),
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              readOnly: readOnly,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [CodeDigitsFormatter(length)],
              showCursor: false,
              enableSuggestions: false,
              autocorrect: false,
              style: const TextStyle(color: Colors.transparent, fontSize: 1),
              cursorColor: Colors.transparent,
              decoration: const InputDecoration.collapsed(
                hintText: null,
                filled: false,
              ),
              onChanged: (value) {
                if (value.length == length) onCompleted(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(AppPalette palette, {required String digit, required bool active}) {
    final borderColor = hasError
        ? AppColors.error
        : active
            ? palette.accent
            : palette.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: active || hasError ? 2 : 1),
      ),
      child: Text(
        digit,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: enabled ? palette.textPrimary : palette.textSecondary,
        ),
      ),
    );
  }
}
