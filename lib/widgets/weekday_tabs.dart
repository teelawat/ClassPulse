import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Row of weekday selector tabs (จ. อ. พ. พฤ. ศ.).
///
/// [selectedIndex] — currently highlighted day.
/// [todayIndex]    — index of today (-1 on weekends).
/// [pageController] — controls the linked [PageView].
class WeekdayTabs extends StatelessWidget {
  final int selectedIndex;
  final int todayIndex;
  final PageController pageController;

  static const _labels = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.'];

  const WeekdayTabs({
    super.key,
    required this.selectedIndex,
    required this.todayIndex,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_labels.length, (i) => _Tab(
          label: _labels[i],
          isSelected: i == selectedIndex,
          isToday: i == todayIndex,
          onTap: () => pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 350),
            curve: const Cubic(0.65, 0.0, 0.35, 1.0),
          ),
        )),
      ),
    );
  }
}

// ─── Single tab ───────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.primary
        : (isToday ? AppColors.primary.withValues(alpha: 0.25) : Colors.transparent);

    final bgColor = isSelected
        ? Colors.white
        : (isToday ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: ShapeDecoration(
            color: bgColor,
            shape: SmoothRectangleBorder(
              borderRadius: const SmoothBorderRadius.all(
                SmoothRadius(cornerRadius: 8, cornerSmoothing: 0.6),
              ),
              side: BorderSide(color: borderColor, width: 2),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
