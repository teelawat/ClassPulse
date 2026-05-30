import 'dart:async';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import '../data/schedule_data.dart';
import '../data/schedule_manager.dart';
import '../models/class_item.dart';
import '../theme/app_theme.dart';
import '../widgets/class_cards/current_card.dart';
import '../widgets/class_cards/next_card.dart';
import '../widgets/class_cards/normal_card.dart';
import '../widgets/class_cards/past_card.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/schedule_header.dart';
import '../widgets/title_bar.dart';
import 'import_screen.dart';
import 'weekly_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDayIndex = 0; // 0 = จ., 1 = อ., etc.
  int _currentTabIndex = 0; // 0 = Today, 1 = Weekly Schedule, etc.
  int _previousTabIndex = 0;

  double? _overlayX;
  double? _overlayY;

  Timer? _countdownTimer;

  Map<int, List<ClassItem>> _weeklySchedule = {};
  bool _isLoading = true;

  int _getTodayWeekdayIndex() {
    int w = ScheduleManager.getSystemTime().weekday; // 1 = Monday, ..., 7 = Sunday
    if (w >= 1 && w <= 5) {
      return w - 1; // 0 = Mon, ..., 4 = Fri
    }
    return -1; // Weekend
  }

  @override
  void initState() {
    super.initState();
    int todayIndex = _getTodayWeekdayIndex();
    _selectedDayIndex = todayIndex == -1 ? 0 : todayIndex;
    _startTimer();
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

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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

  // Click handler to show class details beautifully
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

  Widget _buildClassCard(ClassItem item, int dayIndex, int itemIndex) {
    switch (item.type) {
      case ClassType.past:
        return PastCard(
          item: item,
          onTap: () => _showClassDetail(item, dayIndex, itemIndex),
          periodNumber: item.periodNumber,
        );
      case ClassType.current:
        final now = ScheduleManager.getSystemTime();
        final parts = item.endTime.split(':');
        int remaining = 0;
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          final classEnd = DateTime(now.year, now.month, now.day, hour, minute);
          remaining = classEnd.difference(now).inSeconds;
          if (remaining < 0) remaining = 0;
        }
        return CurrentCard(
          item: item,
          remainingSeconds: remaining,
          onTap: () => _showClassDetail(item, dayIndex, itemIndex),
          periodNumber: item.periodNumber,
        );
      case ClassType.next:
        return NextCard(
          item: item,
          onTap: () => _showClassDetail(item, dayIndex, itemIndex),
          periodNumber: item.periodNumber,
        );
      case ClassType.normal:
        return NormalCard(
          item: item,
          onTap: () => _showClassDetail(item, dayIndex, itemIndex),
          periodNumber: item.periodNumber,
        );
    }
  }

  Widget _buildBreakSeparator(ClassItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: const Color(0xFFF8FAFC),
        shape: SmoothRectangleBorder(
          borderRadius: squircleRadius(12),
          side: const BorderSide(color: AppColors.border, width: 1.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.coffee_outlined,
            color: AppColors.textLight,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            item.subject,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textMedium,
            ),
          ),
          const Spacer(),
          Text(
            '${item.startTime} - ${item.endTime} น.',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassListForDay(int dayIndex) {
    final List<ClassItem> rawSchedule = _weeklySchedule[dayIndex] ?? [];
    final List<ClassItem> schedule = ScheduleManager.getDynamicSchedule(rawSchedule, dayIndex);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

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
                'นำเข้าตารางเรียนผ่านปุ่ม AI ในหน้าโปรไฟล์หรือตารางเรียนแบบสัปดาห์',
                style: TextStyle(fontSize: 12.5, color: AppColors.textLight),
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
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 104),
      itemCount: schedule.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = schedule[index];
        if (item.isBreak) {
          return _buildBreakSeparator(item);
        }
        return _buildClassCard(item, dayIndex, index);
      },
    );
  }

  Widget _buildAlertsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: ShapeDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: SmoothRectangleBorder(borderRadius: squircleRadius(20)),
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ไม่มีการแจ้งเตือนใหม่',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'คุณจะได้รับแจ้งเตือนเมื่อมีการประกาศจากโรงเรียน',
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ตั้งค่าการใช้งาน',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'จัดการตารางเรียนและตั้งค่าจำลองเวลาของแอปพลิเคชัน',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 24),
          
          // Section 1: Schedule Management
          _buildSettingsSectionHeader('จัดการตารางเรียน'),
          Container(
            decoration: ShapeDecoration(
              color: const Color(0xFFF8FAFC),
              shape: SmoothRectangleBorder(
                borderRadius: squircleRadius(16),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              children: [
                _buildSettingsMenuItem(
                  Icons.add_photo_alternate_outlined,
                  'นำเข้าตารางเรียนด้วย AI',
                  onTap: () => _navigateToImport(context),
                ),
                _buildSettingsMenuItem(
                  Icons.delete_outline,
                  'ล้างข้อมูลตารางเรียน',
                  color: Colors.red,
                  onTap: _clearSchedule,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: For Developers
          _buildSettingsSectionHeader('สำหรับนักพัฒนาซอฟต์แวร์'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: ShapeDecoration(
              color: const Color(0xFFF8FAFC),
              shape: SmoothRectangleBorder(
                borderRadius: squircleRadius(16),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.developer_mode, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'โหมดตั้งเวลาทดสอบ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'เปิดหน้าต่างจำลองวันเวลาสำหรับตรวจสอบ UI คาบเรียน',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: ScheduleManager.isTimeTravelEnabled,
                      activeTrackColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() {
                          ScheduleManager.isTimeTravelEnabled = value;
                          if (value) {
                            final now = DateTime.now();
                            int weekdayIdx = now.weekday - 1;
                            if (weekdayIdx < 0 || weekdayIdx > 4) weekdayIdx = 0; // Mon-Fri clamp
                            ScheduleManager.setMockTime(weekdayIdx, now.hour, now.minute);
                          }
                          int todayIndex = _getTodayWeekdayIndex();
                          _selectedDayIndex = todayIndex == -1 ? 0 : todayIndex;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // Leave space for FloatingNavBar
        ],
      ),
    );
  }

  Widget _buildSettingsSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsMenuItem(
    IconData icon,
    String title, {
    bool isLast = false,
    Color? color,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color ?? AppColors.textMedium, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color ?? AppColors.textDark,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 50, endIndent: 16),
      ],
    );
  }

  void _updateMockTime(int weekdayIdx, int hour, int minute) {
    setState(() {
      ScheduleManager.setMockTime(weekdayIdx, hour, minute);
      int todayIndex = _getTodayWeekdayIndex();
      _selectedDayIndex = todayIndex == -1 ? 0 : todayIndex;
    });
  }

  Widget _buildTimeTravelSimulatorOverlay() {
    final size = MediaQuery.of(context).size;
    const cardWidth = 310.0;
    const cardHeight = 310.0;
    
    if (_overlayX == null || _overlayY == null) {
      _overlayX = size.width - cardWidth - 16;
      _overlayY = 100.0;
    }
    
    // Clamp to ensure it doesn't go off-screen
    _overlayX = _overlayX!.clamp(0.0, (size.width - cardWidth).clamp(0.0, size.width));
    _overlayY = _overlayY!.clamp(0.0, (size.height - cardHeight).clamp(0.0, size.height));
    
    final systemTime = ScheduleManager.getSystemTime();
    final hour = systemTime.hour;
    final minute = systemTime.minute;
    final weekdayIdx = systemTime.weekday - 1; // 0 = Mon, ..., 6 = Sun
    
    // Clamp weekdayIdx to 0-4 for Mon-Fri simulation
    final activeWeekdayIdx = weekdayIdx >= 0 && weekdayIdx <= 4 ? weekdayIdx : 0;

    return Positioned(
      left: _overlayX,
      top: _overlayY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _overlayX = (_overlayX! + details.delta.dx).clamp(0.0, (size.width - cardWidth).clamp(0.0, size.width));
            _overlayY = (_overlayY! + details.delta.dy).clamp(0.0, (size.height - cardHeight).clamp(0.0, size.height));
          });
        },
        child: Container(
          width: cardWidth,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: SmoothRectangleBorder(
              borderRadius: squircleRadius(16),
              side: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Bar
                  Row(
                    children: [
                      const Icon(Icons.bolt, color: AppColors.orange, size: 20),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'จำลองเวลา (Time Travel)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            ScheduleManager.isTimeTravelEnabled = false;
                            int todayIndex = _getTodayWeekdayIndex();
                            _selectedDayIndex = todayIndex == -1 ? 0 : todayIndex;
                          });
                        },
                        child: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const Divider(height: 12, color: AppColors.border),
                  
                  // Day Selector chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'วันจำลอง:',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      ),
                      Text(
                        activeWeekdayIdx == 0 ? 'วันจันทร์' :
                        activeWeekdayIdx == 1 ? 'วันอังคาร' :
                        activeWeekdayIdx == 2 ? 'วันพุธ' :
                        activeWeekdayIdx == 3 ? 'วันพฤหัสบดี' : 'วันศุกร์',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final days = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.'];
                      final isSelected = activeWeekdayIdx == index;
                      return GestureDetector(
                        onTap: () {
                          _updateMockTime(index, hour, minute);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: ShapeDecoration(
                            color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                            shape: SmoothRectangleBorder(borderRadius: squircleRadius(8)),
                          ),
                          child: Text(
                            days[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textMedium,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  
                  // Hour Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ชั่วโมง:',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      ),
                      Text(
                        '${hour.toString().padLeft(2, '0')} น.',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: hour.toDouble(),
                      min: 0,
                      max: 23,
                      divisions: 23,
                      activeColor: AppColors.primary,
                      inactiveColor: const Color(0xFFE2E8F0),
                      onChanged: (val) {
                        _updateMockTime(activeWeekdayIdx, val.round(), minute);
                      },
                    ),
                  ),
                  
                  // Minute Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'นาที:',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      ),
                      Text(
                        '${minute.toString().padLeft(2, '0')} นาที',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: minute.toDouble(),
                      min: 0,
                      max: 59,
                      divisions: 59,
                      activeColor: AppColors.primary,
                      inactiveColor: const Color(0xFFE2E8F0),
                      onChanged: (val) {
                        _updateMockTime(activeWeekdayIdx, hour, val.round());
                      },
                    ),
                  ),
                  
                  const Divider(height: 12, color: AppColors.border),
                  
                  // Presets
                  const Text(
                    'ทางลัดคาบเรียน:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPresetChip('08:30 คาบ 1', () => _updateMockTime(activeWeekdayIdx, 8, 30)),
                        const SizedBox(width: 6),
                        _buildPresetChip('12:10 เที่ยง', () => _updateMockTime(activeWeekdayIdx, 12, 10)),
                        const SizedBox(width: 6),
                        _buildPresetChip('15:30 เลิกเรียน', () => _updateMockTime(activeWeekdayIdx, 15, 30)),
                        const SizedBox(width: 6),
                        _buildPresetChip('17:00 เย็น', () => _updateMockTime(activeWeekdayIdx, 17, 0)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: ShapeDecoration(
          color: const Color(0xFFF1F5F9),
          shape: SmoothRectangleBorder(
            borderRadius: squircleRadius(6),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMedium),
        ),
      ),
    );
  }

  Future<void> _navigateToImport(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImportScreen()),
    );
    if (result == true) {
      _loadSchedule();
    }
  }

  bool get _isScheduleEmpty =>
      _weeklySchedule.isEmpty ||
      _weeklySchedule.values.every((list) => list.isEmpty);

  Widget _buildEmptySchedulePlaceholder() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: ShapeDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: SmoothRectangleBorder(borderRadius: squircleRadius(28)),
              ),
              child: const Icon(
                Icons.calendar_view_week_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'ยังไม่มีตารางเรียนในระบบ 📅',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'อัปโหลดภาพตารางเรียนของคุณให้ระบบ AI แปลงข้อมูลรายวิชา ห้องเรียน และเวลาเรียนแบบอัตโนมัติในไม่กี่วินาที',
              style: TextStyle(
                fontSize: 14.5,
                color: AppColors.textLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToImport(context),
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Colors.white,
                ),
                label: const Text(
                  'นำเข้าตารางเรียนด้วย AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _populateMockSchedule,
              child: const Text(
                'หรือสร้างตารางเรียนทดสอบ (Mock Data) 🪄',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _populateMockSchedule() async {
    setState(() {
      _isLoading = true;
    });
    final Map<int, List<ClassItem>> mockWeek = {};
    for (int i = 0; i < 5; i++) {
      mockWeek[i] = getScheduleForDay(i);
    }
    await ScheduleManager.saveWeeklySchedule(mockWeek);
    await _loadSchedule();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สร้างตารางเรียนจำลองสำเร็จ!')),
      );
    }
  }

  Future<void> _clearSchedule() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ล้างข้อมูลตารางเรียน'),
        content: const Text(
          'คุณต้องการลบข้อมูลตารางเรียนทั้งหมดใช่หรือไม่? ข้อมูลจะไม่สามารถกู้คืนได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบข้อมูล'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ScheduleManager.clearCustomSchedule();
      await _loadSchedule();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ล้างข้อมูลตารางเรียนแล้ว')),
        );
      }
    }
  }

  // Choose content body based on FloatingNavBar index
  Widget _buildBody() {
    if (_isScheduleEmpty && (_currentTabIndex == 0 || _currentTabIndex == 1)) {
      return _buildEmptySchedulePlaceholder();
    }

    switch (_currentTabIndex) {
      case 0:
        return Column(
          children: [
            // Header Section
            ScheduleHeader(dateText: getDateHeader(_selectedDayIndex)),
            Expanded(child: _buildClassListForDay(_selectedDayIndex)),
          ],
        );
      case 1:
        return WeeklyScreen(key: ValueKey(ScheduleManager.getSystemTime().weekday));
      case 2:
        return _buildAlertsPlaceholder();
      case 3:
        return _buildSettingsView();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const AppTitleBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    reverseDuration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          final childKey = child.key as ValueKey<int>?;
                          final isIncoming =
                              childKey?.value == _currentTabIndex;
                          final direction =
                              _currentTabIndex >= _previousTabIndex
                              ? 1.0
                              : -1.0;
                          final beginOffset = isIncoming
                              ? Offset(0.08 * direction, 0)
                              : Offset(-0.04 * direction, 0);

                          final slideAnimation = Tween<Offset>(
                            begin: beginOffset,
                            end: Offset.zero,
                          ).animate(animation);

                          final scaleAnimation = Tween<double>(
                            begin: isIncoming ? 0.985 : 1.0,
                            end: 1.0,
                          ).animate(animation);

                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: slideAnimation,
                              child: ScaleTransition(
                                scale: scaleAnimation,
                                child: child,
                              ),
                            ),
                          );
                        },
                    child: KeyedSubtree(
                      key: ValueKey(_currentTabIndex),
                      child: _buildBody(),
                    ),
                  ),
                ),
              ],
            ),
            // White Linear Gradient Layer fading upwards from 80% opacity
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 115,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingNavBar(
                currentIndex: _currentTabIndex,
                onTabChanged: (index) {
                  if (index == _currentTabIndex) return;
                  setState(() {
                    _previousTabIndex = _currentTabIndex;
                    _currentTabIndex = index;
                  });
                  if (index == 0 || index == 1) {
                    _loadSchedule();
                  }
                },
              ),
            ),
            // Time Travel Simulator Floating Overlay
            if (ScheduleManager.isTimeTravelEnabled)
              _buildTimeTravelSimulatorOverlay(),
          ],
        ),
      ),
    );
  }
}
