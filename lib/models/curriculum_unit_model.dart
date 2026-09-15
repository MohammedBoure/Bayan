import 'lesson_model.dart';
import 'quiz_model.dart';

/// Represents an educational unit (الوحدة التعليمية) grouping multiple lessons,
/// exercises, and a unit evaluation quiz. Designed for scalable curriculum growth.
class CurriculumUnitModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int order;
  final List<LessonModel> lessons;
  final QuizModel? unitQuiz;

  const CurriculumUnitModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.order,
    required this.lessons,
    this.unitQuiz,
  });

  /// Total number of activities across all lessons in this unit
  int get totalActivitiesCount => lessons.fold(0, (sum, l) => sum + l.activities.length);
}
