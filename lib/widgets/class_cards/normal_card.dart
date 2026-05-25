import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import '../../models/class_item.dart';
import '../../theme/app_theme.dart';

/// Card widget for normal classes (e.g. Thai, History) with customizable theme, card, text colors, and icon.
class NormalCard extends StatelessWidget {
  final ClassItem item;
  final Widget? icon;
  final VoidCallback? onTap;

  const NormalCard({
    super.key,
    required this.item,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Fallbacks if properties are not defined in ClassItem
    final themeColor = item.themeColor ?? AppColors.blue;
    final cardColor = item.cardColor ?? AppColors.blue;
    final textColor = item.textColor ?? Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 86,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: SmoothRectangleBorder(
            borderRadius: squircleRadius(16),
            side: BorderSide(color: themeColor, width: 1.5),
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
            // Right Card Body
            Expanded(
              child: Container(
                decoration: ShapeDecoration(
                  color: cardColor,
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
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '- ${item.teacher}',
                            style: TextStyle(
                              fontSize: 14.5,
                              color: textColor.withValues(alpha: 0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    icon ?? buildClassIcon(item.iconName, themeColor, whiteColor: true, size: 32),
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
