import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Multiple Choice per Sentence widget designed for classroom whiteboards and Data Show projectors.
/// Displays multiple sentences where each sentence has its own dedicated multiple-choice options.
class MultiSentenceChoiceWidget extends StatefulWidget {
  final List<String> sentences;
  final Map<String, List<String>> optionsPerSentence;
  final Map<String, String> solutions;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;

  const MultiSentenceChoiceWidget({
    super.key,
    required this.sentences,
    required this.optionsPerSentence,
    required this.solutions,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
  });

  @override
  State<MultiSentenceChoiceWidget> createState() => _MultiSentenceChoiceWidgetState();
}

class _MultiSentenceChoiceWidgetState extends State<MultiSentenceChoiceWidget> {
  late Map<String, String?> _selectedOptions;

  @override
  void initState() {
    super.initState();
    _resetChoices();
  }

  @override
  void didUpdateWidget(MultiSentenceChoiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed && !oldWidget.areAnswersRevealed) {
      setState(() {
        _selectedOptions = Map.from(widget.solutions);
      });
      widget.onValidationChanged(true);
    } else if (!widget.areAnswersRevealed && oldWidget.areAnswersRevealed) {
      setState(() {
        _resetChoices();
      });
    }
  }

  void _resetChoices() {
    if (widget.areAnswersRevealed) {
      _selectedOptions = Map.from(widget.solutions);
    } else {
      _selectedOptions = {for (var s in widget.sentences) s: null};
    }
    _checkValidation();
  }

  void _selectChoice(String sentence, String choice) {
    setState(() {
      if (_selectedOptions[sentence] == choice) {
        _selectedOptions[sentence] = null;
      } else {
        _selectedOptions[sentence] = choice;
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
    for (var sentence in widget.sentences) {
      final selected = _selectedOptions[sentence];
      final correct = widget.solutions[sentence];
      if (selected == null || selected.trim() != correct?.trim()) {
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
      children: widget.sentences.asMap().entries.map((entry) {
        final idx = entry.key;
        final sentence = entry.value;
        final options = widget.optionsPerSentence[sentence] ?? [];
        final selectedChoice = _selectedOptions[sentence];
        final correctChoice = widget.solutions[sentence];
        final isRowCorrect = selectedChoice != null && selectedChoice.trim() == correctChoice?.trim();

        // Render the sentence with the blank slot replaced if chosen
        final parts = sentence.split(RegExp(r'\.{3,}|_{3,}'));
        final prefix = parts.isNotEmpty ? parts[0].trim() : sentence;
        final suffix = parts.length > 1 ? parts[1].trim() : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isRowCorrect
                  ? AppTheme.successGreen
                  : (selectedChoice != null ? AppTheme.accentOrange : const Color(0xFFCBD5E1)),
              width: isRowCorrect ? 2.5 : 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isRowCorrect
                    ? AppTheme.successGreen.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sentence display with embedded blank slot
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isRowCorrect ? AppTheme.successGreen : AppTheme.primaryTeal,
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
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: selectedChoice != null
                                ? (isRowCorrect
                                    ? AppTheme.successGreen.withValues(alpha: 0.15)
                                    : AppTheme.accentOrange.withValues(alpha: 0.15))
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedChoice != null
                                  ? (isRowCorrect ? AppTheme.successGreen : AppTheme.accentOrange)
                                  : const Color(0xFF94A3B8),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            selectedChoice ?? '........',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: selectedChoice != null
                                  ? (isRowCorrect ? AppTheme.successGreen : AppTheme.accentOrange)
                                  : const Color(0xFF94A3B8),
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

              const SizedBox(height: 14),

              // Multiple choice options row
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: options.map((option) {
                  final isSelected = selectedChoice == option;
                  final isThisCorrect = option.trim() == correctChoice?.trim();
                  final showAsCorrect = widget.areAnswersRevealed && isThisCorrect;

                  Color btnBg = Colors.grey.shade50;
                  Color btnBorder = const Color(0xFFE2E8F0);
                  Color btnText = AppTheme.textDark;

                  if (showAsCorrect || (isSelected && isThisCorrect)) {
                    btnBg = AppTheme.successGreen.withValues(alpha: 0.18);
                    btnBorder = AppTheme.successGreen;
                    btnText = AppTheme.successGreen;
                  } else if (isSelected) {
                    btnBg = AppTheme.accentOrange.withValues(alpha: 0.15);
                    btnBorder = AppTheme.accentOrange;
                    btnText = AppTheme.accentOrange;
                  }

                  return InkWell(
                    onTap: () => _selectChoice(sentence, option),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: btnBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: btnBorder, width: isSelected || showAsCorrect ? 2.5 : 1.5),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: btnBorder.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected
                                ? (isThisCorrect ? Icons.check_circle_rounded : Icons.radio_button_checked_rounded)
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: btnText,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            option,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: btnText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
