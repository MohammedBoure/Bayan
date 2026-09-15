import 'package:flutter_test/flutter_test.dart';
import 'package:nahw_app/main.dart';
import 'package:nahw_app/nlp/arabic_linguistics_engine.dart';
import 'package:nahw_app/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Arabic Linguistics Engine parses verbal sentence correctly', () {
    const sentence = 'كَتَبَ التِّلْمِيذُ الدَّرْسَ';
    final tokens = ArabicLinguisticsEngine.parseVerbalSentence(sentence);

    expect(tokens.length, equals(3));
    expect(tokens[0].pos, equals('فعل'));
    expect(tokens[0].subType, contains('ماض'));
    expect(tokens[1].subType, equals('فاعل'));
    expect(tokens[2].subType, equals('مفعول به'));
  });

  test('Arabic Linguistics Engine checks grammar errors correctly', () {
    // Sentence with wrong subject voweling (accusative fatha instead of nominative damma)
    const errorSentence = 'كَتَبَ التِّلْمِيذَ الدَّرْسَ';
    final issues = ArabicLinguisticsEngine.checkGrammar(errorSentence);

    expect(issues.isNotEmpty, isTrue);
    expect(issues.first.type, equals(GrammarIssueType.subjectCaseError));
  });

  testWidgets('App launches and renders Home Screen', (WidgetTester tester) async {
    final progressService = ProgressService();
    await tester.pumpWidget(NahwApp(progressService: progressService));
    await tester.pumpAndSettle();

    expect(find.textContaining('بُسْتَانُ النَّحْوِ'), findsWidgets);
    expect(find.textContaining('اِبْـدَأِ التَّعَلُّـمَ'), findsOneWidget);
  });
}
