import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Multi-Sentence Fill-in-the-Blank widget designed for classroom whiteboards and Data Show.
/// Supports both Tap-to-Place and Drag-and-Drop for word placement.
class MultiSentenceFillWidget extends StatefulWidget {
  final List<String> sentences;
  final List<String> availableWords;
  final Map<String, String> solutions;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;

  const MultiSentenceFillWidget({
    super.key,
    required this.sentences,
    required this.availableWords,
    required this.solutions,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
  });

  @override
  State<MultiSentenceFillWidget> createState() => _MultiSentenceFillWidgetState();
}

class _MultiSentenceFillWidgetState extends State<MultiSentenceFillWidget> {
  late Map<String, String?> _placements;
  late List<String> _remainingPool;
  String? _selectedWord;

  @override
  void initState() {
    super.initState();
    _resetBoard();
  }

  @override
  void didUpdateWidget(MultiSentenceFillWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed && !oldWidget.areAnswersRevealed) {
      setState(() {
        _placements = Map.from(widget.solutions);
        _remainingPool.clear();
        _selectedWord = null;
      });
      widget.onValidationChanged(true);
    } else if (!widget.areAnswersRevealed && oldWidget.areAnswersRevealed) {
      setState(() {
        _resetBoard();
      });
    }
  }

  void _resetBoard() {
    if (widget.areAnswersRevealed) {
      _placements = Map.from(widget.solutions);
      _remainingPool = [];
    } else {
      _placements = {for (var s in widget.sentences) s: null};
      _remainingPool = List.from(widget.availableWords);
    }
    _selectedWord = null;
    _checkValidation();
  }

  void _placeWord(String word, String sentence) {
    setState(() {
      final oldWord = _placements[sentence];
      if (oldWord != null && !_remainingPool.contains(oldWord)) {
        _remainingPool.add(oldWord);
      }
      _remainingPool.remove(word);
      _placements[sentence] = word;
      _selectedWord = null;
    });
    _checkValidation();
  }

  void _unplaceWord(String sentence) {
    setState(() {
      final word = _placements[sentence];
      if (word != null) {
        if (!_remainingPool.contains(word)) {
          _remainingPool.add(word);
        }
        _placements[sentence] = null;
      }
      _selectedWord = null;
    });
    _checkValidation();
  }

  void _checkValidation() {
    if (widget.areAnswersRevealed) {
      widget.onValidationChanged(true);
      return;
    }

    bool allCorrect = true;
    for (var sentence in widget.sentences) {
      final placed = _placements[sentence];
      final expected = widget.solutions[sentence];
      if (placed == null || placed != expected) {
        allCorrect = false;
        break;
      }
    }
    widget.onValidationChanged(allCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Word Bank Pool at Top
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.verbColor.withValues(alpha: 0.35), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.verbColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.apps_rounded, color: AppTheme.verbColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'بَنْكُ الأَفْعَالِ (انْقُرْ عَلَى الفِعْلِ ثُمَّ انْقُرْ فِي مَكَانِهِ بِالجُمْلَةِ):',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: _remainingPool.isEmpty
                    ? [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'تم وضع جميع الأفعال في الجمل ✓',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                          ),
                        ),
                      ]
                    : _remainingPool.map((word) {
                        final isSelected = _selectedWord == word;
                        return Draggable<String>(
                          data: word,
                          feedback: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.verbColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                word,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.4,
                            child: _buildWordChip(word, isSelected),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedWord = isSelected ? null : word;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: _buildWordChip(word, isSelected),
                          ),
                        );
                      }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Sentence Cards with Blank Target Slots
        ...widget.sentences.asMap().entries.map((entry) {
          final idx = entry.key;
          final sentence = entry.value;
          final placedWord = _placements[sentence];
          final expectedWord = widget.solutions[sentence];
          final isCorrect = placedWord == expectedWord;

          // Strip placeholder "______" from sentence display
          final sentenceClean = sentence.replaceAll('______', '').trim();

          return DragTarget<String>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              _placeWord(details.data, sentence);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isHovered ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isHovered
                        ? AppTheme.successGreen
                        : (placedWord != null ? AppTheme.primaryTeal.withValues(alpha: 0.6) : const Color(0xFFCBD5E1)),
                    width: isHovered ? 2.5 : 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryTeal,
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Blank Slot (Target)
                    InkWell(
                      onTap: () {
                        if (placedWord != null) {
                          _unplaceWord(sentence);
                        } else if (_selectedWord != null) {
                          _placeWord(_selectedWord!, sentence);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        constraints: const BoxConstraints(minWidth: 120),
                        decoration: BoxDecoration(
                          color: placedWord != null
                              ? (widget.areAnswersRevealed
                                  ? const Color(0xFFECFDF5)
                                  : AppTheme.primaryLight)
                              : (_selectedWord != null ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: placedWord != null
                                ? (widget.areAnswersRevealed ? AppTheme.successGreen : AppTheme.primaryTeal)
                                : (_selectedWord != null ? AppTheme.accentAmber : Colors.grey.shade400),
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignCenter,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              placedWord ?? (_selectedWord != null ? 'ضَعْ «$_selectedWord» هُنَا' : '______'),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: placedWord != null
                                    ? (widget.areAnswersRevealed ? const Color(0xFF047857) : AppTheme.primaryDark)
                                    : (_selectedWord != null ? AppTheme.accentOrange : AppTheme.textMuted),
                              ),
                            ),
                            if (placedWord != null && !widget.areAnswersRevealed) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.cancel_rounded, size: 18, color: Colors.redAccent),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Remainder of Sentence
                    Expanded(
                      child: Text(
                        sentenceClean,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),

                    if (widget.areAnswersRevealed && placedWord != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCorrect ? 'صَحِيحٌ ✓' : 'حَاوِلْ مَرَّةً أُخْرَى',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? const Color(0xFF065F46) : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildWordChip(String word, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.verbColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.verbColor : const Color(0xFFCBD5E1),
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        word,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : AppTheme.textDark,
        ),
      ),
    );
  }
}
