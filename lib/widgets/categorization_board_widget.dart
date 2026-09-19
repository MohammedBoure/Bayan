import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Categorization Board Widget supporting 2-column and 3-column classification.
/// Designed for interactive whiteboards and large display screens with drag-and-drop or tap-to-place.
class CategorizationBoardWidget extends StatefulWidget {
  final List<String> categories;
  final Map<String, List<String>> correctMapping;
  final List<String> availableWords;
  final ValueChanged<bool> onValidationChanged;

  const CategorizationBoardWidget({
    super.key,
    required this.categories,
    required this.correctMapping,
    required this.availableWords,
    required this.onValidationChanged,
  });

  @override
  State<CategorizationBoardWidget> createState() => _CategorizationBoardWidgetState();
}

class _CategorizationBoardWidgetState extends State<CategorizationBoardWidget> {
  late Map<String, List<String>> _currentPlacement;
  late List<String> _remainingPool;
  String? _selectedWord;

  @override
  void initState() {
    super.initState();
    _resetBoard();
  }

  @override
  void didUpdateWidget(CategorizationBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableWords != widget.availableWords ||
        oldWidget.categories != widget.categories) {
      _resetBoard();
    }
  }

  void _resetBoard() {
    _currentPlacement = {for (var cat in widget.categories) cat: []};
    _remainingPool = List.from(widget.availableWords);
    _selectedWord = null;
  }

  void _assignWordToCategory(String word, String category) {
    setState(() {
      _remainingPool.remove(word);
      // Remove from any previous category if moved
      for (var cat in _currentPlacement.keys) {
        _currentPlacement[cat]!.remove(word);
      }
      _currentPlacement[category]!.add(word);
      _selectedWord = null;
    });

    _checkValidation();
  }

  void _unassignWord(String word, String fromCategory) {
    setState(() {
      _currentPlacement[fromCategory]!.remove(word);
      if (!_remainingPool.contains(word)) {
        _remainingPool.add(word);
      }
      _selectedWord = null;
    });

    _checkValidation();
  }

  void _checkValidation() {
    if (_remainingPool.isNotEmpty) {
      widget.onValidationChanged(false);
      return;
    }

    bool allCorrect = true;
    for (var entry in widget.correctMapping.entries) {
      final category = entry.key;
      final expectedWords = entry.value;
      final placedWords = _currentPlacement[category] ?? [];

      if (placedWords.length != expectedWords.length) {
        allCorrect = false;
        break;
      }

      for (var w in expectedWords) {
        if (!placedWords.contains(w)) {
          allCorrect = false;
          break;
        }
      }
    }

    widget.onValidationChanged(allCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Word Pool Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: AppTheme.primaryTeal, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    _remainingPool.isEmpty
                        ? 'تَمَّ تَصْنِيفُ كُلِّ الكَلِمَاتِ؛ تَأَكَّدْ مِنْ صِحَّتِهَا أَدْنَاهُ:'
                        : 'انْقُرْ أَوْ اسْحَبِ الكَلِمَةَ إِلَى خَانَتِهَا المُنَاسِبَةِ:',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _remainingPool.map((word) {
                  final isSelected = _selectedWord == word;
                  return Draggable<String>(
                    data: word,
                    feedback: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          word,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _buildWordChip(word, false),
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

        const SizedBox(height: 20),

        // Categories Columns (2 or 3 columns)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 650;

            final columns = widget.categories.asMap().entries.map((entry) {
              final cat = entry.value;
              final wordsInCat = _currentPlacement[cat] ?? [];
              final colors = [
                AppTheme.verbColor,
                AppTheme.subjectColor,
                AppTheme.accentOrange,
              ];
              final catColor = colors[entry.key % colors.length];

              return DragTarget<String>(
                onWillAcceptWithDetails: (details) => true,
                onAcceptWithDetails: (details) => _assignWordToCategory(details.data, cat),
                builder: (context, candidateData, rejectedData) {
                  final isHovered = candidateData.isNotEmpty;
                  return InkWell(
                    onTap: _selectedWord != null
                        ? () => _assignWordToCategory(_selectedWord!, cat)
                        : null,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? catColor.withValues(alpha: 0.15)
                            : (_selectedWord != null ? catColor.withValues(alpha: 0.08) : Colors.white),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isHovered ? catColor : catColor.withValues(alpha: 0.5),
                          width: isHovered || _selectedWord != null ? 3 : 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              cat,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: catColor),
                            ),
                          ),
                          const SizedBox(height: 12),
                          wordsInCat.isEmpty
                              ? Container(
                                  height: 90,
                                  alignment: Alignment.center,
                                  child: Text(
                                    _selectedWord != null ? 'انقر لوضع "$_selectedWord"' : 'اسحب الكلمة إلى هنا',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedWord != null ? catColor : Colors.grey.shade400,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: wordsInCat.map((w) {
                                    return Chip(
                                      label: Text(
                                        w,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor: catColor.withValues(alpha: 0.12),
                                      deleteIcon: const Icon(Icons.close_rounded, size: 18),
                                      onDeleted: () => _unassignWord(w, cat),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: catColor, width: 1.5),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList();

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: columns.map((col) => Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: col,
                ))).toList(),
              );
            } else {
              return Column(
                children: columns.map((col) => Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: col,
                )).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildWordChip(String word, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.accentAmber : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.accentOrange : AppTheme.primaryTeal,
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
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
