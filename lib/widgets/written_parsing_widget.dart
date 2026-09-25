import 'package:flutter/material.dart';
import '../nlp/arabic_clitic_stemmer.dart';
import '../theme/app_theme.dart';

/// Written Parsing widget (إجابة كتابية + تصحيح آلي) designed for classroom whiteboard and Data Show.
/// Provides:
/// 1) High-visibility sentence card with target word highlighted in emerald green.
/// 2) Model Parsing Builder: A structured interactive toolbar of grammatical building blocks
///    allowing the student to assemble the complete authentic parsing with 1-click chips:
///    - Grammatical Status (فَاعِلٌ / مَفْعُولٌ بِهِ / فِعْلٌ مُضَارِعٌ...)
///    - Case State (مَرْفُوعٌ / مَنْصُوبٌ / مَجْزُومٌ...)
///    - Marker connector (وَعَلَامَةُ رَفْعِهِ / وَعَلَامَةُ نَصْبِهِ / وَعَلَامَةُ جَزْمِهِ...)
///    - Syntactic Marks (الضَّمَّةُ الظَّاهِرَةُ / الفَتْحَةُ الظَّاهِرَةُ / السُّكُونُ / حَذْفُ النُّونِ...)
///    - Position connector (عَلَى آخِرِهِ...)
///    - Full Clause Builder chips for speed.
/// 3) Direct Editing & Controls: Direct text input field, Backspace chip, Clear chip, and Model Answer reveal.
/// 4) Smart validation supporting both exact syntactic combinations and fuzzy NLP verification.
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

  // Complete, categorized syntactic building blocks for Arabic parsing:
  static const List<String> _subjectBuilderChips = [
    'فَاعِلٌ',
    'مَرْفُوعٌ',
    'وَعَلَامَةُ رَفْعِهِ',
    'الضَّمَّةُ الظَّاهِرَةُ',
    'عَلَى آخِرِهِ.',
    'فَاعِلٌ مَرْفُوعٌ وَعَلامَةُ رَفْعِهِ الضَّمَّةُ الظَّاهِرَةُ عَلَى آخِرِهِ.',
  ];

  static const List<String> _objectBuilderChips = [
    'مَفْعُولٌ بِهِ',
    'مَنْصُوبٌ',
    'وَعَلَامَةُ نَصْبِهِ',
    'الفَتْحَةُ الظَّاهِرَةُ',
    'عَلَى آخِرِهِ.',
    'مَفْعُولٌ بِهِ مَنْصُوبٌ وَعَلَامَةُ نَصْبِهِ الفَتْحَةُ الظَّاهِرَةُ عَلَى آخِرِهِ.',
  ];

  static const List<String> _subjunctiveBuilderChips = [
    'فِعْلٌ مُضَارِعٌ',
    'مَنْصُوبٌ بِـ',
    'أَنْ،',
    'لَنْ،',
    'كَيْ،',
    'لَامِ التَّعْلِيلِ،',
    'وَعَلَامَةُ نَصْبِهِ',
    'الفَتْحَةُ الظَّاهِرَةُ',
    'الفَتْحَةُ المُقَدَّرَةُ',
    'حَذْفُ النُّونِ',
    'عَلَى آخِرِهِ.',
    'لِلتَّعَذُّرِ.',
    'لأَنَّهُ مِنَ الأَفْعَالِ الخَمْسَةِ.',
  ];

  static const List<String> _jussiveBuilderChips = [
    'فِعْلٌ مُضَارِعٌ',
    'مَجْزُومٌ بِـ',
    'لَمْ،',
    'لَا النَّاهِيَةِ،',
    'وَعَلَامَةُ جَزْمِهِ',
    'السُّكُونُ،',
    'حَذْفُ النُّونِ',
    'حَذْفُ حَرْفِ العِلَّةِ،',
    'لأَنَّهُ مِنَ الأَفْعَالِ الخَمْسَةِ،',
    'وَالفَاعِلُ ضَمِيرٌ مُسْتَتِرٌ',
  ];

  static const List<String> _passiveBuilderChips = [
    'فِعْلٌ مَاضٍ',
    'فِعْلٌ مُضَارِعٌ',
    'مَبْنِيٌّ لِلْمَجْهُولِ',
    'نَائِبُ فَاعِلٍ',
    'مَرْفُوعٌ',
    'وَعَلَامَةُ رَفْعِهِ',
    'الضَّمَّةُ الظَّاهِرَةُ',
    'الأَلِفُ',
    'الوَاوُ',
    'عَلَى آخِرِهِ.',
  ];

  List<String> _getSpecificHelperChipsFor(String targetWord, String sentence) {
    if (widget.helperChips != null && widget.helperChips!.isNotEmpty) {
      return widget.helperChips!;
    }
    final model = _getModelParsing(sentence, targetWord);
    final norm = ArabicCliticStemmer.normalize(ArabicCliticStemmer.stripDiacritics(model));

    if (norm.contains('مجزوم') || norm.contains('جزم')) {
      return _jussiveBuilderChips;
    }
    if (norm.contains('مجهول') || norm.contains('نائب فاعل')) {
      return _passiveBuilderChips;
    }
    if (norm.contains('منصوب') && norm.contains('مضارع')) {
      return _subjunctiveBuilderChips;
    }
    if (norm.contains('مفعول')) {
      return _objectBuilderChips;
    }
    return _subjectBuilderChips;
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

  bool _isInputValid(String input, String targetWord, String sentence) {
    if (input.trim().isEmpty) return false;
    final normalized = ArabicCliticStemmer.normalize(ArabicCliticStemmer.stripDiacritics(input));
    final modelParsing = _getModelParsing(sentence, targetWord);
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
      final hasMafoool = normalized.contains('مفعول');
      final hasMansoub = normalized.contains('منصوب');
      final hasFatha = normalized.contains('فتحة') || normalized.contains('فتحه') || normalized.contains('ياء') || normalized.contains('كسرة');
      return hasMafoool && hasMansoub && hasFatha;
    } else {
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
      if (!_isInputValid(text, target, sentence)) {
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
      // If the chip itself is a full sentence or starts with punctuation, handle cleanly
      if (current.endsWith('.') || current.endsWith('،')) {
        ctrl.text = '$current $chipText';
      } else {
        ctrl.text = '$current $chipText';
      }
    }
    ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
    setState(() {});
  }

  void _backspace(String targetWord) {
    final ctrl = _controllers[targetWord];
    if (ctrl == null || ctrl.text.isEmpty) return;

    final words = ctrl.text.trim().split(RegExp(r'\s+'));
    if (words.isNotEmpty) {
      words.removeLast();
      ctrl.text = words.join(' ');
      ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
      setState(() {});
    }
  }

  void _clearParsing(String targetWord) {
    final ctrl = _controllers[targetWord];
    if (ctrl == null) return;
    ctrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Helper notice banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBBF7D0), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF16A34A), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'أَدَوَاتُ الإِعْرَابِ النَّمُوذَجِيِّ: انْقُرْ عَلَى عِبَارَاتِ الإِعْرَابِ أَدْنَاهُ لِبِنَاءِ الإِعْرَابِ التَّامِّ خُطْوَةً بِخُطْوَةٍ، أَوْ اكْتُبْ مُبَاشَرَةً.',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF15803D), height: 1.5),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // List of parsing sentences
        ...widget.sentences.asMap().entries.map((entry) {
          final idx = entry.key;
          final sentence = entry.value;
          final targetWord = widget.coloredWords[sentence] ?? '';
          final controller = _controllers[targetWord] ?? TextEditingController();
          final text = controller.text;
          final isValid = _isInputValid(text, targetWord, sentence) || widget.areAnswersRevealed;
          final modelParsing = _getModelParsing(sentence, targetWord);
          final chips = _getSpecificHelperChipsFor(targetWord, sentence);

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
                      radius: 18,
                      backgroundColor: isValid ? const Color(0xFF16A34A) : AppTheme.primaryTeal,
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildHighlightedSentence(sentence, targetWord),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Target word label and Input field with Action Buttons
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF86EFAC), width: 1.8),
                      ),
                      child: Text(
                        '$targetWord:',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'اكْتُبِ الإِعْرَابَ هُنَا أَوْ اسْتَعْمِلِ الأَدَوَاتِ أَدْنَاهُ...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (text.isNotEmpty && !widget.areAnswersRevealed)
                                IconButton(
                                  tooltip: 'مَسْحُ الحَقْلِ',
                                  icon: const Icon(Icons.cancel_rounded, color: Colors.grey, size: 22),
                                  onPressed: () => _clearParsing(targetWord),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(left: 12, right: 6),
                                child: isValid
                                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28)
                                    : (text.isNotEmpty
                                        ? const Icon(Icons.edit_note_rounded, color: AppTheme.accentOrange, size: 28)
                                        : const Icon(Icons.edit_rounded, color: Color(0xFF94A3B8), size: 22)),
                              ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isValid ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                              width: isValid ? 2 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Interactive Parsing Tools & Syntactic Building Blocks
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.dashboard_customize_rounded, size: 18, color: AppTheme.primaryTeal),
                          const SizedBox(width: 8),
                          const Text(
                            'أَدَوَاتُ بِنَاءِ الإِعْرَابِ (انْقُرْ لِلإِضَافَةِ إِلَى الحَقْلِ):',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                          ),
                          const Spacer(),
                          // Quick backspace button
                          if (text.isNotEmpty)
                            InkWell(
                              onTap: () => _backspace(targetWord),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.backspace_rounded, size: 14, color: Colors.redAccent),
                                    SizedBox(width: 4),
                                    Text('حَذْفُ كَلِمَةٍ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Parsing Helper Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ...chips.map((chip) {
                            return InkWell(
                              onTap: () => _insertChip(targetWord, chip),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.4), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  chip,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                              ),
                            );
                          }),

                          // 1-Click Complete Model Answer Button
                          InkWell(
                            onTap: () {
                              controller.text = modelParsing;
                              _checkValidation();
                              setState(() {});
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF16A34A)),
                                  SizedBox(width: 6),
                                  Text(
                                    'إِعْرَابٌ نَمُوذَجِيٌّ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
