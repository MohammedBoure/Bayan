import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nahw_app/data/curriculum_repository.dart';
import 'package:nahw_app/main.dart';
import 'package:nahw_app/models/lesson_model.dart';
import 'package:nahw_app/models/reading_passage_model.dart';
import 'package:nahw_app/nlp/arabic_clitic_stemmer.dart';
import 'package:nahw_app/nlp/arabic_hybrid_parser.dart';
import 'package:nahw_app/screens/lesson_detail_screen.dart';
import 'package:nahw_app/screens/settings_screen.dart';
import 'package:nahw_app/services/audio_player_service.dart';
import 'package:nahw_app/services/license_service.dart';
import 'package:nahw_app/services/nlp_database_service.dart';
import 'package:nahw_app/services/progress_service.dart';
import 'package:nahw_app/theme/app_theme.dart';
import 'package:nahw_app/widgets/activation_dialog.dart';
import 'package:nahw_app/widgets/celebration_dialog.dart';
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
}
