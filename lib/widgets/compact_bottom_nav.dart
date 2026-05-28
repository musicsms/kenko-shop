import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';

class CompactBottomNav extends StatelessWidget {
  const CompactBottomNav({
    required this.selectedIndex,
    required this.cartCount,
    required this.onSelect,
    super.key,
  });

  final int selectedIndex;
  final int cartCount;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          key: const Key('compact-bottom-nav'),
          color: KenkoColors.cream.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: 0.38),
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                _CompactNavItem(
                  key: const Key('compact-nav-feed'),
                  icon: Icons.home_rounded,
                  label: 'Feed',
                  isSelected: selectedIndex == 0,
                  onTap: () => onSelect(0),
                ),
                _CompactNavItem(
                  key: const Key('compact-nav-browse'),
                  icon: Icons.search_rounded,
                  label: 'Browse',
                  isSelected: selectedIndex == 1,
                  onTap: () => onSelect(1),
                ),
                _CompactNavItem(
                  key: const Key('compact-nav-cart'),
                  icon: Icons.shopping_basket_rounded,
                  label: 'Cart',
                  isSelected: selectedIndex == 2,
                  badgeCount: cartCount,
                  onTap: () => onSelect(2),
                ),
                _CompactNavItem(
                  key: const Key('compact-nav-you'),
                  icon: Icons.person_rounded,
                  label: 'You',
                  isSelected: selectedIndex == 3,
                  onTap: () => onSelect(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactNavItem extends StatelessWidget {
  const _CompactNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected
        ? KenkoColors.cream
        : KenkoColors.rawBlack.withValues(alpha: 0.58);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? KenkoColors.moss : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: foreground),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
                if (badgeCount > 0)
                  Positioned(
                    key: const Key('compact-cart-badge'),
                    top: 0,
                    right: 14,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: KenkoColors.flash,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
