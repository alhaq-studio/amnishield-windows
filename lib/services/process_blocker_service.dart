import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ProcessBlockerService {
  static Timer? _timer;
  static bool _isActive = false;
  static List<String> _blockedApps = [];
  static DateTime? _lastNotificationTime;

  static const Set<String> _systemWhitelist = {
    // Windows Core Shell & Subsystems
    'explorer', 'taskmgr', 'svchost', 'lsass', 'services', 'winlogon', 
    'csrss', 'smss', 'wininit', 'spoolsv', 'dwm', 'runtimebroker', 
    'taskhostw', 'taskhost', 'searchindexer', 'searchhost', 'searchapp',
    'ctfmon', 'conhost', 'cmd', 'powershell', 'pwsh', 'sihost', 'fontdrvhost',
    'system', 'idle', 'audiodg', 'memory compression', 'registry',
    'aggregatorhost', 'applicationframehost', 'shellexperiencehost', 'shellhost',
    'startmenuexperiencehost', 'textinputhost', 'useroobebroker', 'systemsettings',
    'lockapp', 'tabtip', 'dllhost', 'unsecapp', 'wlanext', 'wmiprvse',
    'wmiregistrationservice', 'lsaiso', 'ngciso', 'secure system',

    // Windows Accounts & Security Authentication Brokers
    'tokenbroker', 'webaccountmanager', 'msa', 'credprov', 'microsoftaccount', 'accountsd',

    // Windows Widgets, Linux (WSL), & Hyper-V Virtualization
    'widgets', 'widgetservice', 'widgetboard', 'wsl', 'wslhost', 'wslservice',
    'vmmem', 'vmcompute', 'vmms',

    // Windows Package Manager & Windows Store Runtimes
    'winget', 'windowspackagemanagerserver', 'winstore.app', 'winappruntime',
    'storedesktopextension', 'storeexperiencehost', 'purchasedesktopextension',
    'storestub',

    // Windows Device Synchronization & Phone Experience
    'phoneexperiencehost', 'crossdeviceservice', 'crossdeviceresume',
    'crossdevicesettingshost', 'crossdevicestreaminghost', 'crossdevicefileshost',
    'crossdevicesharehost', 'filesynchelper', 'filecoauth', 'onedrive.sync.service',
    'offloaditemservice',

    // Windows Security & Health
    'msmpeng', 'nissrv', 'securityhealthservice', 'securityhealthsystray',
    'sechealthui', 'smartscreen', 'sense', 'mpdefendercoreservice',

    // Windows Administrative & System Tools
    'control', 'regedit', 'mmc', 'msconfig', 'perfmon', 'resmon', 
    'cleanmgr', 'dfrgui', 'mdsched', 'iscsicpl', 'odbcad32', 
    'recoverydrive', 'osrecoveryagent', 'postonce', 'msinfo32', 'psr', 
    'mstsc', 'charmap', 'magnify', 'narrator', 'osk', 'voiceaccess', 
    'livecaptions', 'appverif', 'appcertui', 'gpuview', 'wpa', 'wprui',

    // OEM & Hardware Background Drivers (Dell, Intel, Waves, Realtek)
    'dell.coreservices.client', 'dell.remediation.agent', 'dell.techhub',
    'dell.techhub.analytics.subagent', 'dell.techhub.datamanager.subagent',
    'dell.techhub.diagnostics.subagent', 'dell.techhub.instrumentation.subagent',
    'dell.techhub.instrumentation.userprocess', 'dell.uca.manager', 'dell.update.subagent',
    'dellsupportassistremediationservice', 'supportassistagent', 'dcu-cli',
    'bootpartitionmgmt', 'deployer', 'dellsupportassistcontrolpanel',
    'intelaudioservice', 'inteldisplayumservice', 'intelgraphicssoftware.service',
    'ipf_helper', 'ipf_uf', 'ipfsvc', 'wavesaudioservice', 'wavessysvc64',
    'rtkauduservice64', 'rtkngui64', 'rtkaudioservice', 'igfxhk', 'igfxtray', 'hkcmd',
    'nvcontainer', 'nvdisplay.container', 'nvcplui', 'gameinputsvc', 'gameinputredistservice',

    // Development & IDE Subprocesses (Ripgrep, Build Tools, Compilers)
    'rg', 'ripgrep', 'esbuild', 'tsgo', 'rcedit', 'winpty-agent', 'openconsole', 'vsce-sign',

    // Development Runtimes & App Self-Protection
    'amnshield_flutter', 'amnshieldguardian', 'flutter', 'dart', 'dartaotruntime',
    'dartvm', 'node', 'git', 'adb', 'language_server_windows_x64', 'elevation_service',
    'identity_helper',
  };

  static List<String> _customWhitelist = [];
  static final ValueNotifier<String?> lastBlockedNotifier = ValueNotifier<String?>(null);

  /// Starts or updates active process blocking loop.
  static void updateRules({
    required bool isBlockerActive,
    required List<String> blockedApps,
    List<String>? customWhitelist,
  }) {
    _isActive = isBlockerActive;
    _blockedApps = List<String>.from(blockedApps);
    if (customWhitelist != null) {
      _customWhitelist = customWhitelist.map((e) => e.replaceAll('.exe', '').trim().toLowerCase()).toList();
    }

    if (!_isActive || _blockedApps.isEmpty) {
      _timer?.cancel();
      _timer = null;
      return;
    }

    if (_timer == null || !_timer!.isActive) {
      // Run process enforcement check every 1 second
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _enforceBlocking());
      // Run immediate check
      _enforceBlocking();
    }
  }

  static void _notifyBlocked(String cleanName) {
    final now = DateTime.now();
    if (_lastNotificationTime != null && now.difference(_lastNotificationTime!) < const Duration(seconds: 5)) {
      return; // 5-second cooldown to prevent infinite loop / dialog spamming
    }
    _lastNotificationTime = now;
    lastBlockedNotifier.value = cleanName;
  }

  /// Executes process termination for all blocked applications.
  static Future<void> _enforceBlocking() async {
    if (!_isActive || _blockedApps.isEmpty) return;

    for (final rawApp in _blockedApps) {
      final app = rawApp.trim().toLowerCase();
      if (app.isEmpty) continue;

      final cleanName = app.replaceAll('.exe', '').trim();

      // Guard against system whitelist and user custom exceptions
      if (_systemWhitelist.contains(cleanName) || _customWhitelist.contains(cleanName)) continue;

      try {
        // 1. Direct taskkill by exact image name (e.g. taskkill /F /IM whatsapp.exe)
        final targetExe = app.endsWith('.exe') ? app : '$app.exe';
        final res = await Process.run('taskkill', ['/F', '/IM', targetExe]);

        final stdout1 = res.stdout.toString().toUpperCase();
        if (res.exitCode == 0 && stdout1.contains('SUCCESS') && stdout1.contains('TERMINATED')) {
          _notifyBlocked(cleanName);
        }

        // 2. Wildcard taskkill by prefix to kill UWP / Store variants (e.g. whatsapp.root.exe, instagram.app.exe)
        if (cleanName.length >= 3) {
          final prefix = cleanName.split('.')[0];
          if (prefix.length >= 3 && !_systemWhitelist.contains(prefix)) {
            final res2 = await Process.run('taskkill', ['/F', '/FI', 'IMAGENAME eq $prefix*']);
            final stdout2 = res2.stdout.toString().toUpperCase();
            if (res2.exitCode == 0 && stdout2.contains('SUCCESS') && stdout2.contains('TERMINATED')) {
              _notifyBlocked(cleanName);
            }
          }
        }
      } catch (e) {
        debugPrint('Process termination error for $app: $e');
      }
    }
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
