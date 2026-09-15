import '../models/nlp_token_model.dart';
import 'arabic_clitic_stemmer.dart';
import 'arabic_lexicon.dart';

enum SentenceType {
  nominal,          // جملة اسمية (مبتدأ وخبر)
  verbal,           // جملة فعلية تامة (فعل وفاعل ومفعول به)
  kanaCopula,       // جملة ناسخة بفعل ناقص (كان وأخواتها)
  innaCopula,       // جملة ناسخة بحرف (إن وأخواتها)
  prepositional,    // شبه جملة (جار ومجرور مقدم)
  unknown,
}

/// محلل نحوي وإعرابي هجين وخفيف يعمل بدون إنترنت (Offline Rule Engine with Bigram Context).
class ArabicHybridParser {
  /// تحليل متكامل للجملة العربية بالاعتماد على شجرة القرار وفحص السياق الثنائي
  static ParseResult parse(String sentence, {Map<String, NlpToken>? userOverrides}) {
    final words = sentence
        .trim()
        .split(RegExp(r'[\s،.!؟؛:]+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return const ParseResult(tokens: [], type: SentenceType.unknown, typeArabic: 'غير محدد');
    }

    final cliticResults = words.map((w) => ArabicCliticStemmer.analyzeWord(w)).toList();
    final sentenceType = _classifySentence(words, cliticResults);
    final List<NlpToken> tokens = [];

    for (int i = 0; i < words.length; i++) {
      final rawWord = words[i];
      final norm = ArabicCliticStemmer.normalize(rawWord);

      // الأولوية القصوى (Override Priority): إذا كان هناك تعديل يدوي من المستخدم
      if (userOverrides != null && userOverrides.containsKey(norm)) {
        tokens.add(userOverrides[norm]!);
        continue;
      }

      // تحليل الكلمة في سياق الجملة
      final token = _parseWordInContext(
        index: i,
        words: words,
        clitics: cliticResults,
        sentenceType: sentenceType,
        prevToken: i > 0 ? tokens[i - 1] : null,
      );
      tokens.add(token);
    }

    return ParseResult(
      tokens: tokens,
      type: sentenceType,
      typeArabic: _getSentenceTypeName(sentenceType),
    );
  }

  /// شجرة القرار لتحديد نوع الجملة (Sentence Classification)
  static SentenceType _classifySentence(List<String> words, List<CliticResult> clitics) {
    if (words.isEmpty) return SentenceType.unknown;

    final firstWord = words[0];
    final firstClitic = clitics[0];
    final normFirst = ArabicCliticStemmer.normalize(firstWord);

    // 1. فحص الحروف الناسخة (إن وأخواتها)
    if (ArabicLexicon.isInna(firstWord)) {
      return SentenceType.innaCopula;
    }

    // 2. فحص الأفعال الناسخة (كان وأخواتها أو أليس)
    if (ArabicLexicon.isKana(firstWord) || firstClitic.isInterrogative || normFirst == 'اليس' || normFirst == 'ليس') {
      return SentenceType.kanaCopula;
    }

    // 3. فحص حروف الجر الصريحة في بداية الجملة (شبه جملة)
    if (ArabicLexicon.isPreposition(firstWord) || firstClitic.proclitics.contains('ب') || firstClitic.proclitics.contains('ل')) {
      return SentenceType.prepositional;
    }

    // 4. فحص علامات الاسمية القطعية في الكلمة الأولى
    if (firstClitic.isDefinitelyNoun ||
        ArabicLexicon.isInherentNoun(firstWord) ||
        ArabicLexicon.isDemonstrative(firstWord) ||
        ArabicLexicon.isPersonalPronoun(firstWord)) {
      return SentenceType.nominal;
    }

    // 5. فحص السياق الثنائي (Bigram Context Check): نكرة + صفة مشتقة نكرة
    // مثال: "منزلٌ كبيرٌ" أو "بحرٌ واسعٌ" -> يستحيل أن تكون الكلمة الأولى فعلاً!
    if (words.length >= 2) {
      final secondWord = words[1];
      if (ArabicLexicon.isCommonAdjective(secondWord) && !ArabicLexicon.isPreposition(secondWord)) {
        return SentenceType.nominal; // إثبات الاسمية بالسياق الثنائي
      }
    }

    // 6. فحص علامات الفعل الصريحة
    if (firstClitic.proclitics.contains('س (استقبال)') ||
        normFirst.startsWith('ي') ||
        normFirst.startsWith('ت') ||
        normFirst.startsWith('ن') ||
        normFirst.startsWith('اكتب') ||
        normFirst.startsWith('اقر') ||
        normFirst.startsWith('اجلس') ||
        normFirst.startsWith('احفظ')) {
      return SentenceType.verbal;
    }

    // إذا لم تكن أي علامة اسم، واحتملت الوزن الثلاثي فَعَلَ
    return SentenceType.verbal;
  }

  /// إعراب الكلمة وفق سياقها النحوي
  static NlpToken _parseWordInContext({
    required int index,
    required List<String> words,
    required List<CliticResult> clitics,
    required SentenceType sentenceType,
    required NlpToken? prevToken,
  }) {
    final word = words[index];
    final clitic = clitics[index];
    final norm = ArabicCliticStemmer.normalize(word);
    final plain = ArabicCliticStemmer.stripDiacritics(word);

    // أ. فحص الحالات المعجمية الخاصة الشائعة (الظروف، الاستفهام، أسماء الإشارة)
    if (ArabicLexicon.isAdverb(word) || norm == 'جدا' || norm == 'ايضا') {
      return NlpToken(
        word: word,
        plainWord: plain,
        pos: 'اسم',
        subType: 'مفعول مطلق / ظرف توكيد',
        caseMark: 'منصوب وعلامة نصبه الفتحة الظاهرة',
        explanation: 'كلمة تُعرب مفعولاً مطلقاً لفعل محذوف (جَدَّ جِدّاً) أو ظرفاً يفيد التوكيد.',
      );
    }

    if (norm == 'اليس' || norm == 'ليس' || clitic.isInterrogative) {
      return NlpToken(
        word: word,
        plainWord: plain,
        pos: 'فعل',
        subType: 'همزة استفهام + فعل ماضٍ ناقص',
        caseMark: 'مبني على الفتح الظاهر',
        explanation: 'الهمزة حرف استفهام، وليس فعل ماضٍ ناقص جامد من أخوات كان يفيد النفي.',
      );
    }

    if (norm == 'كذلك' || (word.startsWith('ك') && norm.endsWith('ذلك'))) {
      return NlpToken(
        word: word,
        plainWord: plain,
        pos: 'شبه جملة',
        subType: 'جار ومجرور (كاف التشبيه + اسم إشارة)',
        caseMark: 'شبه جملة في محل نصب خبر ليس',
        explanation: 'الكاف حرف جر وتشبيه، و"ذا" اسم إشارة في محل جر، واللام للبعد والكاف للخطاب.',
      );
    }

    if (ArabicLexicon.isPreposition(word)) {
      return NlpToken(
        word: word,
        plainWord: plain,
        pos: 'حرف',
        subType: 'حرف جر',
        caseMark: 'مبني لا محل له من الإعراب',
        explanation: 'حرف جر يدخل على الأسماء ويجر ما بعده بالكسرة.',
      );
    }

    if (prevToken != null && prevToken.subType == 'حرف جر') {
      return NlpToken(
        word: word,
        plainWord: plain,
        pos: 'اسم',
        subType: 'اسم مجرور',
        caseMark: 'مجرور وعلامة جره الكسرة الظاهرة',
        explanation: 'اسم واقع بعد حرف الجر وحكمه الجر.',
      );
    }

    // ب. تحليل الجملة الاسمية (مبتدأ وخبر)
    if (sentenceType == SentenceType.nominal) {
      if (index == 0) {
        return NlpToken(
          word: word,
          plainWord: plain,
          pos: 'اسم',
          subType: 'مبتدأ',
          caseMark: 'مرفوع وعلامة رفعه الضمة الظاهرة',
          explanation: 'المبتدأ هو الاسم المرفوع المعرف أو الموصوف الذي تبدأ به الجملة الاسمية.',
          isTarget: true,
        );
      } else if (index == 1) {
        final isAdjective = ArabicLexicon.isCommonAdjective(word);
        return NlpToken(
          word: word,
          plainWord: plain,
          pos: 'اسم',
          subType: 'خبر المبتدأ',
          caseMark: 'مرفوع وعلامة رفعه الضمة الظاهرة',
          explanation: isAdjective
              ? 'خبر المبتدأ جاء وصفاً متمماً لمعنى المبتدأ، وحكمه الرفع بالضمة.'
              : 'الخبر هو الجزء المتمم لمعنى المبتدأ وبه تكمل فائدة الجملة.',
          isTarget: true,
        );
      }
    }

    // ج. تحليل الجملة الفعلية الناسخة (كان وأخواتها)
    if (sentenceType == SentenceType.kanaCopula) {
      if (index == 0) {
        return NlpToken(
          word: word,
          plainWord: plain,
          pos: 'فعل',
          subType: 'فعل ماضٍ ناقص',
          caseMark: 'مبني على الفتح',
          explanation: 'من أخوات كان، يرفع المبتدأ ويسمى اسمه وينصب الخبر ويسمى خبره.',
        );
      } else if (index == 1) {
        return NlpToken(
          word: word,
          plainWord: plain,
          pos: 'اسم',
          subType: 'اسم كان (أو إحدى أخواتها)',
          caseMark: 'مرفوع وعلامة رفعه الضمة الظاهرة',
          explanation: 'اسم الفعل الناسخ المرفوع بالضمة.',
        );
      } else if (index == 2) {
        return NlpToken(
          word: word,
          plainWord: plain,
          pos: 'اسم',
          subType: 'خبر كان (أو إحدى أخواتها)',
          caseMark: 'منصوب وعلامة نصبه الفتحة الظاهرة',
          explanation: 'خبر الفعل الناسخ المنصوب بالفتحة.',
        );
      }
    }

    // د. تحليل الجملة الفعلية التامة (فعل + فاعل + مفعول به)
    if (sentenceType == SentenceType.verbal) {
      if (index == 0) {
        String tense = 'ماضٍ';
        String mark = 'مبني على الفتح الظاهر';
        if (norm.startsWith('ي') || norm.startsWith('ت') || norm.startsWith('ن') || clitic.proclitics.contains('س (استقبال)')) {
          tense = 'مضارع';
          mark = 'مرفوع وعلامة رفعه الضمة الظاهرة';
        } else if (norm.startsWith('اقر') || norm.startsWith('اكتب') || norm.startsWith('احفظ') || norm.startsWith('اجلس')) {
          tense = 'أمر';
          mark = 'مبني على السكون';
        }
        return NlpToken(
          word: word,
          plainWord: plain,
          pos: 'فعل',
          subType: 'فعل $tense',
          caseMark: mark,
          explanation: 'الركن الأول في الجملة الفعلية، ويدل على حدث مرتبط بزمن.',
          isTarget: true,
        );
      } else if (index == 1) {
        return NlpToken(
          word: word,
          plainWord: plain,
          pos: 'اسم',
          subType: 'فاعل',
          caseMark: 'مرفوع وعلامة رفعه الضمة الظاهرة',
          explanation: 'الفاعل هو الاسم المرفوع الذي قام بالفعل.',
          isTarget: true,
        );
      } else if (index == 2) {
        return NlpToken(
          word: word,
          plainWord: plain,
          pos: 'اسم',
          subType: 'مفعول به',
          caseMark: 'منصوب وعلامة نصبه الفتحة الظاهرة',
          explanation: 'المفعول به هو الاسم المنصوب الذي وقع عليه فعل الفاعل.',
          isTarget: true,
        );
      }
    }

    // هـ. الحالة العامة الاحتياطية الذكية
    final isNoun = clitic.isDefinitelyNoun || ArabicLexicon.isInherentNoun(word);
    return NlpToken(
      word: word,
      plainWord: plain,
      pos: isNoun ? 'اسم' : 'كلمة',
      subType: isNoun ? 'ركن متمم / تابع' : 'عنصر في الجملة',
      caseMark: 'حسب موقعه وسياقه الإعرابي',
      explanation: 'كلمة في الجملة تساهم في اكتمال المعنى والدلالة.',
    );
  }

  static String _getSentenceTypeName(SentenceType type) {
    switch (type) {
      case SentenceType.nominal:
        return 'جُمْلَةٌ اسْمِيَّةٌ (مُبْتَدَأٌ وَخَبَرٌ)';
      case SentenceType.verbal:
        return 'جُمْلَةٌ فِعْلِيَّةٌ (فِعْلٌ وَفَاعِلٌ)';
      case SentenceType.kanaCopula:
        return 'جُمْلَةٌ فِعْلِيَّةٌ نَاسِخَةٌ (كَانَ وَأَخَوَاتُهَا)';
      case SentenceType.innaCopula:
        return 'جُمْلَةٌ اسْمِيَّةٌ مَنْسُوخَةٌ (إِنَّ وَأَخَوَاتُهَا)';
      case SentenceType.prepositional:
        return 'جُمْلَةٌ مُبْتَدَأَةٌ بِشِبْهِ جُمْلَةٍ (جَارٌّ وَمَجْرُورٌ)';
      case SentenceType.unknown:
        return 'تَرْكِيبٌ لُغَوِيٌّ';
    }
  }
}

/// نتيجة تحليل الجملة
class ParseResult {
  final List<NlpToken> tokens;
  final SentenceType type;
  final String typeArabic;

  const ParseResult({
    required this.tokens,
    required this.type,
    required this.typeArabic,
  });
}
