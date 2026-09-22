import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/license_service.dart';
import 'services/nlp_database_service.dart';
import 'services/progress_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite cache and user correction loop
  await NlpDatabaseService.instance.init();

  final progressService = ProgressService();
  await progressService.init();

  final licenseService = LicenseService();
  await licenseService.init();

  runApp(NahwApp(
    progressService: progressService,
    licenseService: licenseService,
  ));
}

/// Root Application Widget for the Arabic Grammar Educational System.
class NahwApp extends StatelessWidget {
  final ProgressService progressService;
  final LicenseService? licenseService;

  const NahwApp({
    super.key,
    required this.progressService,
    this.licenseService,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLicense = licenseService ?? LicenseService();

    return ListenableBuilder(
      listenable: Listenable.merge([progressService, effectiveLicense]),
      builder: (context, _) {
        final uiScale = progressService.uiScale;
        final fontScale = progressService.fontSizeScale;

        return MaterialApp(
          title: 'Bayan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildTheme(fontFamily: progressService.selectedFontFamily),
          home: HomeScreen(
            progressService: progressService,
            licenseService: effectiveLicense,
          ),
          builder: (context, child) {
            if (child == null) return const SizedBox();

            final mediaQuery = MediaQuery.of(context);

            Widget appContent = child;
            if ((uiScale - 1.0).abs() > 0.001) {
              appContent = LayoutBuilder(
                builder: (context, constraints) {
                  if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
                    return MediaQuery(
                      data: mediaQuery.copyWith(
                        textScaler: TextScaler.linear(fontScale),
                      ),
                      child: child,
                    );
                  }

                  final scaledWidth = constraints.maxWidth / uiScale;
                  final scaledHeight = constraints.maxHeight / uiScale;

                  return MediaQuery(
                    data: mediaQuery.copyWith(
                      size: Size(scaledWidth, scaledHeight),
                      textScaler: TextScaler.linear(fontScale),
                    ),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: scaledWidth,
                        height: scaledHeight,
                        child: child,
                      ),
                    ),
                  );
                },
              );
            } else {
              appContent = MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(fontScale),
                ),
                child: appContent,
              );
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: appContent,
            );
          },
        );
      },
    );
  }
}
