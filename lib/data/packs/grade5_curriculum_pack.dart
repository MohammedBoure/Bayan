import '../../models/activity_model.dart';
import '../../models/curriculum_unit_model.dart';
import '../../models/grade_model.dart';
import '../../models/lesson_model.dart';
import '../../models/nlp_token_model.dart';
import '../../models/quiz_model.dart';

/// Modular Curriculum Pack for Grade 5 (السنة الخامسة ابتدائي).
class Grade5CurriculumPack {
  static GradeModel buildGrade() {
    final units = [
      _buildUnitSubjunctiveAndJussive(),
    ];

    final allLessons = units.expand((u) => u.lessons).toList();

    return GradeModel(
      id: 'grade5',
      gradeNumber: 5,
      title: 'السنة الخامسة ابتدائي',
      subtitle: 'نواصب وجوازم المضارع والمفاعيل',
      description: 'دراسة حالات الفعل المضارع المعرب (النصب والجزم)، والمفاعيل المتنوعة، والإعراب التطبيقي المتقدم.',
      imagePath: 'assets/images/grade_five.jpg',
      colorHex: '#EF6C00',
      units: units,
      lessons: allLessons,
      comprehensiveQuiz: _buildComprehensiveQuiz(),
    );
  }

  static CurriculumUnitModel _buildUnitSubjunctiveAndJussive() {
    return CurriculumUnitModel(
      id: 'g5_u1',
      title: 'الوحدة الأولى: نواصب وجوازم الفعل المضارع',
      subtitle: 'أن، لن، كي، ولم، ولا الناهية',
      description: 'إعراب الفعل المضارع عند دخول الحروف الناصبة والحروف الجازمة.',
      order: 1,
      lessons: [
        _buildLessonAccusative(),
        _buildLessonJussive(),
      ],
    );
  }

  static LessonModel _buildLessonAccusative() {
    return LessonModel(
      id: 'g5_l1',
      gradeId: 'grade5',
      title: 'نواصب الفعل المضارع',
      subtitle: 'دخول أن ولن وكي على الفعل المضارع',
      ruleSummary: 'يُنْصَبُ الفِعْلُ المُضَارِعُ إِذَا سَبَقَتْهُ أَدَاةُ نَصْبٍ مِثْلُ: (أَنْ - لَنْ - كَيْ). وَعَلامَةُ نَصْبِهِ الأَصْلِيَّةُ الفَتْحَةُ الظَّاهِرَةُ.',
      detailedExplanation: '''
الأصل في المضارع الرفع بالضمة (يَكْتُبُ).
وإذا سبقته أداة نصب يصبح منصوباً بالفتحة:
• لَنْ يَرْسُبَ المُجْتَهِدُ.
• يَجِبُ أَنْ تَنْجَحَ.
• ذَاكِرْ كَيْ تَتَفَوَّقَ.
''',
      examples: [
        LessonExample(
          sentence: 'لَنْ يُهْمِلَ الطَّالِبُ وَاجِبَهُ',
          tokens: [
            NlpToken(word: 'لَنْ', plainWord: 'لن', pos: 'حرف', subType: 'حرف نفي ونصب', caseMark: 'مبني على السكون', explanation: 'أداة تنفي الفعل وتنصبه.'),
            NlpToken(word: 'يُهْمِلَ', plainWord: 'يهمل', pos: 'فعل', subType: 'فعل مضارع منصوب', caseMark: 'منصوب بلن وعلامة نصبه الفتحة', explanation: 'فعل مضارع منصوب بالفتحة.', isTarget: true),
            NlpToken(word: 'الطَّالِبُ', plainWord: 'الطالب', pos: 'اسم', subType: 'فاعل', caseMark: 'مرفوع بالضمة', explanation: 'فاعل مرفوع بالضمة.'),
          ],
        ),
      ],
      keyTakeaways: [
        'أدوات النصب: أن، لن، كي.',
        'الفعل المضارع بعدها منصوب بالفتحة.',
      ],
      activities: [
        ActivityModel(
          id: 'g5_l1_a1',
          title: 'ضبط الفعل بعد أداة النصب',
          prompt: 'ما هي الحركة الصحيحة لآخر الفعل في: "يَجِبُ أَنْ تَجْتَهِدَ"؟',
          sentence: 'يَجِبُ أَنْ تَجْتَهِدَ',
          options: ['الفتحة (تَجْتَهِدَ)', 'الضمة (تَجْتَهِدُ)', 'السكون (تَجْتَهِدْ)'],
          correctIndex: 0,
          type: ActivityType.classifyVerbTense,
          correctFeedback: 'ممتاز! الفعل المضارع بعد "أن" ينصب بالفتحة الظاهرة.',
          incorrectFeedback: 'تذكر أن "أن" حرف نصب فينصب المضارع.',
          ruleSummary: 'ينصب المضارع بالفتحة بعد أدوات النصب.',
        ),
      ],
    );
  }

  static LessonModel _buildLessonJussive() {
    return LessonModel(
      id: 'g5_l2',
      gradeId: 'grade5',
      title: 'جوازم الفعل المضارع',
      subtitle: 'دخول لم ولا الناهية على الفعل المضارع',
      ruleSummary: 'يُجْزَمُ الفِعْلُ المُضَارِعُ إِذَا سَبَقَتْهُ أَدَاةُ جَزْمٍ (لَمْ - لا النَّاهِيَةُ). وَعَلامَةُ جَزْمِهِ الصَّحِيحِ السُّكُونُ (ـْ).',
      detailedExplanation: '''
عند دخول أدوات الجزم على الفعل المضارع تجزمه بالسكون:
• لَمْ يُقَصِّرْ خَالِدٌ فِي دَرْسِهِ.
• لا تُهْمِلْ وَاجِبَكَ أَبَداً.
''',
      examples: [
        LessonExample(
          sentence: 'لَمْ يَتَأَخَّرِ القِطَارُ',
          tokens: [
            NlpToken(word: 'لَمْ', plainWord: 'لم', pos: 'حرف', subType: 'حرف نفي وجزم', caseMark: 'مبني على السكون', explanation: 'أداة تجزم الفعل المضارع.'),
            NlpToken(word: 'يَتَأَخَّرْ', plainWord: 'يتأخر', pos: 'فعل', subType: 'فعل مضارع مجزوم', caseMark: 'مجزوم بلم وعلامة جزمه السكون', explanation: 'فعل مضارع جزم بالسكون.', isTarget: true),
            NlpToken(word: 'القِطَارُ', plainWord: 'القطار', pos: 'اسم', subType: 'فاعل', caseMark: 'مرفوع بالضمة', explanation: 'فاعل مرفوع بالضمة.'),
          ],
        ),
      ],
      keyTakeaways: [
        'أدوات الجزم: لم، لا الناهية.',
        'علامة الجزم الصحيحة هي السكون.',
      ],
      activities: [
        ActivityModel(
          id: 'g5_l2_a1',
          title: 'إعراب الفعل المجزوم',
          prompt: 'ما علامة جزم الفعل في: "لا تُهْمِلْ وَاجِبَكَ"؟',
          sentence: 'لا تُهْمِلْ وَاجِبَكَ',
          options: ['السكون', 'الفتحة', 'الكسرة'],
          correctIndex: 0,
          type: ActivityType.classifyVerbTense,
          correctFeedback: 'رائع! علامة جزم الفعل المضارع هي السكون الظاهر.',
          incorrectFeedback: 'لا الناهية تجزم الفعل المضارع بالسكون.',
          ruleSummary: 'يجزم المضارع بالسكون مع أدوات الجزم.',
        ),
      ],
    );
  }

  static QuizModel _buildComprehensiveQuiz() {
    return const QuizModel(
      id: 'g5_quiz',
      gradeId: 'grade5',
      title: 'التقويم الشامل للسنة الخامسة',
      description: 'تقويم تركيبي لنواصب وجوازم المضارع.',
      questions: [
        QuizQuestion(
          id: 'g5_q1',
          questionText: 'أَيُّ الجُمَلِ حَوَتْ فِعْلاً مُضَارِعاً مَنْصُوباً؟',
          options: ['لَنْ يَتَكَاسَلَ الفَائِزُ', 'لَمْ يَكْتُبِ الدَّرْسَ', 'يَكْتُبُ التِّلْمِيذُ بِجِدٍّ'],
          correctIndex: 0,
          explanation: '"لَنْ يَتَكَاسَلَ" فعل مضارع منصوب بلن وعلامة نصبه الفتحة.',
        ),
        QuizQuestion(
          id: 'g5_q2',
          questionText: 'مَا هُوَ حُكْمُ الفِعْلِ بَعْدَ (لا النَّاهِيَة)؟',
          options: ['الجزم بالسكون', 'النصب بالفتحة', 'الرفع بالضمة'],
          correctIndex: 0,
          explanation: 'لا الناهية تجزم الفعل المضارع بالسكون إذا كان صحيح الآخر.',
        ),
      ],
    );
  }
}
