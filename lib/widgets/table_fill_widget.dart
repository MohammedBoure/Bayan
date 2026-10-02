import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Table Cell Fill widget (إكمال الفراغات داخل الجدول)
/// Designed for classroom whiteboards, interactive touchscreens, and Data Show projectors.
/// Displays a multi-column table with missing cells that students can complete via:
/// 1) Tap-to-Place from the top word bank.
/// 2) Drag-and-Drop from the word bank to table cells.
/// 3) 1-Click teacher answer reveals with model solution styling.
class TableFillWidget extends StatefulWidget {
  final List<String> headers;
  final List<Map<String, String>> rows;
  final List<String> availableWords;
  final Map<String, String> solutions;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;

  const TableFillWidget({
    super.key,
    required this.headers,
    required this.rows,
    required this.availableWords,
    required this.solutions,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
  });

  @override
  State<TableFillWidget> createState() => _TableFillWidgetState();
}

class _TableFillWidgetState extends State<TableFillWidget> {
  late Map<String, String?> _placements;
  String? _selectedBankWord;
  String? _selectedSlotKey;

  @override
  void initState() {
    super.initState();
    _resetBoard();
  }

  @override
  void didUpdateWidget(TableFillWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed && !oldWidget.areAnswersRevealed) {
      setState(() {
        _placements = Map.from(widget.solutions);
        _selectedBankWord = null;
        _selectedSlotKey = null;
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
    } else {
      _placements = {for (var k in widget.solutions.keys) k: null};
    }
    _selectedBankWord = null;
    _selectedSlotKey = null;
    _checkValidation();
  }

  List<String> get _remainingPool {
    final pool = List<String>.from(widget.availableWords);
    for (var placed in _placements.values) {
      if (placed != null) {
        pool.remove(placed);
      }
    }
    return pool;
  }

  void _placeWord(String word, String slotKey) {
    setState(() {
      // If word was already placed in another slot, unplace it first
      for (final k in _placements.keys) {
        if (_placements[k] == word) {
          _placements[k] = null;
        }
      }
      _placements[slotKey] = word;
      _selectedBankWord = null;
      _selectedSlotKey = null;
    });
    _checkValidation();
  }

  void _unplaceWord(String slotKey) {
    if (widget.areAnswersRevealed) return;
    setState(() {
      _placements[slotKey] = null;
      if (_selectedSlotKey == slotKey) _selectedSlotKey = null;
    });
    _checkValidation();
  }

  void _checkValidation() {
    if (widget.areAnswersRevealed) {
      widget.onValidationChanged(true);
      return;
    }

    bool allCorrect = true;
    for (final entry in widget.solutions.entries) {
      final placed = _placements[entry.key];
      if (placed == null || placed != entry.value) {
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
      if (_placements[entry.key] == entry.value) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final totalSlots = widget.solutions.length;
    final solved = _solvedCount;
    final remainingWords = _remainingPool;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Pedagogical Header & Counter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.table_chart_rounded, color: Color(0xFF2563EB), size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'اسْحَبِ الفِعْلَ أَوْ انْقُرْ عَلَيْهِ لِإِكْمَالِ الخَانَةِ الفَارِغَةِ فِي الجَدْوَلِ:',
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
                  color: solved == totalSlots ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'المُكْتَمَلُ: $solved / $totalSlots',
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

        // 2. Word Bank of Available Verbs
        Container(
          padding: const EdgeInsets.all(18),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: AppTheme.primaryTeal, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'بَنْكُ الأَفْعَالِ (انْقُرْ عَلَى الكَلِمَةِ لِوَضْعِهَا فِي الخَانَةِ):',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  if (!widget.areAnswersRevealed && _placements.values.any((v) => v != null))
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _resetBoard();
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('إِعَادَةُ الضَّبْطِ'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.accentOrange,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (remainingWords.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'تَمَّ اسْتِخْدَامُ جَمِيعِ الأَفْعَالِ بِنَجَاحٍ! ✓',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: remainingWords.map((word) {
                    final isSelected = _selectedBankWord == word;

                    final chipWidget = AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryTeal : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryTeal : const Color(0xFFCBD5E1),
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
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

                    return Draggable<String>(
                      data: word,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Opacity(
                          opacity: 0.9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
                              ],
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
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: chipWidget,
                      ),
                      child: InkWell(
                        onTap: () {
                          if (widget.areAnswersRevealed) return;
                          if (_selectedSlotKey != null) {
                            // Slot was waiting for word
                            _placeWord(word, _selectedSlotKey!);
                          } else {
                            // Toggle word selection
                            setState(() {
                              _selectedBankWord = isSelected ? null : word;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: chipWidget,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. The Interactive Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

    // Interactive Fillable Slot
    final placedWord = _placements[cellKey];
    final expectedWord = widget.solutions[cellKey];
    final isSlotSelected = _selectedSlotKey == cellKey;
    final isCorrect = placedWord != null && placedWord == expectedWord;
    final showSuccess = widget.areAnswersRevealed || isCorrect;

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !widget.areAnswersRevealed,
      onAcceptWithDetails: (details) {
        _placeWord(details.data, cellKey);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        Color bgColor = const Color(0xFFF8FAFC);
        Color borderColor = const Color(0xFFCBD5E1);
        Color textColor = AppTheme.textDark;

        if (showSuccess) {
          bgColor = const Color(0xFFDCFCE7);
          borderColor = const Color(0xFF16A34A);
          textColor = const Color(0xFF15803D);
        } else if (placedWord != null) {
          bgColor = const Color(0xFFEFF6FF);
          borderColor = const Color(0xFF3B82F6);
          textColor = const Color(0xFF1D4ED8);
        } else if (isSlotSelected || isHovered) {
          bgColor = const Color(0xFFFEF3C7);
          borderColor = AppTheme.accentOrange;
          textColor = AppTheme.accentOrange;
        }

        return InkWell(
          onTap: () {
            if (widget.areAnswersRevealed) return;
            if (placedWord != null) {
              // Click placed word to unplace it
              _unplaceWord(cellKey);
            } else if (_selectedBankWord != null) {
              // Place selected bank word into this slot
              _placeWord(_selectedBankWord!, cellKey);
            } else {
              // Toggle slot selection
              setState(() {
                _selectedSlotKey = isSlotSelected ? null : cellKey;
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: (isSlotSelected || isHovered || showSuccess) ? 2.2 : 1.5,
              ),
              boxShadow: (isSlotSelected || isHovered)
                  ? [
                      BoxShadow(
                        color: AppTheme.accentOrange.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showSuccess) ...[
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 4),
                ],
                Text(
                  placedWord ?? (isSlotSelected ? 'انْقُرِ الكَلِمَةَ' : '؟ (فَرَاغٌ)'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: placedWord != null ? 20 : 14,
                    fontWeight: placedWord != null ? FontWeight.w900 : FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (placedWord != null && !widget.areAnswersRevealed) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
