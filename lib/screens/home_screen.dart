import 'dart:async';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import '../data/schedule_data.dart';
import '../models/class_item.dart';
import '../theme/app_theme.dart';
import '../widgets/class_cards/current_card.dart';
import '../widgets/class_cards/next_card.dart';
import '../widgets/class_cards/normal_card.dart';
import '../widgets/class_cards/past_card.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/schedule_header.dart';
import '../widgets/title_bar.dart';
import '../widgets/weekday_tabs.dart';
import 'weekly_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDayIndex = 0; // 0 = จ., 1 = อ., etc.
  int _currentTabIndex = 0;  // 0 = Today, 1 = Weekly Schedule, etc.
  late PageController _pageController;

  // State for dynamic countdown timer of the current active class
  int _remainingSeconds = 1200; // 20 minutes
  Timer? _countdownTimer;

  int _getTodayWeekdayIndex() {
    int w = DateTime.now().weekday; // 1 = Monday, ..., 7 = Sunday
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
    _pageController = PageController(initialPage: _selectedDayIndex);
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _remainingSeconds = 1200; // Reset just for demo persistence
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Waving Hand icon wrapper (fallback / context dependent)
  Widget _buildThaiLetterIcon() {
    return const Padding(
      padding: EdgeInsets.only(right: 6.0),
      child: Text(
        'ญ',
        style: TextStyle(
          color: Color(0x3BFFFFFF),
          fontSize: 38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Click handler to show class details beautifully
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

  Widget _buildClassCard(ClassItem item) {
    switch (item.type) {
      case ClassType.past:
        return PastCard(
          item: item,
          onTap: () => _showClassDetail(item),
        );
      case ClassType.current:
        return CurrentCard(
          item: item,
          remainingSeconds: _remainingSeconds,
          onTap: () => _showClassDetail(item),
        );
      case ClassType.next:
        return NextCard(
          item: item,
          onTap: () => _showClassDetail(item),
        );
      case ClassType.normal:
        final icon = item.themeColor == AppColors.purple
            ? const Icon(Icons.account_balance, color: Colors.white, size: 32)
            : _buildThaiLetterIcon();
        return NormalCard(
          item: item,
          icon: icon,
          onTap: () => _showClassDetail(item),
        );
    }
  }

  Widget _buildClassListForDay(int dayIndex) {
    final List<ClassItem> schedule = getScheduleForDay(dayIndex);

    return ListView.separated(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 104),
      itemCount: schedule.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _buildClassCard(schedule[index]),
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
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Squircle Avatar
            Container(
              width: 90,
              height: 90,
              decoration: ShapeDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: SmoothRectangleBorder(borderRadius: squircleRadius(24)),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ธีรภัทร (เต้)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ชั้นมัธยมศึกษาปีที่ 5/1 • เลขที่ 12',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 24),
            // Mock Menu Items
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
                  _buildProfileMenuItem(Icons.settings_outlined, 'ตั้งค่าการใช้งาน'),
                  _buildProfileMenuItem(Icons.help_outline, 'ศูนย์ช่วยเหลือ'),
                  _buildProfileMenuItem(Icons.logout, 'ออกจากระบบ', isLast: true, color: Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(IconData icon, String title, {bool isLast = false, Color? color}) {
    return Column(
      children: [
        Padding(
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
        if (!isLast)
          const Divider(height: 1, indent: 50, endIndent: 16),
      ],
    );
  }

  // Choose content body based on FloatingNavBar index
  Widget _buildBody() {
    switch (_currentTabIndex) {
      case 0:
        return Column(
          children: [
            // Header Section
            ScheduleHeader(dateText: getDateHeader(_selectedDayIndex)),
            
            // Weekday Selector Tabs
            WeekdayTabs(
              selectedIndex: _selectedDayIndex,
              todayIndex: _getTodayWeekdayIndex(),
              pageController: _pageController,
            ),

            // Swipeable Class List via PageView
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
                itemBuilder: (context, index) => _buildClassListForDay(index),
              ),
            ),
          ],
        );
      case 1:
        return const WeeklyScreen();
      case 2:
        return _buildAlertsPlaceholder();
      case 3:
        return _buildProfilePlaceholder();
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
                    duration: const Duration(milliseconds: 150),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
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
                  setState(() {
                    _currentTabIndex = index;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
