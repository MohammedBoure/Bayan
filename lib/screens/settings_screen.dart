import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

/// [09] شاشة الإعدادات (Settings Screen)
/// Matching tasks.md:
/// - خيارات وضبط التطبيق
/// - التشكيل التلقائي، الأصوات، حجم الخط، إعادة ضبط التقدم، نبذة عن اللسانيات الحاسوبية
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إِعَادَةُ ضَبْطِ التَّقَدُّمِ'),
          content: const Text(
            'هل أنت متأكد من رغبتك في مسح كل الدروس المنجزة والنجوم المحرزة والبدء من جديد؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إِلْغَاء'),
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
              child: const Text('نَعَمْ، إِعَادَةُ الضَّبْطِ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'إِعْدَادَاتُ التَّطْبِيقِ',
      progressService: progressService,
      body: ListenableBuilder(
        listenable: progressService,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // General Options Section
              _buildSectionHeader('خِيَارَاتُ العَرْضِ وَالتَّعَلُّمِ:'),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    // Tashkeel Toggle
                    SwitchListTile(
                      value: progressService.showTashkeel,
                      onChanged: (val) => progressService.setShowTashkeel(val),
                      title: const Text(
                        'إِظْهَارُ التَّشْكِيلِ تِلْقَائِيّاً',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: const Text(
                        'عرض الحركات الإعرابية على الكلمات والجمل لتسهيل القراءة',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      secondary: const Icon(Icons.format_color_text_rounded, color: AppTheme.primaryTeal),
                    ),
                    const Divider(height: 1),

                    // Sound Effects Toggle
                    SwitchListTile(
                      value: progressService.soundEnabled,
                      onChanged: (val) => progressService.setSoundEnabled(val),
                      title: const Text(
                        'المُؤَثِّرَاتُ الصَّوْتِيَّةُ وَالتَّشْجِيعُ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: const Text(
                        'تشغيل أصوات التعزيز الإيجابي عند الإجابة الصحيحة',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      secondary: const Icon(Icons.volume_up_rounded, color: AppTheme.accentOrange),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('إِدَارَةُ البَيَانَاتِ وَالتَّقَدُّمِ:'),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.restart_alt_rounded, color: AppTheme.errorRed, size: 28),
                  title: const Text(
                    'إِعَادَةُ تَعْيِينِ سِجِلِّ التَّقَدُّمِ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorRed),
                  ),
                  subtitle: const Text(
                    'تصفير النجوم المحرزة والدروس المكتملة',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  onTap: () => _confirmReset(context),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('عَنِ التَّطْبِيقِ وَاللِّسَانِيَّاتِ الحَاسُوبِيَّةِ:'),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.smart_toy_rounded, color: AppTheme.primaryTeal, size: 26),
                        SizedBox(width: 10),
                        Text(
                          'تَطْبِيقُ "بُسْتَانِ النَّحْوِ"',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'تطبيق تعليمي إلكتروني تفاعلي لتعليم النحو العربي في المرحلة الابتدائية (السنوات: 3، 4، 5 ابتدائي)، مطابق لمفردات الكتاب المدرسي المعتمد.\n\n'
                      'يرتكز بالأساس على توظيف أدوات اللسانيات الحاسوبية (Computational Linguistics): '
                      'المحلل الصرفي والنحوي الآلي، المُشكّل الذكي، والمدقق النحوي المطور لتزويد التلميذ بتغذية راجعة فورية ذكية وشرح تعليمي وافٍ.',
                      style: TextStyle(fontSize: 13.5, height: 1.7, color: AppTheme.textDark),
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
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }
}
