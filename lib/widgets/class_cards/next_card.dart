import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/class_item.dart';
import '../../theme/app_theme.dart';

/// Card widget for the upcoming/next class, highlighted in orange with a badge.
class NextCard extends StatelessWidget {
  final ClassItem item;
  final VoidCallback? onTap;

  const NextCard({
    super.key,
    required this.item,
    this.onTap,
  });

  Widget _buildENSpeechBubble() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.chat_bubble_outline,
          size: 36,
          color: AppColors.orangeDark,
        ),
        Positioned(
          top: 7,
          child: Text(
            'EN',
            style: GoogleFonts.outfit(
              color: AppColors.orangeDark,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 86,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: SmoothRectangleBorder(
                borderRadius: squircleRadius(16),
                side: const BorderSide(color: AppColors.orange, width: 1.5),
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
                      const SizedBox(height: 8), // Offset for badge overlap
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
                // Right Card Body (Orange theme)
                Expanded(
                  child: Container(
                    decoration: ShapeDecoration(
                      color: AppColors.orangeLight,
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
                                  color: AppColors.orangeText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '- ${item.teacher}',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  color: AppColors.orangeText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildENSpeechBubble(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Overlapping Badge "คาบต่อไป"
        Positioned(
          top: -10,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: ShapeDecoration(
              color: AppColors.orangeDark,
              shape: SmoothRectangleBorder(
                borderRadius: squircleRadius(8),
              ),
            ),
            child: const Text(
              'คาบต่อไป',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
