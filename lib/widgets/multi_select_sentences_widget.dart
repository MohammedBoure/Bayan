import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Interactive sentence multi-selection widget for classroom whiteboards and Data Show.
/// Supports paragraph context display, single-click toggle selection, counter pill,
/// and instant teacher answer reveal.
class MultiSelectSentencesWidget extends StatefulWidget {
  final List<String> sentences;
  final List<int> correctIndices;
  final String? contextParagraph;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;

  const MultiSelectSentencesWidget({
    super.key,
    required this.sentences,
    required this.correctIndices,
    this.contextParagraph,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
  });

  @override
  State<MultiSelectSentencesWidget> createState() => _MultiSelectSentencesWidgetState();
}

class _MultiSelectSentencesWidgetState extends State<MultiSelectSentencesWidget> {
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    if (widget.areAnswersRevealed) {
      _selectedIndices.addAll(widget.correctIndices);
    }
    _checkValidation();
  }

  @override
  void didUpdateWidget(MultiSelectSentencesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed && !oldWidget.areAnswersRevealed) {
      setState(() {
        _selectedIndices.clear();
        _selectedIndices.addAll(widget.correctIndices);
      });
      _checkValidation();
    } else if (!widget.areAnswersRevealed && oldWidget.areAnswersRevealed) {
      setState(() {
        _selectedIndices.clear();
      });
      _checkValidation();
    }
  }

  void _toggleIndex(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
    _checkValidation();
  }

  void _checkValidation() {
    final expectedSet = widget.correctIndices.toSet();
    final isValid = _selectedIndices.length == expectedSet.length &&
        _selectedIndices.containsAll(expectedSet);
    widget.onValidationChanged(isValid);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Optional Narrative Context Paragraph Box
        if (widget.contextParagraph != null && widget.contextParagraph!.trim().isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
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
                        color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryTeal, size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'نَصُّ الفِقْرَةِ المَقْرُوءَةِ:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.contextParagraph!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                    height: 1.85,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Instructions and Selection Counter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: AppTheme.verbColor, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'انْقُرْ عَلَى الجُمْلَةِ الفِعْلِيَّةِ لِتَحْدِيدِهَا، وَانْقُرْ ثَانِيَةً لإِلْغَائِهَا:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedIndices.isNotEmpty
                      ? AppTheme.primaryTeal.withValues(alpha: 0.15)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedIndices.isNotEmpty ? AppTheme.primaryTeal : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  'المُحَدَّدُ: ${_selectedIndices.length} مِنْ ${widget.sentences.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _selectedIndices.isNotEmpty ? AppTheme.primaryDark : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // List of Selectable Sentence Cards
        ...widget.sentences.asMap().entries.map((entry) {
          final idx = entry.key;
          final sentence = entry.value;
          final isSelected = _selectedIndices.contains(idx);
          final isTargetCorrect = widget.correctIndices.contains(idx);

          Color cardBg = Colors.white;
          Color borderColor = const Color(0xFFCBD5E1);
          Color textColor = AppTheme.textDark;

          if (widget.areAnswersRevealed) {
            if (isTargetCorrect) {
              cardBg = const Color(0xFFECFDF5);
              borderColor = AppTheme.successGreen;
              textColor = const Color(0xFF065F46);
            } else {
              cardBg = const Color(0xFFF8FAFC);
              borderColor = const Color(0xFFE2E8F0);
              textColor = AppTheme.textMuted;
            }
          } else if (isSelected) {
            cardBg = AppTheme.primaryLight;
            borderColor = AppTheme.primaryTeal;
            textColor = AppTheme.primaryDark;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              onTap: () => _toggleIndex(idx),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected || (widget.areAnswersRevealed && isTargetCorrect) ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppTheme.primaryTeal.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Checkbox / Number Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryTeal
                            : (widget.areAnswersRevealed && isTargetCorrect
                                ? AppTheme.successGreen
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected || (widget.areAnswersRevealed && isTargetCorrect)
                              ? Colors.transparent
                              : Colors.grey.shade400,
                        ),
                      ),
                      child: Icon(
                        isSelected || (widget.areAnswersRevealed && isTargetCorrect)
                            ? Icons.check_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: isSelected || (widget.areAnswersRevealed && isTargetCorrect)
                            ? Colors.white
                            : Colors.grey.shade400,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Sentence Text
                    Expanded(
                      child: Text(
                        sentence,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Grammatical Role Indicator Pill
                    if (widget.areAnswersRevealed) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isTargetCorrect ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isTargetCorrect ? const Color(0xFF10B981) : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          isTargetCorrect ? 'جُمْلَةٌ فِعْلِيَّةٌ ✓' : 'جُمْلَةٌ أُخْرَى',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isTargetCorrect ? const Color(0xFF047857) : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ] else if (isSelected) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryTeal),
                        ),
                        child: const Text(
                          'مُحَدَّدَةٌ كَفِعْلِيَّةٍ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
