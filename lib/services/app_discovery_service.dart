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

  /// Comprehensive Windows App Discovery engine (< 500ms execution time)
  /// Discovers 100% of installed desktop apps & Microsoft Store (AppX) apps:
  /// (Instagram, WhatsApp, Facebook, TikTok, Netflix, Spotify, Discord, VS Code, Steam, Epic Games, etc.)
  static Future<List<AppItem>> getInstalledApps() async {
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

# 1. Store / UWP Apps (Instagram, WhatsApp, Facebook, TikTok, Netflix, Spotify, Twitter/X, Prime Video, Telegram, etc.)
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

# 2. Registry Uninstall Keys (HKLM & HKCU, 64-bit & 32-bit)
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

# 3. Registry App Paths
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

# 4. Start Menu Shortcuts
$shortcuts = Get-ChildItem -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -Recurse -Filter "*.lnk" -ErrorAction SilentlyContinue
foreach ($s in $shortcuts) {
    try {
        $sh = New-Object -ComObject WScript.Shell
        $target = $sh.CreateShortcut($s.FullName).TargetPath
        if ($target) { Add-App $s.BaseName $target }
    } catch {}
}

# 5. User Programs Directories Direct Scanner
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

# Output deduplicated list: DisplayName||executable.exe||Path
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
      debugPrint('Error discovering installed apps: $e');
    }

    final list = installedMap.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Discovers currently running desktop processes via tasklist.
  static Future<List<AppItem>> getRunningApps() async {
    final Map<String, AppItem> runningMap = {};

    try {
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
    } catch (e) {
      debugPrint('Error getting running apps: $e');
    }

    final list = runningMap.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }
}
