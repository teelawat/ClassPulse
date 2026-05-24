import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Header bar showing the current date and a calendar icon.
class ScheduleHeader extends StatelessWidget {
  final String dateText;

  const ScheduleHeader({super.key, required this.dateText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: SmoothRectangleBorder(
            borderRadius: squircleRadius(12),
          ),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const _CalendarIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dateText,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mini calendar icon ────────────────────────────────────────────────────

class _CalendarIcon extends StatelessWidget {
  const _CalendarIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(borderRadius: squircleRadius(8)),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Red top bar
          Container(
            height: 9,
            decoration: ShapeDecoration(
              color: AppColors.red,
              shape: SmoothRectangleBorder(
                borderRadius: squircleRadiusOnly(topLeft: 8, topRight: 8),
              ),
            ),
          ),
          // Dot grid calendar body
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (_) => Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      3,
                      (_) => Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
