import '../models/nlp_token_model.dart';
import '../services/nlp_database_service.dart';
import 'arabic_clitic_stemmer.dart';
import 'arabic_hybrid_parser.dart';

/// المحرك الرئيسي للسانيات الحاسوبية العربية (Arabic Computational Linguistics Engine).
/// يدمج بين المحلل الهجين (Rule Engine + Bigram Context)
/// ونظام التخزين المؤقت وقاعدة بيانات التصحيحات التفاعلية (Feedback Loop).
class ArabicLinguisticsEngine {
  static const String fatha = '\u064E';
  static const String damma = '\u064F';
  static const String kasra = '\u0650';
  static const String sukun = '\u0652';
  static const String shaddah = '\u0651';
  static const String tanwinFath = '\u064B';
  static const String tanwinDamm = '\u064C';
  static const String tanwinKasr = '\u064D';

  /// إزالة التشكيل
  static String stripDiacritics(String input) => ArabicCliticStemmer.stripDiacritics(input);

  /// توحيد الحروف
  static String normalize(String input) => ArabicCliticStemmer.normalize(input);

  /// تقطيع النص إلى كلمات
  static List<String> tokenize(String sentence) {
    return sentence
        .trim()
        .split(RegExp(r'[\s،.!؟؛:]+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// تحليل نحوي وصرفي ذكي غير متزامن يستشير قاعدة البيانات والكاش أولاً
  static Future<ParseResult> parseSentenceAsync(String sentence) async {
    final cachedTokens = await NlpDatabaseService.instance.lookupSentence(sentence);
    if (cachedTokens != null && cachedTokens.isNotEmpty) {
      return ParseResult(
        tokens: cachedTokens,
        type: SentenceType.nominal,
        typeArabic: 'مُسْتَرْجَعٌ مِنْ قَاعِدَةِ البَيَانَاتِ النَّمُوذَجِيَّةِ',
      );
    }

    final overrides = NlpDatabaseService.instance.currentOverrides;
    final result = ArabicHybridParser.parse(sentence, userOverrides: overrides);

    // حفظ التحليل في الكاش المحلي للمرات القادمة
    final diacritized = autoDiacritizeSentence(sentence);
    await NlpDatabaseService.instance.saveParsedSentence(
      sentence,
      result.tokens,
      result.typeArabic,
      diacritized,
    );

    return result;
  }

  /// تحليل نحوي متزامن بالاعتماد على المحلل الهجين والتصحيحات الفورية
  static List<NlpToken> parseVerbalSentence(String sentence) {
    final overrides = NlpDatabaseService.instance.currentOverrides;
    final result = ArabicHybridParser.parse(sentence, userOverrides: overrides);
    return result.tokens;
  }

  /// التشكيل وضبط الإعراب الآلي الذكي (المُشكّل الآلي)
  static String autoDiacritizeSentence(String sentence) {
    final parseResult = ArabicHybridParser.parse(
      sentence,
      userOverrides: NlpDatabaseService.instance.currentOverrides,
    );
    final diacritizedWords = <String>[];

    for (final token in parseResult.tokens) {
      var word = token.plainWord;

      // إذا كانت الكلمة مشكولة أصلاً بتنوين نحتفظ بتشكيلها
      if (token.word.contains(tanwinFath) || token.word.contains(tanwinDamm) || token.word.contains(tanwinKasr)) {
        diacritizedWords.add(token.word);
        continue;
      }

      if (token.subType == 'مبتدأ' || token.subType?.contains('فاعل') == true) {
        word = '$word$damma';
      } else if (token.subType?.contains('خبر المبتدأ') == true) {
        word = '$word$tanwinDamm';
      } else if (token.subType?.contains('مفعول به') == true) {
        word = '$word$fatha';
      } else if (token.subType?.contains('مفعول مطلق') == true) {
        word = '$word$tanwinFath';
      } else if (token.subType?.contains('اسم مجرور') == true) {
        word = '$word$kasra';
      } else if (token.pos == 'فعل') {
        if (token.subType?.contains('ماض') == true) {
          word = '$word$fatha';
        } else if (token.subType?.contains('مضارع') == true) {
          word = '$word$damma';
        } else if (token.subType?.contains('أمر') == true) {
          word = '$word$sukun';
        }
      }

      diacritizedWords.add(word);
    }

    return diacritizedWords.join(' ');
  }

  /// المدقق النحوي والصرفي الآلي
  static List<GrammarIssue> checkGrammar(String sentence) {
    final issues = <GrammarIssue>[];
    final parsed = ArabicHybridParser.parse(sentence).tokens;

    for (int i = 0; i < parsed.length; i++) {
      final token = parsed[i];
      final word = token.word;

      // 1. فحص حركة الفاعل إن كُتب خطأً بالفتح أو الكسر
      if (token.subType == 'فاعل' || token.subType == 'مبتدأ') {
        if (word.endsWith(fatha) || word.endsWith(tanwinFath)) {
          issues.add(GrammarIssue(
            word: word,
            rule: '${token.subType} مرفوع دائماً وعلامته الضمة',
            suggestion: 'كلمة "$word" جاءت ${token.subType}، لذا يجب أن تُضبط بالضمة وليس الفتحة.',
            type: GrammarIssueType.subjectCaseError,
          ));
        } else if (word.endsWith(kasra) || word.endsWith(tanwinKasr)) {
          issues.add(GrammarIssue(
            word: word,
            rule: '${token.subType} مرفوع وعلامته الضمة',
            suggestion: '${token.subType} لا يكون مجروراً بالكسرة؛ بل مرفوعاً بالضمة.',
            type: GrammarIssueType.subjectCaseError,
          ));
        }
      }

      // 2. فحص حركة المفعول به إن كُتب خطأً بالضم
      if (token.subType == 'مفعول به') {
        if (word.endsWith(damma) || word.endsWith(tanwinDamm)) {
          issues.add(GrammarIssue(
            word: word,
            rule: 'المفعول به منصوب دائماً وعلامته الفتحة',
            suggestion: 'كلمة "$word" مفعول به، وحكمه النصب بالفتحة (ـَ) وليس الرفع بالضمة.',
            type: GrammarIssueType.objectCaseError,
          ));
        }
      }

      // 3. فحص حرف الجر مع الفعل
      if (i > 0 && parsed[i - 1].subType == 'حرف جر' && token.pos == 'فعل') {
        issues.add(GrammarIssue(
          word: word,
          rule: 'حروف الجر تختص بالدخول على الأسماء فقط',
          suggestion: 'لا يجوز دخول حرف الجر على الفعل، فالجر من علامات الأسماء.',
          type: GrammarIssueType.prepositionWithVerb,
        ));
      }
    }

    return issues;
  }
}

enum GrammarIssueType {
  subjectCaseError,
  objectCaseError,
  prepositionWithVerb,
  spellingError,
}

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
