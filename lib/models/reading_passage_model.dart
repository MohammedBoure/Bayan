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
  final List<String> targetWords;

  const GrammarDiscoveryModel({
    required this.triggerSentences,
    required this.observationPrompt,
    required this.observations,
    this.targetedPattern = '',
    this.targetWords = const [],
  });

  List<String> get allTargetWords {
    if (targetWords.isNotEmpty) return targetWords;
    if (targetedPattern.isEmpty) return const [];
    return targetedPattern
        .split(RegExp(r'\s*[-–—]\s*'))
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();
  }
}

/// Represents an audio track for a reading passage (whole text or specific paragraphs).
class ReadingAudioTrack {
  final String title;
  final String assetPath;
  final List<int> paragraphIndices;

  const ReadingAudioTrack({
    required this.title,
    required this.assetPath,
    this.paragraphIndices = const [],
  });
}

/// Represents an item for substituting a highlighted word with its synonym (عَوِّضِ الكَلِمَةَ بِمُرَادِفِهَا).
class SynonymReplacementItem {
  final String sentence;
  final String highlightedWord;
  final String replacementWord;
  final String? note;

  const SynonymReplacementItem({
    required this.sentence,
    required this.highlightedWord,
    required this.replacementWord,
    this.note,
  });
}

/// Represents a complementary word pair item (جِدِ الكَلِمَتَيْنِ المُتَكَامِلَتَيْنِ).
class ComplementaryPairItem {
  final String firstPart;
  final String secondPart;
  final String fullPhrase;
  final String note;

  const ComplementaryPairItem({
    required this.firstPart,
    required this.secondPart,
    this.fullPhrase = '',
    this.note = '',
  });
}

/// Represents a morphological derivation item (ائْتِ بِمُشْتَقَّاتٍ عَلَى وَزْنِ...).
class MorphologicalDerivationItem {
  final String rootVerb;
  final String pastForm;
  final String activeParticiple;
  final String verbalNoun;
  final String passiveParticiple;
  final String note;

  const MorphologicalDerivationItem({
    required this.rootVerb,
    required this.pastForm,
    required this.activeParticiple,
    required this.verbalNoun,
    required this.passiveParticiple,
    this.note = '',
  });
}

/// Represents the textbook linguistic enrichment section (أُثْرِي لُغَتِي).
class LinguisticEnrichmentModel {
  final String title;
  final String pairPrompt;
  final List<ComplementaryPairItem> complementaryPairs;
  final List<String> availablePairTargets;
  final String derivationPrompt;
  final String derivationPatternExample;
  final List<MorphologicalDerivationItem> derivations;

  const LinguisticEnrichmentModel({
    this.title = 'أُثْرِي لُغَتِي',
    this.pairPrompt = 'انْقُلْ ثُمَّ أَنْجِزْ. جِدِ الْكَلِمَتَيْنِ الْمُتَكَامِلَتَيْنِ:',
    this.complementaryPairs = const [],
    this.availablePairTargets = const [],
    this.derivationPrompt = 'ائْتِ بِمُشْتَقَّاتٍ عَلَى وَزْنِ: (اشْتَرَكَ / مُشْتَرِكٌ / اشْتِرَاكٌ / مُشْتَرَكٌ) لِلأَفْعَالِ التَّالِيَةِ:',
    this.derivationPatternExample = 'اشْتَرَكَ / مُشْتَرِكٌ / اشْتِرَاكٌ / مُشْتَرَكٌ',
    this.derivations = const [],
  });

  bool get hasPairs => complementaryPairs.isNotEmpty;
  bool get hasDerivations => derivations.isNotEmpty;
}

/// Represents an item for matching a word to its meaning (اخْتَرْ لِكُلِّ كَلِمَةٍ مَعْنَاهَا).
class WordMeaningMatchItem {
  final String word;
  final String meaning;
  final String? note;

  const WordMeaningMatchItem({
    required this.word,
    required this.meaning,
    this.note,
  });
}

/// Represents the reading text and authentic context anchoring the grammar lesson.
class ReadingPassageModel {
  final String title;
  final String author;
  final List<String> paragraphs;
  final List<VocabularyItem> vocabulary;
  final List<ComprehensionQuestion> comprehensionQuestions;
  final List<ReadingAudioTrack> audioTracks;
  final List<String> availableSynonyms;
  final List<SynonymReplacementItem> synonymReplacements;
  final String meaningMatchPrompt;
  final List<String> availableMeanings;
  final List<WordMeaningMatchItem> meaningMatches;
  final LinguisticEnrichmentModel? enrichment;

  const ReadingPassageModel({
    required this.title,
    this.author = '',
    required this.paragraphs,
    required this.vocabulary,
    required this.comprehensionQuestions,
    this.audioTracks = const [],
    this.availableSynonyms = const [],
    this.synonymReplacements = const [],
    this.meaningMatchPrompt = 'اخْتَرْ لِكُلِّ كَلِمَةٍ مَعْنَاهَا:',
    this.availableMeanings = const [],
    this.meaningMatches = const [],
    this.enrichment,
  });

  String get fullText => paragraphs.join('\n\n');
  bool get hasAudio => audioTracks.isNotEmpty;
  bool get hasSynonyms => synonymReplacements.isNotEmpty;
  bool get hasMeaningMatches => meaningMatches.isNotEmpty;
  bool get hasEnrichment => enrichment != null;
}
