/// Represents a single evaluation quiz question.
class QuizQuestion {
  final String id;
  final String questionText;
  final String? contextSentence;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.questionText,
    this.contextSentence,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  String get correctAnswer => options[correctIndex];
}

/// Represents a full evaluation quiz for a lesson or grade level.
class QuizModel {
  final String id;
  final String title;
  final String gradeId;
  final String description;
  final List<QuizQuestion> questions;

  const QuizModel({
    required this.id,
    required this.title,
    required this.gradeId,
    required this.description,
    required this.questions,
  });
}
