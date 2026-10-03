import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../nlp/arabic_clitic_stemmer.dart';
import '../theme/app_theme.dart';

/// Evaluation result for student-constructed Arabic syntactic parsing.
class _ParsingEvaluationResult {
  final bool isValid;
  final String feedback;

  const _ParsingEvaluationResult(this.isValid, this.feedback);
}

/// Text Extraction & Parsing Table widget
/// Designed for classroom whiteboard, interactive touchscreens, and Data Show projectors.
/// Displays an authentic reading story, supports interactive word tapping to discover and extract target words,
/// and features an interactive table with detailed syntactic and grammatical analysis.
///
/// In student-parsing mode:
/// - Words extracted from the text appear in the table without automatically revealing the parsing answer.
/// - The student builds the authentic grammatical parsing using a rich palette of building blocks (including distractors).
/// - Provides intelligent grammatical verification and targeted error feedback.
class TextExtractionTableWidget extends StatefulWidget {
  final String passage;
  final List<Map<String, String>> tableRows;
  final List<String>? tableHeaders;
  final String? tableTitle;
  final String? passageTitle;
  final bool? requiresStudentParsing;
  final bool? requiresStudentInput;
  final List<String>? helperChips;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;

  const TextExtractionTableWidget({
    super.key,
    required this.passage,
    required this.tableRows,
    this.tableHeaders,
    this.tableTitle,
    this.passageTitle,
    this.requiresStudentParsing,
    this.requiresStudentInput,
    this.helperChips,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
  });

  @override
  State<TextExtractionTableWidget> createState() => _TextExtractionTableWidgetState();
}

class _TextExtractionTableWidgetState extends State<TextExtractionTableWidget> {
  late Set<int> _revealedRowIndices;
  int? _activeParsingRowIndex;
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, bool?> _rowValidationStatus = {};
  final Map<int, String?> _rowFeedbackMessage = {};

  final Map<String, TextEditingController> _cellControllers = {};
  String? _focusedCellKey;

  String? _statusMessage;
  bool _statusIsSuccess = true;
  final List<TapGestureRecognizer> _recognizers = [];

  // Default rich syntactic building blocks and distractors for Arabic subject parsing:
  static const List<String> _defaultSubjectParsingChips = [
    // أجزاء الإعراب الأصلية
    'فَاعِلٌ',
    'مَرْفُوعٌ',
    'وَعَلَامَةُ رَفْعِهِ',
    'الضَّمَّةُ الظَّاهِرَةُ',
    'الضَّمَّةُ الْمُقَدَّرَةُ',
    'عَلَى آخِرِهِ.',
    'عَلَى الْيَاءِ مَنَعَ مِنْ ظُهُورِهَا الثِّقَلُ.',
    // أجزاء ثانوية للتشتيت
    'مَفْعُولٌ بِهِ',
    'مَنْصُوبٌ',
    'مَجْزُومٌ',
    'وَعَلَامَةُ نَصْبِهِ',
    'وَعَلَامَةُ جَزْمِهِ',
    'الْفَتْحَةُ الظَّاهِرَةُ',
    'الْكَسْرَةُ الظَّاهِرَةُ',
    'السُّكُونُ',
    'فِعْلٌ مَاضٍ',
    'مَبْنِيٌّ عَلَى الْفَتْحِ',
  ];

  bool get _isStudentParsingMode =>
      widget.requiresStudentParsing == true ||
      (widget.requiresStudentParsing == null &&
          widget.tableHeaders == null &&
          widget.tableRows.any((r) => r.containsKey('parsing')));

  bool get _isStudentTableInputMode =>
      widget.requiresStudentInput == true ||
      (widget.requiresStudentParsing == true && widget.tableHeaders != null);

  TextEditingController _getController(int idx) {
    if (!_controllers.containsKey(idx)) {
      final ctrl = TextEditingController();
      _controllers[idx] = ctrl;
    }
    return _controllers[idx]!;
  }

  TextEditingController _getCellController(int rowIdx, int colIdx) {
    final key = '${rowIdx}_$colIdx';
    if (!_cellControllers.containsKey(key)) {
      _cellControllers[key] = TextEditingController();
    }
    return _cellControllers[key]!;
  }

  bool _isCellValid(int rowIdx, int colIdx, String input) {
    if (input.trim().isEmpty) return false;
    final row = widget.tableRows[rowIdx];
    final colKey = 'col${colIdx + 1}';
    final model = row[colKey] ?? '';

    final cleanIn = ArabicCliticStemmer.stripDiacritics(input).trim();
    final normIn = ArabicCliticStemmer.normalize(cleanIn);
    final cleanMod = ArabicCliticStemmer.stripDiacritics(model).trim();
    final normMod = ArabicCliticStemmer.normalize(cleanMod);

    if (normIn == normMod) return true;

    String stripPunct(String s) =>
        s.replaceAll(RegExp(r'[.,؛،:؟!«»\(\)]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    if (stripPunct(normIn) == stripPunct(normMod)) return true;

    // Col 2: زمن الفعل
    if (colIdx == 1) {
      if (normMod.contains('ماض') && (normIn.contains('ماض') || normIn.contains('ماضي'))) return true;
      if (normMod.contains('مضارع') && normIn.contains('مضارع')) return true;
    }

    // Col 3: نائب الفاعل
    if (colIdx == 2) {
      final sIn = normIn.startsWith('ال') ? normIn.substring(2) : normIn;
      final sMod = normMod.startsWith('ال') ? normMod.substring(2) : normMod;
      if (sIn == sMod) return true;
    }

    // Col 4: علامة بناء أو رفع الفعل
    if (colIdx == 3) {
      if (normMod.contains('فتح') && (normIn.contains('فتح') || normIn.contains('فتحة'))) return true;
      if (normMod.contains('ضم') && (normIn.contains('ضم') || normIn.contains('ضمة'))) return true;
    }

    // Col 5: علامة رفع نائب الفاعل
    if (colIdx == 4) {
      if (normMod.contains('ضم') && (normIn.contains('ضم') || normIn.contains('ضمة'))) return true;
      if (normMod.contains('الف') && (normIn.contains('الف') || normIn.contains('ألف'))) return true;
      if (normMod.contains('واو') && normIn.contains('واو')) return true;
    }

    return false;
  }

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
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    for (final c in _cellControllers.values) {
      c.dispose();
    }
    _cellControllers.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(TextExtractionTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed && !oldWidget.areAnswersRevealed) {
      setState(() {
        _revealedRowIndices = Set.from(List.generate(widget.tableRows.length, (i) => i));
        if (_isStudentParsingMode) {
          for (int i = 0; i < widget.tableRows.length; i++) {
            final model = widget.tableRows[i]['parsing'] ?? '';
            _getController(i).text = model;
            _rowValidationStatus[i] = true;
            _rowFeedbackMessage[i] = null;
          }
          _activeParsingRowIndex = 0;
        }
        if (_isStudentTableInputMode && widget.tableHeaders != null) {
          final headers = widget.tableHeaders!;
          for (int r = 0; r < widget.tableRows.length; r++) {
            final row = widget.tableRows[r];
            for (int c = 1; c < headers.length; c++) {
              final key = 'col${c + 1}';
              final val = row[key] ?? (row[headers[c]] ?? '');
              _getCellController(r, c).text = val;
            }
          }
        }
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
      if (_isStudentParsingMode) {
        for (int i = 0; i < widget.tableRows.length; i++) {
          final model = widget.tableRows[i]['parsing'] ?? '';
          _getController(i).text = model;
          _rowValidationStatus[i] = true;
          _rowFeedbackMessage[i] = null;
        }
        _activeParsingRowIndex = 0;
      }
      if (_isStudentTableInputMode && widget.tableHeaders != null) {
        final headers = widget.tableHeaders!;
        for (int r = 0; r < widget.tableRows.length; r++) {
          final row = widget.tableRows[r];
          for (int c = 1; c < headers.length; c++) {
            final key = 'col${c + 1}';
            final val = row[key] ?? (row[headers[c]] ?? '');
            _getCellController(r, c).text = val;
          }
        }
      }
    } else {
      _revealedRowIndices = {};
      _activeParsingRowIndex = null;
      _rowValidationStatus.clear();
      _rowFeedbackMessage.clear();
      for (final ctrl in _controllers.values) {
        ctrl.clear();
      }
      for (final ctrl in _cellControllers.values) {
        ctrl.clear();
      }
    }
    _checkValidation();
  }

  void _toggleRow(int index) {
    setState(() {
      if (_revealedRowIndices.contains(index)) {
        if (_isStudentParsingMode) {
          // If already extracted, select it as active parsing target
          _activeParsingRowIndex = index;
          final word = widget.tableRows[index]['word'] ?? '';
          _statusMessage = 'تَمَّ اخْتِيَارُ كَلِمَةِ «$word» لِإِعْرَابِهَا أَدْنَاهُ.';
          _statusIsSuccess = true;
        } else {
          _revealedRowIndices.remove(index);
        }
      } else {
        _revealedRowIndices.add(index);
        final row = widget.tableRows[index];
        final word = row['word'] ?? row['col1'] ?? '';
        if (_isStudentParsingMode) {
          _activeParsingRowIndex = index;
          _statusMessage = 'تَمَّ اسْتِخْرَاجُ «$word»؛ قُمْ الآنَ بِإِعْرَابِهَا فِي اللَّوْحَةِ أَدْنَاهُ.';
        } else {
          _statusMessage = 'تَمَّ إِظْهَارُ تَحْلِيلِ: «$word» فِي الجَدْوَلِ!';
        }
        _statusIsSuccess = true;
      }
    });
    _checkValidation();
  }

  void _toggleAllRows() {
    setState(() {
      if (_revealedRowIndices.length == widget.tableRows.length) {
        _revealedRowIndices.clear();
        _activeParsingRowIndex = null;
        _rowValidationStatus.clear();
        _rowFeedbackMessage.clear();
        for (final c in _controllers.values) {
          c.clear();
        }
        for (final c in _cellControllers.values) {
          c.clear();
        }
        _statusMessage = 'تَمَّ إِخْفَاءُ جَمِيعِ الإِجَابَاتِ.';
        _statusIsSuccess = true;
      } else {
        _revealedRowIndices = Set.from(List.generate(widget.tableRows.length, (i) => i));
        if (_isStudentParsingMode) {
          for (int i = 0; i < widget.tableRows.length; i++) {
            final model = widget.tableRows[i]['parsing'] ?? '';
            _getController(i).text = model;
            _rowValidationStatus[i] = true;
            _rowFeedbackMessage[i] = null;
          }
          _activeParsingRowIndex = 0;
          _statusMessage = 'تَمَّ إِظْهَارُ جَمِيعِ إِجَابَاتِ وَإِعْرَابَاتِ الجَدْوَلِ.';
        } else if (_isStudentTableInputMode && widget.tableHeaders != null) {
          final headers = widget.tableHeaders!;
          for (int r = 0; r < widget.tableRows.length; r++) {
            final row = widget.tableRows[r];
            for (int c = 1; c < headers.length; c++) {
              final key = 'col${c + 1}';
              final val = row[key] ?? (row[headers[c]] ?? '');
              _getCellController(r, c).text = val;
            }
          }
          _statusMessage = 'تَمَّ إِظْهَارُ جَمِيعِ إِجَابَاتِ وَحُلُولِ الجَدْوَلِ.';
        } else {
          _statusMessage = 'تَمَّ إِظْهَارُ جَمِيعِ إِجَابَاتِ وَتَحْلِيلَاتِ الجَدْوَلِ.';
        }
        _statusIsSuccess = true;
      }
    });
    _checkValidation();
  }

  void _checkValidation() {
    if (widget.areAnswersRevealed) {
      widget.onValidationChanged(true);
      return;
    }

    if (_isStudentTableInputMode) {
      final allExtracted = _revealedRowIndices.length == widget.tableRows.length;
      bool allCellsValid = true;
      final colCount = widget.tableHeaders?.length ?? 1;

      for (int r = 0; r < widget.tableRows.length; r++) {
        if (!_revealedRowIndices.contains(r)) {
          allCellsValid = false;
          break;
        }
        for (int c = 1; c < colCount; c++) {
          final text = _getCellController(r, c).text;
          if (!_isCellValid(r, c, text)) {
            allCellsValid = false;
            break;
          }
        }
        if (!allCellsValid) break;
      }
      widget.onValidationChanged(allExtracted && allCellsValid);
    } else if (_isStudentParsingMode) {
      final allExtracted = _revealedRowIndices.length == widget.tableRows.length;
      final allParsed = widget.tableRows.asMap().keys.every(
            (idx) => _rowValidationStatus[idx] == true,
          );
      widget.onValidationChanged(allExtracted && allParsed);
    } else {
      final allRevealed = _revealedRowIndices.length == widget.tableRows.length;
      widget.onValidationChanged(allRevealed);
    }
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
          if (_isStudentParsingMode) {
            _activeParsingRowIndex = unrevealed.first;
            _statusMessage = 'أَحْسَنْتَ! اسْتَخْرَجْتَ: «$cleanWord»؛ قُمْ الآنَ بِإِعْرَابِهِ فِي لَوْحَةِ الإِعْرَابِ أَدْنَاهُ.';
          } else {
            _statusMessage = 'أَحْسَنْتَ! اسْتَخْرَجْتَ: «$cleanWord» بِنَجَاحٍ، وَتَمَّ كَشْفُ السَّطْرِ المُنَاسِبِ فِي الجَدْوَلِ!';
          }
          _statusIsSuccess = true;
        } else {
          if (_isStudentParsingMode) {
            _activeParsingRowIndex = matchingIndices.first;
            _statusMessage = 'هَذِهِ الكَلِمَةُ («$cleanWord») مُسْتَخْرَجَةٌ سَابِقًا. يُمْكِنُكَ إِكْمَالُ إِعْرَابِهَا أَدْنَاهُ.';
          } else {
            _statusMessage = 'هَذِهِ الكَلِمَةُ («$cleanWord») مُسْتَخْرَجَةٌ سَابِقًا فِي الجَدْوَلِ.';
          }
          _statusIsSuccess = true;
        }
      } else {
        _statusMessage = 'كَلِمَةُ «$cleanWord» لَيْسَتْ مِنَ الكَلِمَاتِ المَطْلُوبِ اسْتِخْرَاجُهَا. حَاوِلْ مَرَّةً أُخْرَى!';
        _statusIsSuccess = false;
      }
    });

    _checkValidation();
  }

  void _insertChip(String chipText) {
    if (_activeParsingRowIndex == null) return;
    final ctrl = _getController(_activeParsingRowIndex!);
    final current = ctrl.text.trim();
    if (current.isEmpty) {
      ctrl.text = chipText;
    } else {
      if (current.endsWith('.') || current.endsWith('،')) {
        ctrl.text = '$current $chipText';
      } else {
        ctrl.text = '$current $chipText';
      }
    }
    ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
    setState(() {
      _rowValidationStatus[_activeParsingRowIndex!] = null;
      _rowFeedbackMessage[_activeParsingRowIndex!] = null;
    });
    _checkValidation();
  }

  void _backspace() {
    if (_activeParsingRowIndex == null) return;
    final ctrl = _getController(_activeParsingRowIndex!);
    if (ctrl.text.isEmpty) return;

    final words = ctrl.text.trim().split(RegExp(r'\s+'));
    if (words.isNotEmpty) {
      words.removeLast();
      ctrl.text = words.join(' ');
      ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
      setState(() {
        _rowValidationStatus[_activeParsingRowIndex!] = null;
        _rowFeedbackMessage[_activeParsingRowIndex!] = null;
      });
      _checkValidation();
    }
  }

  void _clearParsing() {
    if (_activeParsingRowIndex == null) return;
    final ctrl = _getController(_activeParsingRowIndex!);
    ctrl.clear();
    setState(() {
      _rowValidationStatus[_activeParsingRowIndex!] = null;
      _rowFeedbackMessage[_activeParsingRowIndex!] = null;
    });
    _checkValidation();
  }

  void _verifyActiveRowParsing() {
    if (_activeParsingRowIndex == null) return;
    final idx = _activeParsingRowIndex!;
    final row = widget.tableRows[idx];
    final word = row['word'] ?? '';
    final ctrl = _getController(idx);
    final input = ctrl.text.trim();
    final modelParsing = row['parsing'] ?? '';

    final checkResult = _evaluateStudentParsing(input, modelParsing, word);
    setState(() {
      _rowValidationStatus[idx] = checkResult.isValid;
      _rowFeedbackMessage[idx] = checkResult.feedback;
      if (checkResult.isValid) {
        _statusMessage = 'أَحْسَنْتَ! إِعْرَابُ «$word» صَحِيحٌ وَتَامٌّ! 🎉';
        _statusIsSuccess = true;
        // Auto-advance to the next extracted row that is not yet validated:
        final nextUnparsed = widget.tableRows.asMap().keys.firstWhere(
              (i) => _revealedRowIndices.contains(i) && _rowValidationStatus[i] != true,
              orElse: () => -1,
            );
        if (nextUnparsed != -1) {
          _activeParsingRowIndex = nextUnparsed;
        }
      } else {
        _statusMessage = checkResult.feedback;
        _statusIsSuccess = false;
      }
    });

    _checkValidation();
  }

  _ParsingEvaluationResult _evaluateStudentParsing(String input, String modelParsing, String word) {
    if (input.trim().isEmpty) {
      return const _ParsingEvaluationResult(
        false,
        'الرَّجَاءُ كِتَابَةُ الإِعْرَابِ أَوِ انْقُرْ عَلَى الأَلْفَاظِ المُنَاسِبَةِ مِنَ القَائِمَةِ لِتَرْكِيبِهِ.',
      );
    }

    final cleanInput = ArabicCliticStemmer.stripDiacritics(input).trim();
    final normInput = ArabicCliticStemmer.normalize(cleanInput);
    final cleanModel = ArabicCliticStemmer.stripDiacritics(modelParsing).trim();
    final normModel = ArabicCliticStemmer.normalize(cleanModel);

    String stripPunct(String s) =>
        s.replaceAll(RegExp(r'[.,؛،:؟!«»]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    if (stripPunct(normInput) == stripPunct(normModel)) {
      return const _ParsingEvaluationResult(true, 'أَحْسَنْتَ! إِعْرَابٌ صَحِيحٌ وَتَامٌّ بِنَجَاحٍ! 🎉');
    }

    // Checking for specific distractor errors:
    if (normInput.contains('مفعول')) {
      return _ParsingEvaluationResult(
        false,
        'تَنْبِيهٌ: الكَلِمَةُ «$word» هِيَ فَاعِلٌ (دَلَّتْ عَلَى مَنْ قَامَ بِالفِعْلِ)، وَلَيْسَتْ مَفْعُولاً بِهِ!',
      );
    }

    if (normInput.contains('فعل ماض') || (normInput.contains('فعل') && !normInput.contains('فاعل'))) {
      return _ParsingEvaluationResult(
        false,
        'تَنْبِيهٌ: الكَلِمَةُ «$word» اسْمٌ وَقَعَ فَاعِلاً، وَلَيْسَتْ فِعْلاً مَاضِيًا!',
      );
    }

    if (normInput.contains('منصوب') || normInput.contains('مجزوم')) {
      return const _ParsingEvaluationResult(
        false,
        'تَنْبِيهٌ: الفَاعِلُ يَكُونُ دَائِمًا «مَرْفُوعًا»، وَلَا يَكُونُ مَنْصُوبًا وَلَا مَجْزُومًا!',
      );
    }

    if (normInput.contains('فتحة') ||
        normInput.contains('كسرة') ||
        normInput.contains('سكون') ||
        normInput.contains('نصب') ||
        normInput.contains('جزم')) {
      return const _ParsingEvaluationResult(
        false,
        'تَنْبِيهٌ: عَلَامَةُ رَفْعِ الفَاعِلِ هِيَ الضَّمَّةُ، وَلَيْسَتِ الفَتْحَةَ أَوِ الكَسْرَةَ أَوِ السُّكُونَ.',
      );
    }

    if (normModel.contains('مقدرة') && !normInput.contains('مقدرة')) {
      return _ParsingEvaluationResult(
        false,
        'تَنْبِيهٌ: «$word» اسْمٌ مَنْقُوصٌ يَنْتَهِي بِيَاءٍ، فَتَكُونُ الضَّمَّةُ «مُقَدَّرَةً عَلَى اليَاءِ مَنَعَ مِنْ ظُهُورِهَا الثِّقَلُ» وَلَيْسَتْ ظَاهِرَةً!',
      );
    }

    if (!normModel.contains('مقدرة') && normInput.contains('مقدرة')) {
      return const _ParsingEvaluationResult(
        false,
        'تَنْبِيهٌ: الضَّمَّةُ هُنَا «ظَاهِرَةٌ عَلَى آخِرِهِ» لأَنَّ آخِرَ الكَلِمَةِ حَرْفٌ صَحِيحٌ تَظْهَرُ عَلَيْهِ الحَرَكَةُ.',
      );
    }

    if (!normInput.contains('فاعل')) {
      return const _ParsingEvaluationResult(
        false,
        'تَنْبِيهٌ: يَجِبُ تَحْدِيدُ المَوْقِعِ الإِعْرَابِيِّ لِلْكَلِمَةِ أَنَّهَا (فَاعِلٌ).',
      );
    }

    if (!normInput.contains('مرفوع')) {
      return const _ParsingEvaluationResult(
        false,
        'تَنْبِيهٌ: يَجِبُ تَحْدِيدُ الحَالَةِ الإِعْرَابِيَّةِ لِلْفَاعِلِ أَنَّهُ (مَرْفُوعٌ).',
      );
    }

    if (!normInput.contains('ضمة')) {
      return const _ParsingEvaluationResult(
        false,
        'تَنْبِيهٌ: يَجِبُ تَحْدِيدُ عَلَامَةِ الرَّفْعِ المُنَاسِبَةِ (الضَّمَّةُ...).',
      );
    }

    // Syntactic match:
    final hasFaiel = normInput.contains('فاعل');
    final hasMarfoo = normInput.contains('مرفوع');
    final hasDamma = normInput.contains('ضمة');

    if (hasFaiel && hasMarfoo && hasDamma) {
      if (normModel.contains('مقدرة')) {
        if (normInput.contains('مقدرة') &&
            (normInput.contains('ياء') || normInput.contains('الثقل') || normInput.contains('ثقل'))) {
          return const _ParsingEvaluationResult(true, 'أَحْسَنْتَ! إِعْرَابٌ صَحِيحٌ وَتَامٌّ بِنَجَاحٍ! 🎉');
        }
      } else {
        return const _ParsingEvaluationResult(true, 'أَحْسَنْتَ! إِعْرَابٌ صَحِيحٌ وَتَامٌّ بِنَجَاحٍ! 🎉');
      }
    }

    return const _ParsingEvaluationResult(
      false,
      'حَاوِلْ مَرَّةً أُخْرَى! رَتِّبْ أَلْفَاظَ الإِعْرَابِ: (المَوْقِعُ + الحَالَةُ + عَلَامَةُ الرَّفْعِ + مَوْضِعُهَا).',
    );
  }

  @override
  Widget build(BuildContext context) {
    final allRevealed = _revealedRowIndices.length == widget.tableRows.length;
    final hasCustomHeaders = widget.tableHeaders != null && widget.tableHeaders!.isNotEmpty;
    final allParsedCount = widget.tableRows.asMap().keys.where((i) => _rowValidationStatus[i] == true).length;

    // Ensure active row has a valid target if extracted rows exist
    if (_isStudentParsingMode && _revealedRowIndices.isNotEmpty) {
      if (_activeParsingRowIndex == null || !_revealedRowIndices.contains(_activeParsingRowIndex)) {
        _activeParsingRowIndex = _revealedRowIndices.first;
      }
    }

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
              // Header title + counter badges
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
                  Wrap(
                    spacing: 8,
                    children: [
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
                      if (_isStudentParsingMode)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: allParsedCount == widget.tableRows.length
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'المُعْرَبُ: $allParsedCount / ${widget.tableRows.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
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
                        const SizedBox(width: 44),
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

                    return _buildSubjectParsingRow(idx, word, verb, parsing, isRevealed);
                  }),
              ],
            ),
          ),
        ),

        // 4. Interactive Student Parsing Builder Panel (In student parsing mode)
        if (_isStudentParsingMode) ...[
          const SizedBox(height: 24),
          _buildStudentParsingBuilder(),
        ],
        if (_isStudentTableInputMode) ...[
          const SizedBox(height: 20),
          _buildStudentTableHelperChips(),
        ],
      ],
    );
  }

  /// Builds row in standard 2-column layout with student-parsing support.
  Widget _buildSubjectParsingRow(int idx, String word, String verb, String parsing, bool isRevealed) {
    final isValidated = _rowValidationStatus[idx] == true;
    final isActive = _activeParsingRowIndex == idx;
    final studentText = _getController(idx).text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFEFF6FF)
            : (idx.isEven ? Colors.white : const Color(0xFFF8FAFC)),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
          right: isActive ? const BorderSide(color: Color(0xFF0284C7), width: 4) : BorderSide.none,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Col 1: Word + Associated Verb
          SizedBox(
            width: 220,
            child: isRevealed
                ? Wrap(
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
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              '؟ (فَاعِلُ ${idx + 1})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(width: 14),

          // Col 2: Detailed Parsing / Student Parsing Status
          Expanded(
            child: isRevealed
                ? (_isStudentParsingMode
                    ? _buildStudentParsingCell(idx, word, parsing, isValidated, isActive, studentText)
                    : _buildDefaultRevealedParsingCell(idx, parsing))
                : InkWell(
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
                            'انْقُرْ عَلَى الفَاعِلِ فِي النَّصِّ لِاسْتِخْرَاجِهِ (أَوْ انْقُرْ هُنَا لِلْكَشْفِ)',
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
        ],
      ),
    );
  }

  Widget _buildStudentParsingCell(
      int idx, String word, String modelParsing, bool isValidated, bool isActive, String studentText) {
    if (widget.areAnswersRevealed) {
      return Container(
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
                modelParsing,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15803D),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isValidated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                studentText.isNotEmpty ? studentText : modelParsing,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15803D),
                  height: 1.4,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF0284C7)),
              onPressed: () => setState(() => _activeParsingRowIndex = idx),
              tooltip: 'تَعْدِيلُ الإِعْرَابِ',
            ),
          ],
        ),
      );
    }

    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF60A5FA), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: Color(0xFF0284C7), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                studentText.isNotEmpty ? studentText : 'قَيْدُ الإِعْرَابِ فِي اللَّوْحَةِ أَدْنَاهُ ✍️',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: studentText.isNotEmpty ? const Color(0xFF1E3A8A) : const Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Extracted but neither active nor validated
    return InkWell(
      onTap: () => setState(() => _activeParsingRowIndex = idx),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.create_rounded, color: Color(0xFFD97706), size: 18),
            const SizedBox(width: 8),
            Text(
              studentText.isNotEmpty ? '«$studentText» (انْقُرْ لِلْمُتَابَعَةِ)' : 'انْقُرْ هُنَا لِإِعْرَابِ «$word» ✍️',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB45309),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultRevealedParsingCell(int idx, String parsing) {
    return Container(
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
    );
  }

  /// Builds the dedicated interactive parsing builder with chips & distractors.
  Widget _buildStudentParsingBuilder() {
    if (_revealedRowIndices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF86EFAC), width: 1.8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.touch_app_rounded, color: Color(0xFF16A34A), size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'اقْرَأِ النَّصَّ أَعْلَاهُ وَانْقُرْ عَلَى الفَاعِلِ لِاسْتِخْرَاجِهِ، ثُمَّ سَتَفْتَحُ لَكَ لَوْحَةُ بِنَاءِ الإِعْرَابِ هُنَا بِاسْتِعْمَالِ بَنْكِ الأَلْفَاظِ!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15803D),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final activeIdx = _activeParsingRowIndex ?? _revealedRowIndices.first;
    final row = widget.tableRows[activeIdx];
    final activeWord = row['word'] ?? '';
    final controller = _getController(activeIdx);
    final isValidated = _rowValidationStatus[activeIdx] == true;
    final isErrored = _rowValidationStatus[activeIdx] == false;
    final feedbackMsg = _rowFeedbackMessage[activeIdx];
    final chips = widget.helperChips ?? _defaultSubjectParsingChips;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isValidated
              ? const Color(0xFF16A34A)
              : (isErrored ? const Color(0xFFEF4444) : const Color(0xFF0284C7)),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header with active word and extracted word selector tabs
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isValidated ? const Color(0xFF16A34A) : const Color(0xFF0284C7)).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isValidated ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                  color: isValidated ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                  size: 26,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'لَوْحَةُ بِنَاءِ إِعْرَابِ: «$activeWord»',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: isValidated ? const Color(0xFF15803D) : AppTheme.primaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isValidated
                      ? const Color(0xFFDCFCE7)
                      : (isErrored ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isValidated
                        ? const Color(0xFF86EFAC)
                        : (isErrored ? const Color(0xFFFCA5A5) : const Color(0xFFBAE6FD)),
                  ),
                ),
                child: Text(
                  isValidated
                      ? 'مُعْرَبٌ صَحِيحًا ✓'
                      : (isErrored ? 'يَحْتَاجُ تَصْحِيحًا ⚠️' : 'قَيْدُ الإِنْجَازِ ✍️'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isValidated
                        ? const Color(0xFF15803D)
                        : (isErrored ? const Color(0xFFB91C1C) : const Color(0xFF0369A1)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Extracted Words Switcher Tabs
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: widget.tableRows.asMap().entries.where((e) => _revealedRowIndices.contains(e.key)).map((e) {
              final idx = e.key;
              final word = e.value['word'] ?? '';
              final isCurrent = idx == activeIdx;
              final isWordValid = _rowValidationStatus[idx] == true;

              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(word, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(width: 4),
                    Icon(
                      isWordValid ? Icons.check_circle_rounded : Icons.edit_rounded,
                      size: 14,
                      color: isWordValid ? const Color(0xFF16A34A) : Colors.grey,
                    ),
                  ],
                ),
                selected: isCurrent,
                selectedColor: const Color(0xFFBAE6FD),
                backgroundColor: isWordValid ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                side: BorderSide(
                  color: isCurrent
                      ? const Color(0xFF0284C7)
                      : (isWordValid ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1)),
                  width: isCurrent ? 2 : 1,
                ),
                onSelected: (_) => setState(() => _activeParsingRowIndex = idx),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // 2. Parsing Text Input Display
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isValidated
                    ? const Color(0xFF86EFAC)
                    : (isErrored ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1)),
                width: 1.8,
              ),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                height: 1.6,
              ),
              maxLines: 2,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
                hintText: 'انْقُرْ عَلَى أَلْفَاظِ الإِعْرَابِ أَدْنَاهُ لِتَرْكِيبِ الإِعْرَابِ التَّامِّ، أَوْ اكْتُبْ مُبَاشَرَةً...',
                hintStyle: TextStyle(fontSize: 15, color: Color(0xFF94A3B8)),
              ),
              onChanged: (_) {
                setState(() {
                  _rowValidationStatus[activeIdx] = null;
                  _rowFeedbackMessage[activeIdx] = null;
                });
                _checkValidation();
              },
            ),
          ),

          const SizedBox(height: 12),

          // 3. Action Toolbar (Verify, Backspace, Clear)
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _verifyActiveRowParsing,
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text(
                  'تَحَقَّقْ مِنَ الإِعْرَابِ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _backspace,
                icon: const Icon(Icons.backspace_rounded, size: 18),
                label: const Text(
                  'حَذْفُ كَلِمَةٍ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD97706),
                  side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _clearParsing,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text(
                  'مَسْحُ الكُلِّ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          // 4. Targeted Row Feedback Alert (if checked)
          if (feedbackMsg != null) ...[
            const SizedBox(height: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isValidated ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isValidated ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isValidated ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: isValidated ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feedbackMsg,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isValidated ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // 5. Grammatical Parts & Distractors Palette
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: const [
                    Icon(Icons.category_rounded, size: 20, color: Color(0xFF0369A1)),
                    SizedBox(width: 8),
                    Text(
                      'قَائِمَةُ أَلْفَاظِ وَأَجْزَاءِ الإِعْرَابِ (اخْتَرِ الأَجْزَاءَ المُنَاسِبَةَ لِإِكْمَالِ الإِعْرَابِ):',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chips.map((chip) {
                    return ActionChip(
                      label: Text(
                        chip,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      backgroundColor: Colors.white,
                      elevation: 1,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      onPressed: () => _insertChip(chip),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
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

    if (_isStudentTableInputMode) {
      final isExtracted = isRevealed || _revealedRowIndices.contains(idx) || widget.areAnswersRevealed;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: idx.isEven ? Colors.white : const Color(0xFFF8FAFC),
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Column 1: The extracted word / target
            Expanded(
              flex: 2,
              child: isExtracted
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                      ),
                      child: Text(
                        word,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    )
                  : InkWell(
                      onTap: () => _toggleRow(idx),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              '؟ (عُنْصُرُ ${idx + 1})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 8),

            // Columns 2 to N: Student input fields!
            for (int i = 1; i < headers.length; i++) ...[
              Expanded(
                flex: headers.length > 3 ? 2 : 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Builder(
                    builder: (context) {
                      if (widget.areAnswersRevealed) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            cellValues[i],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        );
                      }

                      final cellCtrl = _getCellController(idx, i);
                      final cellText = cellCtrl.text.trim();
                      final isValid = isExtracted && _isCellValid(idx, i, cellText);
                      final cellKey = '${idx}_$i';
                      final isFocused = _focusedCellKey == cellKey;

                      return TextFormField(
                        controller: cellCtrl,
                        enabled: isExtracted,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isValid ? const Color(0xFF15803D) : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: isValid
                              ? const Color(0xFFDCFCE7)
                              : isExtracted
                                  ? (isFocused ? const Color(0xFFF0F9FF) : Colors.white)
                                  : const Color(0xFFF8FAFC),
                          hintText: isExtracted ? '«اكْتُبْ هُنَا...»' : '—',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isValid
                                  ? const Color(0xFF16A34A)
                                  : isFocused
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFFCBD5E1),
                              width: isValid || isFocused ? 1.8 : 1.0,
                            ),
                          ),
                          suffixIcon: isValid
                              ? const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A))
                              : null,
                        ),
                        onTap: () {
                          setState(() {
                            _focusedCellKey = cellKey;
                            _activeParsingRowIndex = idx;
                          });
                        },
                        onChanged: (_) {
                          setState(() {});
                          _checkValidation();
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
            IconButton(
              icon: Icon(
                isExtracted ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18,
                color: Colors.grey,
              ),
              onPressed: () => _toggleRow(idx),
              tooltip: isExtracted ? 'إِخْفَاءٌ' : 'إِظْهَارٌ',
            ),
          ],
        ),
      );
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

  Widget _buildStudentTableHelperChips() {
    final chips = widget.helperChips ??
        const [
          'مَاضٍ',
          'مُضَارِعٌ',
          'مَبْنِيٌّ عَلَى الفَتْحِ',
          'مَرْفُوعٌ بِالضَّمَّةِ',
          'الضَّمَّةُ الظَّاهِرَةُ',
          'الأَلِفُ (مُثَنًّى)',
          'الوَاوُ (جَمْعُ مُذَكَّرٍ سَالِمٌ)',
        ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.touch_app_rounded, color: Color(0xFF0284C7), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'لَوْحَةُ الكَلِمَاتِ وَالعَلَامَاتِ المُسَاعِدَةِ: انْقُرْ عَلَى الخَانَةِ فِي الجَدْوَلِ، ثُمَّ انْقُرْ عَلَى الكَلِمَةِ هُنَا لِوَضْعِهَا مُبَاشَرَةً:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: chips.map((chip) {
              return ActionChip(
                label: Text(
                  chip,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF93C5FD)),
                elevation: 1,
                onPressed: () {
                  if (_focusedCellKey != null) {
                    _cellControllers[_focusedCellKey!]?.text = chip;
                    setState(() {});
                    _checkValidation();
                  } else {
                    bool inserted = false;
                    final colCount = widget.tableHeaders?.length ?? 1;
                    for (final r in _revealedRowIndices) {
                      for (int c = 1; c < colCount; c++) {
                        final ctrl = _getCellController(r, c);
                        if (ctrl.text.trim().isEmpty) {
                          ctrl.text = chip;
                          _focusedCellKey = '${r}_$c';
                          inserted = true;
                          break;
                        }
                      }
                      if (inserted) break;
                    }
                    if (!inserted && _revealedRowIndices.isNotEmpty) {
                      final r = _revealedRowIndices.first;
                      _getCellController(r, 1).text = chip;
                    }
                    setState(() {});
                    _checkValidation();
                  }
                },
              );
            }).toList(),
          ),
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
