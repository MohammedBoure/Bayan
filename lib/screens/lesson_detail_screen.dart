import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/sentence_parser_view.dart';
import 'interactive_activity_screen.dart';

/// [04] صفحة الدرس (Lesson Detail Screen)
/// Matching tasks.md:
/// - الوسط: شرح / أمثلة
/// - الجملة الفعلية هي...
/// - مثال:
///   * كَتَبَ (فعل)
///   * التِّلْمِيذُ (فاعل)
///   * الدَّرْسَ (مفعول به)
/// - زر: التالي (Proceed to Interactive Activity)
class LessonDetailScreen extends StatefulWidget {
  final LessonModel lesson;
  final ProgressService progressService;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.progressService,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  late bool _showTashkeel;

  @override
  void initState() {
    super.initState();
    _showTashkeel = widget.progressService.showTashkeel;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.lesson.title,
      progressService: widget.progressService,
      actions: [
        // Tashkeel Toggle Action
        IconButton(
          icon: Icon(
            _showTashkeel ? Icons.format_color_text_rounded : Icons.text_fields_rounded,
            color: Colors.white,
          ),
          tooltip: _showTashkeel ? 'إخفاء التشكيل' : 'إظهار التشكيل',
          onPressed: () {
            setState(() {
              _showTashkeel = !_showTashkeel;
            });
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_rounded, color: AppTheme.primaryTeal, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.lesson.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.lesson.subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rule Box (القاعدة النحوية)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentAmber.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lightbulb_rounded, color: AppTheme.accentAmber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'القَاعِدَةُ النَّحْوِيَّةُ:',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.lesson.ruleSummary,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Interactive Examples (الأمثلة التفاعلية مع تفكيك الكلمات)
            ...widget.lesson.examples.map((example) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: SentenceParserView(
                  tokens: example.tokens,
                  showTashkeel: _showTashkeel,
                  title: 'مِثَالٌ تَفَاعُلِيٌّ: "${example.sentence}"',
                ),
              );
            }),

            // Detailed Explanation (الشرح التربوي)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.menu_book_rounded, color: AppTheme.primaryTeal, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'شَرْحٌ وَتَوْضِيحٌ:',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.lesson.detailedExplanation.trim(),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // [ زر: التالي ] Button as mandated by tasks.md
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (widget.lesson.activities.isNotEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InteractiveActivityScreen(
                          activities: widget.lesson.activities,
                          lessonTitle: widget.lesson.title,
                          lessonIdToComplete: widget.lesson.id,
                          progressService: widget.progressService,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('أحسنت! لا توجد أنشطة إضافية لهذا الدرس.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
                label: const Text(
                  'التَّالِي: الاِنْتِقَالُ إِلَى النَّشَاطِ التَّفَاعُلِيِّ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
