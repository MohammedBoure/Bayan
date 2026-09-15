import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Modal dialog providing intelligent feedback for activities as specified in tasks.md [06].
class FeedbackDialog extends StatelessWidget {
  final bool isCorrect;
  final String title;
  final String message;
  final String ruleSummary;
  final VoidCallback onContinue;

  const FeedbackDialog({
    super.key,
    required this.isCorrect,
    required this.title,
    required this.message,
    required this.ruleSummary,
    required this.onContinue,
  });

  static Future<void> show({
    required BuildContext context,
    required bool isCorrect,
    required String title,
    required String message,
    required String ruleSummary,
    required VoidCallback onContinue,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FeedbackDialog(
        isCorrect: isCorrect,
        title: title,
        message: message,
        ruleSummary: ruleSummary,
        onContinue: () {
          Navigator.of(ctx).pop();
          onContinue();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = isCorrect ? AppTheme.successGreen : AppTheme.accentOrange;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.emoji_events_rounded : Icons.lightbulb_rounded,
                  color: themeColor,
                  size: 42,
                ),
              ),
              const SizedBox(height: 16),

              // Title (e.g. أحسنت! إجابة صحيحة)
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 12),

              // Detailed pedagogical feedback
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textDark,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),

              // Rule box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_rounded, color: AppTheme.primaryTeal, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ruleSummary,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Button: متابعة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  label: const Text(
                    'مُتَابَعَة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
