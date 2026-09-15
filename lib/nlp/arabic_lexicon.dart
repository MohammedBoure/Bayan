import 'arabic_clitic_stemmer.dart';

/// معجم خفيف ومضغوط للمفردات العربية الأساسية والأوزان الشائعة.
/// يضمن الأولوية المعجمية (Lexical Priority) لتفادي الخلط بين الأسماء المجردة والأفعال.
class ArabicLexicon {
  /// الأفعال الناسخة (كان وأخواتها)
  static const Set<String> kanaAndSisters = {
    'كان', 'اصبح', 'اضحي', 'امسي', 'ظل', 'بات', 'صار', 'ليس',
    'مازال', 'مافتئ', 'مابرح', 'ماانفك', 'مادام'
  };

  /// الحروف الناسخة (إن وأخواتها)
  static const Set<String> innaAndSisters = {
    'ان', 'كان', 'لكن', 'ليت', 'لعل'
  };

  /// حروف الجر المنفصلة
  static const Set<String> prepositions = {
    'من', 'الي', 'عن', 'علي', 'في', 'حتي', 'مذ', 'منذ', 'رب'
  };

  /// أسماء الإشارة
  static const Set<String> demonstratives = {
    'هذا', 'هذه', 'هذان', 'هاتان', 'هولاء', 'ذلك', 'تلك', 'اولئك', 'كذلك', 'هنا', 'هناك'
  };

  /// الأسماء الموصولة
  static const Set<String> relatives = {
    'الذي', 'التي', 'اللذان', 'اللتان', 'الذين', 'اللاتي', 'اللواتي', 'ما', 'من'
  };

  /// الضمائر المنفصلة (تأتي في محل رفع مبتدأ غالباً)
  static const Set<String> personalPronouns = {
    'انا', 'نحن', 'انت', 'انتما', 'انتم', 'انتن', 'هو', 'هي', 'هما', 'هم', 'هن'
  };

  /// أدوات الاستفهام
  static const Set<String> interrogativeTools = {
    'هل', 'اليس', 'ما', 'ماذا', 'من', 'كيف', 'متي', 'اين', 'كم', 'اي'
  };

  /// ظروف الزمان والمكان والكلمات المنصوبة الشائعة (مفعول فيه / مفعول مطلق)
  static const Set<String> adverbsAndAccusatives = {
    'جدا', 'ايضا', 'معا', 'دائما', 'ابدا', 'صباحا', 'مساء', 'ظهرا', 'عصرا',
    'فوق', 'تحت', 'امام', 'خلف', 'وراء', 'يمين', 'شمال', 'بين', 'حول', 'عند'
  };

  /// معجم الأسماء المجردة الشائعة (Inherent Common Nouns)
  /// تمنع اعتبار الكلمات غير المشكولة أفعالاً (مثل: بحر، شمس، فصل، رجل...)
  static const Set<String> commonInherentNouns = {
    'بحر', 'شمس', 'قمر', 'سماء', 'ارض', 'نهر', 'جبل', 'سهل', 'صخر',
    'منزل', 'بيت', 'فصل', 'صف', 'مدرسه', 'دار', 'كتاب', 'قلم', 'دفتر',
    'رجل', 'طفل', 'ولد', 'بنت', 'امراه', 'معلم', 'طالب', 'تلميذ',
    'يوم', 'ليله', 'سنه', 'عام', 'وقت', 'ساعه', 'دقيقه', 'زمان',
    'علم', 'نور', 'حق', 'خير', 'شر', 'عدل', 'سلام', 'جهل', 'عمل',
    'شجره', 'ورده', 'زهره', 'حديقه', 'غابه', 'طير', 'عصفور', 'حيوان',
    'باب', 'نافذه', 'حائط', 'طاوله', 'كرسي', 'هاتف', 'لوحه'
  };

  /// الصفات والمشتقات الشائعة (تساعد في فحص السياق الثنائي Bigram: نكرة + صفة نكرة)
  static const Set<String> commonAdjectives = {
    'كبير', 'صغير', 'طويل', 'قصير', 'جميل', 'قبيح', 'نظيف', 'متسخ',
    'واسع', 'ضيق', 'سريع', 'بطيء', 'ذكي', 'غبي', 'شجاع', 'جبان',
    'كريم', 'بخيل', 'شديد', 'لطيف', 'عظيم', 'حقير', 'جديد', 'قديم',
    'مفيد', 'ضار', 'ماطر', 'مشمس', 'بارد', 'حار', 'صعب', 'سهل'
  };

  /// هل الكلمة فعل ناسخ؟
  static bool isKana(String word) {
    return kanaAndSisters.contains(ArabicCliticStemmer.normalize(word));
  }

  /// هل الكلمة حرف ناسخ؟
  static bool isInna(String word) {
    return innaAndSisters.contains(ArabicCliticStemmer.normalize(word));
  }

  /// هل الكلمة حرف جر؟
  static bool isPreposition(String word) {
    return prepositions.contains(ArabicCliticStemmer.normalize(word));
  }

  /// هل الكلمة اسم مجرد شائع يمنع تصنيفها كفعل؟
  static bool isInherentNoun(String word) {
    final norm = ArabicCliticStemmer.normalize(word);
    return commonInherentNouns.contains(norm);
  }

  /// هل الكلمة صفة مشتقة شائعة؟
  static bool isCommonAdjective(String word) {
    final norm = ArabicCliticStemmer.normalize(word);
    return commonAdjectives.contains(norm);
  }

  /// هل الكلمة ظرف أو ملحق منصوب؟
  static bool isAdverb(String word) {
    final norm = ArabicCliticStemmer.normalize(word);
    return adverbsAndAccusatives.contains(norm);
  }

  /// هل الكلمة اسم إشارة؟
  static bool isDemonstrative(String word) {
    final norm = ArabicCliticStemmer.normalize(word);
    return demonstratives.contains(norm);
  }

  /// هل الكلمة ضمير منفصل؟
  static bool isPersonalPronoun(String word) {
    final norm = ArabicCliticStemmer.normalize(word);
    return personalPronouns.contains(norm);
  }
}
