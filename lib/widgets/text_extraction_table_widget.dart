import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../nlp/arabic_clitic_stemmer.dart';
import '../theme/app_theme.dart';

/// Text Extraction & Parsing Table widget
/// Designed for classroom whiteboard, interactive touchscreens, and Data Show projectors.
/// Displays an authentic reading story, supports interactive word tapping to discover and extract target words,
/// and features an interactive table with detailed syntactic and grammatical analysis.
class TextExtractionTableWidget extends StatefulWidget {
  final String passage;
  final List<Map<String, String>> tableRows;
  final List<String>? tableHeaders;
  final String? tableTitle;
  final String? passageTitle;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;

  const TextExtractionTableWidget({
    super.key,
    required this.passage,
    required this.tableRows,
    this.tableHeaders,
    this.tableTitle,
    this.passageTitle,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
  });

  @override
  State<TextExtractionTableWidget> createState() => _TextExtractionTableWidgetState();
}

class _TextExtractionTableWidgetState extends State<TextExtractionTableWidget> {
  late Set<int> _revealedRowIndices;
  String? _statusMessage;
  bool _statusIsSuccess = true;
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _resetRevealedRows();
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(TextExtractionTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed && !oldWidget.areAnswersRevealed) {
      setState(() {
        _revealedRowIndices = Set.from(List.generate(widget.tableRows.length, (i) => i));
        _statusMessage = 'تَمَّ عَرْضُ جَمِيعِ الإِجَابَاتِ وَحُلُولِ الجَدْوَلِ!';
        _statusIsSuccess = true;
      });
      widget.onValidationChanged(true);
    } else if (!widget.areAnswersRevealed && oldWidget.areAnswersRevealed) {
      setState(() {
        _resetRevealedRows();
        _statusMessage = null;
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
        final row = widget.tableRows[index];
        final word = row['word'] ?? row['col1'] ?? '';
        _statusMessage = 'تَمَّ إِظْهَارُ تَحْلِيلِ: «$word» فِي الجَدْوَلِ!';
        _statusIsSuccess = true;
      }
    });
    _checkValidation();
  }

  void _toggleAllRows() {
    setState(() {
      if (_revealedRowIndices.length == widget.tableRows.length) {
        _revealedRowIndices.clear();
        _statusMessage = 'تَمَّ إِخْفَاءُ جَمِيعِ الإِجَابَاتِ.';
        _statusIsSuccess = true;
      } else {
        _revealedRowIndices = Set.from(List.generate(widget.tableRows.length, (i) => i));
        _statusMessage = 'تَمَّ إِظْهَارُ جَمِيعِ إِجَابَاتِ وَتَحْلِيلَاتِ الجَدْوَلِ.';
        _statusIsSuccess = true;
      }
    });
    _checkValidation();
  }

  void _checkValidation() {
    final allRevealed = widget.areAnswersRevealed || _revealedRowIndices.length == widget.tableRows.length;
    widget.onValidationChanged(allRevealed);
  }

  /// Normalizes Arabic text for matching, removing diacritics and handling proclitics.
  bool _isWordMatch(String tappedWord, String targetCandidate) {
    final cleanTapped = ArabicCliticStemmer.stripDiacritics(tappedWord).trim();
    final cleanTarget = ArabicCliticStemmer.stripDiacritics(targetCandidate).trim();
    if (cleanTapped.isEmpty || cleanTarget.isEmpty) return false;

    final normTapped = ArabicCliticStemmer.normalize(cleanTapped);
    final normTarget = ArabicCliticStemmer.normalize(cleanTarget);
    if (normTapped == normTarget) return true;

    // Check with stripped proclitics (و، ف، ل، ب، ك، ال)
    if (normTapped.length > normTarget.length) {
      for (final p in ['و', 'ف', 'ل', 'ب', 'ك', 'ال']) {
        if (normTapped.startsWith(p) && normTapped.substring(p.length) == normTarget) {
          return true;
        }
      }
    }

    if (normTarget.length > normTapped.length) {
      for (final p in ['و', 'ف', 'ل', 'ب', 'ك', 'ال']) {
        if (normTarget.startsWith(p) && normTarget.substring(p.length) == normTapped) {
          return true;
        }
      }
    }

    return false;
  }

  /// Checks if a word tapped in the text matches any field of a table row.
  bool _isRowMatch(String word, Map<String, String> row) {
    final primaryWord = row['word'];
    if (primaryWord != null && primaryWord.isNotEmpty && _isWordMatch(word, primaryWord)) {
      return true;
    }

    final col1 = row['col1'];
    if (col1 != null && col1.isNotEmpty && _isWordMatch(word, col1)) {
      return true;
    }

    final col3 = row['col3'];
    if (col3 != null && col3.isNotEmpty && _isWordMatch(word, col3)) {
      return true;
    }

    final verb = row['verb'];
    if (verb != null && verb.isNotEmpty && _isWordMatch(word, verb)) {
      return true;
    }

    return false;
  }

  void _onWordTapped(String cleanWord) {
    final matchingIndices = <int>[];
    for (int i = 0; i < widget.tableRows.length; i++) {
      if (_isRowMatch(cleanWord, widget.tableRows[i])) {
        matchingIndices.add(i);
      }
    }

    setState(() {
      if (matchingIndices.isNotEmpty) {
        final unrevealed = matchingIndices.where((idx) => !_revealedRowIndices.contains(idx)).toList();
        if (unrevealed.isNotEmpty) {
          _revealedRowIndices.addAll(unrevealed);
          _statusMessage = 'أَحْسَنْتَ! اسْتَخْرَجْتَ: «$cleanWord» بِنَجَاحٍ، وَتَمَّ كَشْفُ السَّطْرِ المُنَاسِبِ فِي الجَدْوَلِ!';
          _statusIsSuccess = true;
        } else {
          _statusMessage = 'هَذِهِ الكَلِمَةُ («$cleanWord») مُسْتَخْرَجَةٌ سَابِقًا فِي الجَدْوَلِ.';
          _statusIsSuccess = true;
        }
      } else {
        _statusMessage = 'كَلِمَةُ «$cleanWord» لَيْسَتْ مِنَ الكَلِمَاتِ المَطْلُوبِ اسْتِخْرَاجُهَا. حَاوِلْ مَرَّةً أُخْرَى!';
        _statusIsSuccess = false;
      }
    });

    _checkValidation();
  }

  @override
  Widget build(BuildContext context) {
    final allRevealed = _revealedRowIndices.length == widget.tableRows.length;
    final hasCustomHeaders = widget.tableHeaders != null && widget.tableHeaders!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Reading Story Card (Interactive word tapping)
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
              // Header title + counter badge
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
                  Expanded(
                    child: Text(
                      widget.passageTitle ?? 'نَصُّ النَّشَاطِ (اقْرَأْ وَانْقُرْ عَلَى الكَلِمَاتِ لِاسْتِخْرَاجِهَا):',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: allRevealed ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'المُسْتَخْرَجُ: ${_revealedRowIndices.length} / ${widget.tableRows.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Interactive Reading Passage
              _buildInteractivePassage(),

              // Live Status / Feedback Banner
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _statusIsSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _statusIsSuccess ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusIsSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: _statusIsSuccess ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _statusIsSuccess ? const Color(0xFF15803D) : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                  widget.tableTitle != null
                      ? '${widget.tableTitle!} (${_revealedRowIndices.length}/${widget.tableRows.length}):'
                      : 'جَدْوَلُ الفَاعِلِ وَإِعْرَابِهِ (${_revealedRowIndices.length}/${widget.tableRows.length}):',
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
                allRevealed
                    ? (hasCustomHeaders ? 'إِخْفَاءُ جَمِيعِ الإِجَابَاتِ' : 'إِخْفَاءُ جَمِيعِ الإِعْرَابَاتِ')
                    : (hasCustomHeaders ? 'إِظْهَارُ جَمِيعِ الإِجَابَاتِ' : 'إِظْهَارُ جَمِيعِ الإِعْرَابَاتِ'),
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

        // 3. Extraction Table
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
                if (hasCustomHeaders)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: const Color(0xFFE0F2FE),
                    child: Row(
                      children: [
                        for (int i = 0; i < widget.tableHeaders!.length; i++)
                          Expanded(
                            flex: i == 0 ? 2 : (widget.tableHeaders!.length > 3 ? 2 : 3),
                            child: Text(
                              widget.tableHeaders![i],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0369A1),
                              ),
                            ),
                          ),
                        const SizedBox(width: 44), // Spacing for hide/reveal action
                      ],
                    ),
                  )
                else
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
                if (hasCustomHeaders)
                  ...widget.tableRows.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final row = entry.value;
                    final isRevealed = _revealedRowIndices.contains(idx);
                    return _buildCustomMultiColRow(idx, row, isRevealed);
                  })
                else
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
                                          tooltip: 'إِخْفَاءٌ',
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
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.visibility_rounded, color: Color(0xFF0284C7), size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            'عَرْضُ الإِعْرَابِ',
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

  Widget _buildCustomMultiColRow(int idx, Map<String, String> row, bool isRevealed) {
    final headers = widget.tableHeaders!;
    final word = row['word'] ?? row['col1'] ?? (row.values.isNotEmpty ? row.values.first : '');

    final List<String> cellValues = [];
    for (int i = 0; i < headers.length; i++) {
      final key = 'col${i + 1}';
      final val = row[key] ?? (i == 0 ? word : (row[headers[i]] ?? (row['parsing'] ?? '')));
      cellValues.add(val);
    }

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
          if (isRevealed) ...[
            // Column 1: Target word badge in green
            Expanded(
              flex: 2,
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
                      cellValues.isNotEmpty ? cellValues[0] : word,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Remaining columns: Grammatical values
            for (int i = 1; i < cellValues.length; i++) ...[
              Expanded(
                flex: headers.length > 3 ? 2 : 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    cellValues[i],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.visibility_off_rounded, size: 18, color: Colors.grey),
              onPressed: () => _toggleRow(idx),
              tooltip: 'إِخْفَاءٌ',
            ),
          ] else ...[
            // Unrevealed Row Placeholder (Interactive Slot)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      '؟ (عُنْصُرُ ${idx + 1})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: (headers.length - 1) * (headers.length > 3 ? 2 : 3),
              child: InkWell(
                onTap: () => _toggleRow(idx),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.touch_app_rounded, color: Color(0xFF0284C7), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'انْقُرْ عَلَى الكَلِمَةِ فِي النَّصِّ لِاسْتِخْرَاجِهَا (أَوْ انْقُرْ هُنَا لِلْكَشْفِ)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ],
      ),
    );
  }

  /// Builds the reading text where target words are NOT pre-highlighted,
  /// but can be tapped by the student to extract them into the table.
  Widget _buildInteractivePassage() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final spans = <InlineSpan>[];
    final matches = RegExp(r'(\S+|\s+)').allMatches(widget.passage.trim());

    for (final match in matches) {
      final token = match.group(0)!;
      if (RegExp(r'^\s+$').hasMatch(token)) {
        spans.add(TextSpan(text: token));
        continue;
      }

      String coreWord = token;
      String punctuation = '';
      const punctuationChars = '.,;:?!،؛؟«»()[]\'"';
      while (coreWord.isNotEmpty && punctuationChars.contains(coreWord[coreWord.length - 1])) {
        punctuation = coreWord[coreWord.length - 1] + punctuation;
        coreWord = coreWord.substring(0, coreWord.length - 1);
      }

      final matchingIndices = <int>[];
      for (int i = 0; i < widget.tableRows.length; i++) {
        if (_isRowMatch(coreWord, widget.tableRows[i])) {
          matchingIndices.add(i);
        }
      }

      final isRevealed = matchingIndices.isNotEmpty &&
          matchingIndices.any((idx) => _revealedRowIndices.contains(idx));

      final rec = TapGestureRecognizer()..onTap = () => _onWordTapped(coreWord);
      _recognizers.add(rec);

      if (isRevealed) {
        spans.add(
          TextSpan(
            text: coreWord,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF15803D),
              backgroundColor: Color(0xFFDCFCE7),
              height: 1.8,
            ),
            recognizer: rec,
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: coreWord,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              height: 1.8,
            ),
            recognizer: rec,
          ),
        );
      }

      if (punctuation.isNotEmpty) {
        spans.add(
          TextSpan(
            text: punctuation,
            style: const TextStyle(
              fontSize: 22,
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
