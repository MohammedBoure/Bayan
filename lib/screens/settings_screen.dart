import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

/// [09] شاشة الإعدادات (Settings Screen)
/// Classroom and projection settings with high-visibility toggles and clean controls.
class SettingsScreen extends StatelessWidget {
  final ProgressService progressService;

  const SettingsScreen({
    super.key,
    required this.progressService,
  });

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('إِعَادَةُ ضَبْطِ التَّقَدُّمِ لِلصَّفِّ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          content: const Text(
            'هل أنت متأكد من رغبتك في مسح كل الدروس المنجزة والنجوم المحرزة والبدء من جديد؟',
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إِلْغَاء', style: TextStyle(fontSize: 18)),
            ),
            ElevatedButton(
              onPressed: () async {
                await progressService.resetProgress();
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت إعادة ضبط سجل التقدم بنجاح.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              child: const Text('نَعَمْ، إِعَادَةُ الضَّبْطِ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'إِعْدَادَاتُ شَاشَةِ العَرْضِ الصَّفِّيِّ',
      progressService: progressService,
      body: ListenableBuilder(
        listenable: progressService,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            children: [
              // General Options Section
              _buildSectionHeader('خِيَارَاتُ العَرْضِ وَالتَّعَلُّمِ فِي القَاعَةِ:'),
              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
                ),
                child: Column(
                  children: [
                    // Tashkeel Toggle
                    SwitchListTile(
                      value: progressService.showTashkeel,
                      onChanged: (val) => progressService.setShowTashkeel(val),
                      title: const Text(
                        'إِظْهَارُ التَّشْكِيلِ تِلْقَائِيّاً لِلتَّلامِيذِ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      subtitle: const Text(
                        'عرض الحركات الإعرابية على الكلمات والجمل لتسهيل القراءة على السبورة',
                        style: TextStyle(fontSize: 16),
                      ),
                      secondary: const Icon(Icons.format_color_text_rounded, color: AppTheme.primaryTeal, size: 32),
                    ),
                    const Divider(height: 1, thickness: 1.2),

                    // Sound Effects Toggle
                    SwitchListTile(
                      value: progressService.soundEnabled,
                      onChanged: (val) => progressService.setSoundEnabled(val),
                      title: const Text(
                        'المُؤَثِّرَاتُ الصَّوْتِيَّةُ وَالتَّشْجِيعُ الصَّفِّيُّ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      subtitle: const Text(
                        'تشغيل أصوات التعزيز الإيجابي عند إجابة التلاميذ الصحيحة',
                        style: TextStyle(fontSize: 16),
                      ),
                      secondary: const Icon(Icons.volume_up_rounded, color: AppTheme.accentOrange, size: 32),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('إِدَارَةُ البَيَانَاتِ وَالتَّقَدُّمِ:'),
              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: const Icon(Icons.restart_alt_rounded, color: AppTheme.errorRed, size: 36),
                  title: const Text(
                    'إِعَادَةُ تَعْيِينِ سِجِلِّ الإِنْجَازِ لِفَصْلٍ جَدِيدٍ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorRed, fontSize: 20),
                  ),
                  subtitle: const Text(
                    'تصفير النجوم والدروس المكتملة لبدء درس جديد مع فوج آخر',
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () => _confirmReset(context),
                ),
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('عَنِ التَّطْبِيقِ وَاللِّسَانِيَّاتِ الحَاسُوبِيَّةِ:'),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryTeal, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.smart_toy_rounded, color: AppTheme.primaryTeal, size: 34),
                        SizedBox(width: 12),
                        Text(
                          'تَطْبِيقُ "بُسْتَانِ النَّحْوِ" - نُسْخَةُ قَاعَاتِ الدَّرْسِ',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.primaryDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'تطبيق تعليمي إلكتروني تفاعلي مهيأ خصيصاً للعرض الصفي عبر أجهزة العرض (Data Show) والسبورات الذكية لتلاميذ المرحلة الابتدائية (السنوات: 3، 4، 5 ابتدائي).\n\n'
                      'يرتكز بالأساس على توظيف أدوات اللسانيات الحاسوبية (Computational Linguistics): '
                      'المحلل الصرفي والنحوي الهجين، شجرة القرار، فحص السياق الثنائي، والمُشكّل الآلي، مع قاعدة بيانات محلية قابلة للتوسع اللانهائي ولاستقبال مئات الدروس والتمارين.',
                      style: TextStyle(fontSize: 17, height: 1.75, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: AppTheme.textDark,
      ),
    );
  }
}
