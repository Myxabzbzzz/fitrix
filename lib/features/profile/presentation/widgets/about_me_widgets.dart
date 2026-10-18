
import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

Widget aboutMeDivider(AppPalette palette) =>
    Divider(height: 1, color: palette.border);

Widget aboutMeList(AppPalette palette, List<Widget> rows) => Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: AppRadius.mdAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );

Widget aboutMePill(
        AppPalette palette, String label, bool selected, VoidCallback onTap,
        {Key? key}) =>
    Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.pillSelected : palette.buttonMuted,
            borderRadius: AppRadius.fullAll,
          ),
          child: Text(
            label,
            style: AppText.captionStrong.copyWith(
              color: selected ? palette.onPillSelected : palette.textPrimary,
            ),
          ),
        ),
      ),
    );

Widget aboutMeSection(AppPalette palette, String title, Widget child,
        {String? note}) =>
    Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppText.headingS.copyWith(color: palette.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          child,
          if (note != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(note,
                key: const Key('about-sports-limit'),
                style: AppText.caption.copyWith(color: palette.danger)),
          ],
        ],
      ),
    );
