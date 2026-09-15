import 'package:flutter/material.dart';
import '../models/nlp_token_model.dart';
import '../nlp/arabic_linguistics_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/sentence_parser_view.dart';

/// المختبر اللغوي الآلي الذكي (Computational Linguistics Lab Screen)
/// Implements the central pillar of the tasks.md specification:
/// - المحلل اللغوي الآلي (Automated Morpho-Syntactic Parser)
/// - المدقق النحوي والصرفي (Grammatical & Case Checker)
/// - المُشكّل الآلي (Automatic Diacritizer)
/// - التغذية الراجعة الذكية الفورية (Instant Pedagogical Feedback)
class NlpLabScreen extends StatefulWidget {
  const NlpLabScreen({super.key});

  @override
  State<NlpLabScreen> createState() => _NlpLabScreenState();
}

class _NlpLabScreenState extends State<NlpLabScreen> {
  final TextEditingController _sentenceController = TextEditingController(
    text: 'كَتَبَ التِّلْمِيذُ الدَّرْسَ',
  );

  List<NlpToken> _parsedTokens = [];
  String _autoDiacritized = '';
  List<GrammarIssue> _grammarIssues = [];
  bool _hasAnalyzed = false;

  final List<String> _sampleSentences = [
    'كَتَبَ التِّلْمِيذُ الدَّرْسَ',
    'يَقْرَأُ الطِّفْلُ قِصَّةً جَمِيلَةً',
    'اِحْفَظْ دَرْسَكَ يَا عَلِيُّ',
    'يَبْنِي العُمَّالُ مَدْرَسَةً',
    'كَتَبَ التِّلْمِيذَ الدَّرْسُ', // Example with intentional grammatical error to test checker!
  ];

  @override
  void initState() {
    super.initState();
    _analyzeSentence();
  }

  void _analyzeSentence() {
    final text = _sentenceController.text.trim();
    if (text.isEmpty) return;

    final tokens = ArabicLinguisticsEngine.parseVerbalSentence(text);
    final diacritized = ArabicLinguisticsEngine.autoDiacritizeSentence(text);
    final issues = ArabicLinguisticsEngine.checkGrammar(text);

    setState(() {
      _parsedTokens = tokens;
      _autoDiacritized = diacritized;
      _grammarIssues = issues;
      _hasAnalyzed = true;
    });
  }

  @override
  void dispose() {
    _sentenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المُخْتَبَرُ اللُّغَوِيُّ الآلِيُّ (اللسانيات الحاسوبية)'),
          backgroundColor: AppTheme.verbColor,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Banner with Linguistics Lab Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Image.asset(
                            'assets/images/linguistics_lab.jpg',
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 120,
                              color: AppTheme.verbColor.withValues(alpha: 0.15),
                              child: const Icon(Icons.psychology_rounded, size: 50, color: AppTheme.verbColor),
                            ),
                          ),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 16,
                            child: Row(
                              children: const [
                                Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'المحلل النحوي والصرفي والمُشكّل الآلي',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input sentence section
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.verbColor.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'أَدْخِلْ أَوْ اخْتَرْ جُمْلَةً لِتَحْلِيلِهَا آلِيّاً:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _sentenceController,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'اكتب جملة فعلية هنا...',
                              filled: true,
                              fillColor: AppTheme.backgroundLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () => _sentenceController.clear(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Quick Sample Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _sampleSentences.map((sample) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: ActionChip(
                                    label: Text(sample),
                                    onPressed: () {
                                      _sentenceController.text = sample;
                                      _analyzeSentence();
                                    },
                                    backgroundColor: AppTheme.primaryLight,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Run Analysis Button
                          ElevatedButton.icon(
                            onPressed: _analyzeSentence,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.verbColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.analytics_rounded, color: Colors.white),
                            label: const Text(
                              'تَحْلِيلُ الجُمْلَةِ وَتَدْقِيقُهَا لُغَوِيّاً',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Analysis Results
                    if (_hasAnalyzed) ...[
                      // 1. Syntactic & Morphological Parser Output
                      SentenceParserView(
                        tokens: _parsedTokens,
                        showTashkeel: true,
                        title: 'نَتَائِجُ التَّحْلِيلِ النَّحْوِيِّ وَالصَّرْفِيِّ الآلِيِّ:',
                      ),
                      const SizedBox(height: 20),

                      // 2. Automated Diacritization Result (المُشكّل الآلي)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.format_color_text_rounded, color: AppTheme.primaryTeal, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'المُشَكِّلُ الآلِيُّ (اقْتِرَاحُ الضَّبْطِ الإِعْرَابِيِّ):',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                _autoDiacritized,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'يقوم المُشكّل الآلي بضبط أواخر الكلمات بناءً على الموقع الإعرابي (الضمة للفاعل، والفتحة للمفعول به والفعل الماضي، والسكون لفعل الأمر).',
                              style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Automated Grammar & Spell Checker (المدقق النحوي والصرفي الآلي)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _grammarIssues.isEmpty
                                ? AppTheme.successGreen.withValues(alpha: 0.4)
                                : AppTheme.errorRed.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _grammarIssues.isEmpty ? Icons.verified_rounded : Icons.warning_amber_rounded,
                                  color: _grammarIssues.isEmpty ? AppTheme.successGreen : AppTheme.errorRed,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'المُدَقِّقُ النَّحْوِيُّ وَالصَّرْفِيُّ الآلِيُّ:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _grammarIssues.isEmpty ? AppTheme.successGreen : AppTheme.errorRed,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_grammarIssues.isEmpty) ...[
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'الجملة سليمة نحوياً وصرفياً ومطابقة لقواعد الجملة الفعلية المقررة.',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.successGreen),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              ..._grammarIssues.map((issue) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorRed.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'تنبيه على كلمة "${issue.word}": ${issue.rule}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.errorRed,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        issue.suggestion,
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
