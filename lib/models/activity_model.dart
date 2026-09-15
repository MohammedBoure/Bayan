enum ActivityType {
  selectVerb,
  selectSubject,
  selectObject,
  classifyVerbTense,
  fillInTheBlank,
  orderSentence,
}

/// Represents an interactive grammar activity designed for primary students.
class ActivityModel {
  final String id;
  final String title;
  final String prompt;
  final String sentence;
  final List<String> options;
  final int correctIndex;
  final ActivityType type;
  final String correctFeedback;
  final String incorrectFeedback;
  final String ruleSummary;

  const ActivityModel({
    required this.id,
    required this.title,
    required this.prompt,
    required this.sentence,
    required this.options,
    required this.correctIndex,
    required this.type,
    required this.correctFeedback,
    required this.incorrectFeedback,
    required this.ruleSummary,
  });

  String get correctAnswer => options[correctIndex];
}
