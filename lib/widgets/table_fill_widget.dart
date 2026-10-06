import 'package:flutter/material.dart';
import '../nlp/arabic_clitic_stemmer.dart';
import '../theme/app_theme.dart';

/// Table Cell Fill widget (إكمال الفراغات داخل الجدول عبر الكتابة المباشرة)
/// Designed for classroom whiteboards, interactive touchscreens, and Data Show projectors.
/// Displays a multi-column table with missing cells that students complete by typing
/// the appropriate verb, supporting diacritic-tolerant NLP validation, quick whiteboard Tashkeel bar,
/// and 1-click teacher answer reveals.
class TableFillWidget extends StatefulWidget {
  final List<String> headers;
  final List<Map<String, String>> rows;
  final List<String>? availableWords;
  final Map<String, String> solutions;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;

  const TableFillWidget({
    super.key,
    required this.headers,
    required this.rows,
    this.availableWords,
    required this.solutions,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
  });

  @override
  State<TableFillWidget> createState() => _TableFillWidgetState();
}

class _TableFillWidgetState extends State<TableFillWidget> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  String? _focusedCellKey;

  static const List<String> _tashkeelSymbols = ['َ', 'ُ', 'ِ', 'ْ', 'ّ', 'ً', 'ٌ', 'ٍ'];

  @override
  void initState() {
    super.initState();
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkValidation();
    });
  }

  void _initControllers() {
    for (final key in widget.solutions.keys) {
      final ctrl = TextEditingController();
      if (widget.areAnswersRevealed) {
        ctrl.text = widget.solutions[key] ?? '';
      }
      _controllers[key] = ctrl;

      final fn = FocusNode();
      fn.addListener(() {
        if (fn.hasFocus) {
          setState(() {
            _focusedCellKey = key;
          });
        }
      });
      _focusNodes[key] = fn;
    }
  }

  @override
  void didUpdateWidget(TableFillWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed && !oldWidget.areAnswersRevealed) {
      for (final key in widget.solutions.keys) {
        _controllers[key]?.text = widget.solutions[key] ?? '';
      }
      setState(() {
        _focusedCellKey = null;
      });
      widget.onValidationChanged(true);
    } else if (!widget.areAnswersRevealed && oldWidget.areAnswersRevealed) {
      for (final ctrl in _controllers.values) {
        ctrl.clear();
      }
      setState(() {
        _focusedCellKey = null;
      });
      _checkValidation();
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    for (final fn in _focusNodes.values) {
      fn.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String key) {
    return _controllers.putIfAbsent(key, () => TextEditingController());
  }

  FocusNode _getFocusNode(String key) {
    return _focusNodes.putIfAbsent(key, () => FocusNode());
  }

  bool _isCellValid(String cellKey, String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    final expected = widget.solutions[cellKey];
    if (expected == null) return false;

    // Direct match
    if (trimmed == expected.trim()) return true;

    // Normalized match tolerant of diacritics and Alef variations
    final cleanIn = ArabicCliticStemmer.stripDiacritics(trimmed).replaceAll(RegExp(r'[.,!؟،\s]'), '').trim();
    final normIn = ArabicCliticStemmer.normalize(cleanIn);

    final cleanExp = ArabicCliticStemmer.stripDiacritics(expected).replaceAll(RegExp(r'[.,!؟،\s]'), '').trim();
    final normExp = ArabicCliticStemmer.normalize(cleanExp);

    return normIn.isNotEmpty && normIn == normExp;
  }

  void _checkValidation() {
    if (widget.areAnswersRevealed) {
      widget.onValidationChanged(true);
      return;
    }

    bool allCorrect = true;
    for (final entry in widget.solutions.entries) {
      final input = _controllers[entry.key]?.text ?? '';
      if (!_isCellValid(entry.key, input)) {
        allCorrect = false;
        break;
      }
    }
    widget.onValidationChanged(allCorrect);
  }

  int get _solvedCount {
    if (widget.areAnswersRevealed) return widget.solutions.length;
    int count = 0;
    for (final entry in widget.solutions.entries) {
      final input = _controllers[entry.key]?.text ?? '';
      if (_isCellValid(entry.key, input)) {
        count++;
      }
    }
    return count;
  }

  void _clearAll() {
    if (widget.areAnswersRevealed) return;
    for (final ctrl in _controllers.values) {
      ctrl.clear();
    }
    setState(() {
      _focusedCellKey = null;
    });
    _checkValidation();
  }

  void _insertTashkeel(String diacritic) {
    String? targetKey = _focusedCellKey;
    if (targetKey == null || !_controllers.containsKey(targetKey)) {
      // Pick first unsolved cell or first cell
      targetKey = widget.solutions.keys.firstWhere(
        (k) => !_isCellValid(k, _getController(k).text),
        orElse: () => widget.solutions.keys.first,
      );
      _focusedCellKey = targetKey;
      _getFocusNode(targetKey).requestFocus();
    }

    final ctrl = _getController(targetKey);
    final text = ctrl.text;
    final selection = ctrl.selection;

    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, diacritic);
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + diacritic.length),
      );
    } else {
      ctrl.text = '$text$diacritic';
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    }

    setState(() {});
    _checkValidation();
  }

  @override
  Widget build(BuildContext context) {
    final totalSlots = widget.solutions.length;
    final solved = _solvedCount;
    final hasUserTyped = _controllers.values.any((c) => c.text.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Pedagogical Header & Counter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 26),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'اكْتُبِ الفِعْلَ المُنَاسِبَ فِي الخَانَةِ الفَارِغَةِ فِي الجَدْوَلِ كَمَا فِي المِثَالِ:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
              if (!widget.areAnswersRevealed && hasUserTyped) ...[
                TextButton(
                  onPressed: _clearAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: const Text('مَسْحُ الخَانَاتِ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: solved == totalSlots ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'المُكْتَمَلُ: $solved / $totalSlots',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Quick Tashkeel Toolbar for Interactive Whiteboard and Touch Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.keyboard_outlined, size: 20, color: Color(0xFF64748B)),
              const SizedBox(width: 10),
              const Text(
                'حَرَكَاتُ التَّشْكِيلِ لِلَّوْحَةِ:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _tashkeelSymbols.map((t) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Material(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _insertTashkeel(t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. The Interactive Data-Show Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  color: const Color(0xFFE0F2FE),
                  child: Row(
                    children: widget.headers.map((header) {
                      return Expanded(
                        child: Text(
                          header,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Table Rows
                ...widget.rows.asMap().entries.map((entry) {
                  final rowIdx = entry.key;
                  final row = entry.value;
                  final isExample = row['isExample'] == 'true';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isExample
                          ? const Color(0xFFF0FDF4)
                          : (rowIdx.isEven ? Colors.white : const Color(0xFFF8FAFC)),
                      border: Border(
                        bottom: BorderSide(
                          color: isExample ? const Color(0xFFBBF7D0) : Colors.grey.shade200,
                          width: isExample ? 1.5 : 1.0,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (int colIdx = 1; colIdx <= widget.headers.length; colIdx++)
                          Expanded(
                            child: _buildCell(rowIdx, colIdx, row, isExample),
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

  Widget _buildCell(int rowIdx, int colIdx, Map<String, String> row, bool isExample) {
    final cellKey = 'r${rowIdx}_c$colIdx';
    final fixedVal = row['col$colIdx'] ?? '';
    final isBlankSlot = fixedVal.contains('___') || row.containsKey('ans$colIdx');

    if (isExample || !isBlankSlot) {
      // Fixed / Example cell
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isExample ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExample ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fixedVal,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isExample ? const Color(0xFF15803D) : AppTheme.textDark,
              ),
            ),
            if (isExample && colIdx == 2) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'مِثَالٌ تَوْضِيحِيٌّ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Interactive Student Input Slot
    final ctrl = _getController(cellKey);
    final fn = _getFocusNode(cellKey);
    final textVal = ctrl.text;
    final isRevealed = widget.areAnswersRevealed;
    final isValid = isRevealed || _isCellValid(cellKey, textVal);
    final isFocused = _focusedCellKey == cellKey;

    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFCBD5E1);
    Color textColor = AppTheme.textDark;

    if (isValid) {
      bgColor = const Color(0xFFDCFCE7);
      borderColor = const Color(0xFF16A34A);
      textColor = const Color(0xFF15803D);
    } else if (isFocused) {
      bgColor = const Color(0xFFF0F9FF);
      borderColor = const Color(0xFF0284C7);
      textColor = const Color(0xFF0F172A);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: TextFormField(
        key: Key('cell_input_$cellKey'),
        controller: ctrl,
        focusNode: fn,
        enabled: !isRevealed,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: bgColor,
          hintText: 'اكْتُبْ...',
          hintStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: Color(0xFF94A3B8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: borderColor,
              width: (isValid || isFocused) ? 2.0 : 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF0284C7),
              width: 2.2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isValid ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
              width: 2.0,
            ),
          ),
          suffixIcon: isValid
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                    size: 20,
                  ),
                )
              : (textVal.isNotEmpty && !isRevealed
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                      onPressed: () {
                        ctrl.clear();
                        setState(() {});
                        _checkValidation();
                      },
                      tooltip: 'مَسْحٌ',
                    )
                  : null),
        ),
        onTap: () {
          setState(() {
            _focusedCellKey = cellKey;
          });
        },
        onChanged: (_) {
          setState(() {});
          _checkValidation();
        },
      ),
    );
  }
}
