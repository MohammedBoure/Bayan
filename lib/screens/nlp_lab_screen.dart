import 'package:flutter/material.dart';
import '../models/nlp_token_model.dart';
import '../nlp/arabic_linguistics_engine.dart';
import '../services/nlp_database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sentence_parser_view.dart';

/// المختبر اللغوي الآلي الذكي (Computational Linguistics Lab Screen)
/// يدعم المحلل النحوي والصرفي الهجين (Hybrid Rule Engine + Bigram Context)
/// ونظام التخزين المؤقت (SQLite Cache) وحلقة التغذية الراجعة والتصحيح التفاعلي (Feedback Loop).
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
  String _sentenceTypeName = 'جُمْلَةٌ اسْمِيَّةٌ';
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
    'كَتَبَ التِّلْمِيذَ الدَّرْسُ', // مثال خطأ مقصود لاختبار المدقق
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

  /// نافذة تعديل وتصحيح إعراب أي كلمة (User Correction & Feedback Loop)
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              title: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppTheme.verbColor, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تصحيح إعراب: "${token.word}"',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('نوع الكلمة (قسم الكلام):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: posOptions.map((pos) {
                        final isSelected = selectedPos == pos;
                        return ChoiceChip(
                          label: Text(pos),
                          selected: isSelected,
                          onSelected: (val) {
                            setDialogState(() => selectedPos = pos);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    const Text('الموقع الإعرابي (الدور النحوي):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subTypeController,
                      decoration: InputDecoration(
                        hintText: 'مثال: مبتدأ، فاعل، مفعول به...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // اختصارات سريعة
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: quickRoles.map((role) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ActionChip(
                              label: Text(role, style: const TextStyle(fontSize: 11.5)),
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
                    const SizedBox(height: 14),

                    const Text('الحالة وعلامة الإعراب:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: caseMarkController,
                      decoration: InputDecoration(
                        hintText: 'مثال: مرفوع وعلامة رفعه الضمة الظاهرة',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('التوضيح التربوي:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: explanationController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'شرح بسيط يوضح سبب هذا الإعراب...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء'),
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.verbColor),
                  icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                  label: const Text('حفظ التصحيح للأبد', style: TextStyle(color: Colors.white)),
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
          title: const Text('المُخْتَبَرُ اللُّغَوِيُّ الآلِيُّ الهَجِينُ (اللسانيات الحاسوبية)'),
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
                    // Header Banner
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Image.asset(
                            'assets/images/linguistics_lab.jpg',
                            height: 125,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 125,
                              color: AppTheme.verbColor.withValues(alpha: 0.15),
                              child: const Icon(Icons.psychology_rounded, size: 50, color: AppTheme.verbColor),
                            ),
                          ),
                          Container(
                            height: 125,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
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
                                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'المحلل الهجين: شجرة قرار + سياق ثنائي + قاعدة أمثلة',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input Section
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
                            'أَدْخِلْ أَوْ اخْتَرْ جُمْلَةً لِتَحْلِيلِهَا آلِيّاً (اسمية، فعلية، ناسخة):',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _sentenceController,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'اكتب الجملة هنا (مثال: المنزل كبير جدا أليس كذلك)...',
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
                                    backgroundColor: sample.contains('المنزل')
                                        ? AppTheme.verbColor.withValues(alpha: 0.15)
                                        : AppTheme.primaryLight,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Run Analysis Button
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _analyzeSentence,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.verbColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.analytics_rounded, color: Colors.white),
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
                      // Sentence Type Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.verbColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.verbColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.category_rounded, color: AppTheme.verbColor, size: 22),
                            const SizedBox(width: 10),
                            const Text(
                              'نَوْعُ التَّرْكِيبِ:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _sentenceTypeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.verbColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. Syntactic & Morphological Parser Output with Edit Capability
                      SentenceParserView(
                        tokens: _parsedTokens,
                        showTashkeel: true,
                        title: 'نَتَائِجُ التَّحْلِيلِ النَّحْوِيِّ وَالصَّرْفِيِّ الآلِيِّ (انقر لتعديل أي كلمة):',
                        onEditToken: _openCorrectionDialog,
                      ),
                      const SizedBox(height: 20),

                      // 2. Automated Diacritization Result
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Automated Grammar Checker
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
                                      'الجملة سليمة نحوياً ومطابقة للقواعد الإعرابية.',
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
