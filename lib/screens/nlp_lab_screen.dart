import 'package:flutter/material.dart';
import '../models/nlp_token_model.dart';
import '../nlp/arabic_linguistics_engine.dart';
import '../services/nlp_database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sentence_parser_view.dart';

/// المختبر اللغوي الآلي الذكي (Computational Linguistics Lab Screen)
/// Scaled for lecture display on Data Show projectors and interactive whiteboards.
class NlpLabScreen extends StatefulWidget {
  const NlpLabScreen({super.key});

  @override
  State<NlpLabScreen> createState() => _NlpLabScreenState();
}

class _NlpLabScreenState extends State<NlpLabScreen> {
  final TextEditingController _sentenceController = TextEditingController(
    text: 'المنزل كبير جدا أليس كذلك',
  );

  List<NlpToken> _parsedTokens = [];
  String _sentenceTypeName = 'جُمْلَةٌ اسْمِيَّةٌ (مُبْتَدَأٌ وَخَبَرٌ)';
  String _autoDiacritized = '';
  List<GrammarIssue> _grammarIssues = [];
  bool _hasAnalyzed = false;
  bool _isLoading = false;

  final List<String> _sampleSentences = [
    'المنزل كبير جدا أليس كذلك',
    'كَتَبَ التِّلْمِيذُ الدَّرْسَ',
    'يَقْرَأُ الطِّفْلُ قِصَّةً جَمِيلَةً',
    'اِحْفَظْ دَرْسَكَ يَا عَلِيُّ',
    'العِلْمُ نُورٌ وَالجَهْلُ ظَلامٌ',
    'بَحْرٌ وَاسِعٌ وَجَمِيلٌ',
    'كَتَبَ التِّلْمِيذَ الدَّرْسُ', // خطأ مقصود في الفاعل لاختبار المدقق
  ];

  @override
  void initState() {
    super.initState();
    _analyzeSentence();
  }

  Future<void> _analyzeSentence() async {
    final text = _sentenceController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final parseResult = await ArabicLinguisticsEngine.parseSentenceAsync(text);
    final diacritized = ArabicLinguisticsEngine.autoDiacritizeSentence(text);
    final issues = ArabicLinguisticsEngine.checkGrammar(text);

    setState(() {
      _parsedTokens = parseResult.tokens;
      _sentenceTypeName = parseResult.typeArabic;
      _autoDiacritized = diacritized;
      _grammarIssues = issues;
      _hasAnalyzed = true;
      _isLoading = false;
    });
  }

  void _openCorrectionDialog(NlpToken token) {
    String selectedPos = token.pos;
    final subTypeController = TextEditingController(text: token.subType ?? '');
    final caseMarkController = TextEditingController(text: token.caseMark ?? '');
    final explanationController = TextEditingController(text: token.explanation ?? '');

    const posOptions = ['اسم', 'فعل', 'حرف', 'شبه جملة'];
    const quickRoles = [
      'مبتدأ',
      'خبر المبتدأ',
      'فاعل',
      'مفعول به',
      'مفعول مطلق / توكيد',
      'اسم مجرور',
      'فعل ماضٍ ناقص',
      'اسم كان',
      'خبر كان',
      'فعل ماضٍ',
      'فعل مضارع',
      'فعل أمر',
      'نعت / صفة',
      'مضاف إليه',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              title: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppTheme.verbColor, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تصحيح إعراب كلمة: "${token.word}"',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('قسم الكلام (النوع الأساسي):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: posOptions.map((pos) {
                          final isSelected = selectedPos == pos;
                          return ChoiceChip(
                            label: Text(pos, style: const TextStyle(fontSize: 16)),
                            selected: isSelected,
                            onSelected: (val) {
                              setDialogState(() => selectedPos = pos);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      const Text('الموقع الإعرابي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: subTypeController,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'مثال: مبتدأ، فاعل، مفعول به...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: quickRoles.map((role) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ActionChip(
                                label: Text(role, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  setDialogState(() {
                                    subTypeController.text = role;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text('الحالة وعلامة الإعراب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: caseMarkController,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'مثال: مرفوع وعلامة رفعه الضمة الظاهرة',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text('التوضيح التربوي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: explanationController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'شرح مبسط يوضح سبب هذا الإعراب لتلاميذ الصف...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء', style: TextStyle(fontSize: 18)),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    Navigator.of(ctx).pop();
                    await NlpDatabaseService.instance.saveUserCorrection(
                      word: token.plainWord,
                      pos: selectedPos,
                      subType: subTypeController.text.trim(),
                      caseMark: caseMarkController.text.trim(),
                      explanation: explanationController.text.trim(),
                    );
                    await _analyzeSentence();
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('تم حفظ تصحيح كلمة "${token.plainWord}" واعتماده كأولوية قصوى!'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.verbColor, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  icon: const Icon(Icons.save_rounded, color: Colors.white, size: 22),
                  label: const Text('حفظ التصحيح للأبد', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
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
          toolbarHeight: 68,
          title: const Text('المُخْتَبَرُ اللُّغَوِيُّ الآلِيُّ الهَجِينُ (اللسانيات الحاسوبية)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.verbColor,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1450), // Widescreen for Data Show
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Banner
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          Image.asset(
                            'assets/images/linguistics_lab.jpg',
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 140,
                              color: AppTheme.verbColor.withValues(alpha: 0.15),
                              child: const Icon(Icons.psychology_rounded, size: 60, color: AppTheme.verbColor),
                            ),
                          ),
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 20,
                            child: Row(
                              children: const [
                                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
                                SizedBox(width: 10),
                                Text(
                                  'المحلل الهجين: شجرة قرار نحوية + سياق ثنائي + قاعدة أمثلة معربة',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Input Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.verbColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'أَدْخِلْ أَوْ اخْتَرْ جُمْلَةً لِتَحْلِيلِهَا آلِيّاً عَلَى السَّبُّورَةِ (اسمية، فعلية، ناسخة):',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _sentenceController,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'اكتب الجملة هنا (مثال: المنزل كبير جدا أليس كذلك)...',
                              filled: true,
                              fillColor: AppTheme.backgroundLight,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 28),
                                onPressed: () => _sentenceController.clear(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Quick Sample Chips with Large Readability
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _sampleSentences.map((sample) {
                                final isSelectedSample = _sentenceController.text.trim() == sample;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: ActionChip(
                                    label: Text(sample, style: TextStyle(fontSize: 16, fontWeight: isSelectedSample ? FontWeight.bold : FontWeight.w600)),
                                    onPressed: () {
                                      _sentenceController.text = sample;
                                      _analyzeSentence();
                                    },
                                    backgroundColor: isSelectedSample
                                        ? AppTheme.verbColor.withValues(alpha: 0.2)
                                        : AppTheme.primaryLight,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Run Analysis Button
                          SizedBox(
                            height: 64,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _analyzeSentence,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.verbColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : const Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                              label: const Text(
                                'تَحْلِيلُ الجُمْلَةِ وَتَدْقِيقُهَا لُغَوِيّاً',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Analysis Results
                    if (_hasAnalyzed) ...[
                      // Sentence Type Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.verbColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.verbColor, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.category_rounded, color: AppTheme.verbColor, size: 30),
                            const SizedBox(width: 14),
                            const Text(
                              'نَوْعُ التَّرْكِيبِ النَّحْوِيِّ:',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.textDark),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _sentenceTypeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  color: AppTheme.verbColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 1. Syntactic & Morphological Parser Output with Edit Capability
                      SentenceParserView(
                        tokens: _parsedTokens,
                        showTashkeel: true,
                        title: 'نَتَائِجُ التَّحْلِيلِ النَّحْوِيِّ وَالصَّرْفِيِّ الآلِيِّ عَلَى شَاشَةِ العَرْضِ:',
                        onEditToken: _openCorrectionDialog,
                      ),
                      const SizedBox(height: 24),

                      // 2. Automated Diacritization Result
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.primaryTeal, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.format_color_text_rounded, color: AppTheme.primaryTeal, size: 30),
                                SizedBox(width: 10),
                                Text(
                                  'المُشَكِّلُ الآلِيُّ (اقْتِرَاحُ الضَّبْطِ الإِعْرَابِيِّ لِلصَّفِّ):',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                _autoDiacritized,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 34, // Prominent voweling for projector
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Automated Grammar Checker
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _grammarIssues.isEmpty
                                ? AppTheme.successGreen
                                : AppTheme.errorRed,
                            width: 2,
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
                                  size: 32,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'المُدَقِّقُ النَّحْوِيُّ وَالصَّرْفِيُّ الآلِيُّ:',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: _grammarIssues.isEmpty ? AppTheme.successGreen : AppTheme.errorRed,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (_grammarIssues.isEmpty) ...[
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 26),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'الجملة سليمة نحوياً ومطابقة للقواعد الإعرابية المقررة.',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              ..._grammarIssues.map((issue) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorRed.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.errorRed, width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'تنبيه إعرابي على كلمة "${issue.word}": ${issue.rule}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: AppTheme.errorRed,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        issue.suggestion,
                                        style: const TextStyle(fontSize: 16, color: AppTheme.textDark, fontWeight: FontWeight.w600),
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
