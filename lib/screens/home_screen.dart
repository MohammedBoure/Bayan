import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import 'grade_selection_screen.dart';
import 'nlp_lab_screen.dart';
import 'progress_results_screen.dart';
import 'settings_screen.dart';

/// [01] الشاشة الرئيسية (Home Screen)
/// Matching tasks.md specification:
/// - اسم التطبيق (App Name)
/// - رسم يناسب الأطفال (Child-friendly illustration)
/// - زر: ابدأ (Start Button)
/// - أيقونة كتاب (Book Icon)
/// - روابط سريعة للمختبر اللغوي الحاسوبي والإعدادات
class HomeScreen extends StatelessWidget {
  final ProgressService progressService;

  const HomeScreen({
    super.key,
    required this.progressService,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 750),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top App Bar with Quick Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Star count badge
                        ListenableBuilder(
                          listenable: progressService,
                          builder: (context, _) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentAmber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: AppTheme.accentAmber, size: 24),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${progressService.progress.totalStars} نجمة',
                                    style: const TextStyle(
                                      color: AppTheme.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Quick Settings Button
                        IconButton(
                          icon: const Icon(Icons.settings_rounded, color: AppTheme.primaryTeal, size: 28),
                          tooltip: 'الإعدادات',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SettingsScreen(progressService: progressService),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // App Title & Tagline
                    const Center(
                      child: Text(
                        'بُسْتَانُ النَّحْوِ العَرَبِيِّ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'تَعَلَّمِ الجُمْلَةَ الفِعْلِيَّةَ وَالأَفْعَالَ بِأَدَوَاتِ اللِّسَانِيَّاتِ الحَاسُوبِيَّةِ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Child-friendly Hero Illustration (Downloaded from Internet)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Image.asset(
                            'assets/images/hero_reading.jpg',
                            height: 230,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 200,
                              color: AppTheme.primaryLight,
                              child: const Center(
                                child: Icon(Icons.menu_book_rounded, size: 80, color: AppTheme.primaryTeal),
                              ),
                            ),
                          ),
                          Container(
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.75),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'المرحلة الابتدائية: السنوات 3 . 4 . 5',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Primary Action: [ زر: ابدأ ]
                    SizedBox(
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GradeSelectionScreen(progressService: progressService),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: AppTheme.primaryTeal.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.play_circle_filled_rounded, size: 30, color: Colors.white),
                        label: const Text(
                          'اِبْـدَأِ التَّعَلُّـمَ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Computational Linguistics Lab Button (اللسانيات الحاسوبية)
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NlpLabScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.verbColor, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.smart_toy_rounded, size: 26, color: AppTheme.verbColor),
                        label: const Text(
                          'المُخْتَبَرُ اللُّغَوِيُّ الذَّكِيُّ (المُحَلِّلُ الآلِيُّ)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.verbColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Progress and Settings Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProgressResultsScreen(progressService: progressService),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.accentAmber.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.emoji_events_rounded, color: AppTheme.accentAmber, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'سِجِلُّ التَّقَدُّمِ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SettingsScreen(progressService: progressService),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.tune_rounded, color: AppTheme.primaryTeal, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'الإِعْدَادَاتُ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
