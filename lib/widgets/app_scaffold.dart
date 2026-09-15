import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';

/// Reusable responsive scaffold with custom educational navigation header,
/// star counters, sound toggle, and RTL alignment.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool showHomeButton;
  final ProgressService? progressService;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.showHomeButton = true,
    this.progressService,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            if (progressService != null) ...[
              // Star display badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: AppTheme.accentAmber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${progressService!.progress.totalStars}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            ...?actions,
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: body,
            ),
          ),
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
