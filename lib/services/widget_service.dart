import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/class_item.dart';
import '../data/schedule_manager.dart';

class WidgetService {
  /// Compiles schedule state and updates Android Home Screen Widgets.
  static Future<void> updateWidgets(Map<int, List<ClassItem>> schedule) async {
    // Only support Android platform for widgets
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final now = ScheduleManager.getSystemTime();
      final dayIndex = now.weekday - 1; // 0 = Mon, ..., 4 = Fri, 5 = Sat, 6 = Sun

      // Thai day names mapper
      final dayNames = [
        "วันจันทร์",
        "วันอังคาร",
        "วันพุธ",
        "วันพฤหัสบดี",
        "วันศุกร์",
        "วันเสาร์",
        "วันอาทิตย์"
      ];
      final dayTitle = "ตารางเรียน${now.weekday >= 1 && now.weekday <= 7 ? dayNames[now.weekday - 1] : "วันนี้"}";

      final todayRawClasses = (dayIndex >= 0 && dayIndex < 5) ? (schedule[dayIndex] ?? []) : <ClassItem>[];
      final todayClasses = ScheduleManager.getDynamicSchedule(todayRawClasses, dayIndex);

      // ─── Update Current Class Widget ───
      String currentSubject = "ไม่มีคาบเรียนขณะนี้";
      String currentTeacher = "พักผ่อนตามอัธยาศัย 🎉";
      String currentTime = "-";
      String currentStatus = "วันหยุดสุดสัปดาห์";

      if (dayIndex >= 0 && dayIndex < 5) {
        if (todayClasses.isEmpty) {
          currentSubject = "ไม่มีเรียนในวันนี้";
          currentTeacher = "พักผ่อนตามอัธยาศัย 🎉";
          currentStatus = "ไม่มีตารางเรียน";
        } else {
          // Check for active current class
          ClassItem? current;
          for (final item in todayClasses) {
            if (item.type == ClassType.current) {
              current = item;
              break;
            }
          }

          if (current != null) {
            currentSubject = current.subject;
            currentTeacher = current.teacher.isNotEmpty ? "ครูผู้สอน: ${current.teacher}" : "-";
            currentTime = "${current.startTime} - ${current.endTime} น.";
            
            // Calculate remaining minutes
            final parts = current.endTime.split(':');
            if (parts.length == 2) {
              final hour = int.tryParse(parts[0]) ?? 0;
              final min = int.tryParse(parts[1]) ?? 0;
              final classEnd = DateTime(now.year, now.month, now.day, hour, min);
              final diffMins = classEnd.difference(now).inMinutes;
              if (diffMins > 0) {
                currentStatus = "กำลังเรียนอยู่ • เหลืออีก $diffMins นาที";
              } else {
                currentStatus = "กำลังเรียนอยู่";
              }
            } else {
              currentStatus = "กำลังเรียนอยู่";
            }
          } else {
            // Check for next upcoming class
            ClassItem? nextItem;
            for (final item in todayClasses) {
              if (item.type == ClassType.next) {
                nextItem = item;
                break;
              }
            }

            if (nextItem != null) {
              currentSubject = "ถัดไป: ${nextItem.subject}";
              currentTeacher = nextItem.teacher.isNotEmpty ? "ครูผู้สอน: ${nextItem.teacher}" : "-";
              currentTime = "${nextItem.startTime} - ${nextItem.endTime} น.";

              // Calculate minutes until start
              final parts = nextItem.startTime.split(':');
              if (parts.length == 2) {
                final hour = int.tryParse(parts[0]) ?? 0;
                final min = int.tryParse(parts[1]) ?? 0;
                final classStart = DateTime(now.year, now.month, now.day, hour, min);
                final diffMins = classStart.difference(now).inMinutes;
                if (diffMins > 0) {
                  currentStatus = "จะเริ่มในอีก $diffMins นาที";
                } else {
                  currentStatus = "คาบถัดไป";
                }
              } else {
                currentStatus = "คาบถัดไป";
              }
            } else {
              // No current and no next class, but it is a weekday: did all classes end?
              final hasClasses = todayClasses.isNotEmpty;
              if (hasClasses) {
                currentSubject = "ไม่มีเรียนแล้ววันนี้";
                currentTeacher = "กลับบ้านปลอดภัยครับ 🚌";
                currentTime = "-";
                currentStatus = "เสร็จสิ้นทุกคาบ";
              } else {
                currentSubject = "ไม่มีเรียนในวันนี้";
                currentTeacher = "พักผ่อนตามอัธยาศัย 🎉";
                currentStatus = "ไม่มีตารางเรียน";
              }
            }
          }
        }
      }

      await HomeWidget.saveWidgetData('current_subject', currentSubject);
      await HomeWidget.saveWidgetData('current_teacher', currentTeacher);
      await HomeWidget.saveWidgetData('current_time', currentTime);
      await HomeWidget.saveWidgetData('current_status', currentStatus);

      // ─── Update Today's Schedule Widget (List style) ───
      // Filter out past classes, show only current/next/upcoming
      final activeClasses = todayClasses.where((c) => c.type != ClassType.past).toList();
      final slotsCount = activeClasses.length > 3 ? 3 : activeClasses.length;

      await HomeWidget.saveWidgetData('today_day_title', dayTitle);
      await HomeWidget.saveWidgetData('today_slots_count', slotsCount);

      for (int i = 0; i < slotsCount; i++) {
        final item = activeClasses[i];
        final index = i + 1;

        await HomeWidget.saveWidgetData('slot${index}_subject', item.subject);
        await HomeWidget.saveWidgetData('slot${index}_time', "${item.startTime} - ${item.endTime} น.");

        // Calculate badge status
        String badge = "ปกติ";
        if (item.type == ClassType.current) {
          badge = "เรียนอยู่";
        } else if (item.type == ClassType.next) {
          badge = "ถัดไป";
        } else if (item.isBreak) {
          badge = "พักเบรก";
        } else if (item.periodNumber != null) {
          badge = "คาบที่ ${item.periodNumber}";
        } else {
          badge = "รอเรียน";
        }

        await HomeWidget.saveWidgetData('slot${index}_badge', badge);
      }

      // ─── Trigger Widget Redraw ───
      await HomeWidget.updateWidget(
        name: 'CurrentClassWidgetProvider',
        androidName: 'CurrentClassWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'TodayScheduleWidgetProvider',
        androidName: 'TodayScheduleWidgetProvider',
      );

      debugPrint("Android widgets updated successfully. time travel=${ScheduleManager.isTimeTravelEnabled}");
    } catch (e) {
      debugPrint("Error updating Android home widgets: $e");
    }
  }
}
