import 'package:flutter/material.dart';
import '../screens/nlp_lab_screen.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';

/// Teacher Presentation Control Bar (شريط أدوات الأستاذ الصفي)
/// Sits at the top or bottom of the lesson screen for instantaneous classroom controls.
class TeacherToolbarWidget extends StatelessWidget {
  final ProgressService progressService;
  final VoidCallback? onToggleAnswers;
  final bool areAnswersRevealed;
  final VoidCallback? onToggleSpotlight;
  final bool isSpotlightActive;

  const TeacherToolbarWidget({
    super.key,
    required this.progressService,
    this.onToggleAnswers,
    this.areAnswersRevealed = false,
    this.onToggleSpotlight,
    this.isSpotlightActive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!progressService.teacherModeEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark slate for clear distinction as teacher controls
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          // Teacher Mode Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.school_rounded, color: AppTheme.accentAmber, size: 24),
              SizedBox(width: 8),
              Text(
                'لَوْحَةُ تَحَكُّمِ الأُسْتَاذِ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),

          // Action Buttons
          Wrap(
            spacing: 8,
            children: [
              // Reveal/Hide Answers
              if (onToggleAnswers != null)
                ElevatedButton.icon(
                  onPressed: onToggleAnswers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: areAnswersRevealed ? AppTheme.accentOrange : const Color(0xFF334155),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(
                    areAnswersRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 20,
                  ),
                  label: Text(
                    areAnswersRevealed ? 'إِخْفَاءُ الحُلُولِ' : 'إِظْهَارُ الحُلُولِ',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),

              // Spotlight Focus
              if (onToggleSpotlight != null)
                IconButton(
                  tooltip: isSpotlightActive ? 'إلغاء تسليط الضوء' : 'تسليط الضوء على الفقرات',
                  icon: Icon(
                    Icons.highlight_rounded,
                    color: isSpotlightActive ? AppTheme.accentAmber : Colors.white70,
                    size: 24,
                  ),
                  onPressed: onToggleSpotlight,
                ),

              // Quick NLP Lab Launcher
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NlpLabScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.verbColor, width: 1.8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.smart_toy_rounded, color: AppTheme.verbColor, size: 20),
                label: const Text('المُحَلِّلُ الآلِيُّ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
