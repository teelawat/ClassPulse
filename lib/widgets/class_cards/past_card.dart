import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import '../../models/class_item.dart';
import '../../theme/app_theme.dart';

/// Card widget for past classes (e.g. Homeroom).
class PastCard extends StatelessWidget {
  final ClassItem item;
  final VoidCallback? onTap;
  final int? periodNumber;

  const PastCard({
    super.key,
    required this.item,
    this.onTap,
    this.periodNumber,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 86,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: SmoothRectangleBorder(
            borderRadius: squircleRadius(16),
            side: const BorderSide(color: AppColors.border, width: 1.5),
          ),
        ),
        child: Row(
          children: [
            // Left Column (Time)
            Container(
              width: 90,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.startTime,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.endTime,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            // Right Card Body (Homeroom)
            Expanded(
              child: Container(
                decoration: ShapeDecoration(
                  color: AppColors.surface,
                  shape: SmoothRectangleBorder(
                    borderRadius: squircleRadiusOnly(
                      topRight: 14,
                      bottomRight: 14,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.subject,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '- ${item.teacher}',
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (periodNumber != null)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: ShapeDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.12),
                          shape: SmoothRectangleBorder(borderRadius: squircleRadius(8)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$periodNumber',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
