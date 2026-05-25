import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import '../data/schedule_manager.dart';
import '../models/class_item.dart';
import '../theme/app_theme.dart';
import '../widgets/class_cards/compact_card.dart';
import 'import_screen.dart';

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

  Map<int, List<ClassItem>> _weeklySchedule = {};
  bool _isLoading = true;

  int _getTodayWeekdayIndex() {
    int w = ScheduleManager.getSystemTime().weekday;
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
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final schedule = await ScheduleManager.loadWeeklySchedule();
    if (mounted) {
      setState(() {
        _weeklySchedule = schedule;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _navigateToImport() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImportScreen()),
    );
    if (result == true) {
      setState(() {
        _isLoading = true;
      });
      _loadSchedule();
    }
  }

  Color _themeColorFor(ClassItem item) {
    switch (item.type) {
      case ClassType.past:
        return Colors.grey;
      case ClassType.current:
        return AppColors.green;
      case ClassType.next:
        return AppColors.orange;
      case ClassType.normal:
        return item.themeColor ?? AppColors.blue;
    }
  }

  // Click handler to show class details beautifully (matches HomeScreen details sheet)
  void _showClassDetail(ClassItem item, int dayIndex, int itemIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final rawList = _weeklySchedule[dayIndex] ?? [];
            final dynamicList = ScheduleManager.getDynamicSchedule(rawList, dayIndex);
            final currentItem = dynamicList.isNotEmpty && itemIndex < dynamicList.length 
                ? dynamicList[itemIndex]
                : _weeklySchedule[dayIndex]![itemIndex];
            final themeColor = _themeColorFor(currentItem);

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _editClassInfo(
                          context,
                          dayIndex,
                          itemIndex,
                          setModalState,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text(
                          'แก้ไขข้อมูล',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentItem.subject,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ผู้สอน: ${currentItem.teacher}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'เวลาเรียน: ${currentItem.startTime} - ${currentItem.endTime} น.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ภารกิจและการบ้าน (${currentItem.tasks.length})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _addTask(
                          context,
                          dayIndex,
                          itemIndex,
                          setModalState,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'เพิ่มภารกิจ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (currentItem.tasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(left: 28, top: 4, bottom: 12),
                      child: Text(
                        'ไม่มีการบ้านหรือสอบย่อยในคาบนี้ ✨',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    )
                  else
                    ...List.generate(currentItem.tasks.length, (taskIndex) {
                      final task = currentItem.tasks[taskIndex];
                      final isHomework = task.type == TaskType.homework;
                      final color = isHomework
                          ? AppColors.orange
                          : AppColors.red;
                      final icon = isHomework
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_outlined;

                      return Container(
                        margin: const EdgeInsets.only(left: 28, bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 18, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: AppColors.green,
                                size: 18,
                              ),
                              onPressed: () {
                                final updatedTasks = List<ClassTask>.from(
                                  currentItem.tasks,
                                )..removeAt(taskIndex);

                                setState(() {
                                  _weeklySchedule[dayIndex]![itemIndex] =
                                      currentItem.copyWith(tasks: updatedTasks);
                                });

                                ScheduleManager.saveWeeklySchedule(
                                  _weeklySchedule,
                                );
                                setModalState(() {});
                              },
                              tooltip: 'เสร็จสิ้นภารกิจ',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }),

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
      },
    );
  }

  void _editClassInfo(
    BuildContext context,
    int dayIndex,
    int itemIndex,
    StateSetter setModalState,
  ) {
    final item = _weeklySchedule[dayIndex]![itemIndex];
    final subjectController = TextEditingController(text: item.subject);
    final teacherController = TextEditingController(text: item.teacher);
    final startController = TextEditingController(text: item.startTime);
    final endController = TextEditingController(text: item.endTime);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขข้อมูลวิชา'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อวิชา / ห้องเรียน',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: teacherController,
                decoration: const InputDecoration(
                  labelText: 'ครูผู้สอน',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startController,
                      decoration: const InputDecoration(
                        labelText: 'เริ่ม',
                        hintText: '08:30',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: endController,
                      decoration: const InputDecoration(
                        labelText: 'เลิก',
                        hintText: '09:20',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final subject = subjectController.text.trim();
              final teacher = teacherController.text.trim();
              final start = startController.text.trim();
              final end = endController.text.trim();

              if (subject.isEmpty || start.isEmpty || end.isEmpty) return;

              final theme = ScheduleManager.detectSubjectTheme(subject);
              final updatedItem = item.copyWith(
                subject: subject,
                teacher: teacher.isEmpty ? 'ครูผู้สอน' : teacher,
                startTime: start,
                endTime: end,
                themeColor: theme.themeColor,
                cardColor: theme.cardColor,
                textColor: theme.textColor,
                iconName: theme.iconName,
              );

              setState(() {
                _weeklySchedule[dayIndex]![itemIndex] = updatedItem;
              });
              await ScheduleManager.saveWeeklySchedule(_weeklySchedule);

              if (!mounted || !context.mounted) return;
              setModalState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('บันทึกข้อมูลวิชาแล้ว')),
              );
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _addTask(
    BuildContext context,
    int dayIndex,
    int itemIndex,
    StateSetter setModalState,
  ) {
    final titleController = TextEditingController();
    TaskType selectedType = TaskType.homework;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('เพิ่มการบ้านหรือสอบ'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioGroup<TaskType>(
                    groupValue: selectedType,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedType = val);
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: RadioListTile<TaskType>(
                            title: const Text(
                              'การบ้าน 📝',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            value: TaskType.homework,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<TaskType>(
                            title: const Text(
                              'สอบย่อย ⚡',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            value: TaskType.quiz,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'รายละเอียดสั้นๆ (เช่น ทำแบบฝึกหัดหน้า 5)',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final newTask = ClassTask(title: title, type: selectedType);

                    final updatedTasks = List<ClassTask>.from(
                      _weeklySchedule[dayIndex]![itemIndex].tasks,
                    )..add(newTask);

                    setState(() {
                      _weeklySchedule[dayIndex]![itemIndex] =
                          _weeklySchedule[dayIndex]![itemIndex].copyWith(
                            tasks: updatedTasks,
                          );
                    });

                    ScheduleManager.saveWeeklySchedule(_weeklySchedule);
                    setModalState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Build the dots indicator under weekdays to hint tasks count and type
  List<Widget> _buildSmartDotsForDay(int dayIndex) {
    final schedule = _weeklySchedule[dayIndex] ?? [];
    List<Widget> dots = [];
    for (var classItem in schedule) {
      for (var task in classItem.tasks) {
        dots.add(
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: task.type == TaskType.homework
                  ? AppColors.orange
                  : AppColors.red,
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
              : (isToday
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : Colors.transparent);

          final bgColor = isSelected
              ? Colors.white
              : (isToday
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.transparent);

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
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMedium,
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
    final schedule = _weeklySchedule[dayIndex] ?? [];
    final String lastClassEndTime = schedule.isNotEmpty
        ? schedule.last.endTime
        : '15:30';
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
              color: totalTasks > 0
                  ? AppColors.orange.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              shape: SmoothRectangleBorder(borderRadius: squircleRadius(10)),
            ),
            child: Icon(
              totalTasks > 0
                  ? Icons.event_note
                  : Icons.sentiment_very_satisfied_outlined,
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
                    color: totalTasks > 0
                        ? AppColors.orangeText
                        : AppColors.textLight,
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
    final List<ClassItem> rawSchedule = _weeklySchedule[dayIndex] ?? [];
    final List<ClassItem> schedule = ScheduleManager.getDynamicSchedule(rawSchedule, dayIndex);

    if (schedule.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 14),
              const Text(
                'ไม่มีตารางเรียนในวันนี้',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'กดปุ่มนำเข้าตารางเรียนด้วย AI ด้านบนเพื่อเพิ่มตารางเรียน',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );
    }

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
          onTap: () =>
              _showClassDetail(schedule[index - 1], dayIndex, index - 1),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Column(
      children: [
        // Section 1: Header & Week Range (matches visual structure)
        Container(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 8,
          ),
          color: Colors.white,
          child: Container(
            padding: const EdgeInsets.only(
              left: 12,
              right: 4,
              top: 2,
              bottom: 2,
            ),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: SmoothRectangleBorder(borderRadius: squircleRadius(12)),
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
                const Icon(
                  Icons.date_range,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
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
                IconButton(
                  icon: const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.primary,
                  ),
                  onPressed: _navigateToImport,
                  tooltip: 'นำเข้าตารางเรียนด้วย AI',
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
