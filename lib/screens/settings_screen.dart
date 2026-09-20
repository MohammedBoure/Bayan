import 'package:flutter/material.dart';
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
          title: const Text('اسْتِعَادَةُ الإِعْدَادَاتِ الاِفْتِرَاضِيَّةِ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          content: const Text(
            'هَلْ تَرْغَبُ فِي إِعَادَةِ ضَبْطِ جَمِيعِ إِعْدَادَاتِ العَرْضِ (حَجْمُ البَرْنَامِجِ وَالوَاجِهَةِ، حَجْمُ الخَطِّ، الصَّوْتُ، المُؤَقِّتُ) إِلَى الوَضْعِ الاِفْتِرَاضِيِّ؟',
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إِلْغَاء', style: TextStyle(fontSize: 18)),
            ),
            ElevatedButton(
              onPressed: () async {
                await progressService.resetSettingsToDefault();
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تَمَّتِ اسْتِعَادَةُ الإِعْدَادَاتِ الاِفْتِرَاضِيَّةِ بِنَجَاحٍ.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
              child: const Text('نَعَمْ، اسْتِعَادَةُ الاِفْتِرَاضِيِّ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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

              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.8),
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
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 2. Display Profiles & Screen Adaptation Section
              _buildSectionHeader('أَوْضَاعُ العَرْضِ الجَاهِزَةُ لِمُخْتَلِفِ الشَّاشَاتِ (Hardware Profiles):'),
              const SizedBox(height: 8),
              const Text(
                'اخْتَرْ وَضْعَ العَرْضِ المُلائِمَ لِشَاشَتِكَ بِنَقْرَةٍ وَاحِدَةٍ لِضَبْطِ حَجْمِ البَرْنَامِجِ وَالخَطِّ مَعاً، أَوْ قُمْ بِتَعْدِيلِهِمَا يَدَوِيّاً أَدْنَاهُ:',
                style: TextStyle(fontSize: 16, color: AppTheme.textMuted, height: 1.5),
              ),
              const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 750;
                  final profiles = [
                    _ProfileData(
                      title: 'حَاسُوبٌ مَحْمُولٌ',
                      subtitle: 'شَاشَاتٌ صَغِيرَةٌ (13-15 بوصة)\nواجهة: 85% | خط: 100%',
                      icon: Icons.laptop_chromebook_rounded,
                      uiScale: 0.85,
                      fontScale: 1.0,
                    ),
                    _ProfileData(
                      title: 'مَكْتَبِيٌّ قِيَاسِيٌّ',
                      subtitle: 'شَاشَاتٌ مَكْتَبِيَّةٌ (1080p)\nواجهة: 100% | خط: 100%',
                      icon: Icons.desktop_windows_rounded,
                      uiScale: 1.0,
                      fontScale: 1.0,
                    ),
                    _ProfileData(
                      title: 'سَبُّورَةٌ ذَكِيَّةٌ',
                      subtitle: 'شَاشَاتٌ لَمْسِيَّةٌ تَفَاعُلِيَّةٌ\nواجهة: 115% | خط: 115%',
                      icon: Icons.touch_app_rounded,
                      uiScale: 1.15,
                      fontScale: 1.15,
                    ),
                    _ProfileData(
                      title: 'جِهَازُ عَرْضٍ (Data Show)',
                      subtitle: 'بْرُوجِكْتُور القَاعَةِ الصَّفِّيَّةِ\nواجهة: 125% | خط: 130%',
                      icon: Icons.cast_for_education_rounded,
                      uiScale: 1.25,
                      fontScale: 1.30,
                    ),
                  ];

                  if (isWide) {
                    return Row(
                      children: profiles.map((p) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _buildProfileCard(p),
                          ),
                        );
                      }).toList(),
                    );
                  } else {
                    return Column(
                      children: profiles.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildProfileCard(p),
                        );
                      }).toList(),
                    );
                  }
                },
              ),

              const SizedBox(height: 32),

              // 3. Manual Scaling & Display Customization Section
              _buildSectionHeader('تَخْصِيصُ مَقَايِيسِ البَرْنَامِجِ وَالخُطُوطِ (Custom Display Scaling):'),
              const SizedBox(height: 14),

              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.8),
                ),
                child: Column(
                  children: [
                    // A. General Application UI Scaling
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.aspect_ratio_rounded, color: AppTheme.primaryTeal, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'حَجْمُ البَرْنَامِجِ وَالوَاجِهَةِ بِصِفَةٍ عَامَّةٍ (App & UI Scale)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'تَكْبِيرُ أَوْ تَصْغِيرُ كَافَّةِ عَنَاصِرِ الوَاجِهَةِ (الأَزْرَار، البِطَاقَات، القَوَائِم، التَّبَاعُد) لِمُلائَمَةِ شَاشَتِكَ',
                                      style: TextStyle(fontSize: 15, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Scale Stepper Control
                              _buildScaleStepper(
                                currentValue: progressService.uiScale,
                                onDecrease: () {
                                  final newVal = (progressService.uiScale - 0.05).clamp(0.75, 1.45);
                                  progressService.setUiScale(double.parse(newVal.toStringAsFixed(2)));
                                },
                                onIncrease: () {
                                  final newVal = (progressService.uiScale + 0.05).clamp(0.75, 1.45);
                                  progressService.setUiScale(double.parse(newVal.toStringAsFixed(2)));
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Quick Presets Row for UI Scale
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildScaleChip(
                                label: '85% (مَحْمُول / مُدْمَج)',
                                isSelected: (progressService.uiScale - 0.85).abs() < 0.02,
                                onTap: () => progressService.setUiScale(0.85),
                              ),
                              _buildScaleChip(
                                label: '90%',
                                isSelected: (progressService.uiScale - 0.90).abs() < 0.02,
                                onTap: () => progressService.setUiScale(0.90),
                              ),
                              _buildScaleChip(
                                label: '100% (قِيَاسِي - افْتِرَاضِي)',
                                isSelected: (progressService.uiScale - 1.00).abs() < 0.02,
                                onTap: () => progressService.setUiScale(1.00),
                              ),
                              _buildScaleChip(
                                label: '115% (سَبُّورَة ذَكِيَّة)',
                                isSelected: (progressService.uiScale - 1.15).abs() < 0.02,
                                onTap: () => progressService.setUiScale(1.15),
                              ),
                              _buildScaleChip(
                                label: '125% (بْرُوجِكْتُور صَفِّي)',
                                isSelected: (progressService.uiScale - 1.25).abs() < 0.02,
                                onTap: () => progressService.setUiScale(1.25),
                              ),
                              _buildScaleChip(
                                label: '135% (شَاشَة عِمْلاقَة)',
                                isSelected: (progressService.uiScale - 1.35).abs() < 0.02,
                                onTap: () => progressService.setUiScale(1.35),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1.2),

                    // B. Educational Font Size Scaling
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.format_size_rounded, color: AppTheme.primaryTeal, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'حَجْمُ الخُطُوطِ وَالنُّصُوصِ التَّعْلِيمِيَّةِ (Font Size Scale)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'تَكْبِيرُ حَجْمِ النُّصُوصِ، الكَلِمَاتِ، وَالحَرَكَاتِ الإِعْرَابِيَّةِ لِتَيْسِيرِ القِرَاءَةِ عَلَى التَّلَامِيذِ',
                                      style: TextStyle(fontSize: 15, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Font Stepper Control
                              _buildScaleStepper(
                                currentValue: progressService.fontSizeScale,
                                onDecrease: () {
                                  final newVal = (progressService.fontSizeScale - 0.05).clamp(0.80, 1.60);
                                  progressService.setFontSizeScale(double.parse(newVal.toStringAsFixed(2)));
                                },
                                onIncrease: () {
                                  final newVal = (progressService.fontSizeScale + 0.05).clamp(0.80, 1.60);
                                  progressService.setFontSizeScale(double.parse(newVal.toStringAsFixed(2)));
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Quick Presets Row for Font Scale
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildScaleChip(
                                label: '85% (صَغِير)',
                                isSelected: (progressService.fontSizeScale - 0.85).abs() < 0.02,
                                onTap: () => progressService.setFontSizeScale(0.85),
                              ),
                              _buildScaleChip(
                                label: '100% (عَادِي - افْتِرَاضِي)',
                                isSelected: (progressService.fontSizeScale - 1.00).abs() < 0.02,
                                onTap: () => progressService.setFontSizeScale(1.00),
                              ),
                              _buildScaleChip(
                                label: '115% (مُتَوَسِّط)',
                                isSelected: (progressService.fontSizeScale - 1.15).abs() < 0.02,
                                onTap: () => progressService.setFontSizeScale(1.15),
                              ),
                              _buildScaleChip(
                                label: '130% (كَبِير)',
                                isSelected: (progressService.fontSizeScale - 1.30).abs() < 0.02,
                                onTap: () => progressService.setFontSizeScale(1.30),
                              ),
                              _buildScaleChip(
                                label: '145% (بْرُوجِكْتُور صَفِّي)',
                                isSelected: (progressService.fontSizeScale - 1.45).abs() < 0.02,
                                onTap: () => progressService.setFontSizeScale(1.45),
                              ),
                              _buildScaleChip(
                                label: '160% (ضَخْم)',
                                isSelected: (progressService.fontSizeScale - 1.60).abs() < 0.02,
                                onTap: () => progressService.setFontSizeScale(1.60),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1.2),

                    // C. Arabic Font Family Selector
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: const Icon(Icons.font_download_rounded, color: AppTheme.primaryTeal, size: 34),
                      title: const Text(
                        'نَوْعُ الخَطِّ العَرَبِيِّ (Arabic Font Style)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      subtitle: const Text(
                        'اختر الخط المناسب للأطفال؛ خط النسخ المدرسي مخصص لسلامة رسم الحروف والتشكيل',
                        style: TextStyle(fontSize: 16),
                      ),
                      trailing: DropdownButton<String>(
                        value: progressService.selectedFontFamily,
                        borderRadius: BorderRadius.circular(16),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                        onChanged: (newFamily) {
                          if (newFamily != null) {
                            progressService.setSelectedFontFamily(newFamily);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'NotoNaskhArabic',
                            child: Text('خَطُّ النَّسْخِ المَدْرَسِيِّ (مُوصَى بِهِ للأَطْفَال)'),
                          ),
                          DropdownMenuItem(
                            value: 'ReadexPro',
                            child: Text('خَطُّ القِرَاءَةِ التَّعْلِيمِيُّ (Readex Pro)'),
                          ),
                          DropdownMenuItem(
                            value: 'Amiri',
                            child: Text('خَطُّ النَّسْخِ الأَصِيلُ (أميري)'),
                          ),
                          DropdownMenuItem(
                            value: 'Cairo',
                            child: Text('الخَطُّ الرَّقْمِيُّ (Cairo)'),
                          ),
                        ],
                      ),
                    ),

                    // D. Live Interactive Preview Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.35), width: 1.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.preview_rounded, size: 22, color: AppTheme.primaryTeal),
                              const SizedBox(width: 8),
                              const Text(
                                'مُعَايَنَةٌ حَيَّةٌ لِلْخَطِّ وَحَجْمِ البَرْنَامِجِ الحَالِيِّ:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTeal,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'الوَاجِهَةُ: ${(progressService.uiScale * 100).round()}%  |  الخَطُّ: ${(progressService.fontSizeScale * 100).round()}%',
                                  style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            progressService.showTashkeel
                                ? '« قَرَأَ التِّلْمِيذُ النَّجِيبُ نَصَّ الْقِرَاءَةِ بِتَمَعُّنٍ، وَعَرَّفَ أَرْكَانَ الجُمْلَةِ الفِعْلِيَّةِ بِوُضُوحٍ. »'
                                : '« قرأ التلميذ النجيب نص القراءة بتمعن، وعرف أركان الجملة الفعلية بوضوح. »',
                            style: TextStyle(
                              fontFamily: progressService.selectedFontFamily,
                              fontSize: 22,
                              height: 1.8,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: const [
                              _GrammarTagBadge(label: 'فِعْلٌ مَاضٍ', color: AppTheme.verbColor),
                              _GrammarTagBadge(label: 'فَاعِلٌ مَرْفُوعٌ', color: AppTheme.subjectColor),
                              _GrammarTagBadge(label: 'مَفْعُولٌ بِهِ', color: AppTheme.objectColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1.2),

                    // E. Tashkeel Toggle
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

                    // F. Sound Effects Toggle
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

              // 4. Reset Settings Section
              _buildSectionHeader('إِعَادَةُ الضَّبْطِ:'),
              const SizedBox(height: 14),

              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: const Icon(Icons.restart_alt_rounded, color: AppTheme.primaryTeal, size: 36),
                  title: const Text(
                    'اسْتِعَادَةُ إِعْدَادَاتِ العَرْضِ الاِفْتِرَاضِيَّةِ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal, fontSize: 20),
                  ),
                  subtitle: const Text(
                    'إعادة ضبط حجم الخط، المؤقت، والصوت إلى القيم الأولية الافتراضية',
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

  Widget _buildProfileCard(_ProfileData profile) {
    final isSelected = (progressService.uiScale - profile.uiScale).abs() < 0.03 &&
        (progressService.fontSizeScale - profile.fontScale).abs() < 0.03;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          progressService.setDisplayProfile(
            uiScale: profile.uiScale,
            fontScale: profile.fontScale,
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryTeal.withValues(alpha: 0.10) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryTeal : const Color(0xFFCBD5E1),
              width: isSelected ? 2.4 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryTeal : AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  profile.icon,
                  color: isSelected ? Colors.white : AppTheme.primaryTeal,
                  size: 28,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                profile.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? AppTheme.primaryTeal : AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                profile.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryDark : AppTheme.textMuted,
                  height: 1.35,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'مُفَعَّلٌ حَالِيّاً ✓',
                    style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaleStepper({
    required double currentValue,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.primaryTeal, size: 26),
            tooltip: 'تَصْغِير',
            onPressed: onDecrease,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              '${(currentValue * 100).round()}%',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryTeal, size: 26),
            tooltip: 'تَكْبِير',
            onPressed: onIncrease,
          ),
        ],
      ),
    );
  }

  Widget _buildScaleChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryTeal : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            color: isSelected ? Colors.white : AppTheme.textDark,
          ),
        ),
      ),
    );
  }
}

class _ProfileData {
  final String title;
  final String subtitle;
  final IconData icon;
  final double uiScale;
  final double fontScale;

  const _ProfileData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.uiScale,
    required this.fontScale,
  });
}

class _GrammarTagBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _GrammarTagBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
