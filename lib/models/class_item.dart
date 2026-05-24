import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Type of task linked to a class.
enum TaskType { homework, quiz }

/// A task/homework/quiz associated with a class period.
class ClassTask {
  final String title;
  final TaskType type;
  final String? deadline;

  const ClassTask({
    required this.title,
    required this.type,
    this.deadline,
  });
}

/// Enum representing the type/style of a class card.
enum ClassType { past, current, next, normal }

/// A single class period in the schedule.
class ClassItem {
  final String startTime;
  final String endTime;
  final String subject;
  final String teacher;
  final ClassType type;

  /// Theme / border color used for [ClassType.normal] cards.
  final Color? themeColor;

  /// Fill color of the right panel for [ClassType.normal] cards.
  final Color? cardColor;

  /// Text color for [ClassType.normal] cards.
  final Color? textColor;

  /// Tasks or homework associated with this class.
  final List<ClassTask> tasks;

  const ClassItem({
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
    required this.type,
    this.themeColor,
    this.cardColor,
    this.textColor,
    this.tasks = const [],
  });

  // ─── Convenience factories ───────────────────────────────────────────────

  factory ClassItem.past({
    required String startTime,
    required String endTime,
    required String subject,
    required String teacher,
    List<ClassTask> tasks = const [],
  }) =>
      ClassItem(
        startTime: startTime,
        endTime: endTime,
        subject: subject,
        teacher: teacher,
        type: ClassType.past,
        tasks: tasks,
      );

  factory ClassItem.current({
    required String subject,
    required String teacher,
    String startTime = '09:20',
    String endTime = '10:10',
    List<ClassTask> tasks = const [],
  }) =>
      ClassItem(
        startTime: startTime,
        endTime: endTime,
        subject: subject,
        teacher: teacher,
        type: ClassType.current,
        tasks: tasks,
      );

  factory ClassItem.next({
    required String startTime,
    required String endTime,
    required String subject,
    required String teacher,
    List<ClassTask> tasks = const [],
  }) =>
      ClassItem(
        startTime: startTime,
        endTime: endTime,
        subject: subject,
        teacher: teacher,
        type: ClassType.next,
        tasks: tasks,
      );

  factory ClassItem.normal({
    required String startTime,
    required String endTime,
    required String subject,
    required String teacher,
    Color themeColor = AppColors.blue,
    Color cardColor = AppColors.blue,
    Color textColor = Colors.white,
    List<ClassTask> tasks = const [],
  }) =>
      ClassItem(
        startTime: startTime,
        endTime: endTime,
        subject: subject,
        teacher: teacher,
        type: ClassType.normal,
        themeColor: themeColor,
        cardColor: cardColor,
        textColor: textColor,
        tasks: tasks,
      );
}
