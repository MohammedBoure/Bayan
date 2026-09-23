enum ActivityType {
  selectVerb,
  selectSubject,
  selectObject,
  classifyVerbTense,
  fillInTheBlank,
  orderSentence,
  multipleChoice,
  dragDropFillBlank,
  categorizationTwoCols,
  categorizationThreeCols,
  sentenceOrdering,
  imageMatching,
  multiSelect,
  multiSentenceFill,
  multiSentenceOrder,
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

  // Rich interaction support (Categorization, Ordering, Image matching)
  final List<String>? categories;
  final Map<String, List<String>>? categorizedItems;
  final List<String>? availableWords;
  final List<String>? orderedWords;
  final Map<String, String>? imagePairs;

  // Multi-item & classroom board interaction support
  final List<int>? correctIndices;
  final List<String>? sentenceItems;
  final Map<String, String>? sentenceSolutions;
  final Map<String, List<String>>? sentenceWordsMap;
  final Map<String, List<String>>? sentenceOrderedMap;
  final String? contextParagraph;

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
    this.categories,
    this.categorizedItems,
    this.availableWords,
    this.orderedWords,
    this.imagePairs,
    this.correctIndices,
    this.sentenceItems,
    this.sentenceSolutions,
    this.sentenceWordsMap,
    this.sentenceOrderedMap,
    this.contextParagraph,
  });

  String get correctAnswer => options.isNotEmpty && correctIndex >= 0 && correctIndex < options.length
      ? options[correctIndex]
      : '';
}
