import '../models/class_item.dart';
import '../theme/app_theme.dart';

// ─── Static subject / teacher / room pools for mock data ──────────────────

const _subjects = [
  'คณิตศาสตร์', 'วิทยาศาสตร์', 'ศิลปะ', 'คอมพิวเตอร์',
  'พละศึกษา', 'แนะแนว', 'ชีววิทยา', 'เคมี',
];

const _teachers = [
  'ครูสมศรี', 'ครูณรงค์', 'ครูวิภา', 'ครูสุพจน์',
  'ครูสมจิต', 'ครูรัตนา', 'ครูสุรพล', 'ครูชลธิชา',
];

const _rooms = [
  'ห้อง 102', 'ห้องปฏิบัติการ 1', 'ห้องศิลปะ', 'ห้องคอม 2',
  'โรงยิม', 'ห้องแนะแนว', 'ห้อง 403', 'ห้องปฏิบัติการ 3',
];

String _s(int i) => _subjects[i % _subjects.length];
String _t(int i) => _teachers[i % _teachers.length];
String _r(int i) => _rooms[i % _rooms.length];

// ─── Date header strings per weekday ──────────────────────────────────────

/// Returns the Thai date-header text for a given weekday index (0 = Mon … 4 = Fri).
String getDateHeader(int index) {
  const headers = [
    'วันจันทร์ที่ 25 พฤษภาคม | ตารางเรียนของฉัน',
    'วันอังคารที่ 26 พฤษภาคม | ตารางเรียนของฉัน',
    'วันพุธที่ 27 พฤษภาคม | ตารางเรียนของฉัน',
    'วันพฤหัสบดีที่ 28 พฤษภาคม | ตารางเรียนของฉัน',
    'วันศุกร์ที่ 29 พฤษภาคม | ตารางเรียนของฉัน',
  ];
  return headers[index.clamp(0, headers.length - 1)];
}

// ─── Monday schedule (exact, matches the design reference) ────────────────

final _mondaySchedule = [
  ClassItem.past(
    startTime: '08:30',
    endTime: '09:20',
    subject: 'โฮมรูม (ห้อง 201)',
    teacher: 'ครูวรรณา',
    periodNumber: null,
  ),
  ClassItem.current(
    subject: 'ฟิสิกส์ (ห้องปฏิบัติการ 2)',
    teacher: 'ครูอ้อย',
    periodNumber: 1,
    tasks: const [
      ClassTask(title: 'ส่ง Lab Report คานดีด', type: TaskType.homework),
    ],
  ),
  ClassItem.next(
    startTime: '10:10',
    endTime: '11:00',
    subject: 'ภาษาอังกฤษ (ห้อง 312)',
    teacher: 'ครูสุนีย์',
    periodNumber: 2,
    tasks: const [
      ClassTask(title: 'สอบย่อยคำศัพท์ Unit 5', type: TaskType.quiz),
    ],
  ),
  ClassItem.normal(
    startTime: '11:00',
    endTime: '11:50',
    subject: 'ภาษาไทย (ห้อง 223)',
    teacher: 'ครูวิชัย',
    themeColor: AppColors.blue,
    cardColor: AppColors.blue,
    periodNumber: 3,
  ),
  ClassItem(
    startTime: '11:50',
    endTime: '12:40',
    subject: 'พักกลางวัน',
    teacher: '',
    type: ClassType.normal,
    isBreak: true,
  ),
  ClassItem.normal(
    startTime: '12:40',
    endTime: '13:30',
    subject: 'ประวัติศาสตร์ (ห้อง 301)',
    teacher: 'ครูสมชาย',
    themeColor: AppColors.purple,
    cardColor: AppColors.purple,
    periodNumber: 4,
  ),
];

// ─── Public API ───────────────────────────────────────────────────────────

/// Returns the list of [ClassItem] for a given weekday [dayIndex] (0–4).
///
/// To add or edit a day's schedule, modify [_mondaySchedule] (day 0) or
/// add a new list for other days.  The fallback uses generated mock data.
List<ClassItem> getScheduleForDay(int dayIndex) {
  if (dayIndex == 0) return _mondaySchedule;
  return _buildMockSchedule(dayIndex);
}

// ─── Mock schedule builder for Tue–Fri ────────────────────────────────────

List<ClassItem> _buildMockSchedule(int dayIndex) {
  final o = dayIndex * 2; // subject offset per day

  List<ClassTask> currentClassTasks = const [];
  List<ClassTask> normalClass1Tasks = const [];

  if (dayIndex == 1) { // Tuesday
    normalClass1Tasks = const [
      ClassTask(title: 'ส่งการบ้านบทที่ 2', type: TaskType.homework),
    ];
  } else if (dayIndex == 3) { // Thursday
    currentClassTasks = const [
      ClassTask(title: 'สอบเก็บคะแนนท้ายบท', type: TaskType.quiz),
    ];
  }

  return [
    ClassItem.past(
      startTime: '08:30',
      endTime: '09:20',
      subject: 'โฮมรูม (ห้อง 201)',
      teacher: 'ครูวรรณา',
      periodNumber: null,
    ),
    ClassItem.current(
      subject: '${_s(o)} (${_r(o)})',
      teacher: _t(o),
      periodNumber: 1,
      tasks: currentClassTasks,
    ),
    ClassItem.next(
      startTime: '10:10',
      endTime: '11:00',
      subject: '${_s(o + 1)} (${_r(o + 1)})',
      teacher: _t(o + 1),
      periodNumber: 2,
    ),
    ClassItem.normal(
      startTime: '11:00',
      endTime: '11:50',
      subject: '${_s(o + 2)} (${_r(o + 2)})',
      teacher: _t(o + 2),
      themeColor: AppColors.blue,
      cardColor: AppColors.blue,
      periodNumber: 3,
      tasks: normalClass1Tasks,
    ),
    ClassItem(
      startTime: '11:50',
      endTime: '12:40',
      subject: 'พักกลางวัน',
      teacher: '',
      type: ClassType.normal,
      isBreak: true,
    ),
    ClassItem.normal(
      startTime: '12:40',
      endTime: '13:30',
      subject: '${_s(o + 3)} (${_r(o + 3)})',
      teacher: _t(o + 3),
      themeColor: AppColors.purple,
      cardColor: AppColors.purple,
      periodNumber: 4,
    ),
  ];
}
