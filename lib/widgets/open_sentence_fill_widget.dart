import 'package:flutter/material.dart';
import '../nlp/arabic_clitic_stemmer.dart';
import '../theme/app_theme.dart';

/// Open Sentence Fill widget (أكمل الجملة بفاعل أو مفعول مناسب من عندك)
/// Designed for classroom whiteboards, interactive touchscreens, and Data Show projectors.
/// Displays sentences with inline blanks accepting typed open-ended answers, validates grammatical suitability,
/// and provides a per-sentence verification button and per-sentence model answer reveal button.
class OpenSentenceFillWidget extends StatefulWidget {
  final List<String> sentences;
  final Map<String, List<String>> acceptableAnswers;
  final Map<String, String> defaultModelAnswers;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;
  final bool showSuggestions;
  final String? instructionsText;
  final String? hintText;

  const OpenSentenceFillWidget({
    super.key,
    required this.sentences,
    required this.acceptableAnswers,
    required this.defaultModelAnswers,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
    this.showSuggestions = false,
    this.instructionsText,
    this.hintText,
  });

  @override
  State<OpenSentenceFillWidget> createState() => _OpenSentenceFillWidgetState();
}

class _OpenSentenceFillWidgetState extends State<OpenSentenceFillWidget> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, bool?> _sentenceValidationStatus = {};
  final Map<String, String?> _sentenceFeedback = {};
  String? _activeSentenceKey;

  static const List<String> _tashkeelSymbols = ['َ', 'ُ', 'ِ', 'ْ', 'ّ', 'ً', 'ٌ', 'ٍ'];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (var sentence in widget.sentences) {
      final initial = widget.areAnswersRevealed ? (widget.defaultModelAnswers[sentence] ?? '') : '';
      final ctrl = TextEditingController(text: initial);
      _controllers[sentence] = ctrl;

      final fn = FocusNode();
      fn.addListener(() {
        if (fn.hasFocus) {
          setState(() {
            _activeSentenceKey = sentence;
          });
        }
      });
      _focusNodes[sentence] = fn;

      if (widget.areAnswersRevealed) {
        _sentenceValidationStatus[sentence] = true;
        _sentenceFeedback[sentence] = 'الإِجَابَةُ النَّمُوذَجِيَّةُ: «${widget.defaultModelAnswers[sentence]}»';
      }
    }
    _checkValidation();
  }

  @override
  void didUpdateWidget(OpenSentenceFillWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed && !oldWidget.areAnswersRevealed) {
      for (var sentence in widget.sentences) {
        final ctrl = _controllers[sentence];
        if (ctrl != null) {
          ctrl.text = widget.defaultModelAnswers[sentence] ?? '';
        }
        _sentenceValidationStatus[sentence] = true;
        _sentenceFeedback[sentence] = 'الإِجَابَةُ النَّمُوذَجِيَّةُ: «${widget.defaultModelAnswers[sentence]}»';
      }
      setState(() {});
      widget.onValidationChanged(true);
    } else if (!widget.areAnswersRevealed && oldWidget.areAnswersRevealed) {
      for (var ctrl in _controllers.values) {
        ctrl.clear();
      }
      _sentenceValidationStatus.clear();
      _sentenceFeedback.clear();
      setState(() {});
      _checkValidation();
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    for (var fn in _focusNodes.values) {
      fn.dispose();
    }
    super.dispose();
  }

  bool _isAnswerAcceptable(String sentence, String input) {
    final text = input.trim();
    if (text.isEmpty) return false;

    final norm = ArabicCliticStemmer.normalize(ArabicCliticStemmer.stripDiacritics(text));
    final acceptableList = widget.acceptableAnswers[sentence] ?? [];

    for (var acc in acceptableList) {
      final normAcc = ArabicCliticStemmer.normalize(ArabicCliticStemmer.stripDiacritics(acc));
      if (norm == normAcc || norm.contains(normAcc) || normAcc.contains(norm)) {
        return true;
      }
    }

    final modelAns = widget.defaultModelAnswers[sentence];
    if (modelAns != null) {
      final normMod = ArabicCliticStemmer.normalize(ArabicCliticStemmer.stripDiacritics(modelAns));
      if (norm == normMod) return true;
    }

    if (acceptableList.isEmpty) {
      final isParticle = ['في', 'من', 'إلى', 'على', 'عن', 'ثم', 'أو', 'لا', 'ما'].contains(norm);
      return norm.length >= 2 && !isParticle;
    }

    return false;
  }

  void _verifySentence(String sentence) {
    final text = _controllers[sentence]?.text.trim() ?? '';
    if (text.isEmpty) {
      setState(() {
        _sentenceValidationStatus[sentence] = false;
        _sentenceFeedback[sentence] = 'يُرْجَى كِتَابَةُ الإِجَابَةِ فِي الفَرَاغِ أَوَّلاً.';
      });
      _checkValidation();
      return;
    }

    final isValid = _isAnswerAcceptable(sentence, text);
    setState(() {
      _sentenceValidationStatus[sentence] = isValid;
      if (isValid) {
        _sentenceFeedback[sentence] = 'أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ وَمُنَاسِبَةٌ لِلسِّيَاقِ ✓';
      } else {
        _sentenceFeedback[sentence] = 'حَاوِلْ مَرَّةً أُخْرَى! ضَعْ كَلِمَةً صَحِيحَةً تُنَاسِبُ المَعْنَى وَالإِعْرَابَ.';
      }
    });
    _checkValidation();
  }

  void _revealModelAnswerForSentence(String sentence) {
    final modelAns = widget.defaultModelAnswers[sentence] ?? '';
    if (modelAns.isNotEmpty) {
      final ctrl = _controllers[sentence];
      if (ctrl != null) {
        ctrl.text = modelAns;
      }
      setState(() {
        _sentenceValidationStatus[sentence] = true;
        _sentenceFeedback[sentence] = 'الإِجَابَةُ النَّمُوذَجِيَّةُ: «$modelAns» ✓';
      });
      _checkValidation();
    }
  }

  void _checkValidation() {
    if (widget.areAnswersRevealed) {
      widget.onValidationChanged(true);
      return;
    }

    bool allValid = true;
    for (var sentence in widget.sentences) {
      final text = _controllers[sentence]?.text ?? '';
      if (!_isAnswerAcceptable(sentence, text)) {
        allValid = false;
        break;
      }
    }
    widget.onValidationChanged(allValid);
  }

  void _insertTashkeel(String diacritic) {
    String? targetKey = _activeSentenceKey;
    if (targetKey == null || !_controllers.containsKey(targetKey)) {
      targetKey = widget.sentences.first;
      _activeSentenceKey = targetKey;
      _focusNodes[targetKey]?.requestFocus();
    }

    final ctrl = _controllers[targetKey];
    if (ctrl == null) return;

    final text = ctrl.text;
    final selection = ctrl.selection;

    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, diacritic);
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + diacritic.length),
      );
    } else {
      ctrl.text = '$text$diacritic';
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    }

    setState(() {
      _sentenceValidationStatus[targetKey!] = null;
      _sentenceFeedback[targetKey] = null;
    });
    _checkValidation();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Pedagogical Instructions Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.instructionsText ??
                      'اكْتُبِ الإِجَابَةَ المُنَاسِبَةَ مِنْ عِنْدِكَ فِي كُلِّ فَرَاغٍ، ثُمَّ انْقُرْ عَلَى «تَحَقَّقْ» أَوْ «إِجَابَةٌ نَمُوذَجِيَّةٌ» لِكُلِّ جُمْلَةٍ:',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Quick Tashkeel Toolbar for Whiteboard and Touch Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
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
              const Icon(Icons.keyboard_outlined, size: 20, color: Color(0xFF64748B)),
              const SizedBox(width: 10),
              const Text(
                'حَرَكَاتُ التَّشْكِيلِ لِلَّوْحَةِ:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _tashkeelSymbols.map((t) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Material(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _insertTashkeel(t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. Sentences List with Per-Option Verification and Model Answer Buttons
        ...widget.sentences.asMap().entries.map((entry) {
          final idx = entry.key;
          final sentence = entry.value;
          final ctrl = _controllers[sentence] ?? TextEditingController();
          final fn = _focusNodes[sentence];
          final text = ctrl.text;
          final status = _sentenceValidationStatus[sentence];
          final isCorrect = widget.areAnswersRevealed || status == true;
          final isFailed = status == false;
          final feedbackText = _sentenceFeedback[sentence];

          // Split sentence by blank dots or underscores
          final parts = sentence.split(RegExp(r'\.{3,}|_{3,}'));
          final prefix = parts.isNotEmpty ? parts[0].trim() : sentence;
          final suffix = parts.length > 1 ? parts[1].trim() : '';

          Color borderColor = const Color(0xFFCBD5E1);
          if (isCorrect) {
            borderColor = const Color(0xFF16A34A);
          } else if (isFailed) {
            borderColor = const Color(0xFFEF4444);
          } else if (text.isNotEmpty) {
            borderColor = AppTheme.primaryTeal;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: borderColor,
                width: isCorrect ? 2.5 : (isFailed ? 2.0 : 1.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: isCorrect
                      ? const Color(0xFF16A34A).withValues(alpha: 0.08)
                      : (isFailed
                          ? const Color(0xFFEF4444).withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.03)),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Index Badge & Sentence with Inline Input Field
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isCorrect ? const Color(0xFF16A34A) : AppTheme.primaryTeal,
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Text(
                            prefix,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          SizedBox(
                            width: 190,
                            child: TextField(
                              key: Key('open_fill_input_$idx'),
                              controller: ctrl,
                              focusNode: fn,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isCorrect ? const Color(0xFF15803D) : AppTheme.textDark,
                              ),
                              decoration: InputDecoration(
                                hintText: widget.hintText ?? 'الكَلِمَةُ المُنَاسِبَةُ...',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                                isDense: true,
                                filled: true,
                                fillColor: isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                                    width: isCorrect ? 2 : 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                                ),
                                suffixIcon: isCorrect
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6),
                                        child: Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                                      )
                                    : (text.isNotEmpty && !widget.areAnswersRevealed
                                        ? IconButton(
                                            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                                            onPressed: () {
                                              ctrl.clear();
                                              setState(() {
                                                _sentenceValidationStatus[sentence] = null;
                                                _sentenceFeedback[sentence] = null;
                                              });
                                              _checkValidation();
                                            },
                                            tooltip: 'مَسْحٌ',
                                          )
                                        : null),
                              ),
                              onTap: () {
                                setState(() {
                                  _activeSentenceKey = sentence;
                                });
                              },
                              onChanged: (_) {
                                setState(() {
                                  _sentenceValidationStatus[sentence] = null;
                                  _sentenceFeedback[sentence] = null;
                                });
                                _checkValidation();
                              },
                            ),
                          ),
                          if (suffix.isNotEmpty)
                            Text(
                              suffix,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bottom Row: Per-Sentence Verification & Model Answer Buttons + Feedback
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // زر تحقق لكل خيار
                    ElevatedButton.icon(
                      key: Key('verify_sentence_$idx'),
                      onPressed: () => _verifySentence(sentence),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('تَحَقَّقْ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 1,
                      ),
                    ),

                    // زر عرض إجابة نموذجية لكل خيار
                    OutlinedButton.icon(
                      key: Key('reveal_sentence_$idx'),
                      onPressed: () => _revealModelAnswerForSentence(sentence),
                      icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                      label: const Text('إِجَابَةٌ نَمُوذَجِيَّةٌ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                        backgroundColor: const Color(0xFFF0F9FF),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    // التغذية الراجعة الفورية الخاصة بهذه الجملة
                    if (feedbackText != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isCorrect ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                              size: 16,
                              color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              feedbackText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
