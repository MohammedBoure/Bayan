import 'lesson_model.dart';
import 'quiz_model.dart';

/// Represents a primary school academic grade level.
class GradeModel {
  final String id;
  final int gradeNumber; // 3, 4, 5
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final String colorHex;
  final List<LessonModel> lessons;
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
    required this.comprehensiveQuiz,
  });
}
