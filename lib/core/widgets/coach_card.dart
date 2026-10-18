import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';

class CoachCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String message;
  final String? imageAsset;
  final double imageWidth;
  final double imageHeight;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const CoachCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.message,
    this.imageAsset,
    this.imageWidth = 84,
    this.imageHeight = 120,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final image = imageAsset;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration:
          BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (image != null) ...[
            SizedBox(
              width: imageWidth,
              height: imageHeight,
              child: Image.asset(image, fit: BoxFit.contain),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(eyebrow.toUpperCase(),
                    style:
                        AppText.captionStrong.copyWith(color: palette.accent)),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(title,
                      style: AppText.headingS
                          .copyWith(color: palette.textPrimary)),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(message,
                    style:
                        AppText.caption.copyWith(color: palette.textPrimary)),
                if (primaryLabel != null || secondaryLabel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (primaryLabel != null)
                        Expanded(
                          child: AppButton(
                            label: primaryLabel!,
                            onPressed: onPrimary,
                            expand: true,
                          ),
                        ),
                      if (primaryLabel != null && secondaryLabel != null)
                        const SizedBox(width: AppSpacing.xs),
                      if (secondaryLabel != null)
                        Flexible(
                          child: AppButton(
                            label: secondaryLabel!,
                            onPressed: onSecondary,
                            style: AppButtonStyle.secondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
