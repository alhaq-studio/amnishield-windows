import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'services/config_syncer.dart';
import 'theme/app_theme.dart';
import 'screens/main_gate_screen.dart';

import 'services/app_usage_service.dart';
import 'services/guardian_http_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Initialize App Usage Tracking Engine & HTTP API Server for Extension Sync
  await AppUsageService.initialize();
  await GuardianHttpService.start();

  // Load initial theme configuration
  final config = await ConfigSyncer.loadLocalConfig();
  themeNotifier.value = config['theme'] ?? 'emerald';

  // Set window size constraints for desktop
  WindowOptions windowOptions = const WindowOptions(
    size: Size(960, 680),
    minimumSize: Size(900, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'AmnShield | Desktop Guardian',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const AmnShieldApp());
}

class AmnShieldApp extends StatelessWidget {
  const AmnShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          title: 'AmnShield Guardian',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(currentTheme),
          home: const MainGateScreen(),
        );
      },
    );
  }
}
