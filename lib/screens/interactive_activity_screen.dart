import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/categorization_board_widget.dart';
import '../widgets/celebration_dialog.dart';
import '../widgets/classroom_timer_widget.dart';
import '../widgets/image_matching_widget.dart';
import '../widgets/multi_select_sentences_widget.dart';
import '../widgets/multi_sentence_choice_widget.dart';
import '../widgets/multi_sentence_fill_widget.dart';
import '../widgets/multi_sentence_order_widget.dart';
import '../widgets/open_sentence_fill_widget.dart';
import '../widgets/sentence_ordering_widget.dart';
import '../widgets/sentence_parts_analysis_widget.dart';
import '../widgets/sentence_target_tap_widget.dart';
import '../widgets/teacher_toolbar_widget.dart';
import '../widgets/text_extraction_table_widget.dart';
import '../widgets/text_word_extraction_widget.dart';
import '../widgets/written_parsing_widget.dart';

/// [05] النشاط التفاعلي الشامل (Comprehensive Interactive Activity Screen)
/// Supports 10 activity engines:
/// 1. Multiple Choice with large whiteboard letters (أ، ب، ج)
/// 2. Drag & Drop fill in the blanks
/// 3. Categorization Boards (2-column & 3-column)
/// 4. Sentence Word Ordering
/// 5. Image & Verb Matching
/// 6. Multi-sentence selection
/// 7. Multi-sentence verb/subject placement
/// 8. Multi-sentence choice per sentence
/// 9. Written syntactic parsing with auto-correction
/// 10. Open-ended sentence completion and text extraction table
/// Includes Classroom Challenge Timer and Teacher Mode quick-controls.
class InteractiveActivityScreen extends StatefulWidget {
  final List<ActivityModel> activities;
  final String lessonTitle;
  final String? lessonIdToComplete;
  final ProgressService progressService;

  const InteractiveActivityScreen({
    super.key,
    required this.activities,
    required this.lessonTitle,
    this.lessonIdToComplete,
    required this.progressService,
  });

  @override
  State<InteractiveActivityScreen> createState() => _InteractiveActivityScreenState();
}

class _InteractiveActivityScreenState extends State<InteractiveActivityScreen> {
  int _currentIndex = 0;
  int _attemptKey = 0;
  int? _selectedOptionIndex;
  bool _submitted = false;
  bool _areAnswersRevealed = false;

  // State flags for rich interaction engines
  bool _categorizationValid = false;
  bool _sentenceOrderValid = false;
  bool _imageMatchValid = false;
  bool _multiSelectValid = false;
  bool _multiFillValid = false;
  bool _multiOrderValid = false;
  bool _multiChoiceValid = false;
  bool _writtenParsingValid = false;
  bool _openFillValid = false;
  bool _extractionTableValid = false;
  bool _targetTapValid = false;
  bool _partsAnalysisValid = false;
  bool _textWordExtractionValid = false;

  ActivityModel get _currentActivity => widget.activities[_currentIndex];

  @override
  void initState() {
    super.initState();
    _areAnswersRevealed = widget.progressService.revealAnswersDirectly;
  }

  void _submitAnswer() {
    bool isCorrect = false;

    switch (_currentActivity.type) {
      case ActivityType.categorizationTwoCols:
      case ActivityType.categorizationThreeCols:
        isCorrect = _categorizationValid;
        break;
      case ActivityType.sentenceOrdering:
        isCorrect = _sentenceOrderValid;
        break;
      case ActivityType.imageMatching:
        isCorrect = _imageMatchValid;
        break;
      case ActivityType.multiSelect:
        isCorrect = _multiSelectValid;
        break;
      case ActivityType.multiSentenceFill:
        isCorrect = _multiFillValid;
        break;
      case ActivityType.multiSentenceOrder:
        isCorrect = _multiOrderValid;
        break;
      case ActivityType.sentenceMultiChoice:
        isCorrect = _multiChoiceValid;
        break;
      case ActivityType.writtenParsing:
        isCorrect = _writtenParsingValid;
        break;
      case ActivityType.openSentenceFill:
        isCorrect = _openFillValid;
        break;
      case ActivityType.textExtractionTable:
        isCorrect = _extractionTableValid;
        break;
      case ActivityType.sentenceTargetTap:
        isCorrect = _targetTapValid;
        break;
      case ActivityType.sentencePartsAnalysis:
        isCorrect = _partsAnalysisValid;
        break;
      case ActivityType.textWordExtraction:
        isCorrect = _textWordExtractionValid;
        break;
      case ActivityType.multipleChoice:
      case ActivityType.dragDropFillBlank:
      case ActivityType.selectVerb:
      case ActivityType.selectSubject:
      case ActivityType.selectObject:
      case ActivityType.classifyVerbTense:
      default:
        if (_selectedOptionIndex == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الرجاء اختيار إجابة من اللوحة أولاً!'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        isCorrect = _selectedOptionIndex == _currentActivity.correctIndex;
        break;
    }

    setState(() {
      _submitted = true;
    });

    // Show [06] التغذية الراجعة (FeedbackDialog) with retry or continue options
    FeedbackDialog.show(
      context: context,
      isCorrect: isCorrect,
      title: isCorrect ? 'أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ' : 'إِجَابَةٌ غَيْرُ صَحِيحَةٍ - حَاوِلْ ثَانِيَةً',
      message: isCorrect ? _currentActivity.correctFeedback : _currentActivity.incorrectFeedback,
      ruleSummary: _currentActivity.ruleSummary,
      onRetry: () => _retryCurrentActivity(),
      onContinue: () => _proceedToNextActivity(),
    );
  }

  void _retryCurrentActivity() {
    setState(() {
      _attemptKey++;
      _selectedOptionIndex = null;
      _submitted = false;
      _categorizationValid = false;
      _sentenceOrderValid = false;
      _imageMatchValid = false;
      _multiSelectValid = false;
      _multiFillValid = false;
      _multiOrderValid = false;
      _multiChoiceValid = false;
      _writtenParsingValid = false;
      _openFillValid = false;
      _extractionTableValid = false;
      _targetTapValid = false;
      _partsAnalysisValid = false;
      _textWordExtractionValid = false;
      _areAnswersRevealed = false;
    });
  }

  void _switchActivity(int newIndex) {
    if (newIndex < 0 || newIndex >= widget.activities.length) return;
    setState(() {
      _currentIndex = newIndex;
      _attemptKey = 0;
      _selectedOptionIndex = null;
      _submitted = false;
      _categorizationValid = false;
      _sentenceOrderValid = false;
      _imageMatchValid = false;
      _multiSelectValid = false;
      _multiFillValid = false;
      _multiOrderValid = false;
      _multiChoiceValid = false;
      _writtenParsingValid = false;
      _openFillValid = false;
      _extractionTableValid = false;
      _targetTapValid = false;
      _partsAnalysisValid = false;
      _textWordExtractionValid = false;
      _areAnswersRevealed = false;
    });
  }

  void _proceedToNextActivity() {
    if (_currentIndex < widget.activities.length - 1) {
      _switchActivity(_currentIndex + 1);
    } else {
      // Completed all activities for this set
      if (widget.lessonIdToComplete != null) {
        widget.progressService.markLessonCompleted(widget.lessonIdToComplete!);
      }
      _showCompletionAlert();
    }
  }

  void _showCompletionAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 40),
              SizedBox(width: 12),
              Text('تَمَّ إِنْجَازُ الأَنْشِطَةِ بِنَجَاحٍ!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/trophy_success.jpg',
                height: 140,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.emoji_events_rounded, size: 90, color: AppTheme.accentAmber),
              ),
              const SizedBox(height: 18),
              const Text(
                'مبارك لك ولتلاميذك! لقد تم حل جميع الأنشطة بنجاح وإتقان.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.6),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('العَوْدَةُ لِقَائِمَةِ الدُّرُوسِ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Font scaling is applied globally via MediaQuery.textScaler in main.dart
    const scale = 1.0;
    final total = widget.activities.length;
    final progressVal = (_currentIndex + 1) / total;

    return AppScaffold(
      title: 'الأَنْشِطَةُ التَّفَاعُلِيَّةُ: ${widget.lessonTitle}',
      progressService: widget.progressService,
      actions: [
        TeacherHeaderActions(
          progressService: widget.progressService,
          areAnswersRevealed: _areAnswersRevealed,
          onToggleAnswers: () {
            setState(() {
              _areAnswersRevealed = !_areAnswersRevealed;
              if (_areAnswersRevealed && _currentActivity.correctIndex >= 0) {
                _selectedOptionIndex = _currentActivity.correctIndex;
              }
            });
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Activity Progress & Classroom Timer Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'النَّشَاطُ ${_currentIndex + 1} مِنْ $total',
                            style: TextStyle(
                              fontSize: 20 * scale,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                          Text(
                            _currentActivity.title,
                            style: TextStyle(
                              fontSize: 18 * scale,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progressVal,
                          minHeight: 12,
                          backgroundColor: const Color(0xFFCBD5E1),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.progressService.timerDuration > 0) ...[
                  const SizedBox(width: 20),
                  ClassroomTimerWidget(
                    key: ValueKey('${_currentIndex}_$_attemptKey'),
                    initialSeconds: widget.progressService.timerDuration,
                    onTimerFinished: () {
                      if (!_submitted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('انتهى وقت التحدي الصفي!')),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),

            // Free Activity Navigation Tabs Bar (شريط التبديل الحر بين الأنشطة)
            if (total > 1) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                child: Row(
                  children: [
                    // Previous Activity Button
                    IconButton(
                      tooltip: 'النَّشَاطُ السَّابِقُ',
                      onPressed: _currentIndex > 0
                          ? () => _switchActivity(_currentIndex - 1)
                          : null,
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: _currentIndex > 0 ? AppTheme.primaryLight : const Color(0xFFF1F5F9),
                        foregroundColor: _currentIndex > 0 ? AppTheme.primaryTeal : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Scrollable Activity Selection Chips
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: widget.activities.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final act = entry.value;
                            final isSelected = _currentIndex == idx;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                key: Key('activity_tab_$idx'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected && _currentIndex != idx) {
                                    _switchActivity(idx);
                                  }
                                },
                                selectedColor: AppTheme.primaryTeal,
                                backgroundColor: const Color(0xFFF8FAFC),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isSelected ? AppTheme.primaryTeal : const Color(0xFFCBD5E1),
                                    width: isSelected ? 2.0 : 1.2,
                                  ),
                                ),
                                labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: isSelected ? Colors.white : AppTheme.primaryTeal.withValues(alpha: 0.15),
                                      child: Text(
                                        '${idx + 1}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: isSelected ? AppTheme.primaryTeal : AppTheme.primaryDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      act.title.isNotEmpty ? act.title : 'النشاط ${idx + 1}',
                                      style: TextStyle(
                                        fontSize: 16 * scale,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Next Activity Button
                    IconButton(
                      tooltip: 'النَّشَاطُ التَّالِي',
                      onPressed: _currentIndex < total - 1
                          ? () => _switchActivity(_currentIndex + 1)
                          : null,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: _currentIndex < total - 1 ? AppTheme.primaryLight : const Color(0xFFF1F5F9),
                        foregroundColor: _currentIndex < total - 1 ? AppTheme.primaryTeal : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Prompt Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.help_outline_rounded, color: AppTheme.accentOrange, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _currentActivity.prompt,
                          style: TextStyle(
                            fontSize: 22 * scale,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_currentActivity.sentence.isNotEmpty &&
                      _currentActivity.type != ActivityType.categorizationTwoCols &&
                      _currentActivity.type != ActivityType.categorizationThreeCols &&
                      _currentActivity.type != ActivityType.multiSelect &&
                      _currentActivity.type != ActivityType.multiSentenceFill &&
                      _currentActivity.type != ActivityType.multiSentenceOrder &&
                      _currentActivity.type != ActivityType.sentenceMultiChoice &&
                      _currentActivity.type != ActivityType.writtenParsing &&
                      _currentActivity.type != ActivityType.openSentenceFill &&
                      _currentActivity.type != ActivityType.textExtractionTable &&
                      _currentActivity.type != ActivityType.sentenceTargetTap &&
                      _currentActivity.type != ActivityType.sentencePartsAnalysis &&
                      _currentActivity.type != ActivityType.textWordExtraction) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryTeal, width: 2),
                      ),
                      child: Text(
                        _currentActivity.sentence,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26 * scale,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Interactive Interaction Engine
            _buildInteractionEngine(scale),

            const SizedBox(height: 32),

            // Bottom Action Bar: Navigation and Verification
            Row(
              children: [
                // Previous Activity Action (if available)
                if (total > 1 && _currentIndex > 0) ...[
                  SizedBox(
                    height: 72,
                    child: OutlinedButton.icon(
                      onPressed: () => _switchActivity(_currentIndex - 1),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryTeal,
                        side: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 22),
                      label: Text(
                        'السَّابِقُ',
                        style: TextStyle(fontSize: 18 * scale, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],

                // Main Submit Button
                Expanded(
                  child: SizedBox(
                    height: 72,
                    child: ElevatedButton.icon(
                      onPressed: _submitAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 36),
                      label: Text(
                        'تَحَقَّقْ مِنَ الإِجَابَةِ فِي السَّبُّورَةِ',
                        style: TextStyle(fontSize: 22 * scale, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),

                // Next Activity Action (if available)
                if (total > 1 && _currentIndex < total - 1) ...[
                  const SizedBox(width: 14),
                  SizedBox(
                    height: 72,
                    child: OutlinedButton.icon(
                      onPressed: () => _switchActivity(_currentIndex + 1),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryTeal,
                        side: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                      icon: Text(
                        'التَّالِي',
                        style: TextStyle(fontSize: 18 * scale, fontWeight: FontWeight.bold),
                      ),
                      label: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionEngine(double scale) {
    switch (_currentActivity.type) {
      case ActivityType.multiSelect:
        return MultiSelectSentencesWidget(
          key: ValueKey('${_currentIndex}_$_attemptKey'),
          sentences: _currentActivity.sentenceItems ?? _currentActivity.options,
          correctIndices: _currentActivity.correctIndices ?? [_currentActivity.correctIndex],
          contextParagraph: _currentActivity.contextParagraph,
          areAnswersRevealed: _areAnswersRevealed,
          onValidationChanged: (isValid) {
            _multiSelectValid = isValid;
          },
        );

      case ActivityType.multiSentenceFill:
        return MultiSentenceFillWidget(
          key: ValueKey('${_currentIndex}_$_attemptKey'),
          sentences: _currentActivity.sentenceItems ?? [_currentActivity.sentence],
          availableWords: _currentActivity.availableWords ?? _currentActivity.options,
          solutions: _currentActivity.sentenceSolutions ?? {
            _currentActivity.sentence: _currentActivity.correctAnswer,
          },
          areAnswersRevealed: _areAnswersRevealed,
          onValidationChanged: (isValid) {
            _multiFillValid = isValid;
          },
        );

      case ActivityType.multiSentenceOrder:
        final sentenceItems = _currentActivity.sentenceItems ?? [_currentActivity.sentence];
        return MultiSentenceOrderWidget(
          key: ValueKey('${_currentIndex}_$_attemptKey'),
          sentenceItems: sentenceItems,
          sentenceWordsMap: _currentActivity.sentenceWordsMap ?? {
            for (var item in sentenceItems)
              item: _currentActivity.availableWords ?? _currentActivity.options
          },
          targetSequences: _currentActivity.sentenceOrderedMap ?? {
            for (var item in sentenceItems)
              item: _currentActivity.orderedWords ?? _currentActivity.options
          },
          areAnswersRevealed: _areAnswersRevealed,
          onValidationChanged: (isValid) {
            _multiOrderValid = isValid;
          },
        );

      case ActivityType.categorizationTwoCols:
      case ActivityType.categorizationThreeCols:
        return CategorizationBoardWidget(
          key: ValueKey('${_currentIndex}_$_attemptKey'),
          categories: _currentActivity.categories ?? ['الفئة الأولى', 'الفئة الثانية'],
          correctMapping: _currentActivity.categorizedItems ?? {},
          availableWords: _currentActivity.availableWords ?? _currentActivity.options,
          onValidationChanged: (isValid) {
            _categorizationValid = isValid;
          },
        );

      case ActivityType.sentenceOrdering:
        return SentenceOrderingWidget(
          key: ValueKey('${_currentIndex}_$_attemptKey'),
          initialWords: _currentActivity.availableWords ?? _currentActivity.options,
          targetSequence: _currentActivity.orderedWords ?? _currentActivity.options,
          onValidationChanged: (isValid) {
            _sentenceOrderValid = isValid;
          },
        );

      case ActivityType.imageMatching:
        return ImageMatchingWidget(
          key: ValueKey('${_currentIndex}_$_attemptKey'),
          pairs: _currentActivity.imagePairs ?? {},
          onValidationChanged: (isValid) {
            _imageMatchValid = isValid;
          },
        );

      case ActivityType.sentenceMultiChoice:
        return MultiSentenceChoiceWidget(
          key: ValueKey('${_currentIndex}_$_attemptKey'),
          sentences: _currentActivity.sentenceItems ?? [_currentActivity.sentence],
          optionsPerSentence: _currentActivity.sentenceChoiceOptions ?? {},
          solutions: _currentActivity.sentenceSolutions ?? {},
          areAnswersRevealed: _areAnswersRevealed,
          onValidationChanged: (isValid) {
            _multiChoiceValid = isValid;
          },
        );

      case ActivityType.writtenParsing:
        return WrittenParsingWidget(
          key: ValueKey('${_currentIndex}_$_attemptKey'),
          sentences: _currentActivity.sentenceItems ?? [_currentActivity.sentence],
          coloredWords: _currentActivity.coloredWordsMap ?? {},
          modelParsings: _currentActivity.sentenceSolutions ?? {},
          helperChips: _currentActivity.helperChips,
          areAnswersRevealed: _areAnswersRevealed,
          onValidationChanged: (isValid) {
            _writtenParsingValid = isValid;
          },
        );

      case ActivityType.openSentenceFill:
        return OpenSentenceFillWidget(
          key: ValueKey('${_currentIndex}_$_attemptKey'),
          sentences: _currentActivity.sentenceItems ?? [_currentActivity.sentence],
          acceptableAnswers: _currentActivity.acceptableAnswersMap ?? {},
          defaultModelAnswers: _currentActivity.sentenceSolutions ?? {},
          showSuggestions: _currentActivity.showSuggestions,
          areAnswersRevealed: _areAnswersRevealed,
          onValidationChanged: (isValid) {
            _openFillValid = isValid;
          },
        );

      case ActivityType.textExtractionTable:
        return TextExtractionTableWidget(
          key: ValueKey('${_currentIndex}_$_attemptKey'),
          passage: _currentActivity.contextParagraph ?? _currentActivity.sentence,
          tableRows: _currentActivity.tableRows ?? [],
          tableHeaders: _currentActivity.tableHeaders,
          tableTitle: _currentActivity.tableTitle,
          passageTitle: _currentActivity.passageTitle,
          areAnswersRevealed: _areAnswersRevealed,
          onValidationChanged: (isValid) {
            _extractionTableValid = isValid;
          },
        );

      case ActivityType.sentenceTargetTap:
        return SentenceTargetTapWidget(
          key: ValueKey('${_currentIndex}_$_attemptKey'),
          sentences: _currentActivity.sentenceItems ?? [_currentActivity.sentence],
          solutions: _currentActivity.sentenceSolutions ?? {},
          instructionHeader: _currentActivity.instructionHeader,
          errorHintMessage: _currentActivity.errorHintMessage,
          allowNoneOption: _currentActivity.allowNoneOption,
          noneOptionText: _currentActivity.noneOptionText,
          areAnswersRevealed: _areAnswersRevealed,
          onValidationChanged: (isValid) {
            _targetTapValid = isValid;
          },
        );

      case ActivityType.sentencePartsAnalysis:
        return SentencePartsAnalysisWidget(
          key: ValueKey('${_currentIndex}_$_attemptKey'),
          sentences: _currentActivity.sentenceItems ?? [_currentActivity.sentence],
          sentencePartsMap: _currentActivity.sentencePartsMap ?? {},
          areAnswersRevealed: _areAnswersRevealed,
          onValidationChanged: (isValid) {
            _partsAnalysisValid = isValid;
          },
        );

      case ActivityType.textWordExtraction:
        return TextWordExtractionWidget(
          key: ValueKey('${_currentIndex}_$_attemptKey'),
          passage: _currentActivity.contextParagraph ?? _currentActivity.sentence,
          targetWords: _currentActivity.targetWordsList ?? _currentActivity.options,
          wordContexts: _currentActivity.sentenceSolutions,
          areAnswersRevealed: _areAnswersRevealed,
          onValidationChanged: (isValid) {
            _textWordExtractionValid = isValid;
          },
        );

      case ActivityType.multipleChoice:
      case ActivityType.dragDropFillBlank:
      case ActivityType.selectVerb:
      case ActivityType.selectSubject:
      case ActivityType.selectObject:
      case ActivityType.classifyVerbTense:
      default:
        return _buildStandardOptionTiles(scale);
    }
  }

  Widget _buildStandardOptionTiles(double scale) {
    final letters = ['أ', 'ب', 'ج', 'د', 'هـ'];

    return Column(
      children: _currentActivity.options.asMap().entries.map((entry) {
        final idx = entry.key;
        final optionText = entry.value;
        final isSelected = _selectedOptionIndex == idx;
        final isAnswerRevealed = _areAnswersRevealed && idx == _currentActivity.correctIndex;
        final letter = idx < letters.length ? letters[idx] : '${idx + 1}';

        Color tileBg = Colors.white;
        Color tileBorder = const Color(0xFFCBD5E1);
        Color textColor = AppTheme.textDark;

        if (isSelected) {
          tileBg = AppTheme.primaryLight;
          tileBorder = AppTheme.primaryTeal;
          textColor = AppTheme.primaryDark;
        } else if (isAnswerRevealed) {
          tileBg = AppTheme.accentAmber.withValues(alpha: 0.15);
          tileBorder = AppTheme.accentAmber;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedOptionIndex = idx;
              });
            },
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: tileBorder,
                  width: isSelected || isAnswerRevealed ? 3 : 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isSelected
                        ? AppTheme.primaryTeal
                        : (isAnswerRevealed ? AppTheme.accentAmber : const Color(0xFFF1F5F9)),
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.w900,
                        color: isSelected || isAnswerRevealed ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      optionText,
                      style: TextStyle(
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal, size: 32)
                  else if (isAnswerRevealed)
                    const Icon(Icons.lightbulb_rounded, color: AppTheme.accentAmber, size: 30),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
