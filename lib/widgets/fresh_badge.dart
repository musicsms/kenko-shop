import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';

class FreshBadge extends StatelessWidget {
  const FreshBadge({
    required this.label,
    super.key,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final effectiveForeground = foregroundColor ?? KenkoColors.rawBlack;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? KenkoColors.cream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor ?? effectiveForeground.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: effectiveForeground),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: effectiveForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
