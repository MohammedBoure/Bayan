import 'package:flutter/material.dart';
import '../nlp/arabic_clitic_stemmer.dart';
import '../theme/app_theme.dart';

/// Sentence Parts Analysis Widget (استخرج الفعل والفاعل والمفعول به).
/// Optimized for classroom Data Show projection and interactive whiteboards.
/// Displays sentences with three dedicated analysis slots for:
/// 1. الفِعْلُ (Verb)
/// 2. الفَاعِلُ (Subject)
/// 3. المَفْعُولُ بِهِ (Object)
/// Supports quick word tap placement, manual keyboard input, and teacher answer reveals.
class SentencePartsAnalysisWidget extends StatefulWidget {
  final List<String> sentences;
  final Map<String, Map<String, String>> sentencePartsMap;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;

  const SentencePartsAnalysisWidget({
    super.key,
    required this.sentences,
    required this.sentencePartsMap,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
  });

  @override
  State<SentencePartsAnalysisWidget> createState() => _SentencePartsAnalysisWidgetState();
}

class _SentencePartsAnalysisWidgetState extends State<SentencePartsAnalysisWidget> {
  // Map: sentence -> role ('الفعل', 'الفاعل', 'المفعول به') -> TextEditingController
  late Map<String, Map<String, TextEditingController>> _controllers;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = {};
    for (var sentence in widget.sentences) {
      final parts = widget.sentencePartsMap[sentence] ?? {};
      _controllers[sentence] = {
        'الفعل': TextEditingController(text: widget.areAnswersRevealed ? (parts['الفعل'] ?? '') : ''),
        'الفاعل': TextEditingController(text: widget.areAnswersRevealed ? (parts['الفاعل'] ?? '') : ''),
        'المفعول به': TextEditingController(text: widget.areAnswersRevealed ? (parts['المفعول به'] ?? '') : ''),
      };

      for (var ctrl in _controllers[sentence]!.values) {
        ctrl.addListener(_checkValidation);
      }
    }
    _checkValidation();
  }

  @override
  void didUpdateWidget(SentencePartsAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed && !oldWidget.areAnswersRevealed) {
      for (var sentence in widget.sentences) {
        final parts = widget.sentencePartsMap[sentence] ?? {};
        _controllers[sentence]?['الفعل']?.text = parts['الفعل'] ?? '';
        _controllers[sentence]?['الفاعل']?.text = parts['الفاعل'] ?? '';
        _controllers[sentence]?['المفعول به']?.text = parts['المفعول به'] ?? '';
      }
      widget.onValidationChanged(true);
    } else if (!widget.areAnswersRevealed && oldWidget.areAnswersRevealed) {
      for (var sentence in widget.sentences) {
        _controllers[sentence]?['الفعل']?.clear();
        _controllers[sentence]?['الفاعل']?.clear();
        _controllers[sentence]?['المفعول به']?.clear();
      }
      widget.onValidationChanged(false);
    }
  }

  @override
  void dispose() {
    for (var subMap in _controllers.values) {
      for (var ctrl in subMap.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  bool _isMatch(String input, String expected) {
    if (widget.areAnswersRevealed) return true;
    final cleanIn = ArabicCliticStemmer.normalize(
      ArabicCliticStemmer.stripDiacritics(input).replaceAll(RegExp(r'[.,!؟]'), '').trim(),
    );
    final cleanExp = ArabicCliticStemmer.normalize(
      ArabicCliticStemmer.stripDiacritics(expected).replaceAll(RegExp(r'[.,!؟]'), '').trim(),
    );

    return cleanIn == cleanExp || cleanIn.contains(cleanExp) || cleanExp.contains(cleanIn);
  }

  bool _isSentenceComplete(String sentence) {
    if (widget.areAnswersRevealed) return true;
    final expected = widget.sentencePartsMap[sentence] ?? {};
    final map = _controllers[sentence] ?? {};

    final verbIn = map['الفعل']?.text ?? '';
    final subjIn = map['الفاعل']?.text ?? '';
    final objIn = map['المفعول به']?.text ?? '';

    return _isMatch(verbIn, expected['الفعل'] ?? '') &&
        _isMatch(subjIn, expected['الفاعل'] ?? '') &&
        _isMatch(objIn, expected['المفعول به'] ?? '');
  }

  void _checkValidation() {
    if (widget.areAnswersRevealed) {
      widget.onValidationChanged(true);
      return;
    }

    bool allValid = true;
    for (var sentence in widget.sentences) {
      if (!_isSentenceComplete(sentence)) {
        allValid = false;
        break;
      }
    }
    widget.onValidationChanged(allValid);
  }

  int get _completedCount {
    if (widget.areAnswersRevealed) return widget.sentences.length;
    int count = 0;
    for (var sentence in widget.sentences) {
      if (_isSentenceComplete(sentence)) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.sentences.length;
    final completed = _completedCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pedagogical header instructions & live counter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Color(0xFF2563EB), size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'حَدِّدِ الفِعْلَ وَالفَاعِلَ وَالمَفْعُولَ بِهِ فِي كُلِّ جُمْلَةٍ مِنَ الجُمَلِ الآتِيَةِ:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: completed == total ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'الجُمَلُ المُحَلَّلَةُ: $completed / $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // List of sentences with 3-part analysis slots
        ...widget.sentences.asMap().entries.map((entry) {
          final idx = entry.key;
          final sentence = entry.value;
          final expectedParts = widget.sentencePartsMap[sentence] ?? {};
          final isDone = _isSentenceComplete(sentence);

          final verbCtrl = _controllers[sentence]?['الفعل'] ?? TextEditingController();
          final subjCtrl = _controllers[sentence]?['الفاعل'] ?? TextEditingController();
          final objCtrl = _controllers[sentence]?['المفعول به'] ?? TextEditingController();

          final isVerbCorrect = _isMatch(verbCtrl.text, expectedParts['الفعل'] ?? '');
          final isSubjCorrect = _isMatch(subjCtrl.text, expectedParts['الفاعل'] ?? '');
          final isObjCorrect = _isMatch(objCtrl.text, expectedParts['المفعول به'] ?? '');

          // Words of the sentence for quick tap insertion
          final words = sentence.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDone ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                width: isDone ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDone ? const Color(0xFF16A34A).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row: Sentence index badge and full sentence text
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isDone ? const Color(0xFF16A34A) : AppTheme.primaryTeal,
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          sentence,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ),
                    if (isDone) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                            SizedBox(width: 6),
                            Text(
                              'أَحْسَنْتَ ✓',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 14),

                // Source word chips from the sentence for instant 1-tap entry
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'كَلِمَاتُ الجُمْلَةِ: ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                    ...words.map((w) {
                      final cleanWord = w.replaceAll(RegExp(r'[.,!؟]'), '').trim();
                      return InkWell(
                        onTap: () {
                          // Auto place in first empty slot
                          if (verbCtrl.text.isEmpty) {
                            verbCtrl.text = cleanWord;
                          } else if (subjCtrl.text.isEmpty) {
                            subjCtrl.text = cleanWord;
                          } else if (objCtrl.text.isEmpty) {
                            objCtrl.text = cleanWord;
                          }
                          _checkValidation();
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            cleanWord,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 16),

                // Three Analysis Slots: الفعل - الفاعل - المفعول به
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isMultiCol = width >= 720;
                    final colWidth = isMultiCol ? (width - 24) / 3 : width;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildPartSlot(
                          label: 'الفِعْلُ (الحَدَثُ):',
                          roleName: 'الفعل',
                          controller: verbCtrl,
                          isValid: isVerbCorrect,
                          accentColor: const Color(0xFF2563EB),
                          expectedWord: expectedParts['الفعل'] ?? '',
                          width: colWidth,
                        ),
                        _buildPartSlot(
                          label: 'الفَاعِلُ (مَنْ قَامَ بِهِ):',
                          roleName: 'الفاعل',
                          controller: subjCtrl,
                          isValid: isSubjCorrect,
                          accentColor: const Color(0xFF0D9488),
                          expectedWord: expectedParts['الفاعل'] ?? '',
                          width: colWidth,
                        ),
                        _buildPartSlot(
                          label: 'المَفْعُولُ بِهِ (مَنْ وَقَعَ عَلَيْهِ):',
                          roleName: 'المفعول به',
                          controller: objCtrl,
                          isValid: isObjCorrect,
                          accentColor: const Color(0xFF16A34A),
                          expectedWord: expectedParts['المفعول به'] ?? '',
                          width: colWidth,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPartSlot({
    required String label,
    required String roleName,
    required TextEditingController controller,
    required bool isValid,
    required Color accentColor,
    required String expectedWord,
    required double width,
  }) {
    final text = controller.text.trim();

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isValid ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isValid ? const Color(0xFF16A34A) : (text.isNotEmpty ? AppTheme.accentOrange : accentColor.withValues(alpha: 0.3)),
            width: isValid ? 2 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle_rounded : Icons.label_important_outline_rounded,
                  color: isValid ? const Color(0xFF16A34A) : accentColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isValid ? const Color(0xFF15803D) : accentColor,
                    ),
                  ),
                ),
                if (text.isNotEmpty && !widget.areAnswersRevealed)
                  InkWell(
                    onTap: () {
                      controller.clear();
                      _checkValidation();
                      setState(() {});
                    },
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isValid ? const Color(0xFF15803D) : AppTheme.textDark,
              ),
              decoration: InputDecoration(
                hintText: 'اكْتُبْ هُنَا...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                isDense: true,
                filled: true,
                fillColor: isValid ? const Color(0xFFDCFCE7) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isValid ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                    width: isValid ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
