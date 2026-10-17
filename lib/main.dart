import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:app_links/app_links.dart';
import 'services/config_syncer.dart';
import 'services/license_service.dart';
import 'theme/app_theme.dart';
import 'screens/main_gate_screen.dart';
import 'services/app_usage_service.dart';
import 'services/guardian_http_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  if (isDesktop) {
    await windowManager.ensureInitialized();
  }

  // Initialize App Usage Tracking Engine & HTTP API Server for Extension Sync
  await AppUsageService.initialize();

  if (!kIsWeb) {
    await GuardianHttpService.start();
  }

  // Load initial theme configuration
  final config = await ConfigSyncer.loadLocalConfig();
  themeNotifier.value = config['theme'] ?? 'emerald';

  if (isDesktop) {
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
  }

  runApp(const AmnShieldApp());
}

class AmnShieldApp extends StatefulWidget {
  const AmnShieldApp({super.key});

  @override
  State<AmnShieldApp> createState() => _AmnShieldAppState();
}

class _AmnShieldAppState extends State<AmnShieldApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was launched via protocol URL
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _processDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('[DeepLink] Error fetching initial link: $e');
    }

    // Subscribe to incoming stream links
    _appLinks.uriLinkStream.listen((uri) {
      _processDeepLink(uri);
    }, onError: (err) {
      debugPrint('[DeepLink] Stream listener error: $err');
    });
  }

  void _processDeepLink(Uri uri) async {
    if (uri.scheme == 'amnshield' && uri.host == 'activate') {
      final key = uri.queryParameters['key'];
      if (key != null && key.isNotEmpty) {
        final success = await LicenseService.activateLicense(key);
        debugPrint('[DeepLink] One-click activation result: $success');
      }
    }
  }

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
