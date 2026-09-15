import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import 'progress_results_screen.dart';

/// [07] التقويم (Evaluation Quiz Screen)
/// Scaled for lecture display on a Data Show projector.
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
        const SnackBar(content: Text('يرجى اختيار إجابة للسؤال الحالي المعروض.')),
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
      title: 'التَّقْوِيمُ التَّحْصِيلِيُّ الشَّامِلُ',
      progressService: widget.progressService,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accentPurple,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentPurple),
                  ),
                  child: const Text(
                    'تقويم مرحلي على السبورة',
                    style: TextStyle(
                      color: AppTheme.accentPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                minHeight: 12,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentPurple),
              ),
            ),
            const SizedBox(height: 28),

            // Question Card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppTheme.accentPurple, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _currentQuestion.questionText,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (_currentQuestion.contextSentence != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryTeal, width: 2),
                      ),
                      child: Text(
                        '"${_currentQuestion.contextSentence!}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 36, // Highly visible context sentence
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Options List
            ...List.generate(_currentQuestion.options.length, (index) {
              final option = _currentQuestion.options[index];
              final isSelected = selectedOption == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _onOptionSelected(index),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accentPurple.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.accentPurple : const Color(0xFFCBD5E1),
                        width: isSelected ? 3.0 : 1.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.accentPurple : Colors.grey,
                              width: 2.5,
                            ),
                            color: isSelected ? AppTheme.accentPurple : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(Icons.check, size: 22, color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
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

            const SizedBox(height: 28),

            // Submit / Next Question Button
            SizedBox(
              height: 68,
              child: ElevatedButton.icon(
                onPressed: _goToNextOrSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: Icon(
                  _currentQuestionIndex == widget.quiz.questions.length - 1
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                label: Text(
                  _currentQuestionIndex == widget.quiz.questions.length - 1
                      ? 'إِرْسَالُ الإِجَابَاتِ وَعَرْضُ النَّتِيجَةِ الشَّامِلَةِ'
                      : 'السُّؤَالُ التَّالِي',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
