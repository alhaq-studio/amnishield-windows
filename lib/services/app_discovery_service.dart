import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AppItem {
  final String name;
  final String executable;
  final String? path;
  final String? iconBase64;

  const AppItem({
    required this.name,
    required this.executable,
    this.path,
    this.iconBase64,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppItem &&
          runtimeType == other.runtimeType &&
          executable.toLowerCase() == other.executable.toLowerCase();

  @override
  int get hashCode => executable.toLowerCase().hashCode;
}

class AppDiscoveryService {
  static const Set<String> systemWhitelist = {
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

    // Linux & macOS System Whitelist
    'systemd', 'init', 'bash', 'zsh', 'sh', 'python', 'python3', 'Xorg', 'wayland',
    'gnome-shell', 'dock', 'finder', 'launchd', 'windowserver', 'syslog',

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

  static final RegExp _noiseFilter = RegExp(
    r'uninstall|setup|installer|unins000|helper|update|crash-reporter|elevate|vcredist|winpty|esbuild|tsgo|rcedit|compil32|iscc|islzma|iediag|msoadfsb|msoasb|msoxmled|wabmig|pad\.|storestub|framework|redist|vc_redist|subagent|driver|ripgrep|^rg$',
    caseSensitive: false,
  );

  /// Cross-platform App Discovery engine (Windows, macOS, Linux, Web)
  static Future<List<AppItem>> getInstalledApps() async {
    if (kIsWeb) {
      return const [
        AppItem(name: 'Google Chrome', executable: 'chrome'),
        AppItem(name: 'Mozilla Firefox', executable: 'firefox'),
        AppItem(name: 'Brave Browser', executable: 'brave'),
        AppItem(name: 'Discord', executable: 'discord'),
        AppItem(name: 'Spotify', executable: 'spotify'),
        AppItem(name: 'VS Code', executable: 'code'),
      ];
    }

    if (Platform.isWindows) {
      return _getInstalledAppsWindows();
    } else if (Platform.isMacOS) {
      return _getInstalledAppsMac();
    } else if (Platform.isLinux) {
      return _getInstalledAppsLinux();
    }

    return [];
  }

  static Future<List<AppItem>> _getInstalledAppsWindows() async {
    final Map<String, AppItem> installedMap = {};

    try {
      const psScript = r'''
$apps = [System.Collections.Generic.List[PSCustomObject]]::new()

function Add-App ($name, $exePath) {
    if ([string]::IsNullOrWhiteSpace($name)) { return }

    $cleanPath = ""
    if (-not [string]::IsNullOrWhiteSpace($exePath)) {
        $cleanPath = $exePath.Split(',')[0].Trim('"').Trim()
    }

    $exeName = ""
    if ($cleanPath.EndsWith(".exe", [System.StringComparison]::OrdinalIgnoreCase)) {
        $exeName = [System.IO.Path]::GetFileName($cleanPath).ToLower()
    } elseif ($name -and -not $name.Contains(' ')) {
        $exeName = ($name.ToLower() + ".exe")
    }

    if ($exeName -and $exeName.EndsWith(".exe")) {
        if ($exeName -notmatch 'uninstall|setup|installer|unins000|helper|update|crash-reporter|elevate|vcredist|winpty|esbuild|tsgo|rcedit|compil32|iscc|islzma|storestub|redist|vc_redist|subagent') {
            $apps.Add([PSCustomObject]@{ Name = $name.Trim(); Executable = $exeName; Path = $cleanPath })
        }
    }
}

try {
    Get-AppxPackage | ForEach-Object {
        if (-not $_.IsFramework -and $_.NonRemovable -ne $true) {
            $rawName = $_.Name
            $displayName = if ($rawName.Contains('.')) { $rawName.Split('.')[-1] } else { $rawName }

            $manifest = Get-AppxPackageManifest $_ -ErrorAction SilentlyContinue
            if ($manifest -and $manifest.Package.Properties.DisplayName) {
                $propName = $manifest.Package.Properties.DisplayName
                if ($propName -and -not $propName.StartsWith("ms-resource:")) {
                    $displayName = $propName
                }
            }

            $exe = ($displayName.ToLower().Replace(' ', '') + ".exe")
            try {
                if ($manifest.Package.Applications.Application.Executable) {
                    $exe = [System.IO.Path]::GetFileName($manifest.Package.Applications.Application.Executable).ToLower()
                }
            } catch {}

            Add-App $displayName $exe
        }
    }
} catch {}

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
foreach ($p in $regPaths) {
    Get-ItemProperty $p -ErrorAction SilentlyContinue | ForEach-Object {
        $name = $_.DisplayName
        if ($name) {
            if ($_.DisplayIcon) { Add-App $name $_.DisplayIcon }
            elseif ($_.InstallLocation -and (Test-Path $_.InstallLocation)) {
                $exes = Get-ChildItem -Path $_.InstallLocation -Filter '*.exe' -ErrorAction SilentlyContinue | Select-Object -First 2
                foreach ($e in $exes) { Add-App $name $e.FullName }
            }
        }
    }
}

$appPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*"
)
foreach ($ap in $appPaths) {
    Get-ItemProperty $ap -ErrorAction SilentlyContinue | ForEach-Object {
        $exeName = $_.PSChildName
        $target = $_.'(default)'
        if ($exeName -and $target) {
            $name = [System.IO.Path]::GetFileNameWithoutExtension($exeName)
            $name = (Get-Culture).TextInfo.ToTitleCase($name)
            Add-App $name $target
        }
    }
}

$shortcuts = Get-ChildItem -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -Recurse -Filter "*.lnk" -ErrorAction SilentlyContinue
foreach ($s in $shortcuts) {
    try {
        $sh = New-Object -ComObject WScript.Shell
        $target = $sh.CreateShortcut($s.FullName).TargetPath
        if ($target) { Add-App $s.BaseName $target }
    } catch {}
}

$userProgDirs = @(
    "$env:LOCALAPPDATA\Programs",
    "$env:APPDATA\Programs"
)
foreach ($dir in $userProgDirs) {
    if (Test-Path $dir) {
        Get-ChildItem -Path $dir -Recurse -Filter "*.exe" -ErrorAction SilentlyContinue | ForEach-Object {
            $n = $_.Directory.Name
            if (-not $n) { $n = $_.BaseName }
            Add-App $n $_.FullName
        }
    }
}

$apps | Group-Object Executable | ForEach-Object {
    $item = $_.Group[0]
    Write-Output "$($item.Name)||$($item.Executable)||$($item.Path)"
}
''';

      final result = await Process.run('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', psScript]);
      if (result.exitCode == 0) {
        final lines = const LineSplitter().convert(result.stdout as String);
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split('||');
          if (parts.length >= 2) {
            final name = parts[0].trim();
            final exe = parts[1].trim().toLowerCase();
            final pathVal = parts.length >= 3 ? parts[2].trim() : null;
            final cleanExe = exe.replaceAll('.exe', '');

            if (name.isNotEmpty &&
                exe.endsWith('.exe') &&
                !systemWhitelist.contains(cleanExe) &&
                !_noiseFilter.hasMatch(exe) &&
                !_noiseFilter.hasMatch(name)) {
              if (!installedMap.containsKey(exe)) {
                installedMap[exe] = AppItem(
                  name: name,
                  executable: exe,
                  path: (pathVal != null && pathVal.isNotEmpty) ? pathVal : null,
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error discovering installed apps on Windows: $e');
    }

    final list = installedMap.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  static Future<List<AppItem>> _getInstalledAppsMac() async {
    final Map<String, AppItem> installedMap = {};
    final dirs = [Directory('/Applications'), Directory('/System/Applications')];

    for (final dir in dirs) {
      if (dir.existsSync()) {
        try {
          final entities = dir.listSync();
          for (final entity in entities) {
            if (entity.path.endsWith('.app')) {
              final name = entity.path.split('/').last.replaceAll('.app', '');
              final cleanExe = name.toLowerCase().replaceAll(' ', '');
              if (!systemWhitelist.contains(cleanExe) && !_noiseFilter.hasMatch(name)) {
                installedMap[cleanExe] = AppItem(
                  name: name,
                  executable: cleanExe,
                  path: entity.path,
                );
              }
            }
          }
        } catch (e) {
          debugPrint('Error scanning Mac applications directory: $e');
        }
      }
    }

    final list = installedMap.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  static Future<List<AppItem>> _getInstalledAppsLinux() async {
    if (kIsWeb || !Platform.isLinux) return [];
    final Map<String, AppItem> installedMap = {};
    final home = Platform.environment['HOME'] ?? '';
    final dirs = [
      Directory('/usr/share/applications'),
      if (home.isNotEmpty) Directory('$home/.local/share/applications'),
    ];

    for (final dir in dirs) {
      if (dir.existsSync()) {
        try {
          final entities = dir.listSync();
          for (final entity in entities) {
            if (entity.path.endsWith('.desktop')) {
              try {
                final file = File(entity.path);
                final lines = file.readAsLinesSync();
                String? name;
                String? exec;

                for (final line in lines) {
                  if (line.startsWith('Name=') && name == null) {
                    name = line.substring(5).trim();
                  } else if (line.startsWith('Exec=') && exec == null) {
                    exec = line.substring(5).split(' ').first.split('/').last.trim();
                  }
                }

                if (name != null && exec != null) {
                  final cleanExe = exec.toLowerCase().replaceAll('.exe', '');
                  if (!systemWhitelist.contains(cleanExe) && !_noiseFilter.hasMatch(name)) {
                    installedMap[cleanExe] = AppItem(
                      name: name,
                      executable: cleanExe,
                      path: entity.path,
                    );
                  }
                }
              } catch (_) {}
            }
          }
        } catch (e) {
          debugPrint('Error scanning Linux applications directory: $e');
        }
      }
    }

    final list = installedMap.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Discovers currently running desktop processes across platforms.
  static Future<List<AppItem>> getRunningApps() async {
    if (kIsWeb) {
      return const [
        AppItem(name: 'Web Browser', executable: 'browser'),
      ];
    }

    final Map<String, AppItem> runningMap = {};

    try {
      if (Platform.isWindows) {
        final result = await Process.run('tasklist', ['/FO', 'CSV', '/NH']);
        if (result.exitCode == 0) {
          final lines = const LineSplitter().convert(result.stdout as String);
          for (final line in lines) {
            if (line.trim().isEmpty) continue;
            final parts = line.split('","');
            if (parts.isNotEmpty) {
              final exe = parts[0].replaceAll('"', '').trim().toLowerCase();
              final cleanExe = exe.replaceAll('.exe', '');

              if (exe.endsWith('.exe') &&
                  !systemWhitelist.contains(cleanExe) &&
                  !_noiseFilter.hasMatch(exe)) {
                if (!runningMap.containsKey(exe)) {
                  final displayName = cleanExe.length > 1
                      ? '${cleanExe[0].toUpperCase()}${cleanExe.substring(1)}'
                      : cleanExe.toUpperCase();
                  runningMap[exe] = AppItem(name: displayName, executable: exe);
                }
              }
            }
          }
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        final result = await Process.run('ps', ['-A', '-o', 'comm=']);
        if (result.exitCode == 0) {
          final lines = const LineSplitter().convert(result.stdout as String);
          for (final line in lines) {
            final raw = line.trim().split('/').last.trim();
            if (raw.isEmpty) continue;

            final cleanExe = raw.toLowerCase();
            if (!systemWhitelist.contains(cleanExe) && !_noiseFilter.hasMatch(cleanExe)) {
              if (!runningMap.containsKey(cleanExe)) {
                final displayName = cleanExe.length > 1
                    ? '${cleanExe[0].toUpperCase()}${cleanExe.substring(1)}'
                    : cleanExe.toUpperCase();
                runningMap[cleanExe] = AppItem(name: displayName, executable: cleanExe);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting running apps: $e');
    }

    final list = runningMap.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }
}
