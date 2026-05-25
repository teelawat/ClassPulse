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

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type.name,
        'deadline': deadline,
      };

  factory ClassTask.fromJson(Map<String, dynamic> json) => ClassTask(
        title: json['title'] as String,
        type: TaskType.values.byName(json['type'] as String),
        deadline: json['deadline'] as String?,
      );
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

  /// Icon identifier (e.g. 'science', 'math', 'thai', etc.)
  final String? iconName;

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
    this.iconName,
    this.tasks = const [],
  });

  ClassItem copyWith({
    String? startTime,
    String? endTime,
    String? subject,
    String? teacher,
    ClassType? type,
    Color? themeColor,
    Color? cardColor,
    Color? textColor,
    String? iconName,
    List<ClassTask>? tasks,
  }) {
    return ClassItem(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subject: subject ?? this.subject,
      teacher: teacher ?? this.teacher,
      type: type ?? this.type,
      themeColor: themeColor ?? this.themeColor,
      cardColor: cardColor ?? this.cardColor,
      textColor: textColor ?? this.textColor,
      iconName: iconName ?? this.iconName,
      tasks: tasks ?? this.tasks,
    );
  }

  // ─── JSON Serialization ──────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'startTime': startTime,
        'endTime': endTime,
        'subject': subject,
        'teacher': teacher,
        'type': type.name,
        'themeColor': themeColor?.toARGB32(),
        'cardColor': cardColor?.toARGB32(),
        'textColor': textColor?.toARGB32(),
        'iconName': iconName,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  factory ClassItem.fromJson(Map<String, dynamic> json) {
    return ClassItem(
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      subject: json['subject'] as String,
      teacher: json['teacher'] as String,
      type: ClassType.values.byName(json['type'] as String),
      themeColor: json['themeColor'] != null ? Color(json['themeColor'] as int) : null,
      cardColor: json['cardColor'] != null ? Color(json['cardColor'] as int) : null,
      textColor: json['textColor'] != null ? Color(json['textColor'] as int) : null,
      iconName: json['iconName'] as String?,
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((t) => ClassTask.fromJson(t as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  // ─── Convenience factories ───────────────────────────────────────────────

  factory ClassItem.past({
    required String startTime,
    required String endTime,
    required String subject,
    required String teacher,
    String? iconName,
    List<ClassTask> tasks = const [],
  }) =>
      ClassItem(
        startTime: startTime,
        endTime: endTime,
        subject: subject,
        teacher: teacher,
        type: ClassType.past,
        iconName: iconName,
        tasks: tasks,
      );

  factory ClassItem.current({
    required String subject,
    required String teacher,
    String startTime = '09:20',
    String endTime = '10:10',
    String? iconName,
    List<ClassTask> tasks = const [],
  }) =>
      ClassItem(
        startTime: startTime,
        endTime: endTime,
        subject: subject,
        teacher: teacher,
        type: ClassType.current,
        iconName: iconName,
        tasks: tasks,
      );

  factory ClassItem.next({
    required String startTime,
    required String endTime,
    required String subject,
    required String teacher,
    String? iconName,
    List<ClassTask> tasks = const [],
  }) =>
      ClassItem(
        startTime: startTime,
        endTime: endTime,
        subject: subject,
        teacher: teacher,
        type: ClassType.next,
        iconName: iconName,
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
    String? iconName,
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
        iconName: iconName,
        tasks: tasks,
      );
}
