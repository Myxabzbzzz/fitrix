import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/widgets/screen_title.dart';

/// Placeholder for sections that exist as entry points in the design
/// (Discover, Shop, Fitrix map) but don't have their own screens yet.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? imageAsset;

  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(title),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (imageAsset != null)
                      Image.asset(imageAsset!, height: 160)
                    else
                      Icon(icon, size: 64, color: palette.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Coming soon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
