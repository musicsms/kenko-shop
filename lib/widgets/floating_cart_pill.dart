import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';

class FloatingCartPill extends StatelessWidget {
  const FloatingCartPill({required this.count, required this.onTap, super.key});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          key: const Key('floating-cart-pill'),
          color: KenkoColors.cream,
          borderRadius: BorderRadius.circular(999),
          elevation: 14,
          shadowColor: Colors.black.withValues(alpha: 0.35),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_basket_outlined,
                    color: KenkoColors.rawBlack,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: KenkoColors.rawBlack,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Fresh cart',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: KenkoColors.rawBlack,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
