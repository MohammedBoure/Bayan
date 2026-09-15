import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

/// [08] النتيجة والتقدم (Progress & Results Screen)
/// Scaled for lecture display on a Data Show projector.
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
      title: 'النَّتِيجَةُ وَسِجِلُّ التَّقَدُّمِ',
      progressService: progressService,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // If coming from a recently submitted quiz, display the latest result card
            if (latestScore != null) ...[
              _buildLatestQuizCard(context),
              const SizedBox(height: 28),
            ],

            // Overall Progress Summary Card
            _buildOverallProgressCard(context),
            const SizedBox(height: 24),

            // Grade-by-Grade Achievement Breakdown
            _buildGradeBreakdownCard(context),
            const SizedBox(height: 32),

            // Back to Home Button
            SizedBox(
              height: 64,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.home_rounded, color: Colors.white, size: 30),
                label: const Text(
                  'العَوْدَةُ إِلَى الشَّاشَةِ الرَّئِيسِيَّةِ لِلصَّفِّ',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isHighPass
              ? AppTheme.successGreen
              : AppTheme.accentOrange,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Trophy Image from internet assets
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/trophy_success.jpg',
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.emoji_events_rounded, size: 90, color: AppTheme.accentAmber),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            isHighPass
                ? 'مُمْتَازٌ جِدّاً! أَحْسَنْتُمْ يَا أَبْطَالَ الصَّفِّ'
                : (isPass ? 'جَيِّدٌ جِدّاً! نَتِيجَةٌ مُمَيَّزَةٌ' : 'حَاوِلْ مَرَّةً أُخْرَى مَعَ زُمَلائِكَ لِتَحْسِينِ النَّتِيجَةِ'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isHighPass ? AppTheme.successGreen : (isPass ? AppTheme.accentOrange : AppTheme.errorRed),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            quizTitle ?? 'نتيجة التقويم التحصيلي',
            style: const TextStyle(fontSize: 18, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Big Score Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryTeal, width: 2),
            ),
            child: Text(
              '%$latestScore',
              style: const TextStyle(
                fontSize: 52, // Massive score
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (correctAnswers != null && totalQuestions != null) ...[
            Text(
              'تمت الإجابة بشكل صحيح عن $correctAnswers من أصل $totalQuestions أسئلة.',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ],
          const SizedBox(height: 18),

          // Giant Stars Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final starEarned = isHighPass ? true : (isPass ? index < 2 : index < 1);
              return Icon(
                Icons.star_rounded,
                size: 56, // Big celebratory stars
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
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights_rounded, color: AppTheme.primaryTeal, size: 32),
              SizedBox(width: 12),
              Text(
                'إِجْمَالِيُّ الإِنْجَازَاتِ وَالنُّجُومِ لِلصَّفِّ:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.menu_book_rounded,
                  label: 'الدروس المنجزة',
                  value: '${progressService.progress.completedLessons.length}',
                  color: AppTheme.primaryTeal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.task_alt_rounded,
                  label: 'التمارين المكتملة',
                  value: '${progressService.progress.totalExercisesCompleted}',
                  color: AppTheme.verbColor,
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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
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
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نَتَائِجُ التَّقْوِيمِ حَسَبَ السَّنَوَاتِ الدِّرَاسِيَّةِ:',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textDark),
          ),
          const SizedBox(height: 18),
          _buildGradeRow('السنة الثالثة ابتدائي', grade3Score, AppTheme.primaryTeal),
          const Divider(height: 24, thickness: 1.5),
          _buildGradeRow('السنة الرابعة ابتدائي', grade4Score, AppTheme.verbColor),
          const Divider(height: 24, thickness: 1.5),
          _buildGradeRow('السنة الخامسة ابتدائي', grade5Score, AppTheme.accentOrange),
        ],
      ),
    );
  }

  Widget _buildGradeRow(String gradeTitle, int score, Color color) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            gradeTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
        ),
        Text(
          score > 0 ? '%$score' : 'لم يُجتز بعد',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: score > 0 ? color : Colors.grey,
          ),
        ),
      ],
    );
  }
}
