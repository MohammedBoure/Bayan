import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';

/// Teacher Presentation Header Actions (عناصر لوحة تحكم الأستاذ في شريط عنوان الدرس)
/// Positioned directly on the side of the AppBar to save vertical screen space for projector display.
class TeacherHeaderActions extends StatelessWidget {
  final ProgressService progressService;
  final VoidCallback? onToggleAnswers;
  final bool areAnswersRevealed;
  final VoidCallback? onToggleSpotlight;
  final bool isSpotlightActive;
  final VoidCallback? onToggleTashkeel;
  final bool? showTashkeel;
  final VoidCallback? onToggleAudio;
  final bool isAudioActive;
  final bool hasAudio;
  final bool isAudioPlaying;

  const TeacherHeaderActions({
    super.key,
    required this.progressService,
    this.onToggleAnswers,
    this.areAnswersRevealed = false,
    this.onToggleSpotlight,
    this.isSpotlightActive = false,
    this.onToggleTashkeel,
    this.showTashkeel,
    this.onToggleAudio,
    this.isAudioActive = false,
    this.hasAudio = false,
    this.isAudioPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!progressService.teacherModeEnabled) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Audio Toggle button (شريط المقطع الصوتي)
        if (hasAudio && onToggleAudio != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton.icon(
              onPressed: onToggleAudio,
              style: TextButton.styleFrom(
                backgroundColor: isAudioActive
                    ? AppTheme.successGreen
                    : Colors.black.withValues(alpha: 0.25),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isAudioActive ? Colors.white : Colors.white24,
                    width: 1.2,
                  ),
                ),
              ),
              icon: Icon(
                isAudioPlaying
                    ? Icons.volume_up_rounded
                    : (isAudioActive ? Icons.headphones_rounded : Icons.headset_mic_rounded),
                size: 19,
                color: isAudioActive
                    ? Colors.white
                    : (isAudioPlaying ? AppTheme.accentAmber : Colors.white),
              ),
              label: Text(
                isAudioActive ? 'إِخْفَاءُ الصَّوْتِ' : 'المَقْطَعُ الصَّوْتِيُّ',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        // Reveal / Hide Answers button
        if (onToggleAnswers != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton.icon(
              onPressed: onToggleAnswers,
              style: TextButton.styleFrom(
                backgroundColor: areAnswersRevealed
                    ? AppTheme.accentOrange
                    : Colors.black.withValues(alpha: 0.25),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: areAnswersRevealed ? AppTheme.accentAmber : Colors.white24,
                    width: 1.2,
                  ),
                ),
              ),
              icon: Icon(
                areAnswersRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 19,
                color: Colors.white,
              ),
              label: Text(
                areAnswersRevealed ? 'إِخْفَاءُ الحُلُولِ' : 'إِظْهَارُ الحُلُولِ',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        // Spotlight Focus Button
        if (onToggleSpotlight != null)
          IconButton(
            tooltip: isSpotlightActive ? 'إلغاء تسليط الضوء على الفقرات' : 'تسليط الضوء على الفقرات',
            icon: Icon(
              Icons.highlight_rounded,
              color: isSpotlightActive ? AppTheme.accentAmber : Colors.white,
              size: 25,
            ),
            onPressed: onToggleSpotlight,
          ),

        // Tashkeel Toggle Button
        if (onToggleTashkeel != null && showTashkeel != null)
          IconButton(
            tooltip: showTashkeel! ? 'إخفاء التشكيل' : 'إظهار التشكيل',
            icon: Icon(
              showTashkeel! ? Icons.format_color_text_rounded : Icons.text_fields_rounded,
              color: Colors.white,
              size: 25,
            ),
            onPressed: onToggleTashkeel,
          ),
      ],
    );
  }
}

/// Backward compatibility alias pointing to TeacherHeaderActions
typedef TeacherToolbarWidget = TeacherHeaderActions;
