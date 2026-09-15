import '../../models/activity_model.dart';
import '../../models/curriculum_unit_model.dart';
import '../../models/grade_model.dart';
import '../../models/lesson_model.dart';
import '../../models/nlp_token_model.dart';
import '../../models/quiz_model.dart';

/// Modular Curriculum Pack for Grade 3 (السنة الثالثة ابتدائي).
/// Ready to receive and expand dozens of lessons and exercises.
class Grade3CurriculumPack {
  static GradeModel buildGrade() {
    final units = [
      _buildUnitVerbs(),
      _buildUnitVerbalSentence(),
    ];

    final allLessons = units.expand((u) => u.lessons).toList();

    return GradeModel(
      id: 'grade3',
      gradeNumber: 3,
      title: 'السنة الثالثة ابتدائي',
      subtitle: 'الأفعال والجملة الفعلية البسيطة',
      description: 'يتعلم التلميذ التعرف على أقسام الكلمة، وأنواع الأفعال (الماضي، المضارع، الأمر)، وأركان الجملة الفعلية الأساسية.',
      imagePath: 'assets/images/grade_three.jpg',
      colorHex: '#00796B',
      units: units,
      lessons: allLessons,
      comprehensiveQuiz: _buildComprehensiveQuiz(),
    );
  }

  static CurriculumUnitModel _buildUnitVerbs() {
    return CurriculumUnitModel(
      id: 'g3_u1',
      title: 'الوحدة الأولى: أزمنة الأفعال',
      subtitle: 'الفعل الماضي، الفعل المضارع، وفعل الأمر',
      description: 'التمييز بين الأفعال وفق دلالتها الزمنية وعلاماتها الإعرابية.',
      order: 1,
      lessons: [
        _buildLessonPastVerb(),
        _buildLessonPresentVerb(),
        _buildLessonImperativeVerb(),
      ],
    );
  }

  static CurriculumUnitModel _buildUnitVerbalSentence() {
    return CurriculumUnitModel(
      id: 'g3_u2',
      title: 'الوحدة الثانية: الجملة الفعلية وأركانها',
      subtitle: 'الفعل والفاعل والمفعول به',
      description: 'فهم البنية التركيبية للجملة التي تبدأ بفعل وتحديد أركانها الأساسية.',
      order: 2,
      lessons: [
        _buildLessonVerbalSentence(),
      ],
    );
  }

  static LessonModel _buildLessonPastVerb() {
    return LessonModel(
      id: 'g3_l1',
      gradeId: 'grade3',
      title: 'الفعل الماضي',
      subtitle: 'الحدث الذي وقع وانتهى في الزمن الماضي',
      ruleSummary: 'الفِعْلُ المَاضِي هُوَ كُلُّ كَلِمَةٍ تَدُلُّ عَلَى حَدَثٍ وَقَعَ وَانْتَهَى، وَتَكُونُ حَرَكَتُهُ الأَصْلِيَّةُ هِيَ الفَتْحَةَ (ـَ).',
      detailedExplanation: '''
مرحباً بكم في قاعة الدرس!
الفعل الماضي يدل على عمل قمنا به وانتهينا منه:
• كَتَبَ التِّلْمِيذُ الدَّرْسَ.
• رَسَمَ الفَنَّانُ لَوْحَةً.
• شَرِبَ الطِّفْلُ الحَلِيبَ.

العلامة المميزة: يقبل تاء التأنيث الساكنة في آخره (كَتَبَتْ، رَسَمَتْ).
''',
      examples: [
        LessonExample(
          sentence: 'كَتَبَ التِّلْمِيذُ الدَّرْسَ',
          tokens: [
            NlpToken(word: 'كَتَبَ', plainWord: 'كتب', pos: 'فعل', subType: 'فعل ماضٍ', caseMark: 'مبني على الفتح الظاهر', explanation: 'فعل ماضٍ مبني على الفتح الظاهر.', isTarget: true),
            NlpToken(word: 'التِّلْمِيذُ', plainWord: 'التلميذ', pos: 'اسم', subType: 'فاعل', caseMark: 'مرفوع بالضمة', explanation: 'الفاعل الذي قام بالكتابة.'),
            NlpToken(word: 'الدَّرْسَ', plainWord: 'الدرس', pos: 'اسم', subType: 'مفعول به', caseMark: 'منصوب بالفتحة', explanation: 'الشيء المكتوب.'),
          ],
        ),
      ],
      keyTakeaways: [
        'الفعل الماضي يدل على حدث وقع وانتهى.',
        'يبنى غالباً على الفتح الظاهر (ـَ).',
        'يقبل تاء التأنيث الساكنة (رَسَمَتْ).',
      ],
      activities: [
        ActivityModel(
          id: 'g3_l1_a1',
          title: 'تحديد الفعل الماضي',
          prompt: 'اقرأ الجملة واضغط على الفعل الماضي:',
          sentence: 'خَرَجَ الوَلَدُ إِلَى المَدْرَسَةِ',
          options: ['خَرَجَ', 'الوَلَدُ', 'إِلَى', 'المَدْرَسَةِ'],
          correctIndex: 0,
          type: ActivityType.selectVerb,
          correctFeedback: 'أحسنت! "خَرَجَ" هو الفعل الماضي لأنه يدل على حدث وقع وانتهى.',
          incorrectFeedback: 'حاول مجدداً. تذكر أن الفعل يدل على حركة أو عمل.',
          ruleSummary: 'الفعل الماضي يدل على عمل وقع في الماضي.',
        ),
      ],
    );
  }

  static LessonModel _buildLessonPresentVerb() {
    return LessonModel(
      id: 'g3_l2',
      gradeId: 'grade3',
      title: 'الفعل المضارع',
      subtitle: 'الحدث الذي يقع في الحاضر أو المستقبل',
      ruleSummary: 'الفِعْلُ المُضَارِعُ يَدُلُّ عَلَى عَمَلٍ يَقَعُ الآنَ، وَيَبْدَأُ بِحَرْفٍ مِنْ حُرُوفِ (أَنَيْتُ)، وَحَرَكَتُهُ الضَّمَّةُ (ـُ).',
      detailedExplanation: '''
الفعل المضارع يحدث الآن أمامنا:
• يَقْرَأُ التِّلْمِيذُ الكِتَابَ.
• تَرْسُمُ البِنْتُ زَهْرَةً.
• نَكْتُبُ دُرُوسَنَا بِنَشَاطٍ.
''',
      examples: [
        LessonExample(
          sentence: 'يَقْرَأُ التِّلْمِيذُ الكِتَابَ',
          tokens: [
            NlpToken(word: 'يَقْرَأُ', plainWord: 'يقرأ', pos: 'فعل', subType: 'فعل مضارع', caseMark: 'مرفوع وعلامة رفعه الضمة', explanation: 'فعل مضارع مرفوع بالضمة.', isTarget: true),
            NlpToken(word: 'التِّلْمِيذُ', plainWord: 'التلميذ', pos: 'اسم', subType: 'فاعل', caseMark: 'مرفوع بالضمة', explanation: 'الفاعل الذي يقرأ.'),
            NlpToken(word: 'الكِتَابَ', plainWord: 'الكتاب', pos: 'اسم', subType: 'مفعول به', caseMark: 'منصوب بالفتحة', explanation: 'المفعول به المنصوب.'),
          ],
        ),
      ],
      keyTakeaways: [
        'يبدأ بحروف المضارعة (أ، ن، ي، ت).',
        'مرفوع بالضمة الظاهرة ما لم تسبقه أداة نصب أو جزم.',
      ],
      activities: [
        ActivityModel(
          id: 'g3_l2_a1',
          title: 'النشاط التفاعلي للوحة العرض',
          prompt: 'حَدِّدِ الفِعْلَ مِنَ الجُمْلَةِ التَّالِيَة:',
          sentence: 'يَقْرَأُ التِّلْمِيذُ الكِتَابَ',
          options: ['يَقْرَأُ', 'التِّلْمِيذُ', 'الكِتَابَ'],
          correctIndex: 0,
          type: ActivityType.selectVerb,
          correctFeedback: 'أحسنت! إجابة صحيحة. "الفعل هو يَقْرَأُ" لأنه يدل على حدث مقترن بزمن.',
          incorrectFeedback: 'حاول مجدداً. الفعل هو الكلمة الدالة على الحدث.',
          ruleSummary: 'الفعل يدل على حدث في زمن معين.',
        ),
      ],
    );
  }

  static LessonModel _buildLessonImperativeVerb() {
    return LessonModel(
      id: 'g3_l3',
      gradeId: 'grade3',
      title: 'فعل الأمر',
      subtitle: 'طلب القيام بعمل في المستقبل',
      ruleSummary: 'فِعْلُ الأَمْرِ هُوَ طَلَبُ القِيَامِ بِعَمَلٍ، وَحَرَكَتُهُ الأَصْلِيَّةُ هِيَ السُّكُونُ (ـْ).',
      detailedExplanation: '''
نستخدم فعل الأمر عندما نطلب من شخص إنجاز عمل مفيد:
• اِحْفَظْ دَرْسَكَ يَا عَلِيُّ.
• اِجْلِسْ بِهُدُوءٍ فِي الصَّفِّ.
''',
      examples: [
        LessonExample(
          sentence: 'اِحْفَظِ الأَمَانَةَ',
          tokens: [
            NlpToken(word: 'اِحْفَظْ', plainWord: 'احفظ', pos: 'فعل', subType: 'فعل أمر', caseMark: 'مبني على السكون', explanation: 'فعل أمر مبني على السكون.', isTarget: true),
            NlpToken(word: 'الأَمَانَةَ', plainWord: 'الأمانة', pos: 'اسم', subType: 'مفعول به', caseMark: 'منصوب بالفتحة', explanation: 'الشيء المطلوب حفظه.'),
          ],
        ),
      ],
      keyTakeaways: [
        'فعل الأمر يطلب به حصول عمل.',
        'مبني على السكون الظاهر (ـْ).',
      ],
      activities: [
        ActivityModel(
          id: 'g3_l3_a1',
          title: 'تمييز فعل الأمر',
          prompt: 'اختر فعل الأمر المعروض أمامك:',
          sentence: 'اِجْلِسْ بِهُدُوءٍ فِي الفَصْلِ',
          options: ['اِجْلِسْ', 'بِهُدُوءٍ', 'الفَصْلِ'],
          correctIndex: 0,
          type: ActivityType.selectVerb,
          correctFeedback: 'رائع جداً! "اِجْلِسْ" فعل أمر مبني على السكون.',
          incorrectFeedback: 'تذكر أن فعل الأمر يطلب منك القيام بعمل.',
          ruleSummary: 'فعل الأمر يفيد الطلب ويبنى على السكون.',
        ),
      ],
    );
  }

  static LessonModel _buildLessonVerbalSentence() {
    return LessonModel(
      id: 'g3_l4',
      gradeId: 'grade3',
      title: 'الجملة الفعلية وأركانها',
      subtitle: 'الجملة التي تبدأ بفعل وتتكون من أركان أساسية',
      ruleSummary: 'الجُمْلَةُ الفِعْلِيَّةُ تَبْدَأُ بِفِعْلٍ. وَأَرْكَانُهَا الأَسَاسِيَّةُ: الفِعْلُ + الفَاعِلُ (+ المَفْعُولُ بِهِ).',
      detailedExplanation: '''
الجملة الفعلية هي البنية الأساسية في لغتنا الجميلة:
• كَتَبَ (فعل ماضٍ)
• التِّلْمِيذُ (فاعل مرفوع بالضمة)
• الدَّرْسَ (مفعول به منصوب بالفتحة)
''',
      examples: [
        LessonExample(
          sentence: 'كَتَبَ التِّلْمِيذُ الدَّرْسَ',
          tokens: [
            NlpToken(word: 'كَتَبَ', plainWord: 'كتب', pos: 'فعل', subType: 'فعل ماضٍ', caseMark: 'مبني على الفتح الظاهر', explanation: 'الفعل الذي تبدأ به الجملة.', isTarget: true),
            NlpToken(word: 'التِّلْمِيذُ', plainWord: 'التلميذ', pos: 'اسم', subType: 'فاعل', caseMark: 'مرفوع وعلامة رفعه الضمة', explanation: 'الفاعل: من قام بالكتابة وحركته الضمة.', isTarget: true),
            NlpToken(word: 'الدَّرْسَ', plainWord: 'الدرس', pos: 'اسم', subType: 'مفعول به', caseMark: 'منصوب وعلامة نصبه الفتحة', explanation: 'المفعول به: ما وقع عليه الفعل وحركته الفتحة.', isTarget: true),
          ],
        ),
      ],
      keyTakeaways: [
        'الجملة الفعلية تبدأ بفعل.',
        'الفاعل مرفوع بالضمة دائماً.',
        'المفعول به منصوب بالفتحة دائماً.',
      ],
      activities: [
        ActivityModel(
          id: 'g3_l4_a1',
          title: 'إعراب ركن الجملة',
          prompt: 'في جملة "كَتَبَ التِّلْمِيذُ الدَّرْسَ"، ماذا تُعرب كلمة "التِّلْمِيذُ"؟',
          sentence: 'كَتَبَ التِّلْمِيذُ الدَّرْسَ',
          options: ['فاعل مرفوع بالضمة', 'فعل ماضٍ', 'مفعول به منصوب'],
          correctIndex: 0,
          type: ActivityType.selectSubject,
          correctFeedback: 'ممتاز! "التِّلْمِيذُ" فاعل مرفوع بالضمة الظاهرة.',
          incorrectFeedback: 'من الذي كتب؟ إنه التلميذ، فهو الفاعل.',
          ruleSummary: 'الفاعل هو من قام بالفعل ويكون مرفوعاً.',
        ),
      ],
    );
  }

  static QuizModel _buildComprehensiveQuiz() {
    return const QuizModel(
      id: 'g3_quiz',
      gradeId: 'grade3',
      title: 'التقويم الشامل للسنة الثالثة',
      description: 'قياس تحصيل التلاميذ على شاشة العرض التفاعلية.',
      questions: [
        QuizQuestion(
          id: 'g3_q1',
          questionText: 'اخْتَرِ الفِعْلَ مِنَ الجُمْلَةِ التَّالِيَة:',
          contextSentence: 'جَلَسَ التِّلْمِيذُ فِي الفَصْلِ',
          options: ['جَلَسَ', 'التِّلْمِيذُ', 'فِي', 'الفَصْلِ'],
          correctIndex: 0,
          explanation: '"جَلَسَ" فعل ماضٍ يدل على حدث الجلوس.',
        ),
        QuizQuestion(
          id: 'g3_q2',
          questionText: 'مَا نَوْعُ الفِعْلِ فِي جُمْلَة: "يَسْمَعُ الطِّفْلُ كَلامَ أُمِّهِ"؟',
          contextSentence: 'يَسْمَعُ الطِّفْلُ كَلامَ أُمِّهِ',
          options: ['فعل مضارع', 'فعل ماضٍ', 'فعل أمر'],
          correctIndex: 0,
          explanation: '"يَسْمَعُ" فعل مضارع يدل على الحاضر.',
        ),
        QuizQuestion(
          id: 'g3_q3',
          questionText: 'مَا هُوَ الفَاعِلُ فِي جُمْلَة: "نَجَحَ المُجْتَهِدُ فِي الاِمْتِحَانِ"؟',
          contextSentence: 'نَجَحَ المُجْتَهِدُ فِي الاِمْتِحَانِ',
          options: ['المُجْتَهِدُ', 'نَجَحَ', 'الاِمْتِحَانِ'],
          correctIndex: 0,
          explanation: '"المُجْتَهِدُ" هو الفاعل المرفوع بالضمة.',
        ),
        QuizQuestion(
          id: 'g3_q4',
          questionText: 'أَيُّ الأَفْعَالِ التَّالِيَةِ هُوَ فِعْلُ أَمْر؟',
          contextSentence: 'اُكْتُبْ - كَتَبَ - يَكْتُبُ',
          options: ['اُكْتُبْ', 'كَتَبَ', 'يَكْتُبُ'],
          correctIndex: 0,
          explanation: '"اُكْتُبْ" فعل أمر مبني على السكون.',
        ),
      ],
    );
  }
}
