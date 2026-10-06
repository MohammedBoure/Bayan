import 'package:flutter/material.dart';
import '../theme/app_theme.dart';



/// Interactive sentence multi-selection widget for classroom whiteboards and Data Show.
/// Supports paragraph context display with direct sentence tapping, vibrant emerald green
/// selection highlighting, counter pill, intelligent error feedback ("حاول مرة أخرى"),
/// and delayed solution reveal ("الجمل الفعلية الموجودة في الفقرة") shown only upon correct completion.
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
  bool _hasChecked = false;
  String? _statusMessage;
  bool _statusIsSuccess = true;



  @override
  void initState() {
    super.initState();
    if (widget.areAnswersRevealed) {
      _selectedIndices.addAll(widget.correctIndices);
      _hasChecked = true;
      _statusMessage = 'تَمَّ إِظْهَارُ جَمِيعِ الإِجَابَاتِ وَالجُمَلِ الفِعْلِيَّةِ!';
      _statusIsSuccess = true;
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
        _hasChecked = true;
        _statusMessage = 'تَمَّ إِظْهَارُ جَمِيعِ الإِجَابَاتِ وَالجُمَلِ الفِعْلِيَّةِ!';
        _statusIsSuccess = true;
      });
      _checkValidation();
    } else if (!widget.areAnswersRevealed && oldWidget.areAnswersRevealed) {
      setState(() {
        _selectedIndices.clear();
        _hasChecked = false;
        _statusMessage = null;
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
      _hasChecked = false;
      _statusMessage = null;
    });
    _checkValidation();
  }

  void _verifyAnswers() {
    final expectedSet = widget.correctIndices.toSet();
    final isCorrect = _selectedIndices.length == expectedSet.length &&
        _selectedIndices.containsAll(expectedSet);

    setState(() {
      _hasChecked = true;
      if (isCorrect) {
        _statusMessage = '✅ أَحْسَنْتَ! لَقَدْ تَعَرَّفْتَ عَلَى الجُمَلِ الفِعْلِيَّةِ فِي الفِقْرَةِ بِنَجَاحٍ!';
        _statusIsSuccess = true;
      } else {
        _statusMessage = '❌ حَاوِلْ مَرَّةً أُخْرَى! رَاجِعْ بِدَايَةَ كُلِّ جُمْلَةٍ: إِذَا بَدَأَتْ بِفِعْلٍ فَهِيَ جُمْلَةٌ فِعْلِيَّةٌ، وَإِذَا بَدَأَتْ بِاسْمٍ فَلَيْسَتْ جُمْلَةً فِعْلِيَّةً.';
        _statusIsSuccess = false;
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
    final expectedSet = widget.correctIndices.toSet();
    final isSelectionValid = _selectedIndices.length == expectedSet.length &&
        _selectedIndices.containsAll(expectedSet);
    final showSolution = widget.areAnswersRevealed || (_hasChecked && isSelectionValid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Narrative Context Paragraph Box (Interactive sentence tapping)
        if (widget.contextParagraph != null && widget.contextParagraph!.trim().isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.35), width: 2),
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_stories_rounded, color: AppTheme.primaryTeal, size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'نَصُّ الفِقْرَةِ المَقْرُوءَةِ:',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedIndices.isNotEmpty
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'المُحَدَّدُ: ${_selectedIndices.length} / ${widget.correctIndices.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Interactive Paragraph Sentence Pills
                _buildInteractiveParagraph(),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 2. Action Controls & Status Feedback Banner
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.checklist_rounded, color: Color(0xFF16A34A), size: 26),
                const SizedBox(width: 8),
                Text(
                  'قَائِمَةُ الجُمَلِ لِلتَّمْيِيزِ (${_selectedIndices.length} مُحَدَّدَةٌ):',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _verifyAnswers,
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text(
                'تَحَقَّقْ مِنَ الإِجَابَةِ',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Live Status / Feedback Banner
        if (_statusMessage != null) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _statusIsSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _statusIsSuccess ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _statusIsSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: _statusIsSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _statusIsSuccess ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 3. Solution Card: الجمل الفعلية الموجودة في الفقرة (Revealed ONLY when answer is correct or revealed)
        if (showSolution) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF86EFAC), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الجُمَلُ الفِعْلِيَّةُ المَوْجُودَةُ فِي الفِقْرَةِ (${widget.correctIndices.length} جُمَلٍ فِعْلِيَّةٍ):',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...widget.correctIndices.asMap().entries.map((e) {
                  final num = e.key + 1;
                  final sIdx = e.value;
                  final sentence = widget.sentences[sIdx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF16A34A),
                          child: Text(
                            '$num',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            sentence,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: const Text(
                            'جُمْلَةٌ فِعْلِيَّةٌ ✓',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // 4. List of Selectable Sentence Cards (Bright Green when selected)
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
              cardBg = const Color(0xFFDCFCE7);
              borderColor = const Color(0xFF16A34A);
              textColor = const Color(0xFF15803D);
            } else {
              cardBg = const Color(0xFFF8FAFC);
              borderColor = const Color(0xFFE2E8F0);
              textColor = AppTheme.textMuted;
            }
          } else if (isSelected) {
            // Bright Green highlight on student selection
            cardBg = const Color(0xFFDCFCE7);
            borderColor = const Color(0xFF16A34A);
            textColor = const Color(0xFF15803D);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _toggleIndex(idx),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected || (widget.areAnswersRevealed && isTargetCorrect) ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Checkbox Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected || (widget.areAnswersRevealed && isTargetCorrect)
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected || (widget.areAnswersRevealed && isTargetCorrect)
                              ? const Color(0xFF16A34A)
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
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
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
                          color: isTargetCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isTargetCorrect ? const Color(0xFF86EFAC) : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          isTargetCorrect ? 'جُمْلَةٌ فِعْلِيَّةٌ ✓' : 'جُمْلَةٌ اسْمِيَّةٌ / أُخْرَى',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isTargetCorrect ? const Color(0xFF15803D) : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ] else if (isSelected) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                        ),
                        child: const Text(
                          'جُمْلَةٌ فِعْلِيَّةٌ مُحَدَّدَةٌ ✓',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF15803D),
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

  /// Builds continuous reading paragraph as one unified flowing narrative text (نص واحد غير مقسم).
  Widget _buildInteractiveParagraph() {
    final paragraph = widget.contextParagraph!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Text(
        paragraph,
        textAlign: TextAlign.justify,
        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
          height: 1.95,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
