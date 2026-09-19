import 'package:flutter/material.dart';
import '../services/nlp_database_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

/// [09] شاشة الإعدادات الشاملة (Comprehensive Classroom & Teacher Settings)
/// Allows full configuration of Teacher Presentation Mode, Classroom Timer,
/// Data Show font scaling, reading spotlights, sound effects, and offline NLP overrides.
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
          title: const Text('إِعَادَةُ ضَبْطِ سِجِلِّ الفَصْلِ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          content: const Text(
            'هل أنت متأكد من رغبتك في مسح كل الدروس المنجزة والنجوم المحرزة والبدء من جديد مع فوج آخر؟',
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
                    const SnackBar(content: Text('تمت إعادة ضبط سجل الفصل بنجاح.')),
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

  void _confirmClearOverrides(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('إِعَادَةُ تَعْيِينِ قَوَاعِدِ الأُسْتَاذِ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          content: const Text(
            'هل تريد مسح التعديلات والإعرابات المخصصة التي تم حفظها في قاعدة بيانات المحلل المحلي والرجوع للضبط الافتراضي؟',
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إِلْغَاء', style: TextStyle(fontSize: 18)),
            ),
            ElevatedButton(
              onPressed: () async {
                await NlpDatabaseService.instance.clearAllUserCorrections();
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت استعادة القواعد الافتراضية بنجاح.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange),
              child: const Text('مَسْحُ التَّصْحِيحَاتِ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'إِعْدَادَاتُ المَنْظُومَةِ وَالعَرْضِ الصَّفِّيِّ',
      progressService: progressService,
      body: ListenableBuilder(
        listenable: progressService,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            children: [
              // 1. Teacher & Classroom Mode Section
              _buildSectionHeader('أَدَوَاتُ الأُسْتَاذِ وَالتَّدْرِيسِ فِي الفَصْلِ (Teacher Mode):'),
              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
                ),
                child: Column(
                  children: [
                    // Teacher Mode Master Toggle
                    SwitchListTile(
                      value: progressService.teacherModeEnabled,
                      onChanged: (val) => progressService.setTeacherModeEnabled(val),
                      title: const Text(
                        'تَفْعِيلُ وَضْعِ الأُسْتَاذِ فِي الفَصْلِ (Teacher Mode)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      subtitle: const Text(
                        'إظهار شريط أدوات المعلم، الإرشادات البيداغوجية، ومفاتيح التحكم الصفي',
                        style: TextStyle(fontSize: 16),
                      ),
                      secondary: const Icon(Icons.school_rounded, color: AppTheme.primaryTeal, size: 34),
                    ),
                    const Divider(height: 1, thickness: 1.2),

                    // Reveal Model Answers Directly
                    SwitchListTile(
                      value: progressService.revealAnswersDirectly,
                      onChanged: (val) => progressService.setRevealAnswersDirectly(val),
                      title: const Text(
                        'إِظْهَارُ الحُلُولِ النَّمُوذَجِيَّةِ لِلأُسْتَاذِ دَائِماً',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      subtitle: const Text(
                        'إظهار الحلول فوراً للأستاذ بدلاً من إبقائها مخفية للعصف الذهني الصفي',
                        style: TextStyle(fontSize: 16),
                      ),
                      secondary: const Icon(Icons.visibility_rounded, color: AppTheme.accentPurple, size: 32),
                    ),
                    const Divider(height: 1, thickness: 1.2),

                    // Classroom Challenge Timer
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: const Icon(Icons.timer_rounded, color: AppTheme.accentOrange, size: 34),
                      title: const Text(
                        'مُؤَقِّتُ التَّحَدِّي وَالأَنْشِطَةِ الصَّفِّيَّةِ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      subtitle: const Text(
                        'تحديد زمن التنافس بين أفواج وتلاميذ الصف عند صعودهم للسبورة',
                        style: TextStyle(fontSize: 16),
                      ),
                      trailing: DropdownButton<int>(
                        value: progressService.timerDuration,
                        borderRadius: BorderRadius.circular(16),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                        onChanged: (newVal) {
                          if (newVal != null) {
                            progressService.setTimerDuration(newVal);
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('بِدُونِ مُؤَقِّت')),
                          DropdownMenuItem(value: 30, child: Text('30 ثَانِيَة')),
                          DropdownMenuItem(value: 45, child: Text('45 ثَانِيَة')),
                          DropdownMenuItem(value: 60, child: Text('60 ثَانِيَة')),
                          DropdownMenuItem(value: 90, child: Text('90 ثَانِيَة')),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1.2),

                    // Spotlight Reading Toggle
                    SwitchListTile(
                      value: progressService.spotlightReading,
                      onChanged: (val) => progressService.setSpotlightReading(val),
                      title: const Text(
                        'مُؤَشِّرُ التَّرْكِيزِ الصَّفِّيِّ عَلَى الفَقَرَاتِ (Spotlight)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      subtitle: const Text(
                        'تظليل وتكبير الفقرة أو الجملة المقروءة لجذب انتباه المقاعد الخلفية',
                        style: TextStyle(fontSize: 16),
                      ),
                      secondary: const Icon(Icons.highlight_rounded, color: AppTheme.accentAmber, size: 32),
                    ),
                    const Divider(height: 1, thickness: 1.2),

                    // Live NLP Tooltips on Reading
                    SwitchListTile(
                      value: progressService.nlpAutoAnalysis,
                      onChanged: (val) => progressService.setNlpAutoAnalysis(val),
                      title: const Text(
                        'تَفْعِيلُ المُحَلِّلِ اللُّغَوِيِّ التَّفَاعُلِيِّ فِي النُّصُوصِ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      subtitle: const Text(
                        'إمكانية لمس أي كلمة في نص القراءة لإعرابها وتجريد سوابقها فورياً',
                        style: TextStyle(fontSize: 16),
                      ),
                      secondary: const Icon(Icons.auto_stories_rounded, color: AppTheme.verbColor, size: 32),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 2. Data Show Projection & Display Section
              _buildSectionHeader('خِيَارَاتُ عَرْضِ البْرُوجِكْتُور (Data Show Display):'),
              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
                ),
                child: Column(
                  children: [
                    // Font Scaling Dropdown for Large Projection
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: const Icon(Icons.format_size_rounded, color: AppTheme.primaryTeal, size: 34),
                      title: const Text(
                        'حَجْمُ الخُطُوطِ لِشَاشَةِ العَرْضِ (Font Scaling)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      subtitle: const Text(
                        'ملاءمة حجم النصوص لبعد المسافة وإضاءة أجهزة العرض المدرسية',
                        style: TextStyle(fontSize: 16),
                      ),
                      trailing: DropdownButton<double>(
                        value: progressService.fontSizeScale,
                        borderRadius: BorderRadius.circular(16),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                        onChanged: (newScale) {
                          if (newScale != null) {
                            progressService.setFontSizeScale(newScale);
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 1.0, child: Text('عَادِي (100%)')),
                          DropdownMenuItem(value: 1.2, child: Text('كَبِير (120%)')),
                          DropdownMenuItem(value: 1.35, child: Text('بْرُوجِكْتُور (135%)')),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1.2),

                    // Tashkeel Toggle
                    SwitchListTile(
                      value: progressService.showTashkeel,
                      onChanged: (val) => progressService.setShowTashkeel(val),
                      title: const Text(
                        'إِظْهَارُ التَّشْكِيلِ التَّامِّ لِلتَّلامِيذِ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      subtitle: const Text(
                        'عرض الحركات الإعرابية على الكلمات والجمل لتسهيل القراءة والنطق السليم',
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
                        'تشغيل أصوات التعزيز الإيجابي عند إجابة التلاميذ الصحيحة في السبورة',
                        style: TextStyle(fontSize: 16),
                      ),
                      secondary: const Icon(Icons.volume_up_rounded, color: AppTheme.accentOrange, size: 32),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 3. NLP Database & Teacher Overrides Section
              _buildSectionHeader('المُحَلِّلُ اللُّغَوِيُّ وَقَاعِدَةُ بَيَانَاتِ الأُسْتَاذِ (Offline NLP Engine):'),
              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: const Icon(Icons.storage_rounded, color: AppTheme.verbColor, size: 34),
                      title: const Text(
                        'تَعْدِيلَاتُ وَقَوَاعِدُ الأُسْتَاذِ المَحْفُوظَةُ مَحَلِّيّاً',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      subtitle: Text(
                        'عدد الكلمات والإعرابات المخصصة المحفوظة: ${NlpDatabaseService.instance.currentOverrides.length} قاعدة',
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: OutlinedButton.icon(
                        onPressed: () => _confirmClearOverrides(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accentOrange,
                          side: const BorderSide(color: AppTheme.accentOrange, width: 2),
                        ),
                        icon: const Icon(Icons.cleaning_services_rounded, size: 20),
                        label: const Text('مَسْحُ التَّعْدِيلَاتِ'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 4. Data Management & Reset Section
              _buildSectionHeader('إِدَارَةُ السِّجِلِّ وَالفُصُولِ الدِّرَاسِيَّةِ:'),
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
                    'تصفير النجوم والدروس المكتملة لبدء درس جديد مع فوج أو فصل آخر',
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () => _confirmReset(context),
                ),
              ),

              const SizedBox(height: 32),

              // About & Information Card
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
                          'مَنْظُومَةُ "بُسْتَانِ النَّحْوِ" - مُسَاعِدُ الأُسْتَاذِ فِي الصَّفِّ',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.primaryDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'مُصَمَّمٌ لِيَكُونَ السَّنَدَ الرَّقْمِيَّ الأَقْوَى لِلأُسْتَاذِ فِي قَاعَةِ العَرْضِ الصَّفِّيِّ (Data Show) '
                      'لِتَقْدِيمِ دُرُوسِ اللُّغَةِ العَرَبِيَّةِ وَالنَّحْوِ وِفْقَ المِنْهَاجِ الوَطَنِيِّ الرَّسْمِيِّ.\n\n'
                      'يَدْعَمُ العَرْضَ بِالْمَرَاحِلِ الخَمْسِ: النَّصُّ القِرَائِيُّ، الرَّصِيدُ اللُّغَوِيُّ، الاسْتِيعَابُ القِرَائِيُّ، '
                      'المُلاحَظَةُ وَالتَّمْيِيزُ، وَالقَاعِدَةُ النَّحْوِيَّةُ المُسْتَنْتَجَةُ، مَعَ 16 نَشَاطاً تَفَاعُلِيّاً مُتَنَوِّعاً '
                      '(اخْتِيَار، سَحْب، تَصْنِيف، تَرْتِيب، وَمُطَابَقَة صُوَر) مَبْنِيَّةً بِالْكَامِلِ دُونَ الحَاجَةِ لِلإِنْتَرْنِت.',
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
