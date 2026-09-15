import 'package:flutter/material.dart';
import '../data/curriculum_data.dart';
import '../models/grade_model.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import 'lessons_list_screen.dart';

/// [02] اختيار السنة الدراسية (Grade Selection Screen)
/// Matching tasks.md:
/// - [ زر: السنة الثالثة ]
/// - [ زر: السنة الرابعة ]
/// - [ زر: السنة الخامسة ]
/// - [ زر رجوع ]
class GradeSelectionScreen extends StatelessWidget {
  final ProgressService progressService;

  const GradeSelectionScreen({
    super.key,
    required this.progressService,
  });

  @override
  Widget build(BuildContext context) {
    final grades = CurriculumData.getGrades();

    return AppScaffold(
      title: 'اخْتِيَارُ السَّنَةِ الدِّرَاسِيَّةِ',
      progressService: progressService,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subtitle Guidance
            const Center(
              child: Text(
                'اخْتَرْ سَنَتَكَ الدِّرَاسِيَّةَ لِبَدْءِ الدُّرُوسِ وَالأَنْشِطَةِ:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Grade Buttons / Cards (3, 4, 5)
            ...grades.map((grade) => _buildGradeCard(context, grade)),

            const SizedBox(height: 16),

            // Back Button [ زر رجوع ]
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryTeal),
                label: const Text(
                  'رُجُوعٌ إِلَى الرَّئِيسِيَّةِ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeCard(BuildContext context, GradeModel grade) {
    Color gradeColor;
    if (grade.gradeNumber == 3) {
      gradeColor = AppTheme.primaryTeal;
    } else if (grade.gradeNumber == 4) {
      gradeColor = AppTheme.accentBlue;
    } else {
      gradeColor = AppTheme.accentOrange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonsListScreen(
                grade: grade,
                progressService: progressService,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: gradeColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: gradeColor.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Header with Image and Badge
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                    Image.asset(
                      grade.imagePath,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        color: gradeColor.withValues(alpha: 0.15),
                        child: Icon(Icons.school_rounded, size: 50, color: gradeColor),
                      ),
                    ),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: gradeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'السنة ${grade.gradeNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            grade.title,
                            style: const TextStyle(
                              color: Colors.white,
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

              // Card Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            grade.subtitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            grade.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: gradeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_ios_rounded, color: gradeColor, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
