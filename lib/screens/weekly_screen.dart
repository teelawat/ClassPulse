import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import '../data/schedule_data.dart';
import '../models/class_item.dart';
import '../theme/app_theme.dart';
import '../widgets/class_cards/compact_card.dart';

/// The Weekly Schedule page with PageView swipeable daily list views,
/// Bento box summaries, compact class cards, and smart day strips with hints.
class WeeklyScreen extends StatefulWidget {
  const WeeklyScreen({super.key});

  @override
  State<WeeklyScreen> createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends State<WeeklyScreen> {
  int _selectedDayIndex = 0;
  late PageController _pageController;

  int _getTodayWeekdayIndex() {
    int w = DateTime.now().weekday;
    if (w >= 1 && w <= 5) {
      return w - 1;
    }
    return -1;
  }

  @override
  void initState() {
    super.initState();
    int todayIndex = _getTodayWeekdayIndex();
    _selectedDayIndex = todayIndex == -1 ? 0 : todayIndex;
    _pageController = PageController(initialPage: _selectedDayIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Click handler to show class details beautifully (matches HomeScreen details sheet)
  void _showClassDetail(ClassItem item) {
    Color themeColor;
    switch (item.type) {
      case ClassType.past:
        themeColor = Colors.grey;
        break;
      case ClassType.current:
        themeColor = AppColors.green;
        break;
      case ClassType.next:
        themeColor = AppColors.orange;
        break;
      case ClassType.normal:
        themeColor = item.themeColor ?? AppColors.blue;
        break;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const ShapeDecoration(
            color: Colors.white,
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius.vertical(
                top: SmoothRadius(
                  cornerRadius: 24,
                  cornerSmoothing: 0.6,
                ),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: ShapeDecoration(
                    color: Colors.grey[300],
                    shape: SmoothRectangleBorder(
                      borderRadius: squircleRadius(2),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'รายละเอียดวิชาเรียน',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.subject,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF64748B), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ผู้สอน: ${item.teacher}',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF475569)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time_filled, color: Color(0xFF64748B), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'เวลาเรียน: ${item.startTime} - ${item.endTime} น.',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF475569)),
                  ),
                ],
              ),
              if (item.tasks.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.assignment, color: AppColors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ภารกิจ / การบ้าน:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...item.tasks.map((task) {
                  final isHomework = task.type == TaskType.homework;
                  return Padding(
                    padding: const EdgeInsets.only(left: 28, bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          isHomework ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                          size: 16,
                          color: isHomework ? AppColors.orange : AppColors.red,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(fontSize: 14.5, color: AppColors.textMedium),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'ปิดหน้าต่าง',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build the dots indicator under weekdays to hint tasks count and type
  List<Widget> _buildSmartDotsForDay(int dayIndex) {
    final schedule = getScheduleForDay(dayIndex);
    List<Widget> dots = [];
    for (var classItem in schedule) {
      for (var task in classItem.tasks) {
        dots.add(
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: task.type == TaskType.homework ? AppColors.orange : AppColors.red,
              shape: BoxShape.circle,
            ),
          ),
        );
      }
    }
    return dots;
  }

  // Smart day selector strip with task count hints
  Widget _buildSmartDayStrip() {
    final List<String> days = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.'];
    final todayIndex = _getTodayWeekdayIndex();

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(days.length, (index) {
          final isSelected = index == _selectedDayIndex;
          final isToday = index == todayIndex;
          final dots = _buildSmartDotsForDay(index);

          final borderColor = isSelected
              ? AppColors.primary
              : (isToday ? AppColors.primary.withValues(alpha: 0.25) : Colors.transparent);

          final bgColor = isSelected
              ? Colors.white
              : (isToday ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent);

          return Expanded(
            child: GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 350),
                  curve: const Cubic(0.65, 0.0, 0.35, 1.0),
                );
              },
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primary : AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Hint dots under weekday name
                    SizedBox(
                      height: 5,
                      child: dots.isNotEmpty
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: dots,
                            )
                          : Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Bento box style summary card at top of content area
  Widget _buildBentoSummaryCard(int dayIndex) {
    final schedule = getScheduleForDay(dayIndex);
    final String lastClassEndTime = schedule.isNotEmpty ? schedule.last.endTime : '15:30';
    int hwCount = 0;
    int quizCount = 0;

    for (var classItem in schedule) {
      for (var task in classItem.tasks) {
        if (task.type == TaskType.homework) {
          hwCount++;
        } else {
          quizCount++;
        }
      }
    }

    final totalTasks = hwCount + quizCount;
    String taskSummaryText = 'ไม่มีการบ้านหรือสอบในวันนี้ ✨';
    if (totalTasks > 0) {
      List<String> parts = [];
      if (hwCount > 0) parts.add('การบ้าน $hwCount ชิ้น');
      if (quizCount > 0) parts.add('สอบย่อย $quizCount วิชา');
      taskSummaryText = 'มีงานต้องเคลียร์: ${parts.join(" และ ")} 📝';
    }

    // Determine a subtle tint depending on tasks
    final Color bentoBg = totalTasks > 0 
        ? const Color(0xFFFFF7ED) // Orange tint
        : const Color(0xFFF8FAFC); // Clean slate tint
    final Color bentoBorder = totalTasks > 0
        ? const Color(0xFFFFEDD5)
        : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: bentoBg,
        shape: SmoothRectangleBorder(
          borderRadius: squircleRadius(16),
          side: BorderSide(color: bentoBorder, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: ShapeDecoration(
              color: totalTasks > 0 ? AppColors.orange.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
              shape: SmoothRectangleBorder(borderRadius: squircleRadius(10)),
            ),
            child: Icon(
              totalTasks > 0 ? Icons.event_note : Icons.sentiment_very_satisfied_outlined,
              color: totalTasks > 0 ? AppColors.orange : AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'วันนี้เรียน ${schedule.length} วิชา • เลิก $lastClassEndTime น.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  taskSummaryText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: totalTasks > 0 ? AppColors.orangeText : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Renders scrollable timeline of compact cards
  Widget _buildWeeklyClassListForDay(int dayIndex) {
    final List<ClassItem> schedule = getScheduleForDay(dayIndex);

    return ListView.separated(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 104),
      itemCount: schedule.length + 1, // +1 for Bento summary card
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildBentoSummaryCard(dayIndex);
        }
        return CompactCard(
          item: schedule[index - 1],
          onTap: () => _showClassDetail(schedule[index - 1]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section 1: Header & Week Range (matches visual structure)
        Container(
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
            child: const Row(
              children: [
                Icon(Icons.date_range, color: AppColors.primary, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'สัปดาห์นี้: 25 - 29 พฤษภาคม 2026',
                    style: TextStyle(
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
        ),

        // Section 2: Smart Day Strip
        _buildSmartDayStrip(),

        // Section 3: PageView content area
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: 5,
            onPageChanged: (index) {
              setState(() {
                _selectedDayIndex = index;
              });
            },
            itemBuilder: (context, index) => _buildWeeklyClassListForDay(index),
          ),
        ),
      ],
    );
  }
}
