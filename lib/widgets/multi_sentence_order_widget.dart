import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Multi-Sentence Word Ordering & Transformation widget.
/// Ideal for converting nominal sentences to verbal sentences or arranging shuffled words
/// across multiple sentences on interactive whiteboards and Data Show.
class MultiSentenceOrderWidget extends StatefulWidget {
  final List<String> sentenceItems;
  final Map<String, List<String>> sentenceWordsMap;
  final Map<String, List<String>> targetSequences;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;

  const MultiSentenceOrderWidget({
    super.key,
    required this.sentenceItems,
    required this.sentenceWordsMap,
    required this.targetSequences,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
  });

  @override
  State<MultiSentenceOrderWidget> createState() => _MultiSentenceOrderWidgetState();
}

class _MultiSentenceOrderWidgetState extends State<MultiSentenceOrderWidget> {
  late Map<String, List<String>> _assembled;
  late Map<String, List<String>> _available;

  @override
  void initState() {
    super.initState();
    _resetBoard();
  }

  @override
  void didUpdateWidget(MultiSentenceOrderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed && !oldWidget.areAnswersRevealed) {
      setState(() {
        _assembled = {
          for (var item in widget.sentenceItems) item: List.from(widget.targetSequences[item] ?? [])
        };
        _available = {for (var item in widget.sentenceItems) item: []};
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
      _assembled = {
        for (var item in widget.sentenceItems) item: List.from(widget.targetSequences[item] ?? [])
      };
      _available = {for (var item in widget.sentenceItems) item: []};
    } else {
      _assembled = {for (var item in widget.sentenceItems) item: []};
      _available = {
        for (var item in widget.sentenceItems) item: List.from(widget.sentenceWordsMap[item] ?? [])
      };
    }
    _checkValidation();
  }

  void _addWordToAssembled(String sentenceItem, String word) {
    setState(() {
      _available[sentenceItem]?.remove(word);
      _assembled[sentenceItem]?.add(word);
    });
    _checkValidation();
  }

  void _removeWordFromAssembled(String sentenceItem, int index) {
    setState(() {
      final word = _assembled[sentenceItem]?.removeAt(index);
      if (word != null) {
        _available[sentenceItem]?.add(word);
      }
    });
    _checkValidation();
  }

  void _resetSentence(String sentenceItem) {
    setState(() {
      _assembled[sentenceItem]?.clear();
      _available[sentenceItem] = List.from(widget.sentenceWordsMap[sentenceItem] ?? []);
    });
    _checkValidation();
  }

  void _checkValidation() {
    if (widget.areAnswersRevealed) {
      widget.onValidationChanged(true);
      return;
    }

    bool allCorrect = true;
    for (var item in widget.sentenceItems) {
      final currentList = _assembled[item] ?? [];
      final targetList = widget.targetSequences[item] ?? [];

      if (currentList.length != targetList.length) {
        allCorrect = false;
        break;
      }

      for (int i = 0; i < currentList.length; i++) {
        if (currentList[i] != targetList[i]) {
          allCorrect = false;
          break;
        }
      }
      if (!allCorrect) break;
    }
    widget.onValidationChanged(allCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widget.sentenceItems.asMap().entries.map((entry) {
        final idx = entry.key;
        final sentenceItem = entry.value;
        final assembledWords = _assembled[sentenceItem] ?? [];
        final availableWords = _available[sentenceItem] ?? [];
        final targetList = widget.targetSequences[sentenceItem] ?? [];

        bool isSentenceCorrect = assembledWords.length == targetList.length;
        if (isSentenceCorrect) {
          for (int i = 0; i < assembledWords.length; i++) {
            if (assembledWords[i] != targetList[i]) {
              isSentenceCorrect = false;
              break;
            }
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 22),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.areAnswersRevealed || isSentenceCorrect
                  ? AppTheme.successGreen
                  : const Color(0xFFCBD5E1),
              width: widget.areAnswersRevealed || isSentenceCorrect ? 2.5 : 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sentence Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.verbColor,
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        sentenceItem.startsWith('الجُمْلَةُ')
                            ? sentenceItem
                            : 'الجُمْلَةُ الأَصْلِيَّةُ: «$sentenceItem»',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  if (assembledWords.isNotEmpty && !widget.areAnswersRevealed)
                    TextButton.icon(
                      onPressed: () => _resetSentence(sentenceItem),
                      icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.accentOrange),
                      label: const Text(
                        'إِعَادَةُ التَّرْتِيبِ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentOrange),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Target Assembled Sentence Drop Zone
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                constraints: const BoxConstraints(minHeight: 68),
                decoration: BoxDecoration(
                  color: isSentenceCorrect || widget.areAnswersRevealed
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSentenceCorrect || widget.areAnswersRevealed
                        ? AppTheme.successGreen
                        : AppTheme.primaryTeal.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: assembledWords.isEmpty
                    ? const Center(
                        child: Text(
                          'انْقُرْ عَلَى الكَلِمَاتِ فِي الأَسْفَلِ بِالتَّرْتِيبِ لِبِنَاءِ الجُمْلَةِ الفِعْلِيَّةِ...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: assembledWords.asMap().entries.map((wEntry) {
                          final wIdx = wEntry.key;
                          final word = wEntry.value;

                          return InkWell(
                            onTap: widget.areAnswersRevealed
                                ? null
                                : () => _removeWordFromAssembled(sentenceItem, wIdx),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: widget.areAnswersRevealed || isSentenceCorrect
                                    ? AppTheme.successGreen
                                    : AppTheme.primaryTeal,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    word,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (!widget.areAnswersRevealed) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),

              if (availableWords.isNotEmpty && !widget.areAnswersRevealed) ...[
                const SizedBox(height: 14),
                // Remaining Shuffled Word Chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: availableWords.map((word) {
                    return InkWell(
                      onTap: () => _addWordToAssembled(sentenceItem, word),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          word,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
