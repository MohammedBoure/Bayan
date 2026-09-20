import 'package:flutter/material.dart';
import '../services/license_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/activation_dialog.dart';
import 'grade_selection_screen.dart';
import 'settings_screen.dart';

/// [01] الشاشة الرئيسية (Home Screen)
/// Scaled and optimized for Classroom Data Show projectors and lecture halls.
/// Displays prominent Arabic typography, high contrast, and responsive widescreen space utilization.
class HomeScreen extends StatelessWidget {
  final ProgressService progressService;
  final LicenseService? licenseService;

  const HomeScreen({
    super.key,
    required this.progressService,
    this.licenseService,
  });

  @override
  Widget build(BuildContext context) {
    final effLicense = licenseService ?? LicenseService();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top App Bar with Data Show Badge, License Badge & Settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Data Show Projection Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.primaryTeal, width: 1.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cast_for_education_rounded, color: AppTheme.primaryTeal, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'مُهيأ للعرض الصفي (Data Show)',
                                    style: TextStyle(
                                      color: AppTheme.primaryTeal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // License Status Badge
                            ListenableBuilder(
                              listenable: effLicense,
                              builder: (context, _) => _buildLicenseBadge(context, effLicense),
                            ),
                          ],
                        ),
                        // Settings Shortcut Button
                        IconButton(
                          icon: const Icon(Icons.settings_rounded, color: AppTheme.primaryTeal, size: 34),
                          tooltip: 'الإعدادات',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SettingsScreen(
                                  progressService: progressService,
                                  licenseService: effLicense,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // App Title Banner
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: const [
                          Text(
                            'بُسْتَانُ النَّحْوِ العَرَبِيِّ التَّفَاعُلِيُّ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 42, // Large font for classroom projector
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'مَنْظُومَةٌ تَعْلِيمِيَّةٌ لِتَعْلِيمِ الجُمْلَةِ الفِعْلِيَّةِ وَالأَفْعَالِ بِاللِّسَانِيَّاتِ الحَاسُوبِيَّةِ (لِلتَّلامِيذِ 7 - 11 سَنَة)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Responsive 2-Column Presentation Layout for Wide Projector Screens
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 850;

                        final heroIllustration = ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Image.asset(
                                'assets/images/hero_reading.jpg',
                                height: isWide ? 360 : 240,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 240,
                                  color: AppTheme.primaryLight,
                                  child: const Center(
                                    child: Icon(Icons.menu_book_rounded, size: 90, color: AppTheme.primaryTeal),
                                  ),
                                ),
                              ),
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.school_rounded, color: Colors.white, size: 28),
                                      SizedBox(width: 10),
                                      Text(
                                        'المرحلة الابتدائية: السنوات 3 . 4 . 5',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        final actionControls = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Primary Classroom Start Action
                            SizedBox(
                              height: 76, // Extra tall for classroom visibility
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (!effLicense.canAccessCurriculum) {
                                    await ActivationDialog.show(context, effLicense);
                                    return;
                                  }
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => GradeSelectionScreen(
                                        progressService: progressService,
                                        licenseService: effLicense,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryTeal,
                                  foregroundColor: Colors.white,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                icon: const Icon(Icons.menu_book_rounded, size: 38, color: Colors.white),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'دُخُولٌ إِلَى دُرُوسِ المِنْهَاجِ',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Classroom Settings Action
                            SizedBox(
                              height: 64,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SettingsScreen(
                                        progressService: progressService,
                                        licenseService: effLicense,
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryTeal,
                                  side: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                icon: const Icon(Icons.tune_rounded, size: 28),
                                label: const Text(
                                  'إِعْدَادَاتُ العَرْضِ الصَّفِّيِّ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(flex: 5, child: heroIllustration),
                              const SizedBox(width: 32),
                              Expanded(flex: 6, child: actionControls),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              heroIllustration,
                              const SizedBox(height: 24),
                              actionControls,
                            ],
                          );
                        }
                      },
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

  Widget _buildLicenseBadge(BuildContext context, LicenseService license) {
    if (license.isActivated) {
      return InkWell(
        onTap: () => ActivationDialog.show(context, license),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.successGreen, width: 1.5),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, color: AppTheme.successGreen, size: 20),
              SizedBox(width: 6),
              Text(
                'البرنامج مفعل بصفة دائمة ✓',
                style: TextStyle(
                  color: AppTheme.successGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (license.isTrialActive) {
      return InkWell(
        onTap: () => ActivationDialog.show(context, license),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentAmber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentOrange, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded, color: AppTheme.accentOrange, size: 20),
              const SizedBox(width: 6),
              Text(
                'فترة تجريبية: متبقي ${license.daysRemaining} أيام ⏳',
                style: const TextStyle(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Trial expired
    return InkWell(
      onTap: () => ActivationDialog.show(context, license),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.errorRed, width: 1.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, color: AppTheme.errorRed, size: 20),
            SizedBox(width: 6),
            Text(
              'انتهت الفترة التجريبية (التفعيل مطلوب) ⚠️',
              style: TextStyle(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
