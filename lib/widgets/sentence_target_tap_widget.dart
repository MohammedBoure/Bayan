import 'package:flutter/material.dart';
import '../nlp/arabic_clitic_stemmer.dart';
import '../theme/app_theme.dart';

/// Interactive sentence target tap widget (انقر على المفعول به في كل جملة).
/// Optimized for classroom Data Show projection and interactive whiteboards.
/// Displays sentences where pupils tap directly on the target word (المفعول به)
/// with real-time feedback, counter badges, and teacher answer reveals.
class SentenceTargetTapWidget extends StatefulWidget {
  final List<String> sentences;
  final Map<String, String> solutions;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;
  final String? instructionHeader;
  final String? errorHintMessage;
  final bool allowNoneOption;
  final String noneOptionText;

  const SentenceTargetTapWidget({
    super.key,
    required this.sentences,
    required this.solutions,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
    this.instructionHeader,
    this.errorHintMessage,
    this.allowNoneOption = false,
    this.noneOptionText = 'لا يُوجَدُ فِعْلٌ مَبْنِيٌّ لِلْمَجْهُولِ',
  });

  @override
  State<SentenceTargetTapWidget> createState() => _SentenceTargetTapWidgetState();
}

class _SentenceTargetTapWidgetState extends State<SentenceTargetTapWidget> {
  // Map of sentence index -> selected word string
  late Map<int, String> _selectedWords;
  // Map of sentence index -> error message if wrong word clicked
  late Map<int, String?> _errorHints;

  @override
  void initState() {
    super.initState();
    _selectedWords = {};
    _errorHints = {};
    _applyRevealedState();
    _checkValidation();
  }

  @override
  void didUpdateWidget(SentenceTargetTapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed != oldWidget.areAnswersRevealed) {
      _applyRevealedState();
      _checkValidation();
    }
  }

  void _applyRevealedState() {
    if (widget.areAnswersRevealed) {
      for (int i = 0; i < widget.sentences.length; i++) {
        final sentence = widget.sentences[i];
        final target = widget.solutions[sentence];
        if (target != null) {
          _selectedWords[i] = target;
          _errorHints[i] = null;
        }
      }
    }
  }

  bool _isWordMatchingTarget(String word, String target) {
    final cleanWord = ArabicCliticStemmer.normalize(
      ArabicCliticStemmer.stripDiacritics(word).replaceAll(RegExp(r'[.,!؟]'), '').trim(),
    );
    final cleanTarget = ArabicCliticStemmer.normalize(
      ArabicCliticStemmer.stripDiacritics(target).replaceAll(RegExp(r'[.,!؟]'), '').trim(),
    );

    return cleanWord == cleanTarget || cleanWord.contains(cleanTarget) || cleanTarget.contains(cleanWord);
  }

  void _onWordTapped(int sentenceIndex, String rawWord) {
    final sentence = widget.sentences[sentenceIndex];
    final target = widget.solutions[sentence] ?? '';

    setState(() {
      if (_isWordMatchingTarget(rawWord, target)) {
        _selectedWords[sentenceIndex] = rawWord;
        _errorHints[sentenceIndex] = null;
      } else {
        _selectedWords.remove(sentenceIndex);
        _errorHints[sentenceIndex] = widget.errorHintMessage ?? 'هَذَا لَيْسَ المَفْعُولَ بِهِ، اسْأَلْ: مَاذَا فَعَلَ الفَاعِلُ؟';
      }
    });

    _checkValidation();
  }

  void _checkValidation() {
    if (widget.areAnswersRevealed) {
      widget.onValidationChanged(true);
      return;
    }

    bool allCorrect = true;
    for (int i = 0; i < widget.sentences.length; i++) {
      final sentence = widget.sentences[i];
      final target = widget.solutions[sentence] ?? '';
      final selected = _selectedWords[i];

      if (selected == null || !_isWordMatchingTarget(selected, target)) {
        allCorrect = false;
        break;
      }
    }

    widget.onValidationChanged(allCorrect);
  }

  int get _correctCount {
    if (widget.areAnswersRevealed) return widget.sentences.length;
    int count = 0;
    for (int i = 0; i < widget.sentences.length; i++) {
      final sentence = widget.sentences[i];
      final target = widget.solutions[sentence] ?? '';
      final selected = _selectedWords[i];
      if (selected != null && _isWordMatchingTarget(selected, target)) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.sentences.length;
    final solved = _correctCount;

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
              const Icon(Icons.touch_app_rounded, color: Color(0xFF2563EB), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.instructionHeader ?? 'انْقُرْ عَلَى المَفْعُولِ بِهِ فِي كُلِّ جُمْلَةٍ مِنَ الجُمَلِ الآتِيَةِ:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: solved == total ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$solved / $total',
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

        // List of sentences with interactive word chips
        ...widget.sentences.asMap().entries.map((entry) {
          final idx = entry.key;
          final sentence = entry.value;
          final target = widget.solutions[sentence] ?? '';
          final selectedWord = _selectedWords[idx];
          final isSentenceSolved = (selectedWord != null && _isWordMatchingTarget(selectedWord, target)) || widget.areAnswersRevealed;
          final errorHint = _errorHints[idx];

          // Split sentence into words
          final words = sentence.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSentenceSolved
                    ? const Color(0xFF16A34A)
                    : (errorHint != null ? AppTheme.accentOrange : const Color(0xFFE2E8F0)),
                width: isSentenceSolved ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSentenceSolved
                      ? const Color(0xFF16A34A).withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row: Index & Status badge
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isSentenceSolved ? const Color(0xFF16A34A) : AppTheme.primaryTeal,
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'جُمْلَةٌ فِعْلِيَّةٌ (${idx + 1})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (isSentenceSolved)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                            SizedBox(width: 4),
                            Text(
                              'تَمَّ التَّحْدِيدُ بِنَجَاحٍ ✓',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Sentence words as tappable interactive chips
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: words.map((rawWord) {
                    final cleanWord = rawWord.replaceAll(RegExp(r'[.,!؟]'), '').trim();
                    final isThisTarget = _isWordMatchingTarget(cleanWord, target);
                    final isSelected = selectedWord != null && _isWordMatchingTarget(cleanWord, selectedWord);
                    final showSuccess = widget.areAnswersRevealed ? isThisTarget : (isSelected && isThisTarget);

                    Color chipBg = const Color(0xFFF8FAFC);
                    Color chipBorder = const Color(0xFFCBD5E1);
                    Color chipTextColor = AppTheme.textDark;

                    if (showSuccess) {
                      chipBg = const Color(0xFF16A34A);
                      chipBorder = const Color(0xFF15803D);
                      chipTextColor = Colors.white;
                    } else if (isSelected) {
                      chipBg = const Color(0xFFFFF7ED);
                      chipBorder = AppTheme.accentOrange;
                      chipTextColor = AppTheme.accentOrange;
                    }

                    return InkWell(
                      onTap: () => _onWordTapped(idx, cleanWord),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: chipBorder, width: showSuccess ? 2.5 : 1.5),
                          boxShadow: showSuccess
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showSuccess) ...[
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              rawWord,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: chipTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Option to select "No target word" (e.g. active verb / no passive verb)
                if (widget.allowNoneOption) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => _onWordTapped(idx, widget.noneOptionText),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: (selectedWord != null && _isWordMatchingTarget(selectedWord, widget.noneOptionText))
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (selectedWord != null && _isWordMatchingTarget(selectedWord, widget.noneOptionText))
                                ? const Color(0xFF15803D)
                                : const Color(0xFF94A3B8),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (selectedWord != null && _isWordMatchingTarget(selectedWord, widget.noneOptionText))
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: (selectedWord != null && _isWordMatchingTarget(selectedWord, widget.noneOptionText))
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.noneOptionText,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: (selectedWord != null && _isWordMatchingTarget(selectedWord, widget.noneOptionText))
                                    ? Colors.white
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Error guidance message if wrong word was tapped
                if (errorHint != null && !isSentenceSolved) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppTheme.accentOrange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorHint,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
