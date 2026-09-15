import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/progress_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final progressService = ProgressService();
  await progressService.init();

  runApp(NahwApp(progressService: progressService));
}

/// Root Application Widget for the Arabic Grammar Educational System.
class NahwApp extends StatelessWidget {
  final ProgressService progressService;

  const NahwApp({
    super.key,
    required this.progressService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بستان النحو العربي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: HomeScreen(progressService: progressService),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
