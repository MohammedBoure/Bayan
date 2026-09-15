import 'package:flutter/material.dart';
import '../models/grade_model.dart';
import '../models/lesson_model.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import 'interactive_activity_screen.dart';
import 'lesson_detail_screen.dart';
import 'quiz_evaluation_screen.dart';

/// [03] قائمة الدروس (Lessons List Screen)
/// Matching tasks.md specification for Grade 3 (and other grades):
/// - [ الفعل الماضي ]
/// - [ الفعل المضارع ]
/// - [ الفعل الأمر ]
/// - [ الجملة الفعلية ]
/// - [ أنشطة وتدريبات ]
/// - [ التقويم ]
class LessonsListScreen extends StatelessWidget {
  final GradeModel grade;
  final ProgressService progressService;

  const LessonsListScreen({
    super.key,
    required this.grade,
    required this.progressService,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'قَائِمَةُ الدُّرُوسِ - ${grade.title}',
      progressService: progressService,
      body: ListenableBuilder(
        listenable: progressService,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryTeal,
                      AppTheme.primaryTeal.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            grade.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            grade.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'الدُّرُوسُ التَّعْلِيمِيَّةُ:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),

              // Lessons List (الفعل الماضي، المضارع، الأمر، الجملة الفعلية)
              ...List.generate(grade.lessons.length, (index) {
                final lesson = grade.lessons[index];
                final isCompleted = progressService.progress.isLessonCompleted(lesson.id);

                return _buildLessonItem(context, lesson, index + 1, isCompleted);
              }),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              const Text(
                'الأَنْشِطَةُ وَالتَّقْوِيمُ:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),

              // [ أنشطة وتدريبات ]
              _buildSpecialCard(
                context: context,
                title: 'أَنْشِطَةٌ وَتَدْرِيبَاتٌ تَفَاعُلِيَّةٌ',
                subtitle: 'تدريبات لغوية لتحديد الفعل والفاعل والمفعول به',
                icon: Icons.extension_rounded,
                color: AppTheme.accentOrange,
                onTap: () {
                  // Open first lesson's activities or aggregated activities
                  if (grade.lessons.isNotEmpty && grade.lessons.first.activities.isNotEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InteractiveActivityScreen(
                          activities: grade.lessons.expand((l) => l.activities).toList(),
                          lessonTitle: 'تدريبات ${grade.title}',
                          progressService: progressService,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 14),

              // [ التقويم ]
              _buildSpecialCard(
                context: context,
                title: 'التَّقْوِيمُ الشَّامِلُ (الاِخْتِبَارُ)',
                subtitle: 'قياس تحصيل التلميذ مع النتيجة والتقييم الفوري',
                icon: Icons.quiz_rounded,
                color: AppTheme.accentPurple,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuizEvaluationScreen(
                        quiz: grade.comprehensiveQuiz,
                        progressService: progressService,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLessonItem(BuildContext context, LessonModel lesson, int number, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonDetailScreen(
                lesson: lesson,
                progressService: progressService,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? AppTheme.successGreen.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Index Circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.successGreen.withValues(alpha: 0.15)
                      : AppTheme.primaryTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 24)
                      : Text(
                          '$number',
                          style: const TextStyle(
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lesson.subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}
