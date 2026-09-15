import 'package:flutter/material.dart';
import '../data/curriculum_data.dart';
import '../models/grade_model.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import 'lessons_list_screen.dart';

/// [02] اختيار السنة الدراسية (Grade Selection Screen)
/// Scaled for Classroom Data Show displays.
/// Uses a responsive multi-column layout across wide screens so students can compare and choose easily.
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prominent Classroom Title
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: const Text(
                'اخْتَرِ المَرْحَلَةَ الدِّرَاسِيَّةَ لِعَرْضِ دُرُوسِهَا وَأَنْشِطَتِهَا التَّفَاعُلِيَّةِ:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Multi-column Responsive Layout for Widescreen Data Show
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 950;

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: grades.map((grade) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: _buildGradeCard(context, grade, isWide: true),
                        ),
                      );
                    }).toList(),
                  );
                } else {
                  return Column(
                    children: grades.map((grade) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: _buildGradeCard(context, grade, isWide: false),
                      );
                    }).toList(),
                  );
                }
              },
            ),

            const SizedBox(height: 32),

            // Back Button [ زر رجوع ]
            Center(
              child: SizedBox(
                height: 58,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryTeal, size: 28),
                  label: const Text(
                    'رُجُوعٌ إِلَى الشَّاشَةِ الرَّئِيسِيَّةِ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeCard(BuildContext context, GradeModel grade, {required bool isWide}) {
    Color gradeColor;
    if (grade.gradeNumber == 3) {
      gradeColor = AppTheme.primaryTeal;
    } else if (grade.gradeNumber == 4) {
      gradeColor = AppTheme.verbColor;
    } else {
      gradeColor = AppTheme.accentOrange;
    }

    return InkWell(
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
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: gradeColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: gradeColor.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header with Image and Badge
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
              child: Stack(
                children: [
                  Image.asset(
                    grade.imagePath,
                    height: isWide ? 180 : 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: gradeColor.withValues(alpha: 0.15),
                      child: Icon(Icons.school_rounded, size: 60, color: gradeColor),
                    ),
                  ),
                  Container(
                    height: isWide ? 180 : 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    right: 18,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: gradeColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'السنة ${grade.gradeNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          grade.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
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
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.subtitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    grade.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textDark,
                      height: 1.6,
                    ),
                    maxLines: isWide ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.menu_book_rounded, size: 20, color: gradeColor),
                          const SizedBox(width: 6),
                          Text(
                            '${grade.totalLessonsCount} دروس',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: gradeColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
