import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import 'progress_results_screen.dart';

/// [07] التقويم (Evaluation Quiz Screen)
/// Matching tasks.md:
/// - مثال على التقويم:
/// - اختر الفعل من الجملة التالية: "جلس التلميذ في الفصل" -> ( ) جلس  ( ) التلميذ
/// - [ زر: إرسال ]
/// Transitions to [08] النتيجة والتقدم
class QuizEvaluationScreen extends StatefulWidget {
  final QuizModel quiz;
  final ProgressService progressService;

  const QuizEvaluationScreen({
    super.key,
    required this.quiz,
    required this.progressService,
  });

  @override
  State<QuizEvaluationScreen> createState() => _QuizEvaluationScreenState();
}

class _QuizEvaluationScreenState extends State<QuizEvaluationScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {};

  QuizQuestion get _currentQuestion => widget.quiz.questions[_currentQuestionIndex];

  void _onOptionSelected(int optionIndex) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = optionIndex;
    });
  }

  void _goToNextOrSubmit() {
    if (!_selectedAnswers.containsKey(_currentQuestionIndex)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار إجابة للسؤال الحالي.')),
      );
      return;
    }

    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _calculateAndShowResults();
    }
  }

  void _calculateAndShowResults() {
    int correctCount = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_selectedAnswers[i] == widget.quiz.questions[i].correctIndex) {
        correctCount++;
      }
    }

    final scorePercentage = ((correctCount / widget.quiz.questions.length) * 100).round();
    widget.progressService.saveGradeQuizScore(widget.quiz.gradeId, scorePercentage);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProgressResultsScreen(
          progressService: widget.progressService,
          latestScore: scorePercentage,
          totalQuestions: widget.quiz.questions.length,
          correctAnswers: correctCount,
          quizTitle: widget.quiz.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = _selectedAnswers[_currentQuestionIndex];

    return AppScaffold(
      title: 'التَّقْوِيمُ التَّحْصِيلِيُّ',
      progressService: widget.progressService,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question Counter & Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'السُّؤَالُ ${_currentQuestionIndex + 1} مِنْ ${widget.quiz.questions.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'تقويم مرحلي',
                    style: TextStyle(
                      color: AppTheme.accentPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                minHeight: 8,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentPurple),
              ),
            ),
            const SizedBox(height: 24),

            // Question Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.25), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _currentQuestion.questionText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (_currentQuestion.contextSentence != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        '"${_currentQuestion.contextSentence!}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Options List
            ...List.generate(_currentQuestion.options.length, (index) {
              final option = _currentQuestion.options[index];
              final isSelected = selectedOption == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _onOptionSelected(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accentPurple.withValues(alpha: 0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.accentPurple : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 2.2 : 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.accentPurple : Colors.grey,
                              width: 2,
                            ),
                            color: isSelected ? AppTheme.accentPurple : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(Icons.check, size: 15, color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppTheme.accentPurple : AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Submit / Next Question Button [ زر: إرسال ]
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _goToNextOrSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: Icon(
                  _currentQuestionIndex == widget.quiz.questions.length - 1
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  _currentQuestionIndex == widget.quiz.questions.length - 1
                      ? 'إِرْسَالُ الإِجَابَاتِ وَعَرْضُ النَّتِيجَةِ'
                      : 'السُّؤَالُ التَّالِي',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
