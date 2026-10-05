import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';

/// Large left-aligned page title ("My workouts", "Gym", "My progress").
/// Shows a back button when the current route can be popped.
class ScreenTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const ScreenTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final canPop = Navigator.of(context).canPop();

    return Padding(
      padding: EdgeInsets.fromLTRB(canPop ? 4 : 16, 12, 16, 12),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: palette.textPrimary,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
