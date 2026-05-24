import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import '../../models/class_item.dart';
import '../../theme/app_theme.dart';

/// A horizontally compact card for the Weekly Schedule page.
/// Shows classes in a slim layout to fit the whole day on screen.
/// Renders attached homework/quizzes underneath with stylized connectors.
class CompactCard extends StatelessWidget {
  final ClassItem item;
  final VoidCallback? onTap;

  const CompactCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bodyColor;
    Color textColor;
    Color subtextColor;
    Widget icon;

    switch (item.type) {
      case ClassType.past:
        borderColor = AppColors.border;
        bodyColor = AppColors.surface;
        textColor = AppColors.textMuted;
        subtextColor = AppColors.textMuted;
        icon = const Icon(Icons.waving_hand_outlined, size: 20, color: AppColors.textMuted);
        break;
      case ClassType.current:
        borderColor = AppColors.green;
        bodyColor = AppColors.greenBg;
        textColor = AppColors.greenDark;
        subtextColor = const Color(0xFF15803D).withValues(alpha: 0.8);
        icon = const Icon(Icons.science_outlined, size: 24, color: AppColors.green);
        break;
      case ClassType.next:
        borderColor = AppColors.orange;
        bodyColor = AppColors.orangeLight;
        textColor = AppColors.orangeText;
        subtextColor = AppColors.orangeText.withValues(alpha: 0.8);
        icon = const Icon(Icons.chat_bubble_outline, size: 22, color: AppColors.orangeDark);
        break;
      case ClassType.normal:
        borderColor = item.themeColor ?? AppColors.blue;
        bodyColor = item.cardColor ?? AppColors.blue;
        textColor = item.textColor ?? Colors.white;
        subtextColor = textColor.withValues(alpha: 0.85);
        icon = item.themeColor == AppColors.purple
            ? const Icon(Icons.account_balance, color: Colors.white, size: 20)
            : const Padding(
                padding: EdgeInsets.only(right: 2.0),
                child: Text(
                  'ญ',
                  style: TextStyle(
                    color: Color(0x3BFFFFFF),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 62,
            decoration: ShapeDecoration(
              color: item.type == ClassType.normal ? bodyColor : Colors.white,
              shape: SmoothRectangleBorder(
                borderRadius: squircleRadius(12),
                side: BorderSide(color: borderColor, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                // Left Column (Time)
                Container(
                  width: 80,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.startTime,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: item.type == ClassType.normal ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.endTime,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: item.type == ClassType.normal ? Colors.white.withValues(alpha: 0.8) : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider line if not normal card
                if (item.type != ClassType.normal)
                  Container(
                    width: 1.5,
                    height: 32,
                    color: borderColor.withValues(alpha: 0.4),
                  ),
                // Right Card Body (Subject & Teacher)
                Expanded(
                  child: Container(
                    decoration: item.type == ClassType.normal
                        ? null
                        : ShapeDecoration(
                            color: bodyColor,
                            shape: SmoothRectangleBorder(
                              borderRadius: squircleRadiusOnly(
                                topRight: 10,
                                bottomRight: 10,
                              ),
                            ),
                          ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '- ${item.teacher}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: subtextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        icon,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Render connected tasks list below the card if any tasks exist
        if (item.tasks.isNotEmpty)
          ...item.tasks.map((task) => _buildTaskAttachment(task)),
      ],
    );
  }

  Widget _buildTaskAttachment(ClassTask task) {
    final emoji = task.type == TaskType.homework ? '📝' : '⚡';
    final taskTypeName = task.type == TaskType.homework ? 'การบ้าน' : 'สอบย่อย';
    final taskColor = task.type == TaskType.homework ? AppColors.orange : AppColors.red;

    return Padding(
      padding: const EdgeInsets.only(left: 45, top: 4, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Styled custom tree connector line
          Text(
            '└ ',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: ShapeDecoration(
              color: taskColor.withValues(alpha: 0.08),
              shape: SmoothRectangleBorder(
                borderRadius: squircleRadius(4),
                side: BorderSide(color: taskColor.withValues(alpha: 0.2), width: 1),
              ),
            ),
            child: Text(
              '$emoji $taskTypeName',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: taskColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text(
                task.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
