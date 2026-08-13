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
      // Run lightweight process enforcement check every 2.5 seconds
      _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) => _enforceBlocking());
      // Run immediate check
      _enforceBlocking();
    }
  }

  static void _notifyBlocked(String cleanName) {
    final now = DateTime.now();
    if (_lastNotificationTime != null && now.difference(_lastNotificationTime!) < const Duration(seconds: 5)) {
      return; // 5-second cooldown to prevent notification spam
    }
    _lastNotificationTime = now;
    lastBlockedNotifier.value = cleanName;
  }

  /// Executes process termination ONLY for apps currently running in RAM.
  static Future<void> _enforceBlocking() async {
    if (!_isActive || _blockedApps.isEmpty) return;

    try {
      // 1. Get snapshot of currently active processes in ONE lightweight call
      final res = await Process.run('tasklist', ['/FO', 'CSV', '/NH']);
      if (res.exitCode != 0) return;

      final outputLines = res.stdout.toString().split('\n');
      final runningProcessNames = <String>{};

      for (final line in outputLines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('","');
        if (parts.isNotEmpty) {
          final procName = parts[0].replaceAll('"', '').trim().toLowerCase();
          if (procName.isNotEmpty) {
            runningProcessNames.add(procName);
          }
        }
      }

      // 2. Cross-reference blocked apps against active running process names
      for (final rawApp in _blockedApps) {
        final app = rawApp.trim().toLowerCase();
        if (app.isEmpty) continue;

        final cleanName = app.replaceAll('.exe', '').trim();
        final targetExe = app.endsWith('.exe') ? app : '$app.exe';

        // Guard against system whitelist and user custom exceptions
        if (_systemWhitelist.contains(cleanName) || _customWhitelist.contains(cleanName)) continue;

        // ONLY execute taskkill IF the process is actually running in RAM!
        if (runningProcessNames.contains(targetExe) || runningProcessNames.contains(cleanName)) {
          final killRes = await Process.run('taskkill', ['/F', '/IM', targetExe]);
          if (killRes.exitCode == 0) {
            _notifyBlocked(cleanName);
          }
        }
      }
    } catch (e) {
      debugPrint('[ProcessBlocker] Enforcement error: $e');
    }
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
