import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_colors.dart';

class QuickReplyChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const QuickReplyChip({
    super.key,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  State<QuickReplyChip> createState() => _QuickReplyChipState();
}

class _QuickReplyChipState extends State<QuickReplyChip> {
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected || _isSelected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isSelected = true;
        });
        widget.onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary
              : (isDark ? AppColors.darkButtonPrimary : AppColors.lightButtonPrimary),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.star,
                  size: 14,
                  color: isDark ? AppColors.darkTextOnDark : AppColors.lightTextOnDark,
                ),
              ),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextOnDark : AppColors.lightTextOnDark,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: isDark ? AppColors.darkTextOnDark : AppColors.lightTextOnDark,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
