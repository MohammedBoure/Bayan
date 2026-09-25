import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nahw_app/data/curriculum_repository.dart';
import 'package:nahw_app/main.dart';
import 'package:nahw_app/models/activity_model.dart';
import 'package:nahw_app/models/lesson_model.dart';
import 'package:nahw_app/models/reading_passage_model.dart';
import 'package:nahw_app/nlp/arabic_clitic_stemmer.dart';
import 'package:nahw_app/nlp/arabic_hybrid_parser.dart';
import 'package:nahw_app/screens/interactive_activity_screen.dart';
import 'package:nahw_app/screens/lesson_detail_screen.dart';
import 'package:nahw_app/screens/settings_screen.dart';
import 'package:nahw_app/services/audio_player_service.dart';
import 'package:nahw_app/services/license_service.dart';
import 'package:nahw_app/services/nlp_database_service.dart';
import 'package:nahw_app/services/progress_service.dart';
import 'package:nahw_app/theme/app_theme.dart';
import 'package:nahw_app/widgets/activation_dialog.dart';
import 'package:nahw_app/widgets/celebration_dialog.dart';
import 'package:nahw_app/widgets/multi_sentence_fill_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
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
    expect(find.textContaining('دُخُولٌ إِلَى دُرُوسِ المِنْهَاجِ'), findsOneWidget);
  });

  test('Grade 3 Curriculum Pack contains all authentic lessons with 5-stage models and activities', () {
    final repo = CurriculumRepository.instance;
    final grade3 = repo.getGradeById('grade3')!;

    // Verify all 4 lessons exist
    expect(grade3.lessons.length, greaterThanOrEqualTo(4));

    // Check Lesson 1: الفعل الماضي - خدمة الأرض
    final lesson1 = grade3.lessons.firstWhere((l) => l.id == 'g3_l1');
    expect(lesson1.readingPassage, isNotNull);
    expect(lesson1.readingPassage!.title, equals('خِدْمَةُ الْأَرْضِ'));
    expect(lesson1.readingPassage!.paragraphs.length, equals(5));
    expect(lesson1.readingPassage!.vocabulary.length, equals(8));
    expect(lesson1.readingPassage!.comprehensionQuestions.length, equals(6));
    expect(lesson1.discovery, isNotNull);
    expect(lesson1.discovery!.triggerSentences.isNotEmpty, isTrue);
    expect(lesson1.activities.length, equals(5));

    // Check Lesson 2: الفعل المضارع - عمر ياسف
    final lesson2 = grade3.lessons.firstWhere((l) => l.id == 'g3_l2');
    expect(lesson2.readingPassage!.title, equals('عُمَرُ يَاسَفُ'));
    expect(lesson2.activities.isNotEmpty, isTrue);
    expect(lesson2.examples.length, equals(5));
    expect(lesson2.discovery!.allTargetWords, contains('سَأَحْمِلُ'));
    expect(lesson2.discovery!.allTargetWords, contains('تَسْتَحِقُّ'));

    // Check Lesson 3: فعل الأمر - من أجلك يا جزائر
    final lesson3 = grade3.lessons.firstWhere((l) => l.id == 'g3_l3');
    expect(lesson3.readingPassage!.title, equals('مِنْ أَجْلِكِ يَا جَزَائِرُ'));
    expect(lesson3.activities.isNotEmpty, isTrue);
    expect(lesson3.discovery!.allTargetWords, contains('اِلْبِسْ'));

    // Check Lesson 4: الجملة الفعلية
    final lesson4 = grade3.lessons.firstWhere((l) => l.id == 'g3_l4');
    expect(lesson4.readingPassage!.title, equals('يَوْمٌ فِي الحَقْلِ'));
    expect(lesson4.activities.isNotEmpty, isTrue);
    expect(lesson4.discovery!.allTargetWords, contains('يَحْرُثُ'));

    // Check total activities across Grade 3 equals at least 16 (currently 17 applied activities)
    final totalActivities = grade3.lessons.fold<int>(0, (sum, l) => sum + l.activities.length);
    expect(totalActivities, greaterThanOrEqualTo(16));
  });

  test('Grade 4 Curriculum Pack contains all authentic lessons with 5-stage models and activities', () {
    final repo = CurriculumRepository.instance;
    final grade4 = repo.getGradeById('grade4')!;

    // Verify all 3 authentic lessons exist across 2 units
    expect(grade4.units.length, equals(2));
    expect(grade4.lessons.length, equals(3));

    // Check Lesson 1: الجملة الفعلية - التَّاجَمَاعْتُ
    final lesson1 = grade4.lessons.firstWhere((l) => l.id == 'g4_l1');
    expect(lesson1.readingPassage, isNotNull);
    expect(lesson1.readingPassage!.title, equals('التَّاجَمَاعْتُ'));
    expect(lesson1.readingPassage!.paragraphs.length, equals(4));
    expect(lesson1.readingPassage!.vocabulary.length, equals(5));
    expect(lesson1.readingPassage!.vocabulary.any((v) => v.isAntonym), isFalse);
    expect(lesson1.readingPassage!.comprehensionQuestions.length, equals(11));
    expect(lesson1.discovery, isNotNull);
    expect(lesson1.discovery!.triggerSentences.isNotEmpty, isTrue);
    expect(lesson1.discovery!.allTargetWords, contains('تَدَخَّلَ'));
    expect(lesson1.readingPassage!.hasAudio, isTrue);
    expect(lesson1.readingPassage!.audioTracks.length, equals(3));
    expect(lesson1.readingPassage!.audioTracks.first.assetPath, equals('assets/sounds/4_1/1.wav'));
    expect(lesson1.readingPassage!.hasEnrichment, isTrue);
    expect(lesson1.readingPassage!.enrichment!.complementaryPairs.length, equals(6));
    expect(lesson1.readingPassage!.enrichment!.derivations.length, equals(4));
    expect(lesson1.activities.length, equals(6));
    expect(lesson1.activities[0].type, equals(ActivityType.multiSelect));
    expect(lesson1.activities[0].correctIndices, equals([0, 2, 4]));
    expect(lesson1.activities[1].type, equals(ActivityType.multiSentenceFill));
    expect(lesson1.activities[2].type, equals(ActivityType.multiSentenceOrder));
    expect(lesson1.activities[3].type, equals(ActivityType.multiSentenceFill));
    expect(lesson1.activities[4].type, equals(ActivityType.multiSelect));
    expect(lesson1.activities[5].type, equals(ActivityType.multiSentenceOrder));

    // Check Lesson 2: الفاعل - الْمُعَلِّمُ الْجَدِيدُ
    final lesson2 = grade4.lessons.firstWhere((l) => l.id == 'g4_l2');
    expect(lesson2.readingPassage!.title, equals('الْمُعَلِّمُ الْجَدِيدُ'));
    expect(lesson2.readingPassage!.paragraphs.length, equals(5));
    expect(lesson2.readingPassage!.vocabulary.length, equals(3));
    expect(lesson2.readingPassage!.hasMeaningMatches, isTrue);
    expect(lesson2.readingPassage!.meaningMatches.length, equals(4));
    expect(lesson2.readingPassage!.comprehensionQuestions.length, equals(10));
    expect(lesson2.readingPassage!.hasEnrichment, isTrue);
    expect(lesson2.readingPassage!.enrichment!.hasOddWords, isTrue);
    expect(lesson2.readingPassage!.enrichment!.oddWordItems.length, equals(3));
    expect(lesson2.discovery!.title, equals('أُلاَحِظُ وَأَكْتَشِفُ'));
    expect(lesson2.discovery!.triggerSentences.length, equals(2));
    expect(lesson2.discovery!.hasObservationQuestions, isTrue);
    expect(lesson2.discovery!.observationQuestions.length, equals(2));
    expect(lesson2.discovery!.allTargetWords, contains('السَّائِقُ'));
    expect(lesson2.discovery!.allTargetWords, contains('المُعَلِّمُ'));
    expect(lesson2.readingPassage!.hasAudio, isTrue);
    expect(lesson2.readingPassage!.audioTracks.length, equals(3));
    expect(lesson2.activities.length, equals(5));
    expect(lesson2.activities[0].type, equals(ActivityType.sentenceMultiChoice));
    expect(lesson2.activities[0].sentenceItems!.length, equals(4));
    expect(lesson2.activities[1].type, equals(ActivityType.sentenceMultiChoice));
    expect(lesson2.activities[1].sentenceItems!.length, equals(4));
    expect(lesson2.activities[2].type, equals(ActivityType.writtenParsing));
    expect(lesson2.activities[2].sentenceItems!.length, equals(3));
    expect(lesson2.activities[3].type, equals(ActivityType.openSentenceFill));
    expect(lesson2.activities[3].sentenceItems!.length, equals(6));
    expect(lesson2.activities[4].type, equals(ActivityType.textExtractionTable));
    expect(lesson2.activities[4].tableRows!.length, equals(7));
    final lesson3 = grade4.lessons.firstWhere((l) => l.id == 'g4_l3');
    expect(lesson3.readingPassage!.title, equals('بَيْنَ جَارَيْنِ'));
    expect(lesson3.readingPassage!.paragraphs.length, equals(4));
    expect(lesson3.readingPassage!.vocabulary.length, equals(6));
    expect(lesson3.readingPassage!.comprehensionQuestions.length, equals(9));
    expect(lesson3.discovery!.allTargetWords, contains('الحَائِطَ'));
    expect(lesson3.readingPassage!.hasAudio, isTrue);
    expect(lesson3.readingPassage!.audioTracks.length, equals(1));
    expect(lesson3.readingPassage!.audioTracks.first.assetPath, equals('assets/sounds/4_3/1.wav'));
    expect(lesson3.activities.length, equals(5));

    // Check total activities across Grade 4 equals 16 applied activities (6 + 5 + 5)
    final totalActivities = grade4.lessons.fold<int>(0, (sum, l) => sum + l.activities.length);
    expect(totalActivities, equals(16));

    // Check comprehensive quiz
    expect(grade4.comprehensiveQuiz, isNotNull);
    expect(grade4.comprehensiveQuiz.questions.length, equals(5));
  });

  test('ProgressService supports full teacher presentation configuration and persistence', () async {
    final ps = ProgressService();
    await ps.init();

    // Verify default teacher settings
    expect(ps.teacherModeEnabled, isTrue);
    expect(ps.revealAnswersDirectly, isFalse);
    expect(ps.timerDuration, equals(45));
    expect(ps.spotlightReading, isTrue);
    expect(ps.fontSizeScale, equals(1.0));
    expect(ps.uiScale, equals(1.0));
    expect(ps.selectedFontFamily, equals('NotoNaskhArabic'));
    expect(ps.showTashkeel, isTrue);

    // Toggle teacher settings and scaling
    await ps.setTeacherModeEnabled(false);
    expect(ps.teacherModeEnabled, isFalse);

    await ps.setRevealAnswersDirectly(true);
    expect(ps.revealAnswersDirectly, isTrue);

    await ps.setTimerDuration(60);
    expect(ps.timerDuration, equals(60));

    await ps.setSpotlightReading(false);
    expect(ps.spotlightReading, isFalse);

    await ps.setFontSizeScale(1.35);
    expect(ps.fontSizeScale, equals(1.35));

    await ps.setUiScale(1.25);
    expect(ps.uiScale, equals(1.25));

    await ps.setDisplayProfile(uiScale: 0.85, fontScale: 1.15);
    expect(ps.uiScale, equals(0.85));
    expect(ps.fontSizeScale, equals(1.15));

    await ps.setSelectedFontFamily('ReadexPro');
    expect(ps.selectedFontFamily, equals('ReadexPro'));

    await ps.setShowTashkeel(false);
    expect(ps.showTashkeel, isFalse);

    // Reset back
    await ps.setTeacherModeEnabled(true);
    await ps.setRevealAnswersDirectly(false);
    await ps.setTimerDuration(45);
    await ps.setSpotlightReading(true);
    await ps.setUiScale(1.0);
    await ps.setFontSizeScale(1.0);
    await ps.setSelectedFontFamily('NotoNaskhArabic');
    await ps.setShowTashkeel(true);
  });

  test('AppTheme builds child-friendly typography with custom font families', () {
    final theme = AppTheme.buildTheme(fontFamily: 'NotoNaskhArabic');
    expect(theme.textTheme.bodyLarge?.fontFamily, equals('NotoNaskhArabic'));
    expect(theme.textTheme.displayLarge?.fontFamily, equals('NotoNaskhArabic'));
    expect(theme.textTheme.bodyLarge?.height, greaterThanOrEqualTo(1.8));

    final readexTheme = AppTheme.buildTheme(fontFamily: 'ReadexPro');
    expect(readexTheme.textTheme.bodyLarge?.fontFamily, equals('ReadexPro'));
    expect(AppTheme.getFontLabel('NotoNaskhArabic'), contains('النسخ المدرسي'));
  });

  testWidgets('FeedbackDialog displays both retry and continue options on wrong answer', (WidgetTester tester) async {
    bool retried = false;
    bool continued = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedbackDialog(
            isCorrect: false,
            title: 'إِجَابَةٌ غَيْرُ صَحِيحَةٍ',
            message: 'حاول مجدداً',
            ruleSummary: 'قاعدة النحو',
            onRetry: () => retried = true,
            onContinue: () => continued = true,
          ),
        ),
      ),
    );

    expect(find.text('إِعَادَةُ المُحَاوَلَةِ'), findsOneWidget);
    expect(find.text('الإِكْمَالُ وَالمُتَابَعَةُ'), findsOneWidget);

    await tester.tap(find.text('إِعَادَةُ المُحَاوَلَةِ'));
    expect(retried, isTrue);

    await tester.tap(find.text('الإِكْمَالُ وَالمُتَابَعَةُ'));
    expect(continued, isTrue);
  });

  test('AudioPlayerService accurately reads WAV track duration for segmented audio', () async {
    const track1 = ReadingAudioTrack(
      title: 'المَقْطَعُ 2',
      assetPath: 'assets/sounds/3_1/2.wav',
      paragraphIndices: [2, 3, 4],
    );
    final duration1 = await AudioPlayerService.instance.getTrackDuration(track1);
    expect(duration1, greaterThan(45000));
    expect(duration1, lessThan(50000));

    const track2 = ReadingAudioTrack(
      title: 'المَقْطَعُ 3',
      assetPath: 'assets/sounds/3_2/3.wav',
      paragraphIndices: [3, 4],
    );
    final duration2 = await AudioPlayerService.instance.getTrackDuration(track2);
    expect(duration2, greaterThan(50000));
    expect(duration2, lessThan(80000));
  });

  testWidgets('LessonDetailScreen renders discovery stage with correct sentence text and word ordering', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = CurriculumRepository.instance;
    final lesson1 = repo.getGradeById('grade3')!.lessons.firstWhere((l) => l.id == 'g3_l1');
    final ps = ProgressService();
    await ps.init();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: LessonDetailScreen(
          lesson: lesson1,
          progressService: ps,
        ),
      ),
    );

    // Switch to stage 4 ("أُلاحِظُ وَأُمَيِّزُ")
    await tester.tap(find.text('4. أُلاحِظُ وَأُمَيِّزُ'));
    await tester.pumpAndSettle();

    // Verify discovery title is shown
    expect(find.textContaining('أُلاحِظُ وَأُمَيِّزُ'), findsWidgets);

    // Find RichText widgets in discovery stage
    final richTexts = tester.widgetList<RichText>(find.byType(RichText));
    final triggerRichText = richTexts.firstWhere(
      (r) => r.text.toPlainText().contains('سَارَ') && r.text.toPlainText().contains('عَبْدُ الْقَادِرِ'),
    );

    // Verify plain text contains the entire sentence in exact grammatical order
    final text1 = triggerRichText.text.toPlainText();
    final idxSara = text1.indexOf('سَارَ');
    final idxAbdu = text1.indexOf('عَبْدُ');
    expect(idxSara, lessThan(idxAbdu));

    // Check sentence 2
    final trigger2 = richTexts.firstWhere(
      (r) => r.text.toPlainText().contains('وَصَلَ') && r.text.toPlainText().contains('يَبْذُرُهَا'),
    );
    final text2 = trigger2.text.toPlainText();

    // Verify word order: 'وصل' appears BEFORE 'تناول', 'تناول' BEFORE 'وضعها', 'وضعها' BEFORE 'راح'
    final idxWasala = text2.indexOf('وَصَلَ');
    final idxTanawala = text2.indexOf('تَنَاوَلَ');
    final idxWadaaha = text2.contains('وَوَضَعَهَا') ? text2.indexOf('وَوَضَعَهَا') : text2.indexOf('وَضَعَهَا');
    final idxRaha = text2.indexOf('رَاحَ');

    expect(idxWasala, isNot(-1));
    expect(idxTanawala, isNot(-1));
    expect(idxWadaaha, isNot(-1));
    expect(idxRaha, isNot(-1));

    expect(idxWasala, lessThan(idxTanawala));
    expect(idxTanawala, lessThan(idxWadaaha));
    expect(idxWadaaha, lessThan(idxRaha));
  });

  testWidgets('Antonyms are hidden by default and teacher can reveal and hide them individually and collectively', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = CurriculumRepository.instance;
    final lesson1 = repo.getGradeById('grade3')!.lessons.firstWhere((l) => l.id == 'g3_l1');
    final ps = ProgressService();
    await ps.init();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: LessonDetailScreen(
          lesson: lesson1,
          progressService: ps,
        ),
      ),
    );

    // Switch to stage 2 ("2. كَلِمَاتِي الجَدِيدَةُ")
    await tester.tap(find.text('2. كَلِمَاتِي الجَدِيدَةُ'));
    await tester.pumpAndSettle();

    // Verify antonym section exists
    expect(find.textContaining('الْكَلِمَةُ وَضِدُّهَا فِي النَّصِّ'), findsOneWidget);

    // Verify antonym is HIDDEN by default (shows 'انْقُرْ لِلْكَشْفِ')
    expect(find.text('انْقُرْ لِلْكَشْفِ'), findsWidgets);
    // The opposite words 'فَرَغَ' and 'نَائِمَةً' should NOT be visible initially
    expect(find.text('فَرَغَ'), findsNothing);
    expect(find.text('نَائِمَةً'), findsNothing);

    // Tap on the reveal slot of the first antonym card ('بَدَأَ')
    final revealFinder = find.text('انْقُرْ لِلْكَشْفِ').first;
    await tester.ensureVisible(revealFinder);
    await tester.pumpAndSettle();
    await tester.tap(revealFinder);
    await tester.pumpAndSettle();

    // Now 'فَرَغَ' should be revealed!
    expect(find.text('فَرَغَ'), findsOneWidget);

    // Tap 'إِخْفَاءُ الضِّدِّ' to hide it again
    final hideFinder = find.text('إِخْفَاءُ الضِّدِّ').first;
    await tester.ensureVisible(hideFinder);
    await tester.pumpAndSettle();
    await tester.tap(hideFinder);
    await tester.pumpAndSettle();
    expect(find.text('فَرَغَ'), findsNothing);

    // Tap the master button 'إِظْهَارُ جَمِيعِ الأَضْدَادِ'
    final toggleAllFinder = find.text('إِظْهَارُ جَمِيعِ الأَضْدَادِ');
    await tester.ensureVisible(toggleAllFinder);
    await tester.pumpAndSettle();
    await tester.tap(toggleAllFinder);
    await tester.pumpAndSettle();
    expect(find.text('فَرَغَ'), findsOneWidget);
    expect(find.text('نَائِمَةً'), findsOneWidget);
    expect(find.text('إِخْفَاءُ جَمِيعِ الأَضْدَادِ'), findsOneWidget);
  });

  testWidgets('SettingsScreen allows configuring display profiles, general UI scale, and font scaling', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final ps = ProgressService();
    await ps.init();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(progressService: ps),
      ),
    );
    await tester.pumpAndSettle();

    // Verify sections exist
    expect(find.textContaining('أَوْضَاعُ العَرْضِ الجَاهِزَةُ لِمُخْتَلِفِ الشَّاشَاتِ'), findsOneWidget);
    expect(find.textContaining('حَاسُوبٌ مَحْمُولٌ'), findsOneWidget);
    expect(find.textContaining('سَبُّورَةٌ ذَكِيَّةٌ'), findsOneWidget);
    expect(find.textContaining('حَجْمُ البَرْنَامِجِ وَالوَاجِهَةِ بِصِفَةٍ عَامَّةٍ'), findsOneWidget);
    expect(find.textContaining('حَجْمُ الخُطُوطِ وَالنُّصُوصِ التَّعْلِيمِيَّةِ'), findsOneWidget);

    // Tap Laptop profile
    final laptopFinder = find.text('حَاسُوبٌ مَحْمُولٌ');
    await tester.ensureVisible(laptopFinder);
    await tester.pumpAndSettle();
    await tester.tap(laptopFinder);
    await tester.pumpAndSettle();
    expect(ps.uiScale, equals(0.85));
    expect(ps.fontSizeScale, equals(1.0));

    // Tap Data Show profile
    final dataShowFinder = find.text('جِهَازُ عَرْضٍ (Data Show)');
    await tester.ensureVisible(dataShowFinder);
    await tester.pumpAndSettle();
    await tester.tap(dataShowFinder);
    await tester.pumpAndSettle();
    expect(ps.uiScale, equals(1.25));
    expect(ps.fontSizeScale, equals(1.30));

    // Tap UI Scale preset chip 100%
    final standardChipFinder = find.text('100% (قِيَاسِي - افْتِرَاضِي)');
    await tester.ensureVisible(standardChipFinder);
    await tester.pumpAndSettle();
    await tester.tap(standardChipFinder);
    await tester.pumpAndSettle();
    expect(ps.uiScale, equals(1.0));
  });

  testWidgets('NahwApp renders seamlessly under different UI scales and font scales', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final ps = ProgressService();
    await ps.init();
    await ps.setUiScale(1.25);
    await ps.setFontSizeScale(1.20);

    await tester.pumpWidget(NahwApp(progressService: ps));
    await tester.pumpAndSettle();

    expect(find.textContaining('بُسْتَانُ النَّحْوِ'), findsWidgets);
    final startFinder = find.textContaining('دُخُولٌ إِلَى دُرُوسِ المِنْهَاجِ');
    expect(startFinder, findsOneWidget);

    // Tap start lesson button when scaled
    await tester.tap(startFinder);
    await tester.pumpAndSettle();

    // Verify navigating to Grade Selection screen worked accurately under scaled coordinates
    expect(find.text('اخْتِيَارُ السَّنَةِ الدِّرَاسِيَّةِ'), findsOneWidget);
  });

  test('LicenseService manages 7-day trial, unique device code, and HMAC-SHA256 activation', () async {
    SharedPreferences.setMockInitialValues({});
    final license = LicenseService();
    await license.init();

    // 1. Verify Device Code formatting
    expect(license.deviceCode, startsWith('BYN-'));
    expect(RegExp(r'^BYN-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}$').hasMatch(license.deviceCode), isTrue);

    // 2. Initial state: Trial active for 7 days
    expect(license.isTrialActive, isTrue);
    expect(license.isActivated, isFalse);
    expect(license.canAccessCurriculum, isTrue);
    expect(license.daysRemaining, inInclusiveRange(1, 7));

    // 3. Reject invalid keys
    final failResult = await license.activateSoftware('ACT-DEAD-BEEF-0000');
    expect(failResult, isFalse);
    expect(license.isActivated, isFalse);

    // 4. Test Keygen Algorithm correctness
    final validKey = LicenseService.generateActivationKey(license.deviceCode);
    expect(validKey, startsWith('ACT-'));
    expect(RegExp(r'^ACT-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}$').hasMatch(validKey), isTrue);

    // 5. Successful activation
    final successResult = await license.activateSoftware(validKey);
    expect(successResult, isTrue);
    expect(license.isActivated, isTrue);
    expect(license.canAccessCurriculum, isTrue);
    expect(license.status, equals(LicenseStatus.activated));
  });

  test('LicenseService restricts curriculum access upon trial expiry until activated', () async {
    SharedPreferences.setMockInitialValues({});
    final license = LicenseService();
    await license.init();

    // Simulate 7-day trial expiration
    await license.expireTrialForTesting();
    expect(license.isTrialActive, isFalse);
    expect(license.isActivated, isFalse);
    expect(license.canAccessCurriculum, isFalse);
    expect(license.status, equals(LicenseStatus.trialExpired));

    // Curriculum should be locked, then unlocked when developer key is entered
    final validKey = LicenseService.generateActivationKey(license.deviceCode);
    final activated = await license.activateSoftware(validKey);
    expect(activated, isTrue);
    expect(license.canAccessCurriculum, isTrue);
    expect(license.isActivated, isTrue);
  });

  testWidgets('SettingsScreen displays license status, device code, and activation card', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    final ps = ProgressService();
    await ps.init();
    final license = LicenseService();
    await license.init();

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SettingsScreen(progressService: ps, licenseService: license),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down to the license section
    final licenseFinder = find.textContaining('License & Activation');
    await tester.scrollUntilVisible(
      licenseFinder,
      300.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(licenseFinder, findsOneWidget);
    expect(find.textContaining(license.deviceCode), findsOneWidget);
    expect(find.text('نَسْخُ الكُودِ'), findsOneWidget);
    expect(find.text('إِدْخَالُ كُودِ التَّفْعِيلِ الآنَ'), findsOneWidget);
  });

  testWidgets('ActivationDialog accepts valid key and activates software', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    final license = LicenseService();
    await license.init();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ActivationDialog.show(context, license),
              child: const Text('Open Activation'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open dialog
    await tester.tap(find.text('Open Activation'));
    await tester.pumpAndSettle();

    expect(find.textContaining(license.deviceCode), findsOneWidget);

    // Enter invalid key
    final inputFinder = find.byType(TextField);
    expect(inputFinder, findsOneWidget);
    await tester.enterText(inputFinder, 'ACT-0000-0000-0000-0000');
    await tester.pumpAndSettle();

    final activateButtonFinder = find.text('تَفْعِيلُ البَرْنَامِجِ الآنَ');
    expect(activateButtonFinder, findsOneWidget);
    await tester.tap(activateButtonFinder);
    await tester.pumpAndSettle();
    expect(find.textContaining('كَوْدُ التَّفْعِيلِ غَيْرُ صَحِيحٍ'), findsOneWidget);

    // Enter valid key from Keygen algorithm
    final validKey = LicenseService.generateActivationKey(license.deviceCode);
    await tester.enterText(inputFinder, validKey);
    await tester.pumpAndSettle();

    await tester.tap(find.text('تَفْعِيلُ البَرْنَامِجِ الآنَ'));
    await tester.pump();

    expect(license.isActivated, isTrue);
    expect(find.textContaining('تَمَّ تَفْعِيلُ البَرْنَامِجِ بِنَجَاحٍ'), findsOneWidget);

    // Advance through the auto-dismiss delay
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
  });

  testWidgets('InteractiveActivityScreen renders Grade 4 Lesson 1 multi-selection, fill, and order activities', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = CurriculumRepository.instance;
    final lesson1 = repo.getGradeById('grade4')!.lessons.firstWhere((l) => l.id == 'g4_l1');
    final ps = ProgressService();
    await ps.init();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: InteractiveActivityScreen(
            activities: lesson1.activities,
            lessonTitle: lesson1.title,
            progressService: ps,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Activity 1: اخْتَرْ الجُمَلَ الفِعْلِيَّةَ
    expect(find.textContaining('اخْتَرْ الجُمَلَ الفِعْلِيَّةَ'), findsWidgets);
    expect(find.textContaining('تَدَخَّلَ الضَّامِنُ لِتَهْدِئَةِ الْوَضْعِ'), findsOneWidget);
    expect(find.textContaining('الطَّالِبُ مُجْتَهِدٌ'), findsOneWidget);
    expect(find.textContaining('سَاعَدَ الجِيرَانُ أَهْلَ الحَيِّ'), findsOneWidget);
    expect(find.textContaining('الْمَدْرَسَةُ جَمِيلَةٌ'), findsOneWidget);
    expect(find.textContaining('كَتَبَ التِّلْمِيذُ وَاجِبَهُ'), findsOneWidget);

    // Tap sentences 1, 3, 5 to select them
    await tester.tap(find.textContaining('تَدَخَّلَ الضَّامِنُ'));
    await tester.tap(find.textContaining('سَاعَدَ الجِيرَانُ'));
    await tester.tap(find.textContaining('كَتَبَ التِّلْمِيذُ'));
    await tester.pumpAndSettle();

    // Check answer
    await tester.tap(find.text('تَحَقَّقْ مِنَ الإِجَابَةِ فِي السَّبُّورَةِ'));
    await tester.pumpAndSettle();

    // Success dialog shown
    expect(find.text('أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ'), findsOneWidget);
    expect(find.textContaining('أَحْسَنْتَ! لَقَدِ اخْتَرْتَ الأَفْعَالَ المُنَاسِبَةَ'), findsOneWidget);

    // Continue to next activity
    await tester.tap(find.text('مُتَابَعَةُ التَّعَلُّمِ'));
    await tester.pumpAndSettle();

    // Activity 2: أَكْمِلْ الجُمْلَةَ بِالفِعْلِ المُنَاسِبِ
    expect(find.textContaining('أَكْمِلْ الجُمْلَةَ بِالفِعْلِ المُنَاسِبِ'), findsWidgets);
    expect(find.text('زَرَعَ'), findsWidgets);
    expect(find.text('كَتَبَ'), findsWidgets);
    expect(find.text('سَاعَدَ'), findsWidgets);
    expect(find.text('نَظَّفَ'), findsWidgets);
  });

  testWidgets('LessonDetailScreen renders Grade 4 Lesson 2 authentic glossary (رصيدي الجديد) and word meaning matching', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = CurriculumRepository.instance;
    final lesson2 = repo.getGradeById('grade4')!.lessons.firstWhere((l) => l.id == 'g4_l2');
    final ps = ProgressService();
    await ps.init();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: LessonDetailScreen(
            lesson: lesson2,
            progressService: ps,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Stage 2: كَلِمَاتِي الجَدِيدَةُ
    await tester.tap(find.text('2. كَلِمَاتِي الجَدِيدَةُ'));
    await tester.pumpAndSettle();

    // Verify رصيدي الجديد header with 3 words
    expect(find.textContaining('رَصِيدِي الجَدِيدُ (3)'), findsWidgets);
    expect(find.text('حَفَاوَةٌ'), findsOneWidget);
    expect(find.text('الهِنْدَامُ'), findsOneWidget);
    expect(find.text('الوَقَارُ'), findsOneWidget);

    // Verify Meaning Matching section with prompt and bank
    expect(find.textContaining('اخْتَرْ لِكُلِّ كَلِمَةٍ مَعْنَاهَا'), findsWidgets);
    expect(find.textContaining('بَنْكُ المَعَانِي المُتَاحَةِ'), findsOneWidget);
    expect(find.text('جَرَّبَ وَعَرَفَ'), findsWidgets);
    expect(find.text('بِعَدَمِ الرِّضَا'), findsWidgets);
    expect(find.text('اطِّلاعٌ'), findsWidgets);
    expect(find.text('تَوَقُّعُهُمْ'), findsWidgets);

    // Target words in matching cards
    expect(find.text('تَفَقَّدَ'), findsOneWidget);
    expect(find.text('بِامْتِعَاضٍ'), findsOneWidget);
    expect(find.text('حَدْسُهُمْ'), findsOneWidget);
    expect(find.text('خَبِرَ'), findsOneWidget);

    // Initially answers are hidden
    expect(find.text('«اطِّلاعٌ»'), findsNothing);

    // Click reveal button for meaning matches (first button of reveal all)
    await tester.tap(find.text('إِظْهَارُ جَمِيعِ الإِجَابَاتِ').first);
    await tester.pumpAndSettle();

    // Now meaning matches are revealed
    expect(find.text('«اطِّلاعٌ»'), findsOneWidget);
    expect(find.text('«بِعَدَمِ الرِّضَا»'), findsOneWidget);
    expect(find.text('«تَوَقُّعُهُمْ»'), findsOneWidget);
    expect(find.text('«جَرَّبَ وَعَرَفَ»'), findsOneWidget);

    // Verify Odd Word Out section prompt and items
    expect(find.textContaining('عَيِّنِ الْعُنْصُرَ الدَّخِيلَ فِي كُلِّ سَطْرٍ'), findsOneWidget);
    expect(find.text('الاحْتِرَامُ'), findsOneWidget);
    expect(find.text('التَّقْدِيرُ'), findsOneWidget);
    expect(find.text('التَّعْظِيمُ'), findsOneWidget);
    expect(find.text('الامْتِعَاضُ'), findsOneWidget);
    expect(find.text('الأَقْسَامُ'), findsOneWidget);
    expect(find.text('الفِنَاءُ'), findsOneWidget);
    expect(find.text('السَّكِينَةُ'), findsOneWidget);
    expect(find.text('الثَّقَافَةُ'), findsOneWidget);
    expect(find.text('الْجَهْلُ'), findsOneWidget);

    // Initially odd word badges are hidden
    expect(find.text('دَخِيلٌ'), findsNothing);

    // Click to reveal odd word for line 1
    final revealFirstFinder = find.text('تَعْيِينُ الدَّخِيلِ').first;
    await tester.ensureVisible(revealFirstFinder);
    await tester.tap(revealFirstFinder);
    await tester.pumpAndSettle();

    // Now line 1 reveals badge and explanation
    expect(find.text('دَخِيلٌ'), findsOneWidget);
    expect(find.textContaining('الامْتِعَاضُ'), findsWidgets);

    // Click to reveal all odd words using the second reveal all button
    final revealAllEnrichmentFinder = find.text('إِظْهَارُ جَمِيعِ الإِجَابَاتِ').last;
    await tester.ensureVisible(revealAllEnrichmentFinder);
    await tester.tap(revealAllEnrichmentFinder);
    await tester.pumpAndSettle();

    // All 3 lines have their odd words revealed
    expect(find.text('دَخِيلٌ'), findsNWidgets(3));
    expect(find.textContaining('السَّكِينَةُ'), findsWidgets);
    expect(find.textContaining('الْجَهْلُ'), findsWidgets);

    // Switch to Stage 4: أُلاَحِظُ وَأَكْتَشِفُ
    final stage4Finder = find.text('4. أُلاَحِظُ وَأَكْتَشِفُ');
    await tester.ensureVisible(stage4Finder);
    await tester.tap(stage4Finder);
    await tester.pumpAndSettle();

    // Verify stage 4 header and paired trigger sentences
    expect(find.textContaining('أُلاَحِظُ وَأَكْتَشِفُ'), findsWidgets);
    expect(find.textContaining('وَضَعَ السَّائِقُ الْحَقَائِبَ أَمَامَ بَابِ الْمَدْرَسَةِ'), findsOneWidget);
    expect(find.textContaining('السَّائِقُ هُوَ الَّذِي وَضَعَ الْحَقَائِبَ أَمَامَ الْبَابِ'), findsOneWidget);
    expect(find.textContaining('شَعَرَ الْمُعَلِّمُ بِامْتِعَاضٍ'), findsOneWidget);
    expect(find.textContaining('الْمُعَلِّمُ هُوَ الَّذِي شَعَرَ بِامْتِعَاضٍ'), findsNWidgets(2));

    // Verify observation questions
    expect(find.textContaining('مَا نَوْعُ الْكَلِمَتَيْنِ (الْمُعَلِّمُ – السَّائِقُ)؟'), findsOneWidget);
    expect(find.textContaining('مَا هِيَ عَلَامَةُ الإِعْرَابِ الظَّاهِرَةُ عَلَى آخِرِ الْكَلِمَتَيْنِ؟'), findsOneWidget);

    // Verify inductive observations / conclusions
    expect(find.textContaining('نَوْعُ الْكَلِمَتَيْنِ (الْمُعَلِّمُ – السَّائِقُ): كِلْتَاهُمَا اسْمٌ'), findsOneWidget);
    expect(find.textContaining('فَاعِلاً'), findsOneWidget);
  });

  testWidgets('Grade 4 Lesson 2 interactive activities render and operate properly (all 5 activities)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = CurriculumRepository.instance;
    final lesson2 = repo.getGradeById('grade4')!.lessons.firstWhere((l) => l.id == 'g4_l2');
    final ps = ProgressService();
    await ps.init();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: InteractiveActivityScreen(
            activities: lesson2.activities,
            lessonTitle: lesson2.title,
            progressService: ps,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Activity 1: sentenceMultiChoice
    expect(find.textContaining('النشاط الأول: اختر الفاعل المناسب'), findsWidgets);
    expect(find.textContaining('الأشجار في الحديقة'), findsOneWidget);
    expect(find.textContaining('القصة للأطفال'), findsOneWidget);
    expect(find.textContaining('الصندوق الثقيل'), findsOneWidget);
    expect(find.textContaining('الكتب في المكتبة'), findsOneWidget);
    expect(find.text('الفَلاَّحُ'), findsOneWidget);
    expect(find.text('الأُمُّ'), findsOneWidget);
    expect(find.text('العَامِلُ'), findsOneWidget);
    expect(find.text('البِنْتُ'), findsOneWidget);

    // Select options for Activity 1
    final opt1 = find.text('الفَلاَّحُ');
    await tester.ensureVisible(opt1);
    await tester.pumpAndSettle();
    await tester.tap(opt1);
    await tester.pumpAndSettle();

    final opt2 = find.text('الأُمُّ');
    await tester.ensureVisible(opt2);
    await tester.pumpAndSettle();
    await tester.tap(opt2);
    await tester.pumpAndSettle();

    final opt3 = find.text('العَامِلُ');
    await tester.ensureVisible(opt3);
    await tester.pumpAndSettle();
    await tester.tap(opt3);
    await tester.pumpAndSettle();

    final opt4 = find.text('البِنْتُ');
    await tester.ensureVisible(opt4);
    await tester.pumpAndSettle();
    await tester.tap(opt4);
    await tester.pumpAndSettle();

    // Check answer
    final checkBtn = find.text('تَحَقَّقْ مِنَ الإِجَابَةِ فِي السَّبُّورَةِ');
    await tester.ensureVisible(checkBtn);
    await tester.tap(checkBtn);
    await tester.pumpAndSettle();

    // Feedback dialog
    expect(find.text('أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ'), findsOneWidget);

    // Continue to Activity 2
    await tester.tap(find.text('مُتَابَعَةُ التَّعَلُّمِ'));
    await tester.pumpAndSettle();

    // Verify Activity 2: sentenceMultiChoice (الحركة الإعرابية)
    expect(find.textContaining('النشاط الثاني: اختر الفاعل الصحيح'), findsWidgets);
    expect(find.textContaining('الرسالة'), findsOneWidget);
    expect(find.text('التِّلْمِيذُ'), findsOneWidget);
    expect(find.text('التِّلْمِيذَ'), findsOneWidget);
    expect(find.text('التِّلْمِيذِ'), findsOneWidget);

    // Reveal answer via teacher mode quick button
    await tester.tap(find.text('إِظْهَارُ الحُلُولِ'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(checkBtn);
    await tester.tap(checkBtn);
    await tester.pumpAndSettle();

    expect(find.text('أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ'), findsOneWidget);
    await tester.tap(find.text('مُتَابَعَةُ التَّعَلُّمِ'));
    await tester.pumpAndSettle();

    // Verify Activity 3: writtenParsing
    expect(find.textContaining('النشاط الثالث: أعرب الكلمات الملونة'), findsWidgets);
    expect(find.textContaining('حَضَرَ المُعَلِّمُ'), findsOneWidget);
    expect(find.textContaining('سَاعَدَ الطَّبِيبُ المَرِيضَ'), findsOneWidget);
    expect(find.textContaining('عَادَ المُسَافِرُ مَسَاءً'), findsOneWidget);
    expect(find.text('إِعْرَابٌ نَمُوذَجِيٌّ'), findsNWidgets(3));

    // Fill model answers
    for (int i = 0; i < 3; i++) {
      final btn = find.text('إِعْرَابٌ نَمُوذَجِيٌّ').at(i);
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(checkBtn);
    await tester.tap(checkBtn);
    await tester.pumpAndSettle();

    expect(find.text('أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ'), findsOneWidget);
    await tester.tap(find.text('مُتَابَعَةُ التَّعَلُّمِ'));
    await tester.pumpAndSettle();

    // Verify Activity 4: openSentenceFill
    expect(find.textContaining('النشاط الرابع: أكمل الجملة بالفاعل المناسب'), findsWidgets);
    expect(find.textContaining('إلى المدرسة مبكرا'), findsOneWidget);
    expect(find.textContaining('القصة في القسم'), findsOneWidget);
    expect(find.textContaining('الأشجار في الحديقة'), findsOneWidget);

    // Reveal answers for Activity 4
    await tester.tap(find.text('إِظْهَارُ الحُلُولِ'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(checkBtn);
    await tester.tap(checkBtn);
    await tester.pumpAndSettle();

    expect(find.text('أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ'), findsOneWidget);
    await tester.tap(find.text('مُتَابَعَةُ التَّعَلُّمِ'));
    await tester.pumpAndSettle();

    // Verify Activity 5: textExtractionTable
    expect(find.textContaining('النشاط الخامس: نص جديد - استخرج الفاعل'), findsWidgets);
    expect(find.textContaining('فِي صَبَاحِ يَوْمٍ جَمِيلٍ خَرَجَ التَّلَامِيذُ إِلَى سَاحَةِ الْمَدْرَسَةِ'), findsOneWidget);
    expect(find.textContaining('جَدْوَلُ الفَاعِلِ وَإِعْرَابِهِ'), findsOneWidget);
    expect(find.text('التَّلَامِيذُ'), findsWidgets);
    expect(find.text('سَامِي'), findsWidgets);
    expect(find.text('مَرْيَمُ'), findsWidgets);
    expect(find.text('الْمُعَلِّمُ'), findsWidgets);
    expect(find.text('الْهَوَاءُ'), findsWidgets);
    expect(find.text('الْأَطْفَالُ'), findsWidgets);
    expect(find.text('الْحَارِسُ'), findsWidgets);

    // Reveal all table rows
    await tester.tap(find.text('إِظْهَارُ جَمِيعِ الإِعْرَابَاتِ'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(checkBtn);
    await tester.tap(checkBtn);
    await tester.pumpAndSettle();

    expect(find.text('أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ'), findsOneWidget);
  });

  testWidgets('Grade 4 Lesson 3 (بين جارين - المفعول به) full reading, discovery, and 5 activities test', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = CurriculumRepository.instance;
    final grade4 = repo.getGradeById('grade4')!;
    final lesson3 = grade4.lessons.firstWhere((l) => l.id == 'g4_l3');

    // 1. Verify Lesson Metadata & Reading Stage
    expect(lesson3.title, contains('بَيْنَ جَارَيْنِ'));
    expect(lesson3.readingPassage, isNotNull);
    final passage = lesson3.readingPassage!;
    expect(passage.vocabulary.length, equals(6));
    expect(passage.vocabulary.where((v) => !v.isAntonym).map((v) => v.word).toList(), equals(['الشَّقَّةُ', 'المُبَيِّضُ']));
    expect(passage.vocabulary.where((v) => v.isAntonym).map((v) => v.word).toList(), equals(['يُزَيِّنُ', 'تَافِهَةٌ', 'الجَمِيلَةُ', 'لِتَثْبِيتٍ']));
    expect(passage.comprehensionQuestions.length, equals(9));
    expect(passage.synonymReplacements.length, equals(3));
    expect(passage.enrichment, isNotNull);
    expect(passage.enrichment!.complementaryPairs.length, equals(10));
    expect(passage.enrichment!.derivations.length, equals(5));

    // 2. Verify Discovery Stage
    expect(lesson3.discovery, isNotNull);
    expect(lesson3.discovery!.triggerSentences.first, contains('نَظَّفَتْ سُعَادُ الشَّقَّةَ'));
    expect(lesson3.discovery!.observationQuestions.length, equals(2));

    // 3. Verify Activities Structure
    expect(lesson3.activities.length, equals(5));
    expect(lesson3.activities[0].type, equals(ActivityType.sentenceTargetTap));
    expect(lesson3.activities[1].type, equals(ActivityType.openSentenceFill));
    expect(lesson3.activities[1].showSuggestions, isFalse);
    expect(lesson3.activities[2].type, equals(ActivityType.sentencePartsAnalysis));
    expect(lesson3.activities[3].type, equals(ActivityType.writtenParsing));
    expect(lesson3.activities[4].type, equals(ActivityType.textWordExtraction));

    // 4. Test Interactive Activities Screen Rendering & Flow
    final progressService = ProgressService();
    await progressService.init();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: InteractiveActivityScreen(
            activities: lesson3.activities,
            lessonTitle: lesson3.title,
            progressService: progressService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Activity 1: sentenceTargetTap
    expect(find.textContaining('النشاط الأول: حدد المفعول به'), findsWidgets);
    expect(find.text('الصَّحْنَ.'), findsOneWidget);
    expect(find.text('الحَقِيبَةَ.'), findsOneWidget);

    // Reveal answers for Activity 1
    await tester.tap(find.text('إِظْهَارُ الحُلُولِ'));
    await tester.pumpAndSettle();

    final checkBtn = find.text('تَحَقَّقْ مِنَ الإِجَابَةِ فِي السَّبُّورَةِ');
    await tester.ensureVisible(checkBtn);
    await tester.tap(checkBtn);
    await tester.pumpAndSettle();

    expect(find.text('أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ'), findsOneWidget);
    await tester.tap(find.text('مُتَابَعَةُ التَّعَلُّمِ'));
    await tester.pumpAndSettle();

    // Verify Activity 2: openSentenceFill (without suggestion chips)
    expect(find.textContaining('النشاط الثاني: أكمل الجملة بالمفعول به المناسب'), findsWidgets);
    expect(find.textContaining('نظف العامل'), findsOneWidget);
    expect(find.textContaining('قرأ التلميذ'), findsOneWidget);
    // Ensure no suggestion chips are rendered
    expect(find.text('مُقْتَرَحَاتٌ: '), findsNothing);

    // Reveal answers for Activity 2
    await tester.tap(find.text('إِظْهَارُ الحُلُولِ'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(checkBtn);
    await tester.tap(checkBtn);
    await tester.pumpAndSettle();

    expect(find.text('أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ'), findsOneWidget);
    await tester.tap(find.text('مُتَابَعَةُ التَّعَلُّمِ'));
    await tester.pumpAndSettle();

    // Verify Activity 3: sentencePartsAnalysis
    expect(find.textContaining('النشاط الثالث: استخرج الفعل والفاعل والمفعول به'), findsWidgets);
    expect(find.textContaining('أصلح العامل الباب'), findsWidgets);
    expect(find.textContaining('قرأ سامي القصة'), findsWidgets);
    expect(find.textContaining('نظفت سعاد الشقة'), findsWidgets);

    // Reveal answers for Activity 3
    await tester.tap(find.text('إِظْهَارُ الحُلُولِ'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(checkBtn);
    await tester.tap(checkBtn);
    await tester.pumpAndSettle();

    expect(find.text('أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ'), findsOneWidget);
    await tester.tap(find.text('مُتَابَعَةُ التَّعَلُّمِ'));
    await tester.pumpAndSettle();

    // Verify Activity 4: writtenParsing
    expect(find.textContaining('النشاط الرابع: أعرب الكلمة الملونة'), findsWidgets);
    expect(find.text('إِعْرَابٌ نَمُوذَجِيٌّ'), findsNWidgets(3));

    // Fill model answers
    for (int i = 0; i < 3; i++) {
      final btn = find.text('إِعْرَابٌ نَمُوذَجِيٌّ').at(i);
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(checkBtn);
    await tester.tap(checkBtn);
    await tester.pumpAndSettle();

    expect(find.text('أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ'), findsOneWidget);
    await tester.tap(find.text('مُتَابَعَةُ التَّعَلُّمِ'));
    await tester.pumpAndSettle();

    // Verify Activity 5: textWordExtraction
    expect(find.textContaining('النشاط الخامس: استخرج المفعول به من النص'), findsWidgets);
    expect(find.textContaining('قَائِمَةُ المَفَاعِيلِ بِهِ المَطْلُوبَةِ'), findsOneWidget);

    // Reveal answers for Activity 5
    await tester.tap(find.text('إِظْهَارُ الحُلُولِ'));
    await tester.pumpAndSettle();

    expect(find.textContaining('نَظَّفَ الأَبُ الحَدِيقَةَ'), findsWidgets);

    await tester.ensureVisible(checkBtn);
    await tester.tap(checkBtn);
    await tester.pumpAndSettle();

    expect(find.text('أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ'), findsOneWidget);
  });

  test('Grade 5 Curriculum Pack contains all authentic lessons with 5-stage models and activities', () {
    final repo = CurriculumRepository.instance;
    final grade5 = repo.getGradeById('grade5');
    expect(grade5, isNotNull);
    expect(grade5!.gradeNumber, equals(5));
    expect(grade5.title, contains('السنة الخامسة'));
    expect(grade5.units.length, equals(1));
    expect(grade5.lessons.length, equals(3));

    // Lesson 1: نواصب الفعل المضارع
    final l1 = grade5.lessons.firstWhere((l) => l.id == 'g5_l1');
    expect(l1.title, contains('نواصب الفعل المضارع'));
    expect(l1.readingPassage, isNotNull);
    expect(l1.readingPassage!.title, contains('تَاكْفَارِينَاسُ يَتَحَدَّثُ'));
    for (final p in l1.readingPassage!.paragraphs) {
      expect(p.contains(r'\n'), isFalse, reason: 'Paragraphs should not contain literal \\n string');
    }
    expect(l1.readingPassage!.vocabulary.length, greaterThanOrEqualTo(3));
    expect(l1.readingPassage!.enrichment, isNotNull);
    expect(l1.readingPassage!.enrichment!.complementaryPairs.isNotEmpty, isTrue);
    expect(l1.discovery, isNotNull);
    expect(l1.discovery!.targetWords, contains('يَقْبَلَ'));
    expect(l1.activities.length, equals(5));

    // Lesson 2: جوازم الفعل المضارع
    final l2 = grade5.lessons.firstWhere((l) => l.id == 'g5_l2');
    expect(l2.title, contains('جوازم الفعل المضارع'));
    expect(l2.readingPassage, isNotNull);
    expect(l2.readingPassage!.title, contains('كُلُّنَا أَبْنَاءُ وَطَنٍ وَاحِدٍ'));
    for (final p in l2.readingPassage!.paragraphs) {
      expect(p.contains(r'\n'), isFalse);
    }
    expect(l2.readingPassage!.enrichment!.derivations.first.hasGroupedDerivations, isTrue);
    expect(l2.readingPassage!.enrichment!.derivations.first.derivedVerbs, isNotEmpty);
    expect(l2.readingPassage!.enrichment!.derivations.first.derivedNouns, isNotEmpty);
    expect(l2.activities.length, equals(5));

    // Lesson 3: الفعل المبني للمجهول ونائب الفاعل
    final l3 = grade5.lessons.firstWhere((l) => l.id == 'g5_l3');
    expect(l3.title, contains('الفعل المبني للمجهول ونائب الفاعل'));
    expect(l3.readingPassage, isNotNull);
    expect(l3.readingPassage!.title, contains('أَرْضٌ غَالِيَةٌ'));
    for (final p in l3.readingPassage!.paragraphs) {
      expect(p.contains(r'\n'), isFalse, reason: 'Paragraphs should not contain literal \\n string');
    }
    expect(l3.activities.length, equals(5));
    expect(l3.activities[0].allowNoneOption, isTrue);
    expect(l3.activities[4].tableHeaders, isNotNull);
    expect(l3.activities[4].tableHeaders!.length, equals(5));

    // Comprehensive Quiz for Grade 5
    expect(grade5.comprehensiveQuiz, isNotNull);
    expect(grade5.comprehensiveQuiz.questions.length, equals(10));
  });

  testWidgets('Grade 5 Lesson 1 (تاكفاريناس - نواصب المضارع) interactive activities test', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = CurriculumRepository.instance;
    final grade5 = repo.getGradeById('grade5')!;
    final l1 = grade5.lessons.firstWhere((l) => l.id == 'g5_l1');
    final ps = ProgressService();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: InteractiveActivityScreen(
            activities: l1.activities,
            lessonTitle: l1.title,
            progressService: ps,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Activity 1: Target Tap for Subjunctive Verbs
    expect(find.textContaining('النشاط الأول: أتعرف الفعل المضارع المنصوب'), findsWidgets);
    expect(find.text('يَحْرِصُ'), findsOneWidget);

    // Reveal answers for Activity 1 via teacher quick-control
    await tester.tap(find.text('إِظْهَارُ الحُلُولِ'));
    await tester.pumpAndSettle();

    // Check verification button
    final checkBtn = find.text('تَحَقَّقْ مِنَ الإِجَابَةِ فِي السَّبُّورَةِ');
    await tester.ensureVisible(checkBtn);
    await tester.tap(checkBtn);
    await tester.pumpAndSettle();

    expect(find.text('أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ'), findsOneWidget);
  });

  testWidgets('Grade 5 Lesson 3 Activity 1 (أرض غالية - تمييز المبني للمجهول)', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = CurriculumRepository.instance;
    final grade5 = repo.getGradeById('grade5')!;
    final l3 = grade5.lessons.firstWhere((l) => l.id == 'g5_l3');
    final ps = ProgressService();

    // Test Activity 1: Sentence target tap with allowNoneOption
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: InteractiveActivityScreen(
            activities: l3.activities,
            lessonTitle: l3.title,
            progressService: ps,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('النشاط الأول: أَكْتَشِفُ الأَفْعَالَ المَبْنِيَّةَ لِلْمَجْهُولِ'), findsWidgets);
    // Verify none option chip exists
    expect(find.text('لا يُوجَدُ فِعْلٌ مَبْنِيٌّ لِلْمَجْهُولِ'), findsWidgets);

    // Reveal solutions for Activity 1
    await tester.tap(find.text('إِظْهَارُ الحُلُولِ'));
    await tester.pumpAndSettle();

    final checkBtn1 = find.text('تَحَقَّقْ مِنَ الإِجَابَةِ فِي السَّبُّورَةِ');
    await tester.ensureVisible(checkBtn1);
    await tester.tap(checkBtn1);
    await tester.pumpAndSettle();

    expect(find.text('أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ'), findsOneWidget);
  });

  testWidgets('Grade 5 Lesson 3 Activity 5 (استخراج وتحليل في جدول 5 أعمدة)', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = CurriculumRepository.instance;
    final grade5 = repo.getGradeById('grade5')!;
    final l3 = grade5.lessons.firstWhere((l) => l.id == 'g5_l3');
    final ps = ProgressService();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: InteractiveActivityScreen(
            activities: [l3.activities[4]],
            lessonTitle: l3.title,
            progressService: ps,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('النشاط الخامس: اسْتِخْرَاجٌ وَتَحْلِيلٌ مِنَ النَّصِّ'), findsWidgets);
    expect(find.text('الفِعْلُ المَبْنِيُّ لِلْمَجْهُولِ'), findsOneWidget);
    expect(find.text('زَمَنُ الفِعْلِ'), findsOneWidget);
    expect(find.text('نَائِبُ الفَاعِلِ'), findsOneWidget);
    expect(find.text('عَلَامَةُ بِنَاءِ/رَفْعِ الفِعْلِ'), findsOneWidget);
    expect(find.text('عَلَامَةُ رَفْعِ نَائِبِ الفَاعِلِ'), findsOneWidget);

    await tester.tap(find.text('إِظْهَارُ الحُلُولِ'));
    await tester.pumpAndSettle();

    final checkBtn5 = find.text('تَحَقَّقْ مِنَ الإِجَابَةِ فِي السَّبُّورَةِ');
    await tester.ensureVisible(checkBtn5);
    await tester.tap(checkBtn5);
    await tester.pumpAndSettle();

    expect(find.text('أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ'), findsOneWidget);
  });

  test('Grade 5 audio tracks are properly wired and WAV durations are accurately parsed', () async {
    final repo = CurriculumRepository.instance;
    final grade5 = repo.getGradeById('grade5')!;

    // Lesson 1: تاكفاريناس يتحدث
    final l1 = grade5.lessons.firstWhere((l) => l.id == 'g5_l1');
    expect(l1.readingPassage!.hasAudio, isTrue);
    expect(l1.readingPassage!.audioTracks.length, equals(1));
    final track1 = l1.readingPassage!.audioTracks.first;
    expect(track1.assetPath, equals('assets/sounds/5_1/1.wav'));
    expect(track1.paragraphIndices, equals([0, 1, 2, 3, 4, 5]));
    final dur1 = await AudioPlayerService.instance.getTrackDuration(track1);
    expect(dur1, greaterThan(130000));
    expect(dur1, lessThan(140000));

    // Lesson 2: كلنا أبناء وطن واحد
    final l2 = grade5.lessons.firstWhere((l) => l.id == 'g5_l2');
    expect(l2.readingPassage!.hasAudio, isTrue);
    expect(l2.readingPassage!.audioTracks.length, equals(1));
    final track2 = l2.readingPassage!.audioTracks.first;
    expect(track2.assetPath, equals('assets/sounds/5_2/1.wav'));
    expect(track2.paragraphIndices, equals([0, 1, 2]));
    final dur2 = await AudioPlayerService.instance.getTrackDuration(track2);
    expect(dur2, greaterThan(130000));
    expect(dur2, lessThan(140000));

    // Lesson 3: أرض غالية
    final l3 = grade5.lessons.firstWhere((l) => l.id == 'g5_l3');
    expect(l3.readingPassage!.hasAudio, isTrue);
    expect(l3.readingPassage!.audioTracks.length, equals(1));
    final track3 = l3.readingPassage!.audioTracks.first;
    expect(track3.assetPath, equals('assets/sounds/5_3/1.wav'));
    expect(track3.paragraphIndices, equals([0, 1, 2, 3]));
    final dur3 = await AudioPlayerService.instance.getTrackDuration(track3);
    expect(dur3, greaterThan(140000));
    expect(dur3, lessThan(155000));
  });

  testWidgets('LessonDetailScreen renders teacher audio toolbar button and controls for Grade 5 Lesson 1', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = CurriculumRepository.instance;
    final grade5 = repo.getGradeById('grade5')!;
    final l1 = grade5.lessons.firstWhere((l) => l.id == 'g5_l1');
    final ps = ProgressService();
    await ps.init();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: LessonDetailScreen(
            lesson: l1,
            progressService: ps,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Teacher Header Audio Action button exists
    final audioBtn = find.text('المَقْطَعُ الصَّوْتِيُّ');
    expect(audioBtn, findsOneWidget);

    // Audio player widget is initially not shown
    expect(find.text('إِخْفَاءُ الصَّوْتِ'), findsNothing);

    // Tap to open Audio Player Widget
    await tester.tap(audioBtn);
    await tester.pumpAndSettle();

    // Audio player should now be visible with track title and close action
    expect(find.text('إِخْفَاءُ الصَّوْتِ'), findsOneWidget);
    expect(find.textContaining('تَاكْفَارِينَاسُ يَتَحَدَّثُ'), findsWidgets);

    // Tap to hide audio player
    await tester.tap(find.text('إِخْفَاءُ الصَّوْتِ'));
    await tester.pumpAndSettle();

    // Reverted back to closed state
    expect(find.text('المَقْطَعُ الصَّوْتِيُّ'), findsOneWidget);
    expect(find.text('إِخْفَاءُ الصَّوْتِ'), findsNothing);
  });

  testWidgets('MultiSentenceFillWidget supports reusable particles and direct inline chip selection', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = CurriculumRepository.instance;
    final grade5 = repo.getGradeById('grade5')!;
    final l1 = grade5.lessons.firstWhere((l) => l.id == 'g5_l1');
    final activity = l1.activities.firstWhere((a) => a.id == 'g5_l1_a2');

    bool isValid = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              child: MultiSentenceFillWidget(
                sentences: activity.sentenceItems!,
                availableWords: activity.availableWords!,
                solutions: activity.sentenceSolutions!,
                areAnswersRevealed: false,
                onValidationChanged: (v) {
                  isValid = v;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and 8 sentences exist
    expect(find.textContaining('بَنْكُ الكَلِمَاتِ'), findsOneWidget);
    expect(find.textContaining('اخْتَرْ مُبَاشَرَةً:'), findsNWidgets(8));

    // Notice we have 4 words in bank: ['أَنْ', 'لَنْ', 'كَيْ', 'لِـ']
    // And 8 sentences! They must be reusable.
    // Let's place the solutions for each sentence using the in-place direct chips
    for (int i = 0; i < activity.sentenceItems!.length; i++) {
      final sentence = activity.sentenceItems![i];
      final correctWord = activity.sentenceSolutions![sentence]!;

      // Find the specific inline choice chip for sentence i
      final chipKey = Key('sentence_${i}_word_$correctWord');
      final chipFinder = find.byKey(chipKey);

      // Ensure the chip is scrolled into view before tapping
      await tester.ensureVisible(chipFinder);
      await tester.pumpAndSettle();

      await tester.tap(chipFinder);
      await tester.pumpAndSettle();
    }

    // After placing words in multiple sentences, verify words never empty or disappear
    expect(find.text('تم وضع جميع الكلمات في الجمل ✓'), findsNothing);

    // Validation should succeed when correct
    expect(isValid, isTrue);
  });

  testWidgets('InteractiveActivityScreen supports free non-linear navigation between activities via tabs and prev/next buttons', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = CurriculumRepository.instance;
    final grade4 = repo.getGradeById('grade4')!;
    final l2 = grade4.lessons.firstWhere((l) => l.id == 'g4_l2');
    final ps = ProgressService();
    await ps.init();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: InteractiveActivityScreen(
            activities: l2.activities,
            lessonTitle: l2.title,
            progressService: ps,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Starts on Activity 1
    expect(find.textContaining('النشاط الأول: اختر الفاعل المناسب'), findsWidgets);

    // Verify activity tabs exist (all 5 activities are directly selectable)
    expect(find.byKey(const Key('activity_tab_0')), findsOneWidget);
    expect(find.byKey(const Key('activity_tab_1')), findsOneWidget);
    expect(find.byKey(const Key('activity_tab_2')), findsOneWidget);
    expect(find.byKey(const Key('activity_tab_3')), findsOneWidget);
    expect(find.byKey(const Key('activity_tab_4')), findsOneWidget);

    // 2. Jump directly to Activity 4 (Open Sentence Fill) without doing 1, 2, 3!
    final tab3 = find.byKey(const Key('activity_tab_3'));
    await tester.ensureVisible(tab3);
    await tester.pumpAndSettle();
    await tester.tap(tab3);
    await tester.pumpAndSettle();

    expect(find.textContaining('النشاط الرابع: أكمل الجملة بالفاعل المناسب'), findsWidgets);
    expect(find.textContaining('إلى المدرسة مبكرا'), findsOneWidget);

    // 3. Jump directly to Activity 3 (Written Parsing)
    final tab2 = find.byKey(const Key('activity_tab_2'));
    await tester.ensureVisible(tab2);
    await tester.pumpAndSettle();
    await tester.tap(tab2);
    await tester.pumpAndSettle();

    expect(find.textContaining('النشاط الثالث: أعرب الكلمات الملونة'), findsWidgets);
    expect(find.textContaining('حَضَرَ المُعَلِّمُ'), findsOneWidget);

    // 4. Test Next button (moves to Activity 4)
    final nextBtn = find.text('التَّالِي');
    expect(nextBtn, findsOneWidget);
    await tester.ensureVisible(nextBtn);
    await tester.pumpAndSettle();
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    expect(find.textContaining('النشاط الرابع: أكمل الجملة بالفاعل المناسب'), findsWidgets);

    // 5. Test Previous button (moves back to Activity 3)
    final prevBtn = find.text('السَّابِقُ');
    expect(prevBtn, findsOneWidget);
    await tester.ensureVisible(prevBtn);
    await tester.pumpAndSettle();
    await tester.tap(prevBtn);
    await tester.pumpAndSettle();

    expect(find.textContaining('النشاط الثالث: أعرب الكلمات الملونة'), findsWidgets);
  });
}





