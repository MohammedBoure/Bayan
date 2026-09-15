import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/celebration_dialog.dart';

/// [05] النشاط التفاعلي (Interactive Activity Screen)
/// Matching tasks.md:
/// - الجملة: [ يقرأ التلميذ الكتاب ]
/// - حدد الفعل من الجملة:
///   * ( ) يقرأ
///   * ( ) التلميذ
///   * ( ) الكتاب
/// - [ زر: إرسال الإجابة ]
/// With transition to:
/// - [06] التغذية الراجعة (FeedbackDialog)
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
  int? _selectedOptionIndex;
  bool _submitted = false;

  ActivityModel get _currentActivity => widget.activities[_currentIndex];

  void _submitAnswer() {
    if (_selectedOptionIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار إجابة أولاً!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _submitted = true;
    });

    final isCorrect = _selectedOptionIndex == _currentActivity.correctIndex;

    // Show [06] التغذية الراجعة (FeedbackDialog)
    FeedbackDialog.show(
      context: context,
      isCorrect: isCorrect,
      title: isCorrect ? 'أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ' : 'حَاوِلْ مَرَّةً أُخْرَى',
      message: isCorrect ? _currentActivity.correctFeedback : _currentActivity.incorrectFeedback,
      ruleSummary: _currentActivity.ruleSummary,
      onContinue: () {
        if (_currentIndex < widget.activities.length - 1) {
          setState(() {
            _currentIndex++;
            _selectedOptionIndex = null;
            _submitted = false;
          });
        } else {
          // Completed all activities for this set
          if (widget.lessonIdToComplete != null) {
            widget.progressService.markLessonCompleted(widget.lessonIdToComplete!);
          }
          _showCompletionAlert();
        }
      },
    );
  }

  void _showCompletionAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: const [
              Icon(Icons.stars_rounded, color: AppTheme.accentAmber, size: 32),
              SizedBox(width: 10),
              Text('تَمَّ إِنْجَازُ الأَنْشِطَةِ!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/trophy_success.jpg',
                height: 120,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.emoji_events_rounded, size: 80, color: AppTheme.accentAmber),
              ),
              const SizedBox(height: 12),
              const Text(
                'مبارك عليك! لقد أتممت الأنشطة التفاعلية بنجاح، وتمت إضافة نجوم الإنجاز إلى رصيدك.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('عَوْدَةٌ إِلَى الدُّرُوسِ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'النَّشَاطُ التَّفَاعُلِيُّ',
      progressService: widget.progressService,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / widget.activities.length,
                      minHeight: 10,
                      backgroundColor: AppTheme.primaryLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_currentIndex + 1} / ${widget.activities.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Target Sentence Box (as in tasks.md: [ يقرأ التلميذ الكتاب ])
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.verbColor.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.verbColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'الجُمْلَةُ التَّطْبِيقِيَّةُ:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentActivity.sentence,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Prompt Question (e.g. حَدِّدِ الفِعْلَ مِنَ الجُمْلَة:)
            Text(
              _currentActivity.prompt,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // Options List: ( ) يقرأ, ( ) التلميذ, ( ) الكتاب
            ...List.generate(_currentActivity.options.length, (index) {
              final option = _currentActivity.options[index];
              final isSelected = _selectedOptionIndex == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: _submitted
                      ? null
                      : () {
                          setState(() {
                            _selectedOptionIndex = index;
                          });
                        },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryTeal : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 2.5 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryTeal : Colors.grey,
                              width: 2,
                            ),
                            color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(Icons.check, size: 16, color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? AppTheme.primaryDark : AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 28),

            // Submit Button: [ زر: إرسال الإجابة ]
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                label: const Text(
                  'إِرْسَالُ الإِجَابَةِ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
