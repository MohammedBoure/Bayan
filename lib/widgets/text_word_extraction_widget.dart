import 'package:flutter/material.dart';
import '../nlp/arabic_clitic_stemmer.dart';
import '../theme/app_theme.dart';

/// Text Word Extraction Widget (استخرج المفعول به من النص).
/// Tailored for Data Show classroom projection and interactive smartboards.
/// Displays an authentic reading story where pupils tap directly on target objects
/// in the paragraph, revealing them into interactive collection cards.
class TextWordExtractionWidget extends StatefulWidget {
  final String passage;
  final List<String> targetWords;
  final Map<String, String>? wordContexts;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;

  const TextWordExtractionWidget({
    super.key,
    required this.passage,
    required this.targetWords,
    this.wordContexts,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
  });

  @override
  State<TextWordExtractionWidget> createState() => _TextWordExtractionWidgetState();
}

class _TextWordExtractionWidgetState extends State<TextWordExtractionWidget> {
  // Set of normalized discovered target words
  late Set<String> _foundNormalizedWords;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _foundNormalizedWords = {};
    _applyRevealedState();
    _checkValidation();
  }

  @override
  void didUpdateWidget(TextWordExtractionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed != oldWidget.areAnswersRevealed) {
      _applyRevealedState();
      _checkValidation();
    }
  }

  void _applyRevealedState() {
    if (widget.areAnswersRevealed) {
      _foundNormalizedWords = widget.targetWords
          .map((w) => ArabicCliticStemmer.normalize(ArabicCliticStemmer.stripDiacritics(w).replaceAll(RegExp(r'[.,!؟،]'), '').trim()))
          .toSet();
    }
  }

  String _clean(String s) {
    return ArabicCliticStemmer.normalize(
      ArabicCliticStemmer.stripDiacritics(s).replaceAll(RegExp(r'[.,!؟،]'), '').trim(),
    );
  }

  bool _isWordTarget(String word) {
    final cleanW = _clean(word);
    for (var target in widget.targetWords) {
      final cleanT = _clean(target);
      if (cleanW == cleanT || cleanW.contains(cleanT) || cleanT.contains(cleanW)) {
        return true;
      }
    }
    return false;
  }

  String? _matchingTarget(String word) {
    final cleanW = _clean(word);
    for (var target in widget.targetWords) {
      final cleanT = _clean(target);
      if (cleanW == cleanT || cleanW.contains(cleanT) || cleanT.contains(cleanW)) {
        return cleanT;
      }
    }
    return null;
  }

  void _onWordTapped(String rawWord) {
    final matchedNorm = _matchingTarget(rawWord);
    setState(() {
      if (matchedNorm != null) {
        _foundNormalizedWords.add(matchedNorm);
        _feedbackMessage = 'أَحْسَنْتَ! «$rawWord» مَفْعُولٌ بِهِ مَنْصُوبٌ بِالفَتْحَةِ.';
      } else {
        _feedbackMessage = 'لَيْسَ مَفْعُولاً بِهِ! ابْحَثْ عَنِ الاسْمِ الَّذِي وَقَعَ عَلَيْهِ الفِعْلُ.';
      }
    });

    _checkValidation();
  }

  void _checkValidation() {
    if (widget.areAnswersRevealed) {
      widget.onValidationChanged(true);
      return;
    }

    final totalTargetNorms = widget.targetWords.map(_clean).toSet();
    final allFound = totalTargetNorms.every((t) => _foundNormalizedWords.contains(t));

    widget.onValidationChanged(allFound);
  }

  int get _foundCount {
    if (widget.areAnswersRevealed) return widget.targetWords.length;
    final totalTargetNorms = widget.targetWords.map(_clean).toSet();
    return totalTargetNorms.where((t) => _foundNormalizedWords.contains(t)).length;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.targetWords.length;
    final found = _foundCount;
    final allSolved = found == total || widget.areAnswersRevealed;

    // Split passage into tokens preserving spaces and punctuation
    final tokens = widget.passage.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

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
              const Icon(Icons.menu_book_rounded, color: Color(0xFF2563EB), size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'اقْرَإِ النَّصَّ ثُمَّ انْقُرْ عَلَى المَفْعُولِ بِهِ فِي كُلِّ جُمْلَةٍ مِنَ الجُمَلِ:',
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
                  color: allSolved ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'المَفَاعِيلُ المُسْتَخْرَجَةُ: $found / $total',
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

        // Interactive Reading Passage Container with tappable word tokens
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
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
              Row(
                children: const [
                  Icon(Icons.auto_stories_rounded, color: AppTheme.primaryTeal, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'نَصُّ النَّشَاطِ (انْقُرْ عَلَى المَفْعُولِ بِهِ لِاسْتِخْرَاجِهِ):',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1.2),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: tokens.map((token) {
                  final cleanToken = _clean(token);
                  final isTarget = _isWordTarget(token);
                  final isFound = _foundNormalizedWords.contains(cleanToken) || (widget.areAnswersRevealed && isTarget);

                  return InkWell(
                    onTap: () => _onWordTapped(token),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFound ? const Color(0xFFDCFCE7) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isFound ? const Color(0xFF16A34A) : Colors.transparent,
                          width: isFound ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        token,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: isFound ? FontWeight.w900 : FontWeight.w600,
                          color: isFound ? const Color(0xFF15803D) : AppTheme.textDark,
                          decoration: isFound ? TextDecoration.underline : TextDecoration.none,
                          decorationColor: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Live feedback hint
        if (_feedbackMessage != null && !allSolved) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.accentOrange, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _feedbackMessage!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC2410C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Extracted Mafa'eel Collection Cards (5 items)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.checklist_rounded, color: Color(0xFF0D9488), size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'قَائِمَةُ المَفَاعِيلِ بِهِ المَطْلُوبَةِ ($total مَفَاعِيلَ):',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isWide = width >= 750;
                  final itemWidth = isWide ? (width - 12) / 2 : width;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: widget.targetWords.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final target = entry.value;
                      final cleanTarget = _clean(target);
                      final isFound = _foundNormalizedWords.contains(cleanTarget) || widget.areAnswersRevealed;
                      final contextText = widget.wordContexts?[target] ?? '';

                      return SizedBox(
                        width: itemWidth,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isFound ? const Color(0xFFF0FDF4) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isFound ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                              width: isFound ? 2 : 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isFound ? const Color(0xFF16A34A).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: isFound ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isFound ? '«$target»' : 'مَفْعُولٌ بِهِ مَفْقُودٌ ...',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: isFound ? const Color(0xFF15803D) : AppTheme.textMuted,
                                      ),
                                    ),
                                    if (contextText.isNotEmpty)
                                      Text(
                                        '($contextText)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isFound ? const Color(0xFF166534) : AppTheme.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                isFound ? Icons.check_circle_rounded : Icons.help_outline_rounded,
                                color: isFound ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
