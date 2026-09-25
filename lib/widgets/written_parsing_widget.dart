import 'package:flutter/material.dart';
import '../nlp/arabic_clitic_stemmer.dart';
import '../theme/app_theme.dart';

/// Written Parsing widget (إجابة كتابية + تصحيح آلي) designed for classroom whiteboard and Data Show.
/// Displays sentences with target words highlighted in green, accepts typed student parsing,
/// provides helper word chips for touch boards, and validates accuracy automatically.
class WrittenParsingWidget extends StatefulWidget {
  final List<String> sentences;
  final Map<String, String> coloredWords;
  final Map<String, String> modelParsings;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;

  final List<String>? helperChips;

  const WrittenParsingWidget({
    super.key,
    required this.sentences,
    required this.coloredWords,
    required this.modelParsings,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
    this.helperChips,
  });

  @override
  State<WrittenParsingWidget> createState() => _WrittenParsingWidgetState();
}

class _WrittenParsingWidgetState extends State<WrittenParsingWidget> {
  late Map<String, TextEditingController> _controllers;

  static const List<String> _helperChips = [
    'فَاعِلٌ',
    'مَرْفُوعٌ',
    'وَعَلامَةُ رَفْعِهِ',
    'الضَّمَّةُ الظَّاهِرَةُ',
    'عَلَى آخِرِهِ',
  ];

  static const List<String> _objectHelperChips = [
    'مَفْعُولٌ بِهِ',
    'مَنْصُوبٌ',
    'وَعَلامَةُ نَصْبِهِ',
    'الفَتْحَةُ الظَّاهِرَةُ',
    'عَلَى آخِرِهِ',
  ];

  static const List<String> _subjunctiveHelperChips = [
    'فِعْلٌ مُضَارِعٌ',
    'مَنْصُوبٌ',
    'وَعَلامَةُ نَصْبِهِ',
    'الفَتْحَةُ الظَّاهِرَةُ',
    'الفَتْحَةُ المُقَدَّرَةُ',
    'حَذْفُ النُّونِ',
    'عَلَى آخِرِهِ',
  ];

  static const List<String> _jussiveHelperChips = [
    'فِعْلٌ مُضَارِعٌ',
    'مَجْزُومٌ',
    'وَعَلامَةُ جَزْمِهِ',
    'السُّكُونُ',
    'حَذْفُ النُّونِ',
    'حَذْفُ حَرْفِ العِلَّةِ',
    'وَالفَاعِلُ ضَمِيرٌ مُسْتَتِرٌ',
  ];

  static const List<String> _passiveHelperChips = [
    'فِعْلٌ مَاضٍ',
    'فِعْلٌ مُضَارِعٌ',
    'مَبْنِيٌّ لِلْمَجْهُولِ',
    'نَائِبُ فَاعِلٍ',
    'مَرْفُوعٌ',
    'الضَّمَّةُ الظَّاهِرَةُ',
    'الأَلِفُ',
    'الوَاوُ',
  ];

  List<String> get _effectiveHelperChips {
    if (widget.helperChips != null && widget.helperChips!.isNotEmpty) {
      return widget.helperChips!;
    }
    final allModel = widget.modelParsings.values.join(' ');
    if (allModel.contains('مَجْزُوم') || allModel.contains('مجزوم') || allModel.contains('جزم')) {
      return _jussiveHelperChips;
    }
    if (allModel.contains('مَبْنِيٌّ لِلْمَجْهُولِ') || allModel.contains('مجهول') || allModel.contains('نائب فاعل')) {
      return _passiveHelperChips;
    }
    if (allModel.contains('مَنْصُوب') && (allModel.contains('مُضَارِع') || allModel.contains('مضارع'))) {
      return _subjunctiveHelperChips;
    }
    if (allModel.contains('مَفْعُول') || allModel.contains('مفعول')) {
      return _objectHelperChips;
    }
    return _helperChips;
  }

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  String _getModelParsing(String sentence, String target) {
    if (widget.modelParsings.containsKey(target)) return widget.modelParsings[target]!;
    if (widget.modelParsings.containsKey(sentence)) return widget.modelParsings[sentence]!;
    final cleanT = ArabicCliticStemmer.stripDiacritics(target).trim();
    for (var entry in widget.modelParsings.entries) {
      final cleanK = ArabicCliticStemmer.stripDiacritics(entry.key).trim();
      if (cleanK == cleanT) return entry.value;
    }
    return widget.modelParsings.values.isNotEmpty ? widget.modelParsings.values.first : '';
  }

  void _initControllers() {
    _controllers = {};
    for (var sentence in widget.sentences) {
      final target = widget.coloredWords[sentence] ?? '';
      final initialText = widget.areAnswersRevealed ? _getModelParsing(sentence, target) : '';
      final controller = TextEditingController(text: initialText);
      controller.addListener(_checkValidation);
      _controllers[target] = controller;
    }
    _checkValidation();
  }

  @override
  void didUpdateWidget(WrittenParsingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed && !oldWidget.areAnswersRevealed) {
      for (var sentence in widget.sentences) {
        final target = widget.coloredWords[sentence] ?? '';
        final ctrl = _controllers[target];
        if (ctrl != null) {
          ctrl.text = _getModelParsing(sentence, target);
        }
      }
      widget.onValidationChanged(true);
    } else if (!widget.areAnswersRevealed && oldWidget.areAnswersRevealed) {
      for (var ctrl in _controllers.values) {
        ctrl.clear();
      }
      widget.onValidationChanged(false);
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  bool _isInputValid(String input, String targetWord) {
    if (input.trim().isEmpty) return false;
    final normalized = ArabicCliticStemmer.normalize(ArabicCliticStemmer.stripDiacritics(input));
    final modelParsing = _getModelParsing('', targetWord);
    final modelNorm = ArabicCliticStemmer.normalize(ArabicCliticStemmer.stripDiacritics(modelParsing));

    if (modelNorm.contains('مضارع') && modelNorm.contains('منصوب')) {
      final hasModare = normalized.contains('مضارع');
      final hasMansoub = normalized.contains('منصوب');
      final hasMark = normalized.contains('فتحة') || normalized.contains('فتحه') || normalized.contains('حذف النون');
      return hasModare && hasMansoub && hasMark;
    } else if (modelNorm.contains('مضارع') && modelNorm.contains('مجزوم')) {
      final hasModare = normalized.contains('مضارع');
      final hasMajzoom = normalized.contains('مجزوم');
      final hasMark = normalized.contains('سكون') || normalized.contains('حذف النون') || normalized.contains('حذف حرف العلة') || normalized.contains('العله');
      return hasModare && hasMajzoom && hasMark;
    } else if (modelNorm.contains('مبني للمجهول') || modelNorm.contains('مجهول')) {
      final hasMajhool = normalized.contains('مجهول') || normalized.contains('المجهول');
      final hasFeil = normalized.contains('فعل') || normalized.contains('ماض') || normalized.contains('مضارع');
      return hasMajhool && hasFeil;
    } else if (modelNorm.contains('نائب فاعل')) {
      final hasNaeb = normalized.contains('نائب');
      final hasFaiel = normalized.contains('فاعل');
      final hasMarfoo = normalized.contains('مرفوع');
      return hasNaeb && hasFaiel && hasMarfoo;
    } else if (modelNorm.contains('مفعول')) {
      // Must contain core grammatical elements: مفعول AND منصوب AND فتحة
      final hasMafoool = normalized.contains('مفعول');
      final hasMansoub = normalized.contains('منصوب');
      final hasFatha = normalized.contains('فتحة') || normalized.contains('فتحه') || normalized.contains('ياء') || normalized.contains('كسرة');
      return hasMafoool && hasMansoub && hasFatha;
    } else {
      // Must contain core grammatical elements: فاعل AND مرفوع AND ضمة
      final hasFaiel = normalized.contains('فاعل');
      final hasMarfoo = normalized.contains('مرفوع');
      final hasDamma = normalized.contains('ضمة') || normalized.contains('ضمه') || normalized.contains('الف') || normalized.contains('واو');
      return hasFaiel && hasMarfoo && hasDamma;
    }
  }

  void _checkValidation() {
    if (widget.areAnswersRevealed) {
      widget.onValidationChanged(true);
      return;
    }

    bool allValid = true;
    for (var sentence in widget.sentences) {
      final target = widget.coloredWords[sentence] ?? '';
      final text = _controllers[target]?.text ?? '';
      if (!_isInputValid(text, target)) {
        allValid = false;
        break;
      }
    }
    widget.onValidationChanged(allValid);
  }

  void _insertChip(String targetWord, String chipText) {
    final ctrl = _controllers[targetWord];
    if (ctrl == null) return;

    final current = ctrl.text.trim();
    if (current.isEmpty) {
      ctrl.text = chipText;
    } else {
      ctrl.text = '$current $chipText';
    }
    ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Helper notice banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
          ),
          child: Row(
            children: const [
              Icon(Icons.auto_fix_high_rounded, color: Color(0xFF16A34A), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'اكْتُبِ الإِعْرَابَ فِي الحَقْلِ أَوْ انْقُرْ عَلَى الكَلِمَاتِ المَسَاعِدَةِ لِبِنَاءِ الإِعْرَابِ النَّمُوذَجِيِّ.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // List of parsing sentences
        ...widget.sentences.asMap().entries.map((entry) {
          final idx = entry.key;
          final sentence = entry.value;
          final targetWord = widget.coloredWords[sentence] ?? '';
          final controller = _controllers[targetWord] ?? TextEditingController();
          final text = controller.text;
          final isValid = _isInputValid(text, targetWord) || widget.areAnswersRevealed;
          final modelParsing = _getModelParsing(sentence, targetWord);

          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isValid ? const Color(0xFF16A34A) : (text.isNotEmpty ? AppTheme.accentOrange : const Color(0xFFCBD5E1)),
                width: isValid ? 2.5 : 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isValid ? const Color(0xFF16A34A).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row: Sentence with target word highlighted in bold emerald green
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isValid ? const Color(0xFF16A34A) : AppTheme.primaryTeal,
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildHighlightedSentence(sentence, targetWord),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Target word label and Input field
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                      ),
                      child: Text(
                        '$targetWord:',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        decoration: InputDecoration(
                          hintText: 'اكْتُبِ الإِعْرَابَ هُنَا (فَاعِلٌ مَرْفُوعٌ...)...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: isValid
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 26)
                              : (text.isNotEmpty ? const Icon(Icons.edit_note_rounded, color: AppTheme.accentOrange) : null),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isValid ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                              width: isValid ? 2 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Helper Quick Chips for this row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'مُسَاعِدُ الإِعْرَابِ: ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                    ..._effectiveHelperChips.map((chip) {
                      return ActionChip(
                        label: Text(chip, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        backgroundColor: const Color(0xFFF1F5F9),
                        onPressed: () => _insertChip(targetWord, chip),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () {
                        controller.text = modelParsing;
                        _checkValidation();
                        setState(() {});
                      },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF16A34A)),
                      label: const Text(
                        'إِعْرَابٌ نَمُوذَجِيٌّ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Highlights the target word in green within the sentence using pure TextSpans
  Widget _buildHighlightedSentence(String sentence, String targetWord) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'([\u0600-\u06FF]+|[^\u0600-\u06FF]+)');
    final matches = regex.allMatches(sentence.trim());

    final cleanTarget = ArabicCliticStemmer.stripDiacritics(targetWord).trim();

    for (final match in matches) {
      final token = match.group(0) ?? '';
      if (token.isEmpty) continue;

      final cleanToken = ArabicCliticStemmer.stripDiacritics(token).trim();
      final isTarget = cleanToken == cleanTarget;

      if (isTarget) {
        spans.add(
          TextSpan(
            text: token,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF15803D), // Bold emerald green
              backgroundColor: Color(0xFFDCFCE7), // Soft pastel green highlight
              height: 1.8,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: token,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              height: 1.8,
            ),
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
    );
  }
}
