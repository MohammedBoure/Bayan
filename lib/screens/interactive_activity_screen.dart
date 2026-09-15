import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/celebration_dialog.dart';

/// [05] النشاط التفاعلي (Interactive Activity Screen)
/// Classroom billboard presentation format for Data Show devices.
/// Features a massive sentence display (44px), prominent option tiles (A, B, C), and large submit buttons.
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
          content: Text('الرجاء اختيار إجابة من اللوحة أولاً!'),
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
      title: isCorrect ? 'أَحْسَنْتَ! إِجَابَةٌ صَحِيحَةٌ' : 'حَاوِلْ مَرَّةً أُخْرَى مَعَ مُعَلِّمِكَ',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: Row(
            children: const [
              Icon(Icons.stars_rounded, color: AppTheme.accentAmber, size: 40),
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
              const SizedBox(height: 16),
              const Text(
                'مبارك لجميع التلاميذ! لقد أتممتم الأنشطة التفاعلية بنجاح على شاشة العرض.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('عَوْدَةٌ إِلَى قَائِمَةِ الدُّرُوسِ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'النَّشَاطُ التَّفَاعُلِيُّ - ${widget.lessonTitle}',
      progressService: widget.progressService,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar Across Classroom Screen
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / widget.activities.length,
                      minHeight: 14,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryTeal),
                  ),
                  child: Text(
                    'تمرين ${_currentIndex + 1} مِنْ ${widget.activities.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primaryDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Giant Target Sentence Billboard (as in tasks.md: [ يقرأ التلميذ الكتاب ])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.verbColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.verbColor.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'الجُمْلَةُ المَعْرُوضَةُ عَلَى السَّبُّورَةِ:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _currentActivity.sentence,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 44, // Huge billboard typography
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Question Prompt (حَدِّدِ الفِعْلَ مِنَ الجُمْلَة:)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: Text(
                _currentActivity.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Option Cards Layout - Widescreen Grid on Data Show
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;

                final optionWidgets = List.generate(_currentActivity.options.length, (index) {
                  final option = _currentActivity.options[index];
                  final isSelected = _selectedOptionIndex == index;
                  final optionLetters = ['أ', 'ب', 'ج', 'د', 'هـ'];
                  final letter = index < optionLetters.length ? optionLetters[index] : '${index + 1}';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: _submitted
                          ? null
                          : () {
                              setState(() {
                                _selectedOptionIndex = index;
                              });
                            },
                      borderRadius: BorderRadius.circular(22),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryLight : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryTeal : const Color(0xFFCBD5E1),
                            width: isSelected ? 3.5 : 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? AppTheme.primaryTeal.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Big Letter Badge
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryTeal : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryTeal : const Color(0xFF94A3B8),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppTheme.textDark,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                  color: isSelected ? AppTheme.primaryDark : AppTheme.textDark,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal, size: 32),
                          ],
                        ),
                      ),
                    ),
                  );
                });

                if (isWide && _currentActivity.options.length <= 4) {
                  return Column(
                    children: optionWidgets,
                  );
                } else {
                  return Column(children: optionWidgets);
                }
              },
            ),

            const SizedBox(height: 28),

            // Submit Button: [ زر: إرسال الإجابة ]
            SizedBox(
              height: 68,
              child: ElevatedButton.icon(
                onPressed: _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 30),
                label: const Text(
                  'إِرْسَالُ الإِجَابَةِ لِلتَّحَقُّقِ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
