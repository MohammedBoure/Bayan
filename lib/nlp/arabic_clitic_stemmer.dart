/// نتيجة تجريد السوابق واللواحق لكلمة عربية.
class CliticResult {
  final String rawWord;
  final String cleanWord;
  final String stem;
  final List<String> proclitics; // السوابق (الـ، و، ف، ب، ك، ل، س، أ)
  final List<String> enclitics;  // اللواحق (الضمائر وعلامات الجمع/التأنيث)
  final bool hasDefiniteArticle;
  final bool hasTanwin;
  final bool hasTehMarbuta;
  final bool isDefinitelyNoun;
  final bool isInterrogative;

  const CliticResult({
    required this.rawWord,
    required this.cleanWord,
    required this.stem,
    required this.proclitics,
    required this.enclitics,
    required this.hasDefiniteArticle,
    required this.hasTanwin,
    required this.hasTehMarbuta,
    required this.isDefinitelyNoun,
    required this.isInterrogative,
  });
}

/// خوارزمية صرفية خفيفة لتجريد السوابق (Proclitics) واللواحق (Enclitics).
class ArabicCliticStemmer {
  static const String fatha = '\u064E';
  static const String damma = '\u064F';
  static const String kasra = '\u0650';
  static const String sukun = '\u0652';
  static const String shaddah = '\u0651';
  static const String tanwinFath = '\u064B';
  static const String tanwinDamm = '\u064C';
  static const String tanwinKasr = '\u064D';

  static final RegExp _diacriticsRegex = RegExp(r'[\u064B-\u0652\u0670\u0640]');

  /// إزالة التشكيل الكامل من النص
  static String stripDiacritics(String input) {
    return input.replaceAll(_diacriticsRegex, '');
  }

  /// توحيد الحروف (الهمزات والتاء المربوطة والياء) للمقارنة المعجمية
  static String normalize(String input) {
    var text = stripDiacritics(input);
    text = text.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
    text = text.replaceAll('ى', 'ي');
    text = text.replaceAll('ة', 'ه');
    return text.trim();
  }

  /// فحص وتجريد السوابق واللواحق من الكلمة
  static CliticResult analyzeWord(String word) {
    final raw = word.trim();
    final clean = stripDiacritics(raw);
    String working = clean;
    final List<String> proclitics = [];
    final List<String> enclitics = [];

    final hasTanwin = raw.contains(tanwinFath) || raw.contains(tanwinDamm) || raw.contains(tanwinKasr);
    final hasTehMarbuta = raw.endsWith('ة') || clean.endsWith('ة');

    // 1. فحص همزة الاستفهام الملتصقة (مثل: أليس، أتكتب، أقرأت)
    bool isInterrogative = false;
    if (working.startsWith('أ') || working.startsWith('ا')) {
      if (working.startsWith('أليس') || working.startsWith('اليس')) {
        proclitics.add('أ (استفهام)');
        working = working.substring(1);
        isInterrogative = true;
      }
    }

    // 2. فحص حروف العطف الملتصقة (و، ف) بشرط بقاء جذر الكلمة كافياً (أكثر من حرفين)
    if ((working.startsWith('و') || working.startsWith('ف')) && working.length >= 4) {
      // استثناء كلمات أصلية تبدأ بالواو/الفاء مثل: ورد، ولد، وقت، فاز، فرح، فصل
      const nonPrefixWords = {'ولد', 'ورد', 'وقت', 'وجه', 'وسط', 'وعد', 'وقوع', 'فرح', 'فصل', 'فكر', 'فوز', 'فهم', 'في'};
      if (!nonPrefixWords.contains(working)) {
        proclitics.add(working.substring(0, 1));
        working = working.substring(1);
      }
    }

    // 3. فحص أل التعريف (علامة قطعية للاسم)
    bool hasDefiniteArticle = false;
    if (working.startsWith('ال') && working.length >= 4) {
      // استثناء الكلمات التي أصلها "ال" مثل: الذي، التي، الذين، اللاتي
      if (!working.startsWith('الذي') && !working.startsWith('التي') && !working.startsWith('الذين')) {
        hasDefiniteArticle = true;
        proclitics.add('ال');
        working = working.substring(2);
      }
    }

    // 4. فحص حروف الجر الملتصقة (بـ، كـ، لـ) بعد إزالة الواو/الفاء
    if (!hasDefiniteArticle && working.length >= 4) {
      if (working.startsWith('بال') || working.startsWith('كال') || working.startsWith('فال') || working.startsWith('وال')) {
        proclitics.add(working.substring(0, 1));
        proclitics.add('ال');
        hasDefiniteArticle = true;
        working = working.substring(3);
      } else if (working.startsWith('لل') && working.length >= 4) {
        proclitics.add('ل');
        proclitics.add('ال');
        hasDefiniteArticle = true;
        working = working.substring(2);
      }
    }

    // 5. فحص سين الاستقبال في الفعل المضارع (سـ)
    if (working.startsWith('س') && working.length >= 4 && !hasDefiniteArticle) {
      final afterS = working.substring(1);
      if (afterS.startsWith('ي') || afterS.startsWith('ت') || afterS.startsWith('ن') || afterS.startsWith('أ')) {
        proclitics.add('س (استقبال)');
        working = afterS;
      }
    }

    // 6. فحص اللواحق (الضمائر المتصلة في نهاية الكلمة)
    if (working.length >= 4) {
      const pronouns = [
        'هما', 'هم', 'هن', 'كما', 'كم', 'كن', 'نا', 'ها', 'ه', 'ك', 'ي'
      ];
      for (final p in pronouns) {
        if (working.endsWith(p) && (working.length - p.length) >= 3) {
          enclitics.add(p);
          working = working.substring(0, working.length - p.length);
          break;
        }
      }
    }

    // استنتاج الاسمية القطعية بناءً على علامات الأسماء
    final isDefinitelyNoun = hasDefiniteArticle || hasTanwin || hasTehMarbuta;

    return CliticResult(
      rawWord: raw,
      cleanWord: clean,
      stem: working,
      proclitics: proclitics,
      enclitics: enclitics,
      hasDefiniteArticle: hasDefiniteArticle,
      hasTanwin: hasTanwin,
      hasTehMarbuta: hasTehMarbuta,
      isDefinitelyNoun: isDefinitelyNoun,
      isInterrogative: isInterrogative,
    );
  }
}
