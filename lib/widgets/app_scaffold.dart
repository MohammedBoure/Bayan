import 'package:flutter/material.dart';
import '../services/progress_service.dart';

/// Reusable responsive scaffold optimized for Data Show projectors and lecture halls.
/// Uses expansive widescreen horizontal space, high-contrast badges, and large touch targets.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool showHomeButton;
  final double maxWidth;
  final ProgressService? progressService;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.showHomeButton = true,
    this.maxWidth = 1450, // Expansive widescreen width for Data Show displays
    this.progressService,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 68,
          title: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          actions: [
            // Data Show / Classroom Mode Indicator Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tv_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'شَاشَةُ العَرْضِ (Data Show)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...?actions,
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: body,
            ),
          ),
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
