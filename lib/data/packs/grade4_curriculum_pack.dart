import '../../models/activity_model.dart';
import '../../models/curriculum_unit_model.dart';
import '../../models/grade_model.dart';
import '../../models/lesson_model.dart';
import '../../models/nlp_token_model.dart';
import '../../models/quiz_model.dart';

/// Modular Curriculum Pack for Grade 4 (السنة الرابعة ابتدائي).
class Grade4CurriculumPack {
  static GradeModel buildGrade() {
    final units = [
      _buildUnitSubjectsAndObjects(),
    ];

    final allLessons = units.expand((u) => u.lessons).toList();

    return GradeModel(
      id: 'grade4',
      gradeNumber: 4,
      title: 'السنة الرابعة ابتدائي',
      subtitle: 'الفاعل، المفعول به، وعلامات الإعراب',
      description: 'تعميق فهم الجملة الفعلية: إعراب الفاعل والمفعول به بالعلامات الأصلية والفرعية، ودخول الأفعال الناقصة.',
      imagePath: 'assets/images/grade_four.jpg',
      colorHex: '#1565C0',
      units: units,
      lessons: allLessons,
      comprehensiveQuiz: _buildComprehensiveQuiz(),
    );
  }

  static CurriculumUnitModel _buildUnitSubjectsAndObjects() {
    return CurriculumUnitModel(
      id: 'g4_u1',
      title: 'الوحدة الأولى: علامات إعراب الفاعل والمفعول به',
      subtitle: 'الضمة، الفتحة، الألف، والياء',
      description: 'دراسة حالات الرفع والنصب في المفرد والمثنى وجموع التكسير والمذكر السالم.',
      order: 1,
      lessons: [
        _buildLessonSubjectCase(),
        _buildLessonObjectCase(),
      ],
    );
  }

  static LessonModel _buildLessonSubjectCase() {
    return LessonModel(
      id: 'g4_l1',
      gradeId: 'grade4',
      title: 'الفاعل وعلامات رفعه',
      subtitle: 'الاسم المرفوع الذي يدل على من قام بالفعل',
      ruleSummary: 'الفَاعِلُ اسْمٌ مَرْفُوعٌ: يُرْفَعُ بِالضَّمَّةِ لِلْمُفْرَدِ، وَبِالأَلِفِ لِلْمُثَنَّى، وَبِالوَاوِ لِجَمْعِ المُذَكَّرِ السَّالِمِ.',
      detailedExplanation: '''
علامات رفع الفاعل بحسب نوع الكلمة:
1. المفرد وجمع التكسير: حَضَرَ المُعَلِّمُ / انْتَصَرَ الجُنُودُ (مرفوع بالضمة).
2. المثنى: حَضَرَ المُعَلِّمَانِ (مرفوع بالألف لأنه مثنى).
3. جمع المذكر السالم: حَضَرَ المُعَلِّمُونَ (مرفوع بالواو).
''',
      examples: [
        LessonExample(
          sentence: 'شَرَحَ المُعَلِّمُ الدَّرْسَ بِمَهَارَةٍ',
          tokens: [
            NlpToken(word: 'شَرَحَ', plainWord: 'شرح', pos: 'فعل', subType: 'فعل ماضٍ', caseMark: 'مبني على الفتح', explanation: 'فعل ماضٍ مبني على الفتح.'),
            NlpToken(word: 'المُعَلِّمُ', plainWord: 'المعلم', pos: 'اسم', subType: 'فاعل', caseMark: 'مرفوع وعلامة رفعه الضمة الظاهرة', explanation: 'فاعل مفرد مرفوع بالضمة.', isTarget: true),
            NlpToken(word: 'الدَّرْسَ', plainWord: 'الدرس', pos: 'اسم', subType: 'مفعول به', caseMark: 'منصوب بالفتحة', explanation: 'مفعول به منصوب بالفتحة.'),
          ],
        ),
      ],
      keyTakeaways: [
        'الفاعل مرفوع دائماً.',
        'علامة رفعه الأصلية الضمة، والفرعية الألف والواو.',
      ],
      activities: [
        ActivityModel(
          id: 'g4_l1_a1',
          title: 'علامة رفع الفاعل',
          prompt: 'ما هي علامة رفع الفاعل في: "انْتَصَرَ الجُنُودُ"؟',
          sentence: 'انْتَصَرَ الجُنُودُ',
          options: ['الضمة الظاهرة', 'الألف', 'الواو'],
          correctIndex: 0,
          type: ActivityType.selectSubject,
          correctFeedback: 'صحيح تماماً! "الجُنُودُ" جمع تكسير يرفع بالضمة الظاهرة.',
          incorrectFeedback: 'جمع التكسير يرفع بالضمة تماماً كالمفرد.',
          ruleSummary: 'جمع التكسير يرفع بالضمة.',
        ),
      ],
    );
  }

  static LessonModel _buildLessonObjectCase() {
    return LessonModel(
      id: 'g4_l2',
      gradeId: 'grade4',
      title: 'المفعول به وعلامات نصبه',
      subtitle: 'الاسم المنصوب الذي يقع عليه فعل الفاعل',
      ruleSummary: 'المَفْعُولُ بِهِ مَنْصُوبٌ دَائِماً: يُنْصَبُ بِالفَتْحَةِ لِلْمُفْرَدِ، وَبِاليَاءِ لِلْمُثَنَّى وَجَمْعِ المُذَكَّرِ السَّالِمِ.',
      detailedExplanation: '''
المفعول به يبين من أو ما وقع عليه الفعل:
• كَرَّمَ المُدِيرُ الطَّالِبَ (منصوب بالفتحة).
• كَرَّمَ المُدِيرُ الطَّالِبَيْنِ (منصوب بالياء لأنه مثنى).
• شَجَّعَ الجُمْهُورُ اللاَّعِبِينَ (منصوب بالياء لأنه جمع مذكر سالم).
''',
      examples: [
        LessonExample(
          sentence: 'قَطَفَ الفَلاَّحُ الثِّمَارَ',
          tokens: [
            NlpToken(word: 'قَطَفَ', plainWord: 'قطف', pos: 'فعل', subType: 'فعل ماضٍ', caseMark: 'مبني على الفتح', explanation: 'فعل ماضٍ.'),
            NlpToken(word: 'الفَلاَّحُ', plainWord: 'الفلاح', pos: 'اسم', subType: 'فاعل', caseMark: 'مرفوع بالضمة', explanation: 'فاعل مرفوع بالضمة.'),
            NlpToken(word: 'الثِّمَارَ', plainWord: 'الثمار', pos: 'اسم', subType: 'مفعول به', caseMark: 'منصوب بالفتحة الظاهرة', explanation: 'مفعول به منصوب وقع عليه القطف.', isTarget: true),
          ],
        ),
      ],
      keyTakeaways: [
        'المفعول به دائماً منصوب.',
        'ينصب بالفتحة للمفرد، وبالياء للمثنى وجمع المذكر السالم.',
      ],
      activities: [
        ActivityModel(
          id: 'g4_l2_a1',
          title: 'استخراج المفعول به',
          prompt: 'عيّن المفعول به في: "يَبْنِي البَنَّاءُ البَيْتَ"',
          sentence: 'يَبْنِي البَنَّاءُ البَيْتَ',
          options: ['البَيْتَ', 'يَبْنِي', 'البَنَّاءُ'],
          correctIndex: 0,
          type: ActivityType.selectObject,
          correctFeedback: 'أحسنت! "البَيْتَ" مفعول به منصوب وقع عليه البناء.',
          incorrectFeedback: 'تذكر أن تسأل: ماذا يبني البناء؟ الجواب هو المفعول به.',
          ruleSummary: 'المفعول به يجيب عن سؤال (ماذا؟).',
        ),
      ],
    );
  }

  static QuizModel _buildComprehensiveQuiz() {
    return const QuizModel(
      id: 'g4_quiz',
      gradeId: 'grade4',
      title: 'التقويم الشامل للسنة الرابعة',
      description: 'اختبار دقيق لعلامات إعراب الفاعل والمفعول به.',
      questions: [
        QuizQuestion(
          id: 'g4_q1',
          questionText: 'مَا إِعْرَابُ "المُهَنْدِسَانِ" فِي: "صَمَّمَ المُهَنْدِسَانِ المَشْرُوعَ"؟',
          contextSentence: 'صَمَّمَ المُهَنْدِسَانِ المَشْرُوعَ',
          options: ['فاعل مرفوع بالألف لأنه مثنى', 'مفعول به منصوب بالياء', 'فاعل مرفوع بالضمة'],
          correctIndex: 0,
          explanation: 'المثنى يرفع بالألف نيابة عن الضمة.',
        ),
        QuizQuestion(
          id: 'g4_q2',
          questionText: 'حَدِّدِ المَفْعُولَ بِهِ المَنْصُوبَ بِاليَاءِ:',
          contextSentence: 'شَجَّعَ المُعَلِّمُ الفَائِزَيْنِ',
          options: ['الفَائِزَيْنِ', 'المُعَلِّمُ', 'شَجَّعَ'],
          correctIndex: 0,
          explanation: '"الفَائِزَيْنِ" مفعول به منصوب بالياء لأنه مثنى.',
        ),
      ],
    );
  }
}
