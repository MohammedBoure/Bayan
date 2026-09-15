import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

/// [08] النتيجة والتقدم (Progress & Results Screen)
/// Matching tasks.md:
/// - عرض نتائج ونسب الإنجاز
/// - حفظ التقدم والنجوم
class ProgressResultsScreen extends StatelessWidget {
  final ProgressService progressService;
  final int? latestScore;
  final int? totalQuestions;
  final int? correctAnswers;
  final String? quizTitle;

  const ProgressResultsScreen({
    super.key,
    required this.progressService,
    this.latestScore,
    this.totalQuestions,
    this.correctAnswers,
    this.quizTitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'النَّتِيجَةُ وَالتَّقَدُّمُ',
      progressService: progressService,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // If coming from a recently submitted quiz, display the latest result card
            if (latestScore != null) ...[
              _buildLatestQuizCard(context),
              const SizedBox(height: 24),
            ],

            // Overall Progress Summary Card
            _buildOverallProgressCard(context),
            const SizedBox(height: 20),

            // Grade-by-Grade Achievement Breakdown
            _buildGradeBreakdownCard(context),
            const SizedBox(height: 24),

            // Back to Home Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.home_rounded, color: Colors.white),
                label: const Text(
                  'العَوْدَةُ إِلَى الصَّفْحَةِ الرَّئِيسِيَّةِ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestQuizCard(BuildContext context) {
    final isHighPass = (latestScore ?? 0) >= 80;
    final isPass = (latestScore ?? 0) >= 50;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHighPass
              ? AppTheme.successGreen.withValues(alpha: 0.5)
              : AppTheme.accentOrange.withValues(alpha: 0.5),
          width: 2,
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
        children: [
          // Trophy Image from internet assets
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/trophy_success.jpg',
              height: 110,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.emoji_events_rounded, size: 70, color: AppTheme.accentAmber),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            isHighPass
                ? 'مُمْتَازٌ جِدّاً! أَحْسَنْتَ صُنْعاً'
                : (isPass ? 'جَيِّدٌ جِدّاً! تَقَدُّمٌ مَلْحُوظٌ' : 'حَاوِلْ مَرَّةً أُخْرَى لِتَحْسِينِ النَّتِيجَةِ'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isHighPass ? AppTheme.successGreen : (isPass ? AppTheme.accentOrange : AppTheme.errorRed),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            quizTitle ?? 'نتيجة التقويم التحصيلي',
            style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),

          // Big Score Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '%$latestScore',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (correctAnswers != null && totalQuestions != null) ...[
            Text(
              'أجبت عن $correctAnswers من أصل $totalQuestions أسئلة بشكل صحيح.',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
          ],
          const SizedBox(height: 14),

          // Stars Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final starEarned = isHighPass ? true : (isPass ? index < 2 : index < 1);
              return Icon(
                Icons.star_rounded,
                size: 36,
                color: starEarned ? AppTheme.accentAmber : Colors.grey.withValues(alpha: 0.3),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgressCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
          const Row(
            children: [
              Icon(Icons.insights_rounded, color: AppTheme.primaryTeal, size: 24),
              SizedBox(width: 8),
              Text(
                'إِجْمَالِيُّ الإِنْجَازَاتِ وَالنُّجُومِ:',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.star_rounded,
                  label: 'مجموع النجوم',
                  value: '${progressService.progress.totalStars}',
                  color: AppTheme.accentAmber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.menu_book_rounded,
                  label: 'الدروس المنجزة',
                  value: '${progressService.progress.completedLessons.length}',
                  color: AppTheme.primaryTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.task_alt_rounded,
                  label: 'التمارين المكتملة',
                  value: '${progressService.progress.totalExercisesCompleted}',
                  color: AppTheme.accentBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBreakdownCard(BuildContext context) {
    final grade3Score = progressService.progress.getGradeScore('grade3');
    final grade4Score = progressService.progress.getGradeScore('grade4');
    final grade5Score = progressService.progress.getGradeScore('grade5');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نَتَائِجُ التَّقْوِيمِ حَسَبَ السَّنَوَاتِ:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 14),
          _buildGradeRow('السنة الثالثة ابتدائي', grade3Score, AppTheme.primaryTeal),
          const Divider(height: 20),
          _buildGradeRow('السنة الرابعة ابتدائي', grade4Score, AppTheme.accentBlue),
          const Divider(height: 20),
          _buildGradeRow('السنة الخامسة ابتدائي', grade5Score, AppTheme.accentOrange),
        ],
      ),
    );
  }

  Widget _buildGradeRow(String gradeTitle, int score, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            gradeTitle,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          ),
        ),
        Text(
          score > 0 ? '%$score' : 'لم يُجتز بعد',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: score > 0 ? color : Colors.grey,
          ),
        ),
      ],
    );
  }
}
