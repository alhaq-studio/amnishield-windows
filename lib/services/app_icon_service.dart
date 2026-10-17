import 'dart:io';
import 'package:flutter/foundation.dart';

class AppIconService {
  static final Map<String, String> _iconCache = {};

  /// Asynchronously fetches native PNG Base64 icon for any app executable/path across Windows
  static Future<String?> getIconBase64(String executable, [String? targetPath]) async {
    if (kIsWeb || !Platform.isWindows) {
      return null;
    }

    final cleanExe = executable.toLowerCase().trim();
    if (_iconCache.containsKey(cleanExe)) {
      return _iconCache[cleanExe];
    }

    try {
      final inputTarget = targetPath != null && targetPath.isNotEmpty ? targetPath : cleanExe;

      const psScript = r'''
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

function Resolve-ExePath ($exe) {
    if ([string]::IsNullOrWhiteSpace($exe)) { return $null }
    $clean = [System.IO.Path]::GetFileName($exe).Trim('"').Trim()

    if (Test-Path $exe) { return $exe }

    # 1. Registry App Paths (HKLM & HKCU)
    try {
        $reg = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$clean" -ErrorAction SilentlyContinue).'(default)'
        if ($reg) {
            $cReg = $reg.Split(',')[0].Trim('"').Trim()
            if (Test-Path $cReg) { return $cReg }
        }
        $regCU = (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$clean" -ErrorAction SilentlyContinue).'(default)'
        if ($regCU) {
            $cRegCU = $regCU.Split(',')[0].Trim('"').Trim()
            if (Test-Path $cRegCU) { return $cRegCU }
        }
    } catch {}

    # 2. LocalAppData Programs (Discord, VS Code, Slack, WhatsApp, Spotify, Notion, etc.)
    try {
        $localProg = Get-ChildItem "$env:LOCALAPPDATA\Programs" -Recurse -Depth 2 -Filter $clean -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($localProg) { return $localProg.FullName }
    } catch {}

    # 3. Start Menu Shortcuts
    try {
        $shortcuts = Get-ChildItem "$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -Recurse -Filter "*.lnk" -ErrorAction SilentlyContinue
        foreach ($s in $shortcuts) {
            $sh = New-Object -ComObject WScript.Shell
            $t = $sh.CreateShortcut($s.FullName).TargetPath
            if ($t) {
                $cT = $t.Split(',')[0].Trim('"').Trim()
                if ($cT.EndsWith(".exe", [System.StringComparison]::OrdinalIgnoreCase)) {
                    if ([System.IO.Path]::GetFileName($cT) -eq $clean -and (Test-Path $cT)) {
                        return $cT
                    }
                }
            }
        }
    } catch {}

    # 4. Get-Command fallback
    try {
        $cmd = (Get-Command $clean -ErrorAction SilentlyContinue).Source
        if ($cmd -and (Test-Path $cmd)) { return $cmd }
    } catch {}

    return $null
}

function Get-ExeIconBase64 ($exe) {
    $resolvedPath = Resolve-ExePath $exe
    if ($resolvedPath -and (Test-Path $resolvedPath)) {
        try {
            $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($resolvedPath)
            if ($icon) {
                $bmp = $icon.ToBitmap()
                $ms = New-Object System.IO.MemoryStream
                $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
                $b64 = [Convert]::ToBase64String($ms.ToArray())
                $ms.Close()
                return $b64
            }
        } catch {}
    }
    return ""
}

Get-ExeIconBase64 $env:TARGET_EXE
''';

      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', psScript],
        environment: {'TARGET_EXE': inputTarget},
      );
      if (result.exitCode == 0) {
        final b64 = (result.stdout as String).trim();
        if (b64.isNotEmpty) {
          _iconCache[cleanExe] = b64;
          return b64;
        }
      }
    } catch (e) {
      debugPrint('Error loading icon for $cleanExe: $e');
    }

    return null;
  }
}
