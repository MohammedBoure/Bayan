import 'curriculum_unit_model.dart';
import 'lesson_model.dart';
import 'quiz_model.dart';

/// Represents a primary school academic grade level.
/// Structured to scale easily to dozens of units, lessons, and interactive activities.
class GradeModel {
  final String id;
  final int gradeNumber; // 3, 4, 5
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final String colorHex;
  final List<LessonModel> lessons;
  final List<CurriculumUnitModel> units;
  final QuizModel comprehensiveQuiz;

  const GradeModel({
    required this.id,
    required this.gradeNumber,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    required this.colorHex,
    required this.lessons,
    this.units = const [],
    required this.comprehensiveQuiz,
  });

  /// Total number of lessons available in this grade
  int get totalLessonsCount => lessons.length;

  /// Total number of activities across all lessons
  int get totalActivitiesCount => lessons.fold(0, (sum, l) => sum + l.activities.length);
}
