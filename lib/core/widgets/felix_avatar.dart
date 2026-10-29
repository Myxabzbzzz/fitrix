import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Felix the robot as a small round avatar: the robot's head on a soft circle
/// that reads in light and dark. Used for chat, the Felix tab, badges and hints.
class FelixAvatar extends StatelessWidget {
  static const String asset = 'assets/images/felix_robot_head.png';

  final double size;

  /// Gap between the circle edge and the head, so the antennae are not cut.
  final double inset;

  const FelixAvatar({super.key, required this.size, this.inset = 0});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      key: const ValueKey('felix-avatar'),
      width: size,
      height: size,
      padding: EdgeInsets.all(inset),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.sheetTile,
      ),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
