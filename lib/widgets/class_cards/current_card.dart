import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import '../../models/class_item.dart';
import '../../theme/app_theme.dart';

/// Card widget for current ongoing class with progress indicator and countdown.
class CurrentCard extends StatelessWidget {
  final ClassItem item;
  final int remainingSeconds;
  final VoidCallback? onTap;
  final int? periodNumber;

  const CurrentCard({
    super.key,
    required this.item,
    required this.remainingSeconds,
    this.onTap,
    this.periodNumber,
  });

  String _formatRemainingTime() {
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;
    if (minutes > 0) {
      return 'เหลืออีก $minutes นาที ${seconds.toString().padLeft(2, '0')} วินาที';
    } else {
      return 'เหลืออีก $seconds วินาที';
    }
  }

  double _getProgressValue() {
    final partsStart = item.startTime.split(':');
    final partsEnd = item.endTime.split(':');
    if (partsStart.length != 2 || partsEnd.length != 2) return 0.5;

    final hourStart = int.tryParse(partsStart[0]) ?? 0;
    final minuteStart = int.tryParse(partsStart[1]) ?? 0;
    final hourEnd = int.tryParse(partsEnd[0]) ?? 0;
    final minuteEnd = int.tryParse(partsEnd[1]) ?? 0;

    final startMinutes = hourStart * 60 + minuteStart;
    final endMinutes = hourEnd * 60 + minuteEnd;
    final totalMinutes = endMinutes - startMinutes;

    if (totalMinutes <= 0) return 0.5;
    final totalSeconds = totalMinutes * 60;
    final elapsedSeconds = totalSeconds - remainingSeconds;

    if (elapsedSeconds <= 0) return 0.0;
    if (elapsedSeconds >= totalSeconds) return 1.0;
    return elapsedSeconds / totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: ShapeDecoration(
          color: AppColors.greenBg,
          shape: SmoothRectangleBorder(
            borderRadius: squircleRadius(16),
            side: const BorderSide(color: AppColors.green, width: 1.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            ClipSmoothRect(
              radius: squircleRadius(10),
              child: LinearProgressIndicator(
                value: _getProgressValue(),
                backgroundColor: AppColors.border,
                color: AppColors.green,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            
            // Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'กำลังเรียนอยู่',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.5,
                  ),
                ),
                Text(
                  _formatRemainingTime(),
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Subject Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.subject,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '- ${item.teacher}',
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (periodNumber != null)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: ShapeDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      shape: SmoothRectangleBorder(borderRadius: squircleRadius(10)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$periodNumber',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
