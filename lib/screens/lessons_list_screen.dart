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
/// Optimized for classroom display on a Data Show device.
/// Shows units and syllabus lessons with large, clear cards, badges, and quick-action assessment panels.
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
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Classroom Presentation Header Banner
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryTeal,
                        AppTheme.primaryTeal.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 50),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              grade.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              grade.subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Responsive 2-Column Presentation Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;

                    final lessonsListWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'دُرُوسُ المَنْهَجِ المُقَرَّرِ:',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(grade.lessons.length, (index) {
                          final lesson = grade.lessons[index];
                          final isCompleted = progressService.progress.isLessonCompleted(lesson.id);
                          return _buildLessonItem(context, lesson, index + 1, isCompleted);
                        }),
                      ],
                    );

                    final sideActionsWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'التَّطْبِيقَاتُ وَالتَّقْوِيمُ:',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSpecialCard(
                          context: context,
                          title: 'أَنْشِطَةٌ وَتَدْرِيبَاتٌ تَفَاعُلِيَّةٌ',
                          subtitle: 'تدريبات لغوية لتحديد الفعل والفاعل والمفعول به على السبورة',
                          icon: Icons.extension_rounded,
                          color: AppTheme.accentOrange,
                          onTap: () {
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
                        const SizedBox(height: 18),
                        _buildSpecialCard(
                          context: context,
                          title: 'التَّقْوِيمُ الشَّامِلُ (الاِخْتِبَارُ)',
                          subtitle: 'قياس تحصيل تلاميذ الصف مع حساب النتيجة الفورية',
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

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: lessonsListWidget),
                          const SizedBox(width: 28),
                          Expanded(flex: 5, child: sideActionsWidget),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          lessonsListWidget,
                          const SizedBox(height: 28),
                          sideActionsWidget,
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLessonItem(BuildContext context, LessonModel lesson, int number, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCompleted ? AppTheme.successGreen : const Color(0xFFCBD5E1),
              width: isCompleted ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Index Circle
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.successGreen.withValues(alpha: 0.15)
                      : AppTheme.primaryTeal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 34)
                      : Text(
                          '$number',
                          style: const TextStyle(
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 18),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lesson.subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios_rounded, size: 22, color: AppTheme.primaryTeal),
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
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white, size: 34),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textDark,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 22, color: color),
          ],
        ),
      ),
    );
  }
}
