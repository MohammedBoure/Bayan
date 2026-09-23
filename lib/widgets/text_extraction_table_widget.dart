import 'package:flutter/material.dart';
import '../nlp/arabic_clitic_stemmer.dart';
import '../theme/app_theme.dart';

/// Text Extraction & Parsing Table widget (استخرج الفاعل وأعربه في الجدول التالي)
/// Designed for classroom whiteboard and Data Show projectors.
/// Displays an authentic reading story, supports interactive word tapping to extract subjects,
/// and features an interactive 2-column table with detailed syntactic analysis.
class TextExtractionTableWidget extends StatefulWidget {
  final String passage;
  final List<Map<String, String>> tableRows;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;

  const TextExtractionTableWidget({
    super.key,
    required this.passage,
    required this.tableRows,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
  });

  @override
  State<TextExtractionTableWidget> createState() => _TextExtractionTableWidgetState();
}

class _TextExtractionTableWidgetState extends State<TextExtractionTableWidget> {
  late Set<int> _revealedRowIndices;

  @override
  void initState() {
    super.initState();
    _resetRevealedRows();
  }

  @override
  void didUpdateWidget(TextExtractionTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed && !oldWidget.areAnswersRevealed) {
      setState(() {
        _revealedRowIndices = Set.from(List.generate(widget.tableRows.length, (i) => i));
      });
      widget.onValidationChanged(true);
    } else if (!widget.areAnswersRevealed && oldWidget.areAnswersRevealed) {
      setState(() {
        _resetRevealedRows();
      });
    }
  }

  void _resetRevealedRows() {
    if (widget.areAnswersRevealed) {
      _revealedRowIndices = Set.from(List.generate(widget.tableRows.length, (i) => i));
    } else {
      _revealedRowIndices = {};
    }
    _checkValidation();
  }

  void _toggleRow(int index) {
    setState(() {
      if (_revealedRowIndices.contains(index)) {
        _revealedRowIndices.remove(index);
      } else {
        _revealedRowIndices.add(index);
      }
    });
    _checkValidation();
  }

  void _toggleAllRows() {
    setState(() {
      if (_revealedRowIndices.length == widget.tableRows.length) {
        _revealedRowIndices.clear();
      } else {
        _revealedRowIndices = Set.from(List.generate(widget.tableRows.length, (i) => i));
      }
    });
    _checkValidation();
  }

  void _checkValidation() {
    final allRevealed = widget.areAnswersRevealed || _revealedRowIndices.length == widget.tableRows.length;
    widget.onValidationChanged(allRevealed);
  }

  @override
  Widget build(BuildContext context) {
    final allRevealed = _revealedRowIndices.length == widget.tableRows.length;

    // Collect all subject target words to highlight in the text
    final targetWords = widget.tableRows.map((r) => r['word'] ?? '').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. New Reading Story Card
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: AppTheme.primaryTeal, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'نَصُّ النَّشَاطِ (اقْرَأْ وَاسْتَخْرِجِ الفَاعِلَ):',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildInteractivePassage(widget.passage, targetWords),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Table Controls Header
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.table_chart_rounded, color: Color(0xFF0284C7), size: 26),
                const SizedBox(width: 8),
                Text(
                  'جَدْوَلُ الفَاعِلِ وَإِعْرَابِهِ (${_revealedRowIndices.length}/${widget.tableRows.length}):',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _toggleAllRows,
              icon: Icon(allRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
              label: Text(
                allRevealed ? 'إِخْفَاءُ جَمِيعِ الإِعْرَابَاتِ' : 'إِظْهَارُ جَمِيعِ الإِعْرَابَاتِ',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: allRevealed ? Colors.grey.shade700 : const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 3. Two-Column Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                // Table Header Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: const Color(0xFFE0F2FE),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 220,
                        child: Text(
                          'الفَاعِلُ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'إِعْرَابُهُ التَّفْصِيلِيُّ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Data Rows
                ...widget.tableRows.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final row = entry.value;
                  final word = row['word'] ?? '';
                  final verb = row['verb'] ?? '';
                  final parsing = row['parsing'] ?? '';
                  final isRevealed = _revealedRowIndices.contains(idx);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: idx.isEven ? Colors.white : const Color(0xFFF8FAFC),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Col 1: Word + Associated Verb
                        SizedBox(
                          width: 220,
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                                ),
                                child: Text(
                                  word,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                              if (verb.isNotEmpty)
                                Text(
                                  '($verb)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Col 2: Detailed Parsing (Tap to reveal or shown)
                        Expanded(
                          child: isRevealed
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          parsing,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF15803D),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.visibility_off_rounded, size: 18, color: Colors.grey),
                                        onPressed: () => _toggleRow(idx),
                                        tooltip: 'إخفاء',
                                      ),
                                    ],
                                  ),
                                )
                              : InkWell(
                                  onTap: () => _toggleRow(idx),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.touch_app_rounded, color: Color(0xFF0284C7), size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'انْقُرْ لِعَرْضِ إِعْرَابِ هَذَا الفَاعِلِ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0284C7),
                                          ),
                                        ),
                                      ],
                                    ),
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
        ),
      ],
    );
  }

  /// Builds the reading text highlighting subjects in soft green when revealed
  Widget _buildInteractivePassage(String passageText, List<String> targetWords) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'([\u0600-\u06FF]+|[^\u0600-\u06FF]+)');
    final matches = regex.allMatches(passageText.trim());

    final cleanTargets = targetWords.map((t) => ArabicCliticStemmer.stripDiacritics(t).trim()).toSet();

    for (final match in matches) {
      final token = match.group(0) ?? '';
      if (token.isEmpty) continue;

      final cleanToken = ArabicCliticStemmer.stripDiacritics(token).trim();
      final isTarget = cleanTargets.contains(cleanToken);

      if (isTarget) {
        spans.add(
          TextSpan(
            text: token,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF15803D), // Emerald green for extracted subjects
              backgroundColor: Color(0xFFDCFCE7),
              height: 1.8,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: token,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              height: 1.8,
            ),
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
    );
  }
}
