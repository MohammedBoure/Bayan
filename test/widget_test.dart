import 'package:flutter_test/flutter_test.dart';
import 'package:nahw_app/main.dart';
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

    // "بحر" is identified as a noun and mubtada due to the following adjective "واسع" and inherent noun lexicon
    expect(result.type, equals(SentenceType.nominal));
    expect(result.tokens[0].pos, equals('اسم'));
    expect(result.tokens[0].subType, equals('مبتدأ'));
    expect(result.tokens[1].subType, equals('خبر المبتدأ'));
  });

  test('User Corrections & Overrides apply with top priority (Feedback Loop)', () async {
    // Override word "سيارة"
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

  testWidgets('App launches and renders Home Screen', (WidgetTester tester) async {
    final progressService = ProgressService();
    await tester.pumpWidget(NahwApp(progressService: progressService));
    await tester.pumpAndSettle();

    expect(find.textContaining('بُسْتَانُ النَّحْوِ'), findsWidgets);
    expect(find.textContaining('اِبْـدَأِ التَّعَلُّـمَ'), findsOneWidget);
  });
}
