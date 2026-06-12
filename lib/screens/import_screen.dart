import 'dart:async';
import 'dart:io';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/schedule_manager.dart';
import '../models/class_item.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/title_bar.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  String? _apiKey;
  final TextEditingController _apiKeyController = TextEditingController();

  PlatformFile? _selectedFile;
  bool _isProcessing = false;
  String _loadingMessage = '';

  Map<int, List<ClassItem>>? _parsedWeek;
  int _previewDayIndex = 0;

  Timer? _loadingTimer;
  int _loadingMsgIndex = 0;
  final List<String> _loadingMessages = [
    'กำลังเปิดอ่านไฟล์รูปภาพ... 📂',
    'กำลังวิเคราะห์รูปภาพตารางเรียน... 🔍',
    'กำลังส่งข้อมูลไปประมวลผลด้วย Gemini AI... 🚀',
    'อดใจรอน้าา AI กำลังอ่านและแกะตัวหนังสือวิชาเรียน... 🧠',
    'กำลังแยกชื่อวิชา ห้องเรียน และเวลาเรียน... 🏫',
    'จัดแจงธีมสีและไอคอนสุดเท่สไตล์มือโปรให้แต่ละวิชา... 🎨',
    'จัดเรียงเวลาตารางเรียนของแต่ละวันให้เข้าที่... ⏱️',
    'เกือบเสร็จแล้วล่ะ! ความเป็นโปรแกรมเมอร์กำลังสร้างผลลัพธ์ขั้นเทพ... ✨',
    'รออีกนิสสส กำลังปัดฝุ่นตารางเรียนให้สวยกริ๊บ... 💅',
  ];

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await ScheduleManager.getApiKey();
    if (mounted) {
      setState(() {
        _apiKey = key;
        if (key != null) {
          _apiKeyController.text = key;
        }
      });
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอก API Key')));
      return;
    }
    await ScheduleManager.saveApiKey(key);
    setState(() {
      _apiKey = key;
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึก API Key สำเร็จ')));
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _parsedWeek = null; // Clear previous result if any
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _startLoadingAnimation() {
    _loadingMsgIndex = 0;
    setState(() {
      _loadingMessage = _loadingMessages[0];
    });
    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _loadingMsgIndex = (_loadingMsgIndex + 1) % _loadingMessages.length;
          _loadingMessage = _loadingMessages[_loadingMsgIndex];
        });
      }
    });
  }

  void _stopLoadingAnimation() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  Future<void> _processImage() async {
    if (_selectedFile == null) return;
    if (_apiKey == null || _apiKey!.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _loadingMessage = 'กำลังเริ่มประมวลผล...';
    });
    _startLoadingAnimation();

    try {
      List<int> bytes;
      if (kIsWeb) {
        bytes = _selectedFile!.bytes!;
      } else {
        bytes = await File(_selectedFile!.path!).readAsBytes();
      }
      final mimeType = _selectedFile!.extension == 'png'
          ? 'image/png'
          : 'image/jpeg';
      final parsed = await ScheduleManager.parseTimetableImage(
        imageBytes: bytes,
        mimeType: mimeType,
        apiKey: _apiKey!,
      );

      _stopLoadingAnimation();
      setState(() {
        _parsedWeek = parsed;
        _isProcessing = false;
        _loadingMessage = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('วิเคราะห์ตารางเรียนเสร็จสิ้น!')),
        );
      }
    } catch (e) {
      _stopLoadingAnimation();
      setState(() {
        _isProcessing = false;
        _loadingMessage = '';
      });
      if (mounted) {
        final errorMsg = e.toString();
        String title = 'เกิดข้อผิดพลาด';
        String displayMsg;
        IconData titleIcon = Icons.error_outline;
        Color iconColor = Colors.red;

        // Check 429 first - quota/rate limit (most common cause)
        if (errorMsg.contains('429') ||
            errorMsg.contains('RESOURCE_EXHAUSTED')) {
          title = 'โควตา API หมดชั่วคราว ⏳';
          titleIcon = Icons.hourglass_bottom;
          iconColor = Colors.orange;
          displayMsg =
              'API Key ฟรีของคุณถูกใช้งานเกินโควตาในช่วงนี้ (Rate Limit Exceeded)\n\n'
              '💡 วิธีแก้ไข:\n'
              '1. กรุณารอ 30 วินาที - 1 นาที แล้วลองกดส่งใหม่อีกครั้ง\n'
              '2. หรือเปลี่ยนไปใช้ API Key ใหม่ในส่วน "แก้ไข API Key"';
        } else if (errorMsg.contains('503') ||
            errorMsg.contains('UNAVAILABLE')) {
          title = 'เซิร์ฟเวอร์ AI หนาแน่น ☁️';
          titleIcon = Icons.cloud_off;
          iconColor = Colors.blue;
          displayMsg =
              'โมเดล AI กำลังมีผู้ใช้งานสูงมาก (Temporary Overload)\n\n'
              '💡 วิธีแก้ไข:\n'
              'รอสักครู่ 5-10 วินาที แล้วลองกดส่งอีกครั้งครับ';
        } else if (errorMsg.contains('API_KEY_INVALID') ||
            errorMsg.contains('API key not valid') ||
            errorMsg.contains('401')) {
          title = 'API Key ไม่ถูกต้อง 🔑';
          titleIcon = Icons.vpn_key_off;
          iconColor = Colors.red;
          displayMsg =
              'API Key ที่ใส่ไว้ไม่ถูกต้อง หรือใช้งานไม่ได้\n\n'
              '💡 วิธีแก้ไข:\n'
              'กดปุ่ม "แก้ไข API Key" ด้านบน แล้วใส่คีย์ใหม่ที่ถูกต้องจาก Google AI Studio ครับ';
        } else if (errorMsg.contains('TimeoutException') ||
            errorMsg.contains('timeout')) {
          title = 'เชื่อมต่อช้าเกินไป ⌛';
          titleIcon = Icons.timer_off;
          iconColor = Colors.orange;
          displayMsg =
              'การส่งรูปภาพไปยัง AI ใช้เวลานานเกินกำหนด (Timeout)\n\n'
              '💡 วิธีแก้ไข:\n'
              '1. ตรวจสอบสัญญาณอินเทอร์เน็ต\n'
              '2. ลองใช้รูปภาพขนาดเล็กลง\n'
              '3. ลองกดส่งใหม่อีกครั้ง';
        } else if (errorMsg.contains('SocketException') ||
            errorMsg.contains('ClientException')) {
          title = 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต 📡';
          titleIcon = Icons.wifi_off;
          iconColor = Colors.grey;
          displayMsg =
              'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้\n\n'
              '💡 วิธีแก้ไข:\n'
              'ตรวจสอบ Wi-Fi หรือสัญญาณเครือข่าย แล้วลองใหม่อีกครั้งครับ';
        } else {
          displayMsg =
              'ไม่สามารถวิเคราะห์ตารางเรียนได้ในขณะนี้\n\n'
              '💡 สิ่งที่ควรตรวจสอบ:\n'
              '• API Key ถูกต้องและยังใช้งานได้\n'
              '• เชื่อมต่ออินเทอร์เน็ตปกติ\n'
              '• ไฟล์รูปภาพไม่เสียหาย\n\n'
              'รายละเอียด: ${errorMsg.length > 120 ? '${errorMsg.substring(0, 120)}...' : errorMsg}';
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(titleIcon, color: iconColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                displayMsg,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _saveSchedule() async {
    if (_parsedWeek == null) return;
    await ScheduleManager.saveWeeklySchedule(_parsedWeek!);
    NotificationService.rescheduleAll(_parsedWeek!);
    WidgetService.updateWidgets(_parsedWeek!);
    if (mounted) {
      Navigator.pop(context, true); // Return true to notify parent of changes
    }
  }

  Future<void> _openManualImport() async {
    final parsed = await Navigator.push<Map<int, List<ClassItem>>>(
      context,
      MaterialPageRoute(builder: (context) => const ManualAiImportScreen()),
    );

    if (parsed == null || !mounted) return;

    setState(() {
      _parsedWeek = parsed;
      _previewDayIndex = 0;
      _isProcessing = false;
      _loadingMessage = '';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('นำเข้าคำตอบจาก AI สำเร็จ!')));
  }

  void _editClassItem(int dayIndex, int itemIndex) {
    final item = _parsedWeek![dayIndex]![itemIndex];
    final subjectController = TextEditingController(text: item.subject);
    final teacherController = TextEditingController(text: item.teacher);
    final startController = TextEditingController(text: item.startTime);
    final endController = TextEditingController(text: item.endTime);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('แก้ไขข้อมูลวิชาเรียน'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อวิชา (และห้องเรียน)',
                  ),
                ),
                TextField(
                  controller: teacherController,
                  decoration: const InputDecoration(labelText: 'ครูผู้สอน'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startController,
                        decoration: const InputDecoration(
                          labelText: 'เวลาเริ่ม (HH:mm)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: endController,
                        decoration: const InputDecoration(
                          labelText: 'เวลาเลิก (HH:mm)',
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
              onPressed: () {
                setState(() {
                  _parsedWeek![dayIndex]!.removeAt(itemIndex);
                });
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('ลบวิชานี้'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                final newSubject = subjectController.text.trim();
                final newTeacher = teacherController.text.trim();
                final newStart = startController.text.trim();
                final newEnd = endController.text.trim();

                if (newSubject.isEmpty || newStart.isEmpty || newEnd.isEmpty) {
                  return;
                }

                final theme = ScheduleManager.detectSubjectTheme(newSubject);

                setState(() {
                  _parsedWeek![dayIndex]![itemIndex] = item.copyWith(
                    startTime: newStart,
                    endTime: newEnd,
                    subject: newSubject,
                    teacher: newTeacher,
                    themeColor: theme.themeColor,
                    cardColor: theme.cardColor,
                    textColor: theme.textColor,
                    iconName: theme.iconName,
                  );
                });

                Navigator.pop(context);
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  // Helper widget to display list preview of parsed classes
  Widget _buildPreviewClassList(int dayIndex) {
    if (_parsedWeek == null) return const SizedBox.shrink();
    final list = _parsedWeek![dayIndex] ?? [];

    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'ไม่มีตารางเรียนในวันนี้',
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = list[index];
        final theme = ScheduleManager.detectSubjectTheme(item.subject, isBreak: item.isBreak);

        if (item.isBreak) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  item.subject,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMedium,
                  ),
                ),
                const Spacer(),
                Text(
                  '${item.startTime} - ${item.endTime} น.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          );
        }

        return InkWell(
          onTap: () => _editClassItem(dayIndex, index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: ShapeDecoration(
              color: item.type == ClassType.normal
                  ? theme.cardColor
                  : Colors.white,
              shape: SmoothRectangleBorder(
                borderRadius: squircleRadius(12),
                side: BorderSide(color: theme.themeColor, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                // Time
                SizedBox(
                  width: 75,
                  child: Text(
                    '${item.startTime} - ${item.endTime}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: item.type == ClassType.normal
                          ? (item.textColor ?? Colors.white)
                          : AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Subject Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.subject,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: item.type == ClassType.normal
                              ? (item.textColor ?? Colors.white)
                              : AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.teacher,
                        style: TextStyle(
                          fontSize: 12,
                          color: item.type == ClassType.normal
                              ? (item.textColor ?? Colors.white).withValues(
                                  alpha: 0.8,
                                  )
                              : AppColors.textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (item.periodNumber != null)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: ShapeDecoration(
                      color: item.type == ClassType.normal
                          ? Colors.white.withValues(alpha: 0.2)
                          : theme.themeColor.withValues(alpha: 0.12),
                      shape: SmoothRectangleBorder(borderRadius: squircleRadius(6)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.periodNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.type == ClassType.normal
                            ? (item.textColor ?? Colors.white)
                            : theme.themeColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> days = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTitleBar(),
            // Custom Back button & Page Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    color: AppColors.textDark,
                  ),
                  Expanded(
                    child: Text(
                      'นำเข้าตารางเรียน (Gemini AI)',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_apiKey == null) ...[
                      _buildApiKeyConfigSection(),
                    ] else ...[
                      // File Upload section
                      _buildUploadSection(),

                      const SizedBox(height: 20),

                      // Loading spinner
                      if (_isProcessing) ...[_buildLoadingSection()],

                      // Parsed Results Preview
                      if (_parsedWeek != null) ...[_buildPreviewSection(days)],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyConfigSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ShapeDecoration(
        color: const Color(0xFFEFF6FF),
        shape: SmoothRectangleBorder(
          borderRadius: squircleRadius(16),
          side: const BorderSide(color: Color(0xFFBFDBFE)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              const Text(
                'ต้องการ Gemini API Key',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'ฟีเจอร์การสแกนตารางเรียนจะส่งรูปภาพไปประมวลผลด้วยโมเดลวิเคราะห์ภาพที่ฉลาดและฟรีของ Google Gemini API กรุณานำคีย์มาใส่เพื่อเปิดใช้งาน',
            style: TextStyle(fontSize: 13, color: AppColors.textMedium),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'ป้อน Gemini API Key ของคุณ',
              hintText: 'AIzaSy...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  // Open browser link to get API Key
                  // Since we don't have url_launcher, we just instruct user
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('วิธีสมัครรับ API Key ฟรี'),
                      content: const Text(
                        '1. ค้นหาในกูเกิลว่า "Google AI Studio"\n'
                        '2. ล็อกอินด้วย Gmail ของคุณ\n'
                        '3. กดปุ่ม "Get API Key" สีน้ำเงินทางซ้ายบน\n'
                        '4. คัดลอกรหัสคีย์ (ขึ้นต้นด้วย AIzaSy...) มาวางที่ช่องนี้ได้ทันทีครับ',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('ตกลง'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'รับคีย์ฟรีคลิกที่นี่ ↗',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: _saveApiKey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'บันทึกคีย์',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'เลือกรูปภาพตารางเรียน',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _apiKey = null;
                });
              },
              icon: const Icon(Icons.edit, size: 14),
              label: const Text(
                'แก้ไข API Key',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Large dash box representing drop/click area
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: ShapeDecoration(
              color: const Color(0xFFF8FAFC),
              shape: SmoothRectangleBorder(
                borderRadius: squircleRadius(16),
                side: BorderSide(
                  color: _selectedFile != null
                      ? AppColors.primary
                      : Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            child: _selectedFile == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'กดเพื่อเลือกรูปภาพจากเครื่อง (.png, .jpg)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedFile!.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ขนาด: ${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB (คลิกเพื่อเปลี่ยนรูป)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 14),
        _buildManualImportOption(),

        // Action Process button
        if (_selectedFile != null && !_isProcessing && _parsedWeek == null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _processImage,
              icon: const Icon(Icons.rocket_launch, color: Colors.white),
              label: const Text(
                'เริ่มวิเคราะห์ด้วย Gemini AI',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildManualImportOption() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFFBEB),
        shape: SmoothRectangleBorder(
          borderRadius: squircleRadius(14),
          side: const BorderSide(color: Color(0xFFFDE68A)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.content_paste_go,
            color: Color(0xFFD97706),
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API หมด? ใช้ Manual AI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'คัดลอก prompt ไปถาม AI เอง แล้วนำ JSON กลับมาวาง',
                  style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: _openManualImport,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD97706),
              side: const BorderSide(color: Color(0xFFF59E0B)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: const Text(
              'เปิด',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Center(
      child: Column(
        children: [
          const CuteLoadingIndicator(),
          const SizedBox(height: 20),
          Text(
            _loadingMessage,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'โปรดรอสักครู่ขั้นตอนนี้อาจใช้เวลา 3 - 8 วินาที',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(List<String> days) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
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
          const Row(
            children: [
              Icon(Icons.preview, color: AppColors.green, size: 22),
              SizedBox(width: 8),
              Text(
                'ผลลัพธ์การวิเคราะห์ (ตรวจสอบข้อมูล)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day strip preview tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(days.length, (index) {
              final isSelected = index == _previewDayIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _previewDayIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: ShapeDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      shape: SmoothRectangleBorder(
                        borderRadius: squircleRadius(8),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        days[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 14),
          _buildPreviewClassList(_previewDayIndex),
          const SizedBox(height: 20),

          // Save and import button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveSchedule,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'ยืนยันและนำเข้าตารางเรียนใหม่',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ManualAiImportScreen extends StatefulWidget {
  const ManualAiImportScreen({super.key});

  @override
  State<ManualAiImportScreen> createState() => _ManualAiImportScreenState();
}

class _ManualAiImportScreenState extends State<ManualAiImportScreen> {
  final TextEditingController _answerController = TextEditingController();
  bool _isParsing = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _copyPrompt() async {
    await Clipboard.setData(
      const ClipboardData(text: ScheduleManager.manualTimetablePrompt),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('คัดลอก prompt แล้ว')));
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    setState(() {
      _answerController.text = text;
    });
  }

  Future<void> _parseAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      _showError('กรุณาวางคำตอบ JSON จาก AI ก่อน');
      return;
    }

    setState(() => _isParsing = true);
    try {
      final parsed = ScheduleManager.parseTimetableJson(answer);
      if (!mounted) return;
      Navigator.pop(context, parsed);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isParsing = false);
      _showError(
        'อ่านคำตอบจาก AI ไม่ได้\n\n'
        'ให้ตรวจว่าคำตอบเป็น JSON ที่มี monday, tuesday, wednesday, thursday, friday\n\n'
        'รายละเอียด: $e',
      );
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('นำเข้าไม่ได้'),
          ],
        ),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTitleBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    color: AppColors.textDark,
                  ),
                  const Expanded(
                    child: Text(
                      'นำเข้าแบบ Manual AI',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepCard(),
                    const SizedBox(height: 16),
                    _buildAnswerInput(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isParsing ? null : _parseAnswer,
                        icon: _isParsing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.auto_fix_high,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isParsing
                              ? 'กำลังแปลงคำตอบ...'
                              : 'แปลงเป็นตารางเรียน',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          const Row(
            children: [
              Icon(Icons.route, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'วิธีใช้',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _step('1', 'กดคัดลอก prompt ด้านล่าง'),
          _step('2', 'เปิดแอพ AI ที่ใช้ได้ เช่น ChatGPT, Gemini หรือ Claude'),
          _step('3', 'อัปโหลดรูปตารางเรียน แล้ววาง prompt ที่คัดลอกไว้'),
          _step('4', 'คัดลอกคำตอบ JSON จาก AI กลับมาวางในช่องนี้'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _copyPrompt,
              icon: const Icon(Icons.copy, color: Colors.white),
              label: const Text(
                'คัดลอก prompt สำหรับ AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
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
              const Expanded(
                child: Text(
                  'วางคำตอบ JSON จาก AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.content_paste, size: 16),
                label: const Text('วาง'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _answerController,
            minLines: 10,
            maxLines: 18,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText:
                  '{\n  "monday": [\n    { "startTime": "08:30", "endTime": "09:20", "subject": "คณิตศาสตร์", "teacher": "ครู..." }\n  ],\n  "tuesday": [],\n  "wednesday": [],\n  "thursday": [],\n  "friday": []\n}',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class CuteLoadingIndicator extends StatefulWidget {
  const CuteLoadingIndicator({super.key});

  @override
  State<CuteLoadingIndicator> createState() => _CuteLoadingIndicatorState();
}

class _CuteLoadingIndicatorState extends State<CuteLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(
      begin: -0.06,
      end: 0.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _bounceAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: ShapeDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        Color(0xFF818CF8),
                        Color(0xFFC084FC),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: SmoothRectangleBorder(
                      borderRadius: squircleRadius(24),
                    ),
                    shadows: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: SmoothRectangleBorder(
                            borderRadius: squircleRadius(20),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, _bounceAnimation.value),
                        child: const Text(
                          '🤖✨',
                          style: TextStyle(fontSize: 38),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
