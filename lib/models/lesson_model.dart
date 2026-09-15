import 'activity_model.dart';
import 'nlp_token_model.dart';
import 'quiz_model.dart';

/// Represents an interactive example sentence broken down morphologically and syntactically.
class LessonExample {
  final String sentence; // Complete sentence with tashkeel
  final String translationOrContext;
  final List<NlpToken> tokens; // Word-by-word syntactic breakdown

  const LessonExample({
    required this.sentence,
    this.translationOrContext = '',
    required this.tokens,
  });
}

/// Represents an educational grammar lesson aligned with the primary curriculum.
class LessonModel {
  final String id;
  final String gradeId; // 'grade3', 'grade4', 'grade5'
  final String title;
  final String subtitle;
  final String ruleSummary;
  final String detailedExplanation;
  final List<LessonExample> examples;
  final List<String> keyTakeaways;
  final List<ActivityModel> activities;
  final QuizModel? evaluationQuiz;
  final String iconName;

  const LessonModel({
    required this.id,
    required this.gradeId,
    required this.title,
    required this.subtitle,
    required this.ruleSummary,
    required this.detailedExplanation,
    required this.examples,
    required this.keyTakeaways,
    required this.activities,
    this.evaluationQuiz,
    this.iconName = 'book',
  });
}
