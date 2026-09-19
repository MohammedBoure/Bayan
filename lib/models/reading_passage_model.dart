/// Represents a single vocabulary item with its definition or antonym.
class VocabularyItem {
  final String word;
  final String explanation;
  final bool isAntonym;
  final String? root;

  const VocabularyItem({
    required this.word,
    required this.explanation,
    this.isAntonym = false,
    this.root,
  });
}

/// Represents a reading comprehension question for teacher-led classroom discussion.
class ComprehensionQuestion {
  final String question;
  final String modelAnswer;
  final List<String>? choices;
  final int? correctChoiceIndex;

  const ComprehensionQuestion({
    required this.question,
    required this.modelAnswer,
    this.choices,
    this.correctChoiceIndex,
  });

  bool get isMultipleChoice => choices != null && choices!.isNotEmpty;
}

/// Represents the inductive grammar observation stage (ألاحظ وأميز).
class GrammarDiscoveryModel {
  final List<String> triggerSentences;
  final String observationPrompt;
  final List<String> observations;
  final String targetedPattern;

  const GrammarDiscoveryModel({
    required this.triggerSentences,
    required this.observationPrompt,
    required this.observations,
    this.targetedPattern = '',
  });
}

/// Represents the reading text and authentic context anchoring the grammar lesson.
class ReadingPassageModel {
  final String title;
  final String author;
  final List<String> paragraphs;
  final List<VocabularyItem> vocabulary;
  final List<ComprehensionQuestion> comprehensionQuestions;

  const ReadingPassageModel({
    required this.title,
    this.author = '',
    required this.paragraphs,
    required this.vocabulary,
    required this.comprehensionQuestions,
  });

  String get fullText => paragraphs.join('\n\n');
}
