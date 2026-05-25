import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/class_item.dart';
import '../theme/app_theme.dart';
import 'app_storage.dart';
import 'schedule_data.dart' as default_data;

class SubjectTheme {
  final Color themeColor;
  final Color cardColor;
  final Color textColor;
  final String iconName;

  const SubjectTheme({
    required this.themeColor,
    required this.cardColor,
    required this.textColor,
    required this.iconName,
  });
}

class ScheduleManager {
  static const String _scheduleKey = 'custom_weekly_schedule';
  static const String _apiKeyKey = 'gemini_api_key';

  static bool isTimeTravelEnabled = false;
  static DateTime mockDateTime = DateTime.now();

  static DateTime getSystemTime() {
    if (isTimeTravelEnabled) {
      return mockDateTime;
    }
    return DateTime.now();
  }

  static void setMockTime(int weekdayIndex, int hour, int minute) {
    final now = DateTime.now();
    // Find the date of the current week that matches the selected weekdayIndex (0 = Mon, ..., 4 = Fri)
    final targetWeekday = weekdayIndex + 1;
    final difference = targetWeekday - now.weekday;
    final targetDate = now.add(Duration(days: difference));
    mockDateTime = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute, 0);
  }
  static const String manualTimetablePrompt = '''
You are an expert school timetable parser. Extract the weekly schedule from the provided image.
Map each class to its respective day of the week: monday, tuesday, wednesday, thursday, friday.
For each class, extract:
- startTime (HH:mm format, e.g. "08:30")
- endTime (HH:mm format, e.g. "09:20")
- subject (subject name, include room number in parentheses if visible, e.g. "ฟิสิกส์ (ห้องปฏิบัติการ 2)")
- teacher (teacher's name, e.g. "ครูอ้อย")

Format the output strictly as a JSON object matching this schema structure:
{
  "monday": [
    { "startTime": "08:30", "endTime": "09:20", "subject": "โฮมรูม (ห้อง 201)", "teacher": "ครูวรรณา" }
  ],
  "tuesday": [],
  "wednesday": [],
  "thursday": [],
  "friday": []
}

Output only the JSON. Do not include markdown code block wrappers (like ```json). Just the raw JSON string.
''';

  // ─── Detect colors and icons based on subject name ───────────────────────

  static SubjectTheme detectSubjectTheme(String subject) {
    final s = subject.toLowerCase();

    if (s.contains('ฟิสิกส์') ||
        s.contains('เคมี') ||
        s.contains('ชีว') ||
        s.contains('วิทย์') ||
        s.contains('science') ||
        s.contains('physics') ||
        s.contains('chemistry') ||
        s.contains('biology') ||
        s.contains('ดาราศาสตร์')) {
      return const SubjectTheme(
        themeColor: AppColors.green,
        cardColor: AppColors.greenBg,
        textColor: AppColors.greenDark,
        iconName: 'science',
      );
    }

    if (s.contains('คณิต') ||
        s.contains('เลข') ||
        s.contains('math') ||
        s.contains('algebra') ||
        s.contains('calculus') ||
        s.contains('ตรีโกณ')) {
      return const SubjectTheme(
        themeColor: AppColors.blue,
        cardColor: AppColors.blue,
        textColor: Colors.white,
        iconName: 'math',
      );
    }

    if (s.contains('อังกฤษ') ||
        s.contains('english') ||
        s.contains('ต่างประเทศ') ||
        s.contains('lang') ||
        s.contains('conversation')) {
      return const SubjectTheme(
        themeColor: AppColors.orange,
        cardColor: AppColors.orangeLight,
        textColor: AppColors.orangeText,
        iconName: 'english',
      );
    }

    if (s.contains('ไทย') || s.contains('thai') || s.contains('วรรณคดี')) {
      return const SubjectTheme(
        themeColor: AppColors.blue,
        cardColor: AppColors.blue,
        textColor: Colors.white,
        iconName: 'thai',
      );
    }

    if (s.contains('ประวัติ') ||
        s.contains('สังคม') ||
        s.contains('ภูมิศาสตร์') ||
        s.contains('หน้าที่พลเมือง') ||
        s.contains('history') ||
        s.contains('social') ||
        s.contains('civic')) {
      return const SubjectTheme(
        themeColor: AppColors.purple,
        cardColor: AppColors.purple,
        textColor: Colors.white,
        iconName: 'history',
      );
    }

    if (s.contains('คอม') ||
        s.contains('com') ||
        s.contains('ict') ||
        s.contains('tech') ||
        s.contains('code') ||
        s.contains('วิทยาการคำนวณ') ||
        s.contains('programming')) {
      return const SubjectTheme(
        themeColor: Color(0xFF64748B),
        cardColor: Color(0xFFF1F5F9),
        textColor: Color(0xFF334155),
        iconName: 'computer',
      );
    }

    if (s.contains('พละ') ||
        s.contains('สุข') ||
        s.contains('pe') ||
        s.contains('sport') ||
        s.contains('gym') ||
        s.contains('ยืดหยุ่น') ||
        s.contains('กรีฑา')) {
      return const SubjectTheme(
        themeColor: Color(0xFF0D9488),
        cardColor: Color(0xFFF0FDFA),
        textColor: Color(0xFF115E59),
        iconName: 'sports',
      );
    }

    if (s.contains('ศิลปะ') ||
        s.contains('วาด') ||
        s.contains('art') ||
        s.contains('music') ||
        s.contains('ดนตรี') ||
        s.contains('นาฏศิลป์')) {
      return const SubjectTheme(
        themeColor: Color(0xFFDB2777),
        cardColor: Color(0xFFFDF2F8),
        textColor: Color(0xFF9D174D),
        iconName: 'art',
      );
    }

    if (s.contains('โฮมรูม') ||
        s.contains('homeroom') ||
        s.contains('แนะแนว') ||
        s.contains('อบรม')) {
      return const SubjectTheme(
        themeColor: Colors.grey,
        cardColor: AppColors.surface,
        textColor: AppColors.textMuted,
        iconName: 'homeroom',
      );
    }

    return const SubjectTheme(
      themeColor: AppColors.primary,
      cardColor: AppColors.primary,
      textColor: Colors.white,
      iconName: 'default',
    );
  }

  // ─── API Key persistence ──────────────────────────────────────────────────

  static Future<String?> getApiKey() async {
    final savedKey = await AppStorage.getString(_apiKeyKey);
    if (savedKey != null && savedKey.trim().isNotEmpty) {
      return savedKey.trim();
    }

    return _loadBundledApiKey();
  }

  static Future<void> saveApiKey(String key) async {
    await AppStorage.setString(_apiKeyKey, key);
  }

  static Future<String?> _loadBundledApiKey() async {
    try {
      final envText = await rootBundle.loadString('.env');
      for (final rawLine in const LineSplitter().convert(envText)) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) continue;

        final separatorIndex = line.indexOf('=');
        if (separatorIndex <= 0) continue;

        final key = line.substring(0, separatorIndex).trim();
        if (key != 'GEMINI_API_KEY') continue;

        final value = line.substring(separatorIndex + 1).trim();
        return value.isEmpty ? null : value;
      }
    } catch (e) {
      debugPrint('No bundled .env API key found: $e');
    }
    return null;
  }

  // ─── Load & Save Weekly Schedule ──────────────────────────────────────────

  static Future<Map<int, List<ClassItem>>> loadWeeklySchedule() async {
    final jsonStr = await AppStorage.getString(_scheduleKey);

    if (jsonStr == null) {
      // Return empty map to trigger the empty state upload layout
      return {};
    }

    try {
      final Map<String, dynamic> rawMap =
          json.decode(jsonStr) as Map<String, dynamic>;
      final Map<int, List<ClassItem>> weeklySchedule = {};

      rawMap.forEach((key, value) {
        final dayIndex = int.tryParse(key);
        if (dayIndex != null) {
          final list = (value as List<dynamic>)
              .map((item) => ClassItem.fromJson(item as Map<String, dynamic>))
              .toList();
          weeklySchedule[dayIndex] = list;
        }
      });

      return weeklySchedule;
    } catch (e) {
      debugPrint('Error parsing saved weekly schedule: $e');
      // If error, fall back to defaults
      final Map<int, List<ClassItem>> defaultWeek = {};
      for (int i = 0; i < 5; i++) {
        defaultWeek[i] = default_data.getScheduleForDay(i);
      }
      return defaultWeek;
    }
  }

  static Future<void> saveWeeklySchedule(
    Map<int, List<ClassItem>> schedule,
  ) async {
    final Map<String, dynamic> rawMap = {};
    schedule.forEach((key, value) {
      rawMap[key.toString()] = value.map((item) => item.toJson()).toList();
    });
    final jsonStr = json.encode(rawMap);
    await AppStorage.setString(_scheduleKey, jsonStr);
  }

  static Future<void> clearCustomSchedule() async {
    await AppStorage.remove(_scheduleKey);
  }

  static List<ClassItem> getDynamicSchedule(List<ClassItem> items, int dayIndex) {
    final now = getSystemTime();
    final currentWeekdayIndex = now.weekday - 1; // 0 = Mon, ..., 4 = Fri
    
    // If it is not today, all classes for this day are considered 'normal'
    if (currentWeekdayIndex != dayIndex || currentWeekdayIndex < 0 || currentWeekdayIndex > 4) {
      return items.map((item) => item.copyWith(type: ClassType.normal)).toList();
    }

    DateTime parseTime(String timeStr) {
      final parts = timeStr.split(':');
      if (parts.length != 2) return now;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    // First, map everyone to past, current, or normal
    final updatedItems = items.map((item) {
      final classStart = parseTime(item.startTime);
      final classEnd = parseTime(item.endTime);

      ClassType computedType = ClassType.normal;
      if (now.isAfter(classEnd)) {
        computedType = ClassType.past;
      } else if ((now.isAfter(classStart) || now.isAtSameMomentAs(classStart)) &&
                 (now.isBefore(classEnd) || now.isAtSameMomentAs(classEnd))) {
        computedType = ClassType.current;
      }

      return item.copyWith(type: computedType);
    }).toList();

    // Find the 'next' class
    // It is the first class of the day that hasn't started yet (i.e. currently 'normal' and start time is in the future)
    int? nextClassIndex;
    DateTime? earliestFutureStart;

    for (int i = 0; i < updatedItems.length; i++) {
      final item = updatedItems[i];
      final classStart = parseTime(item.startTime);

      if (now.isBefore(classStart) && updatedItems[i].type == ClassType.normal) {
        if (earliestFutureStart == null || classStart.isBefore(earliestFutureStart)) {
          earliestFutureStart = classStart;
          nextClassIndex = i;
        }
      }
    }

    if (nextClassIndex != null) {
      updatedItems[nextClassIndex] = updatedItems[nextClassIndex].copyWith(type: ClassType.next);
    }

    return updatedItems;
  }

  static Map<int, List<ClassItem>> parseTimetableJson(String rawText) {
    final cleanedText = _extractJsonObject(rawText);
    final parsedJson = json.decode(cleanedText) as Map<String, dynamic>;
    final Map<int, List<ClassItem>> parsedWeek = {};
    final daysOfWeek = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];

    for (int dayIndex = 0; dayIndex < daysOfWeek.length; dayIndex++) {
      final dayName = daysOfWeek[dayIndex];
      final dayList = parsedJson[dayName] as List<dynamic>? ?? [];
      final List<ClassItem> classItems = [];

      for (int i = 0; i < dayList.length; i++) {
        final rawClass = dayList[i] as Map<String, dynamic>;
        final startTime = rawClass['startTime'] as String? ?? '08:30';
        final endTime = rawClass['endTime'] as String? ?? '09:20';
        final subject = rawClass['subject'] as String? ?? 'วิชาเรียน';
        final teacher = rawClass['teacher'] as String? ?? 'ครูผู้สอน';

        final theme = detectSubjectTheme(subject);

        ClassType cardType = ClassType.normal;
        if (i == 0) {
          cardType = ClassType.past;
        } else if (i == 1) {
          cardType = ClassType.current;
        } else if (i == 2) {
          cardType = ClassType.next;
        }

        classItems.add(
          ClassItem(
            startTime: startTime,
            endTime: endTime,
            subject: subject,
            teacher: teacher,
            type: cardType,
            themeColor: theme.themeColor,
            cardColor: theme.cardColor,
            textColor: theme.textColor,
            iconName: theme.iconName,
          ),
        );
      }

      parsedWeek[dayIndex] = classItems;
    }

    for (int i = 0; i < 5; i++) {
      parsedWeek.putIfAbsent(i, () => []);
    }

    return parsedWeek;
  }

  static String _extractJsonObject(String rawText) {
    var text = rawText.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw const FormatException('ไม่พบ JSON ตารางเรียนในข้อความที่วาง');
    }

    return text.substring(start, end + 1);
  }

  static Future<List<String>> _getAvailableModels(String apiKey) async {
    final List<String> fallbackModels = [
      'gemini-2.0-flash',
      'gemini-2.0-flash-lite',
      'gemini-1.5-pro',
    ];
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final modelsList = data['models'] as List<dynamic>?;
        if (modelsList != null) {
          final List<String> apiModels = [];
          for (final m in modelsList) {
            final name = m['name'] as String? ?? '';
            final supportedMethods =
                m['supportedMethods'] as List<dynamic>? ?? [];
            final cleanName = name.replaceFirst('models/', '');
            if (supportedMethods.contains('generateContent')) {
              if (cleanName.contains('gemini-2.0') ||
                  cleanName.contains('gemini-1.5-pro') ||
                  cleanName.contains('gemini-2.5') ||
                  cleanName.contains('gemini-3.')) {
                apiModels.add(cleanName);
              }
            }
          }
          if (apiModels.isNotEmpty) {
            // Sort to prioritize gemini-2.0-flash first
            apiModels.sort((a, b) {
              if (a.contains('gemini-2.0-flash') &&
                  !b.contains('gemini-2.0-flash')) {
                return -1;
              }
              if (!a.contains('gemini-2.0-flash') &&
                  b.contains('gemini-2.0-flash')) {
                return 1;
              }
              return a.compareTo(b);
            });
            debugPrint('Dynamically resolved Gemini models: $apiModels');
            return apiModels;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch available Gemini models, using fallback: $e');
    }
    return fallbackModels;
  }

  // ─── Call Gemini Vision API to Parse Timetable ──────────────────────────

  static Future<Map<int, List<ClassItem>>> parseTimetableImage({
    required List<int> imageBytes,
    required String mimeType,
    required String apiKey,
  }) async {
    final base64Image = base64Encode(imageBytes);

    final List<String> models = await _getAvailableModels(apiKey);

    final List<String> errors = [];

    for (final model in models) {
      int retries = 0;
      const maxRetries = 2;
      while (retries <= maxRetries) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
          );

          final response = await http
              .post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'contents': [
                    {
                      'parts': [
                        {'text': manualTimetablePrompt},
                        {
                          'inlineData': {
                            'mimeType': mimeType,
                            'data': base64Image,
                          },
                        },
                      ],
                    },
                  ],
                  'generationConfig': {'responseMimeType': 'application/json'},
                }),
              )
              .timeout(const Duration(seconds: 20));

          if (response.statusCode == 200) {
            final responseBody =
                json.decode(response.body) as Map<String, dynamic>;
            final candidates = responseBody['candidates'] as List<dynamic>?;
            if (candidates == null || candidates.isEmpty) {
              throw Exception('No candidates returned.');
            }

            final text = candidates[0]['content']['parts'][0]['text'] as String;
            return parseTimetableJson(text);
          } else if (response.statusCode == 503 || response.statusCode == 429) {
            retries++;
            if (retries <= maxRetries) {
              debugPrint(
                'Model $model returned status ${response.statusCode}. Retrying in 2 seconds... (Attempt $retries of $maxRetries)',
              );
              await Future.delayed(const Duration(seconds: 2));
              continue;
            } else {
              final err =
                  'Model $model failed with status ${response.statusCode} after $maxRetries retries: ${response.body}';
              debugPrint(err);
              errors.add(err);
              break; // Try next model
            }
          } else {
            final err =
                'Model $model failed with status ${response.statusCode}: ${response.body}';
            debugPrint(err);
            errors.add(err);
            break; // Try next model
          }
        } catch (e) {
          retries++;
          if (retries <= maxRetries &&
              (e is http.ClientException ||
                  e is TimeoutException ||
                  e is SocketException)) {
            debugPrint(
              'Connection error with $model: $e. Retrying in 2 seconds... (Attempt $retries of $maxRetries)',
            );
            await Future.delayed(const Duration(seconds: 2));
            continue;
          } else {
            final err = 'Failed parsing with $model: $e';
            debugPrint(err);
            errors.add(err);
            break; // Try next model
          }
        }
      }
    }

    throw Exception(
      'ไม่สามารถเชื่อมต่อป้อนข้อมูลกับระบบ AI ทุกรุ่นได้:\n${errors.join('\n\n')}',
    );
  }
}
