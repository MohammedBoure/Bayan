import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Modal dialog providing intelligent feedback for activities as specified in tasks.md [06].
/// Scaled for Data Show presentation in classroom lectures.
class FeedbackDialog extends StatelessWidget {
  final bool isCorrect;
  final String title;
  final String message;
  final String ruleSummary;
  final VoidCallback onContinue;
  final VoidCallback? onRetry;

  const FeedbackDialog({
    super.key,
    required this.isCorrect,
    required this.title,
    required this.message,
    required this.ruleSummary,
    required this.onContinue,
    this.onRetry,
  });

  static Future<void> show({
    required BuildContext context,
    required bool isCorrect,
    required String title,
    required String message,
    required String ruleSummary,
    required VoidCallback onContinue,
    VoidCallback? onRetry,
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
        onRetry: onRetry == null
            ? null
            : () {
                Navigator.of(ctx).pop();
                onRetry();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Header
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCorrect ? Icons.emoji_events_rounded : Icons.lightbulb_rounded,
                    color: themeColor,
                    size: 54,
                  ),
                ),
                const SizedBox(height: 20),

                // Title (أحسنت! إجابة صحيحة)
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28, // High visibility
                    fontWeight: FontWeight.w900,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Detailed pedagogical feedback
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),

                // Rule box
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_rounded, color: AppTheme.primaryTeal, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ruleSummary,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Actions: Retry and/or Continue
                if (!isCorrect && onRetry != null)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 460;
                      final retryBtn = SizedBox(
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          icon: const Icon(Icons.replay_rounded, size: 28),
                          label: const Text(
                            'إِعَادَةُ المُحَاوَلَةِ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );

                      final continueBtn = SizedBox(
                        height: 60,
                        child: OutlinedButton.icon(
                          onPressed: onContinue,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryTeal, width: 2.5),
                            foregroundColor: AppTheme.primaryTeal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 28),
                          label: const Text(
                            'الإِكْمَالُ وَالمُتَابَعَةُ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            retryBtn,
                            const SizedBox(height: 12),
                            continueBtn,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: retryBtn),
                          const SizedBox(width: 16),
                          Expanded(child: continueBtn),
                        ],
                      );
                    },
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 28),
                      label: const Text(
                        'مُتَابَعَةُ التَّعَلُّمِ',
                        style: TextStyle(
                          fontSize: 22,
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
      ),
    );
  }
}
