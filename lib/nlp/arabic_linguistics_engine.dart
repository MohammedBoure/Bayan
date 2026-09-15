import '../models/nlp_token_model.dart';

/// Computational Linguistics Engine for Arabic Grammar in Primary Education.
/// Implements morphological analysis, part-of-speech tagging, syntactic parsing,
/// diacritics management, and grammatical error checking with intelligent feedback.
class ArabicLinguisticsEngine {
  // Common Arabic diacritics Unicode codepoints
  static const String fatha = '\u064E';
  static const String damma = '\u064F';
  static const String kasra = '\u0650';
  static const String sukun = '\u0652';
  static const String shaddah = '\u0651';
  static const String tanwinFath = '\u064B';
  static const String tanwinDamm = '\u064C';
  static const String tanwinKasr = '\u064D';

  static final RegExp _diacriticsRegex = RegExp(
    r'[\u064B-\u0652\u0670\u0640]',
  );

  // Common prepositions (حروف الجر)
  static const List<String> prepositions = [
    'من', 'مِنْ', 'إلى', 'إِلَى', 'عن', 'عَنْ', 'على', 'عَلَى',
    'في', 'فِي', 'رب', 'رُبَّ', 'الباء', 'اللام', 'الكاف',
  ];

  // Common particles of accusative (نواصب المضارع)
  static const List<String> accusativeParticles = [
    'أن', 'أَنْ', 'لن', 'لَنْ', 'كي', 'كَيْ', 'إذن', 'إِذَنْ', 'حتى', 'حَتَّى'
  ];

  // Common particles of jussive (جوازم المضارع)
  static const List<String> jussiveParticles = [
    'لم', 'لَمْ', 'لما', 'لَمَّا', 'لا الناهية', 'لام الأمر'
  ];

  /// Strips all tashkeel (diacritics) from an Arabic string.
  static String stripDiacritics(String input) {
    return input.replaceAll(_diacriticsRegex, '');
  }

  /// Normalizes Arabic characters (alifs, teh marbuta, etc.)
  static String normalize(String input) {
    var text = stripDiacritics(input);
    text = text.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
    text = text.replaceAll('ى', 'ي');
    text = text.replaceAll('ة', 'ه');
    return text.trim();
  }

  /// Tokenizes a sentence into a list of words.
  static List<String> tokenize(String sentence) {
    return sentence
        .trim()
        .split(RegExp(r'[\s،.!؟؛:]+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// Evaluates whether a word is a particle (حرف).
  static bool isParticle(String word) {
    final clean = normalize(word);
    const particles = [
      'في', 'من', 'الي', 'علي', 'عن', 'ثم', 'او', 'بل', 'لكن',
      'ان', 'لن', 'كي', 'لم', 'لما', 'قد', 'سوف', 'هل', 'ما', 'لا'
    ];
    return particles.contains(clean);
  }

  /// Evaluates whether a word has prominent noun markers (علامات الاسم).
  static bool hasNounMarkers(String word) {
    final raw = word.trim();
    final clean = normalize(raw);

    // Starts with definite article 'ال'
    if (clean.startsWith('ال') && clean.length > 3) return true;

    // Ends with teh marbuta 'ة'
    if (raw.endsWith('ة') || raw.endsWith('َة') || raw.endsWith('ُة') || raw.endsWith('ِة')) return true;

    // Has tanwin
    if (raw.contains(tanwinFath) || raw.contains(tanwinDamm) || raw.contains(tanwinKasr)) return true;

    return false;
  }

  /// Classifies the tense of an Arabic verb (ماضٍ، مضارع، أمر).
  static String classifyVerbTense(String word) {
    final clean = normalize(word);

    // Imperative clues (often starts with ا followed by imperative patterns or direct request)
    if (clean.startsWith('ا') && (clean.length == 4 || clean.length == 5)) {
      if (clean.startsWith('اقر') || clean.startsWith('اكتب') || clean.startsWith('اجلس') ||
          clean.startsWith('احفظ') || clean.startsWith('انتبه') || clean.startsWith('اسمع')) {
        return 'أمر';
      }
    }

    // Present tense clues (starts with حروف أنيت: أ، ن، ي، ت)
    if (clean.startsWith('ي') || clean.startsWith('ت') || clean.startsWith('ن') || clean.startsWith('س')) {
      if (clean.length >= 3) {
        return 'مضارع';
      }
    }

    // Default for 3-letter or common past verbs
    return 'ماضٍ';
  }

  /// Morpho-syntactically analyzes an educational verbal sentence (الجملة الفعلية).
  /// Designed to empower elementary students with computational parsing.
  static List<NlpToken> parseVerbalSentence(String sentence) {
    final tokens = tokenize(sentence);
    final List<NlpToken> results = [];

    for (int i = 0; i < tokens.length; i++) {
      final current = tokens[i];
      final clean = normalize(current);

      if (isParticle(current)) {
        results.add(NlpToken(
          word: current,
          plainWord: stripDiacritics(current),
          pos: 'حرف',
          subType: 'حرف جر أو عطف أو نفي',
          caseMark: 'مبني لا محل له من الإعراب',
          explanation: 'الحرف كلمة لا يظهر معناها كاملاً إلا مع غيرها في الجملة.',
        ));
        continue;
      }

      // In elementary verbal sentences, the first non-particle word is typically the Verb
      if (i == 0 || (i == 1 && results.isNotEmpty && results.first.pos == 'حرف')) {
        final tense = classifyVerbTense(current);
        String caseInfo = 'مبني على الفتح';
        String exp = 'الفعل الماضي يدل على عمل حدث وانتهى في الزمن الماضي.';

        if (tense == 'مضارع') {
          caseInfo = 'مرفوع وعلامة رفعه الضمة الظاهرة';
          exp = 'الفعل المضارع يدل على حدث يقع الآن في الحاضر أو سيقع في المستقبل.';
        } else if (tense == 'أمر') {
          caseInfo = 'مبني على السكون';
          exp = 'فعل الأمر يدل على طلب القيام بعمل في المستقبل.';
        }

        results.add(NlpToken(
          word: current,
          plainWord: stripDiacritics(current),
          pos: 'فعل',
          subType: 'فعل $tense',
          caseMark: caseInfo,
          explanation: exp,
          isTarget: true,
        ));
        continue;
      }

      // Check if preceded by a preposition
      final prev = i > 0 ? results[i - 1] : null;
      if (prev != null && prev.pos == 'حرف' && (clean != 'لا' && clean != 'قد' && clean != 'سوف')) {
        results.add(NlpToken(
          word: current,
          plainWord: stripDiacritics(current),
          pos: 'اسم',
          subType: 'اسم مجرور',
          caseMark: 'مجرور وعلامة جره الكسرة الظاهرة',
          explanation: 'الاسم الواقع بعد حرف الجر يسمى اسماً مجروراً وتكون علامة جره الكسرة.',
        ));
        continue;
      }

      // Detect Subject (الفاعل): typically follows verb
      final hasVerbBefore = results.any((t) => t.pos == 'فعل');
      final hasSubjectBefore = results.any((t) => t.subType == 'فاعل');

      if (hasVerbBefore && !hasSubjectBefore) {
        results.add(NlpToken(
          word: current,
          plainWord: stripDiacritics(current),
          pos: 'اسم',
          subType: 'فاعل',
          caseMark: 'مرفوع وعلامة رفعه الضمة الظاهرة',
          explanation: 'الفاعل هو الاسم المرفوع الذي يدل على من قام بالفعل أو اتصف به.',
        ));
        continue;
      }

      // Detect Object (المفعول به): typically follows subject
      if (hasVerbBefore && hasSubjectBefore) {
        results.add(NlpToken(
          word: current,
          plainWord: stripDiacritics(current),
          pos: 'اسم',
          subType: 'مفعول به',
          caseMark: 'منصوب وعلامة نصبه الفتحة الظاهرة',
          explanation: 'المفعول به هو الاسم المنصوب الذي وقع عليه فعل الفاعل.',
        ));
        continue;
      }

      // General fallback
      results.add(NlpToken(
        word: current,
        plainWord: stripDiacritics(current),
        pos: hasNounMarkers(current) ? 'اسم' : 'كلمة',
        subType: 'ركن متمم للجملة',
        caseMark: 'حسب موقعه في الجملة',
        explanation: 'كلمة تكمل معنى الجملة وتوضح أركانها.',
      ));
    }

    return results;
  }

  /// Automated Diacritization and Tashkeel recommender for elementary verbal sentences.
  static String autoDiacritizeSentence(String sentence) {
    final tokens = parseVerbalSentence(sentence);
    final diacritizedWords = <String>[];

    for (final token in tokens) {
      var word = token.plainWord;
      if (token.pos == 'فعل') {
        if (token.subType?.contains('ماض') == true) {
          // Add fatha on end
          word = '$word$fatha';
        } else if (token.subType?.contains('مضارع') == true) {
          // Add damma on end
          word = '$word$damma';
        } else if (token.subType?.contains('أمر') == true) {
          // Add sukun on end
          word = '$word$sukun';
        }
      } else if (token.subType == 'فاعل') {
        // Subject has damma
        word = '$word$damma';
      } else if (token.subType == 'مفعول به') {
        // Object has fatha
        word = '$word$fatha';
      } else if (token.subType == 'اسم مجرور') {
        // Genitive has kasra
        word = '$word$kasra';
      }
      diacritizedWords.add(word);
    }

    return diacritizedWords.join(' ');
  }

  /// Automated Grammatical & Morphological Checker (المدقق النحوي والصرفي الآلي).
  /// Checks whether a sentence complies with primary school grammar rules.
  static List<GrammarIssue> checkGrammar(String sentence) {
    final issues = <GrammarIssue>[];
    final words = tokenize(sentence);

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final clean = normalize(word);

      // Check 1: Verb directly after preposition
      if (i > 0) {
        final prev = normalize(words[i - 1]);
        if (prepositions.map(normalize).contains(prev)) {
          final isCleanVerb = !hasNounMarkers(word) && (clean.startsWith('ي') || clean.startsWith('ت'));
          if (isCleanVerb && !word.startsWith('ال')) {
            issues.add(GrammarIssue(
              word: word,
              rule: 'حروف الجر تدخل على الأسماء فقط',
              suggestion: 'تأكد من أن الكلمة بعد "$prev" هي اسم مجرور، وليس فعلاً.',
              type: GrammarIssueType.prepositionWithVerb,
            ));
          }
        }
      }

      // Check 2: Haraka on Subject (الفاعل) if user explicitly included fatha/kasra on what should be subject
      if (i == 1 && words.length >= 2) {
        if (word.endsWith(fatha) || word.endsWith(tanwinFath)) {
          issues.add(GrammarIssue(
            word: word,
            rule: 'الفاعل مرفوع دائماً وعلامته الضمة',
            suggestion: 'كلمة "$word" وقعت فاعلاً، لذا يجب أن تنتهي بالضمة وليس الفتحة.',
            type: GrammarIssueType.subjectCaseError,
          ));
        } else if (word.endsWith(kasra) || word.endsWith(tanwinKasr)) {
          issues.add(GrammarIssue(
            word: word,
            rule: 'الفاعل مرفوع وعلامته الضمة',
            suggestion: 'الفاعل لا يكون مجروراً بالكسرة هنا؛ بل مرفوع بالضمة.',
            type: GrammarIssueType.subjectCaseError,
          ));
        }
      }

      // Check 3: Haraka on Object (المفعول به) if user explicitly included damma on object
      if (i == 2 && words.length >= 3) {
        if (word.endsWith(damma) || word.endsWith(tanwinDamm)) {
          issues.add(GrammarIssue(
            word: word,
            rule: 'المفعول به منصوب دائماً وعلامته الفتحة',
            suggestion: 'كلمة "$word" مفعول به، وحكمه النصب بالفتحة (ـَ) وليس الرفع بالضمة.',
            type: GrammarIssueType.objectCaseError,
          ));
        }
      }
    }

    return issues;
  }

  /// Generates intelligent pedagogical feedback for student answers.
  static String generateFeedback({
    required bool isCorrect,
    required String targetWord,
    required String expectedRole,
    required String contextSentence,
  }) {
    if (isCorrect) {
      return 'أحسنت يا بطل! إجابة صحيحة وممتازة. كلمة "$targetWord" هي بالفعل $expectedRole في جملة "$contextSentence".';
    } else {
      return 'إجابة تحتاج إلى مراجعة. لاحظ جيداً: كلمة "$targetWord" ليست $expectedRole. تذكر أن الفعل يدل على عمل وزمن، والفاعل هو من قام بالعمل، والمفعول به هو من وقع عليه الفعل.';
    }
  }
}

enum GrammarIssueType {
  subjectCaseError,
  objectCaseError,
  prepositionWithVerb,
  spellingError,
}

/// Represents an identified grammar or morphology violation.
class GrammarIssue {
  final String word;
  final String rule;
  final String suggestion;
  final GrammarIssueType type;

  const GrammarIssue({
    required this.word,
    required this.rule,
    required this.suggestion,
    required this.type,
  });
}
