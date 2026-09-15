import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nahw_app/data/curriculum_repository.dart';
import 'package:nahw_app/main.dart';
import 'package:nahw_app/models/lesson_model.dart';
import 'package:nahw_app/nlp/arabic_clitic_stemmer.dart';
import 'package:nahw_app/nlp/arabic_hybrid_parser.dart';
import 'package:nahw_app/services/nlp_database_service.dart';
import 'package:nahw_app/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await NlpDatabaseService.instance.init();
  });

  test('Clitic Stemmer strips proclitics and enclitics correctly', () {
    final result = ArabicCliticStemmer.analyzeWord('وبالمدرسة');
    expect(result.proclitics.contains('و'), isTrue);
    expect(result.proclitics.contains('ب'), isTrue);
    expect(result.proclitics.contains('ال'), isTrue);
    expect(result.isDefinitelyNoun, isTrue);
  });

  test('Hybrid Parser correctly parses nominal and complex sentence (المنزل كبير جدا أليس كذلك)', () {
    const sentence = 'المنزل كبير جدا أليس كذلك';
    final result = ArabicHybridParser.parse(sentence);

    expect(result.type, equals(SentenceType.nominal));
    expect(result.tokens.length, equals(5));

    // 1. المنزل = اسم / مبتدأ
    expect(result.tokens[0].pos, equals('اسم'));
    expect(result.tokens[0].subType, equals('مبتدأ'));

    // 2. كبير = اسم / خبر المبتدأ
    expect(result.tokens[1].pos, equals('اسم'));
    expect(result.tokens[1].subType, equals('خبر المبتدأ'));

    // 3. جدا = مفعول مطلق / ظرف
    expect(result.tokens[2].subType, contains('مفعول مطلق'));

    // 4. أليس = فعل ماض ناقص + استفهام
    expect(result.tokens[3].pos, equals('فعل'));
    expect(result.tokens[3].subType, contains('فعل ماضٍ ناقص'));

    // 5. كذلك = شبه جملة جار ومجرور
    expect(result.tokens[4].pos, equals('شبه جملة'));
  });

  test('Bigram context check distinguishes inherent nouns from verbs (بحر واسع)', () {
    const sentence = 'بحر واسع';
    final result = ArabicHybridParser.parse(sentence);

    expect(result.type, equals(SentenceType.nominal));
    expect(result.tokens[0].pos, equals('اسم'));
    expect(result.tokens[0].subType, equals('مبتدأ'));
    expect(result.tokens[1].subType, equals('خبر المبتدأ'));
  });

  test('CurriculumRepository is extensible and supports dynamic lessons & units', () {
    final repo = CurriculumRepository.instance;
    final grades = repo.getAllGrades();
    expect(grades.length, equals(3));

    // Check units in Grade 3
    final grade3 = repo.getGradeById('grade3')!;
    expect(grade3.units.isNotEmpty, isTrue);
    final initialCount = grade3.lessons.length;

    // Dynamically register a new lesson
    const newLesson = LessonModel(
      id: 'g3_custom_lesson',
      gradeId: 'grade3',
      title: 'درس إضافي تجريبي',
      subtitle: 'اختبار قابلية التوسع',
      ruleSummary: 'قاعدة تجريبية',
      detailedExplanation: 'شرح موسع',
      examples: [],
      keyTakeaways: [],
      activities: [],
    );

    repo.addLessonToGrade('grade3', newLesson);
    final updatedGrade3 = repo.getGradeById('grade3')!;
    expect(updatedGrade3.lessons.length, equals(initialCount + 1));
  });

  test('User Corrections & Overrides apply with top priority (Feedback Loop)', () async {
    await NlpDatabaseService.instance.saveUserCorrection(
      word: 'سيارة',
      pos: 'اسم',
      subType: 'فاعل مخصص',
      caseMark: 'مرفوع بالضمة',
    );

    final overrides = NlpDatabaseService.instance.currentOverrides;
    expect(overrides.containsKey('سياره'), isTrue);

    final result = ArabicHybridParser.parse('سارت سيارة سريعة', userOverrides: overrides);
    final target = result.tokens.firstWhere((t) => t.plainWord == 'سيارة');
    expect(target.subType, equals('فاعل مخصص'));
  });

  test('Fast database lookup returns cached pre-seeded sentences', () async {
    const sentence = 'المنزل كبير جدا أليس كذلك';
    final cached = await NlpDatabaseService.instance.lookupSentence(sentence);
    expect(cached, isNotNull);
    expect(cached!.length, equals(5));
    expect(cached[0].subType, equals('مبتدأ'));
  });

  testWidgets('App launches and renders Home Screen for Data Show display', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final progressService = ProgressService();
    await tester.pumpWidget(NahwApp(progressService: progressService));
    await tester.pumpAndSettle();

    expect(find.textContaining('بُسْتَانُ النَّحْوِ'), findsWidgets);
    expect(find.textContaining('Data Show'), findsOneWidget);
    expect(find.textContaining('دَرْسَ اليَوْمِ'), findsOneWidget);
  });
}
