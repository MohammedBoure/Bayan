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
  sentenceMultiChoice,
  writtenParsing,
  openSentenceFill,
  textExtractionTable,
  sentenceTargetTap,
  sentencePartsAnalysis,
  textWordExtraction,
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

  // Advanced grammatical activities (Sentence Multiple Choice, Written Parsing, Open Sentence Fill, Extraction Table, Target Tap)
  final Map<String, List<String>>? sentenceChoiceOptions;
  final Map<String, String>? coloredWordsMap;
  final Map<String, List<String>>? acceptableAnswersMap;
  final List<Map<String, String>>? tableRows;
  final List<String>? tableHeaders;
  final String? tableTitle;
  final String? passageTitle;
  final bool showSuggestions;
  final Map<String, Map<String, String>>? sentencePartsMap;
  final List<String>? targetWordsList;
  final String? instructionHeader;
  final String? errorHintMessage;
  final bool allowNoneOption;
  final String noneOptionText;
  final List<String>? helperChips;

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
    this.sentenceChoiceOptions,
    this.coloredWordsMap,
    this.acceptableAnswersMap,
    this.tableRows,
    this.tableHeaders,
    this.tableTitle,
    this.passageTitle,
    this.showSuggestions = true,
    this.sentencePartsMap,
    this.targetWordsList,
    this.instructionHeader,
    this.errorHintMessage,
    this.allowNoneOption = false,
    this.noneOptionText = 'لا يُوجَدُ فِعْلٌ مَبْنِيٌّ لِلْمَجْهُولِ',
    this.helperChips,
  });

  String get correctAnswer => options.isNotEmpty && correctIndex >= 0 && correctIndex < options.length
      ? options[correctIndex]
      : '';
}
