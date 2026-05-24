import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Premium floating bottom navigation bar with squircle corners.
///
/// [currentIndex] — highlighted tab (0-based).
/// [onTabChanged] — called when a tab is tapped.
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  static const _items = [
    _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Today'),
    _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Schedule'),
    _NavItem(icon: Icons.notifications_none_outlined, activeIcon: Icons.notifications, label: 'Alerts'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      height: 66,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(borderRadius: squircleRadius(22)),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _items.length,
          (i) => _NavButton(
            item: _items[i],
            isSelected: i == currentIndex,
            onTap: () => onTabChanged(i),
          ),
        ),
      ),
    );
  }
}

// ─── Nav item data ────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ─── Single nav button ─────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: ShapeDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                shape: SmoothRectangleBorder(borderRadius: squircleRadius(12)),
              ),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
