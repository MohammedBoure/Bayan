import 'package:flutter/material.dart';
import '../nlp/arabic_clitic_stemmer.dart';
import '../theme/app_theme.dart';

/// Open Sentence Fill widget (أكمل الجملة بفاعل مناسب من عندك) designed for classroom whiteboard and Data Show.
/// Displays sentences with inline blanks accepting typed open-ended answers, validates grammatical suitability,
/// and supports quick suggestion chips and automatic answer reveals.
class OpenSentenceFillWidget extends StatefulWidget {
  final List<String> sentences;
  final Map<String, List<String>> acceptableAnswers;
  final Map<String, String> defaultModelAnswers;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;

  const OpenSentenceFillWidget({
    super.key,
    required this.sentences,
    required this.acceptableAnswers,
    required this.defaultModelAnswers,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
  });

  @override
  State<OpenSentenceFillWidget> createState() => _OpenSentenceFillWidgetState();
}

class _OpenSentenceFillWidgetState extends State<OpenSentenceFillWidget> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = {};
    for (var sentence in widget.sentences) {
      final initial = widget.areAnswersRevealed ? (widget.defaultModelAnswers[sentence] ?? '') : '';
      final ctrl = TextEditingController(text: initial);
      ctrl.addListener(_checkValidation);
      _controllers[sentence] = ctrl;
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

    // Generic heuristic: If at least 2 Arabic letters and not a known preposition/particle
    final isParticle = ['في', 'من', 'إلى', 'على', 'عن', 'ثم', 'أو', 'لا', 'ما'].contains(norm);
    return norm.length >= 2 && !isParticle;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pedagogical instructions header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
          ),
          child: Row(
            children: const [
              Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF2563EB), size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'أَكْمِلْ كُلَّ جُمْلَةٍ بِفَاعِلٍ مُنَاسِبٍ مِنْ عِنْدِكَ مَعَ مُرَاعَاةِ المَعْنَى وَحَرَكَةِ الضَّمَّةِ (ـُ).',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // List of 6 sentences
        ...widget.sentences.asMap().entries.map((entry) {
          final idx = entry.key;
          final sentence = entry.value;
          final ctrl = _controllers[sentence] ?? TextEditingController();
          final text = ctrl.text;
          final isValid = _isAnswerAcceptable(sentence, text) || widget.areAnswersRevealed;

          // Split by blank dots or underscores
          final parts = sentence.split(RegExp(r'\.{3,}|_{3,}'));
          final prefix = parts.isNotEmpty ? parts[0].trim() : sentence;
          final suffix = parts.length > 1 ? parts[1].trim() : '';
          final suggestions = widget.acceptableAnswers[sentence] ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
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
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row: index and inline sentence with input box
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                            width: 180,
                            child: TextField(
                              controller: ctrl,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isValid ? const Color(0xFF15803D) : AppTheme.textDark,
                              ),
                              decoration: InputDecoration(
                                hintText: 'الفَاعِلُ...',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                                isDense: true,
                                filled: true,
                                fillColor: isValid ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isValid ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                                    width: isValid ? 2 : 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2),
                                ),
                              ),
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

                const SizedBox(height: 10),

                // Quick suggestion chips
                if (suggestions.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'مُقْتَرَحَاتٌ: ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                      ),
                      ...suggestions.take(3).map((sug) {
                        return InkWell(
                          onTap: () {
                            ctrl.text = sug;
                            _checkValidation();
                            setState(() {});
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              sug,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                          ),
                        );
                      }),
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
