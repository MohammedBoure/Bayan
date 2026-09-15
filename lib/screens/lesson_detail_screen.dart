import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/sentence_parser_view.dart';
import 'interactive_activity_screen.dart';

/// [04] صفحة الدرس (Lesson Detail Screen)
/// Classroom presentation slide layout for Data Show devices.
/// Displays high-contrast rules, expansive interactive examples, and bold next action.
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
            size: 28,
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Lesson Presentation Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryTeal, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lesson.title,
                          style: const TextStyle(
                            fontSize: 28, // Visible across lecture room
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.lesson.subtitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rule Box (القاعدة النحوية المعروضة للطلاب)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.accentAmber, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentAmber.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lightbulb_rounded, color: AppTheme.accentAmber, size: 32),
                      SizedBox(width: 10),
                      Text(
                        'القَاعِدَةُ النَّحْوِيَّةُ الأَسَاسِيَّةُ:',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.lesson.ruleSummary,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.8,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Interactive Examples (الأمثلة التفاعلية بحجم خط كبير)
            ...widget.lesson.examples.map((example) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: SentenceParserView(
                  tokens: example.tokens,
                  showTashkeel: _showTashkeel,
                  title: 'مِثَالٌ تَفَاعُلِيٌّ عَلَى السَّبُّورَةِ: "${example.sentence}"',
                ),
              );
            }),

            // Detailed Explanation (الشرح والتوضيح)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.menu_book_rounded, color: AppTheme.primaryTeal, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'تَوْضِيحٌ وَأَمْثِلَةٌ إِضَافِيَّةٌ لِلتَّلامِيذِ:',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.lesson.detailedExplanation.trim(),
                    style: const TextStyle(
                      fontSize: 19,
                      height: 1.75,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // [ زر: التالي ] Button as mandated by tasks.md
            SizedBox(
              height: 68, // Tall and prominent
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
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 32),
                label: const Text(
                  'التَّالِي: الاِنْتِقَالُ إِلَى النَّشَاطِ التَّفَاعُلِيِّ عَلَى الشَّاشَةِ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
