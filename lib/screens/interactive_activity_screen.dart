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
import '../widgets/multi_sentence_fill_widget.dart';
import '../widgets/multi_sentence_order_widget.dart';
import '../widgets/sentence_ordering_widget.dart';
import '../widgets/teacher_toolbar_widget.dart';

/// [05] النشاط التفاعلي الشامل (Comprehensive Interactive Activity Screen)
/// Supports 6 activity engines:
/// 1. Multiple Choice with large whiteboard letters (أ، ب، ج)
/// 2. Drag & Drop fill in the blanks
/// 3. Categorization Boards (2-column & 3-column)
/// 4. Sentence Word Ordering
/// 5. Image & Verb Matching
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
      _areAnswersRevealed = false;
    });
  }

  void _proceedToNextActivity() {
    if (_currentIndex < widget.activities.length - 1) {
      setState(() {
        _currentIndex++;
        _attemptKey = 0;
        _selectedOptionIndex = null;
        _submitted = false;
        _categorizationValid = false;
        _sentenceOrderValid = false;
        _imageMatchValid = false;
        _multiSelectValid = false;
        _multiFillValid = false;
        _multiOrderValid = false;
        _areAnswersRevealed = false;
      });
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
                      _currentActivity.type != ActivityType.multiSentenceOrder) ...[
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

            // Submit Button
            SizedBox(
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
