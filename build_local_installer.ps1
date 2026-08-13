# AmnShield Local Installer Automation Script
$ErrorActionPreference = "Stop"

$releaseDir = "build\windows\x64\runner\Release"
$outputDir = "releases"
$installerExe = "releases\AmnShield-Setup-v7.29.2026.exe"
$zipPath = "releases\AmnShield-Windows-v7.29.2026-x64.zip"

if (-not (Test-Path $releaseDir)) {
    Write-Error "Release directory not found: $releaseDir"
    exit 1
}

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# 1. Package Portable ZIP
Write-Host "Packaging portable ZIP..." -ForegroundColor Yellow
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path "$releaseDir\*" -DestinationPath $zipPath -Force
Write-Host "Created $zipPath" -ForegroundColor Green

# 2. Package Self-Extracting Single Installer Executable
Write-Host "Packaging installer staging..." -ForegroundColor Yellow
$staging = "build\installer_staging"
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging | Out-Null

Copy-Item "$releaseDir\*" $staging -Recurse
if (Test-Path "guardian-service") {
    New-Item -ItemType Directory -Path "$staging\guardian-service" -Force | Out-Null
    Copy-Item "guardian-service\*" "$staging\guardian-service" -Recurse
}
if (Test-Path "install.ps1") { Copy-Item "install.ps1" $staging -Force }
if (Test-Path "uninstall.ps1") { Copy-Item "uninstall.ps1" $staging -Force }

$payloadZip = "build\payload.zip"
if (Test-Path $payloadZip) { Remove-Item $payloadZip -Force }
Compress-Archive -Path "$staging\*" -DestinationPath $payloadZip -Force

# Write C# installer code
$csSource = @"
using System;
using System.IO;
using System.IO.Compression;
using System.Diagnostics;
using System.Windows.Forms;
using System.Security.Principal;

namespace AmnShieldInstaller
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            bool isAdmin = new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator);
            if (!isAdmin)
            {
                ProcessStartInfo self = new ProcessStartInfo();
                self.FileName = Application.ExecutablePath;
                self.Verb = "runas";
                try { Process.Start(self); } catch {}
                return;
            }

            DialogResult result = MessageBox.Show(
                "Welcome to AmnShield Guardian Setup!\n\nDeveloped by Afrasyaab Meranai | Al-Haq Studio (Al-Haq.uk)\n\nClick OK to install AmnShield Guardian to C:\\Program Files\\AmnShield\\",
                "AmnShield Guardian Setup - Al-Haq Studio",
                MessageBoxButtons.OKCancel,
                MessageBoxIcon.Information
            );

            if (result != DialogResult.OK) return;

            string targetDir = @"C:\Program Files\AmnShield";
            try
            {
                if (!Directory.Exists(targetDir)) Directory.CreateDirectory(targetDir);

                string tempZip = Path.Combine(Path.GetTempPath(), "amnshield_payload.zip");
                var asm = System.Reflection.Assembly.GetExecutingAssembly();
                using (Stream stream = asm.GetManifestResourceStream("payload.zip"))
                using (FileStream fs = new FileStream(tempZip, FileMode.Create, FileAccess.Write))
                {
                    stream.CopyTo(fs);
                }

                ZipFile.ExtractToDirectory(tempZip, targetDir);
                File.Delete(tempZip);

                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "powershell.exe";
                psi.Arguments = "-ExecutionPolicy Bypass -File \"" + Path.Combine(targetDir, "install.ps1") + "\"";
                psi.WindowStyle = ProcessWindowStyle.Hidden;
                psi.UseShellExecute = true;
                Process p = Process.Start(psi);
                p.WaitForExit();

                string desktopPath = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
                string shortcutPath = Path.Combine(desktopPath, "AmnShield Guardian.lnk");
                CreateShortcut(shortcutPath, Path.Combine(targetDir, "amnshield_flutter.exe"), "AmnShield Digital Protection");

                MessageBox.Show("AmnShield Guardian installed successfully!\n\nAll services and browser extension policies have been registered.", "Setup Complete - Al-Haq Studio", MessageBoxButtons.OK, MessageBoxIcon.Information);

                Process.Start(Path.Combine(targetDir, "amnshield_flutter.exe"));
            }
            catch (Exception ex)
            {
                MessageBox.Show("Installation Error: " + ex.Message, "Setup Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        static void CreateShortcut(string shortcutPath, string targetPath, string description)
        {
            Type shellType = Type.GetTypeFromProgID("WScript.Shell");
            dynamic shell = Activator.CreateInstance(shellType);
            dynamic shortcut = shell.CreateShortcut(shortcutPath);
            shortcut.TargetPath = targetPath;
            shortcut.Description = description;
            shortcut.WorkingDirectory = Path.GetDirectoryName(targetPath);
            shortcut.Save();
        }
    }
}
"@

$csFile = "build\InstallerBootstrap.cs"
[System.IO.File]::WriteAllText($csFile, $csSource)

$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$iconPath = "windows\runner\resources\app_icon.ico"

Write-Host "Compiling executable installer..." -ForegroundColor Yellow
& $csc "/target:winexe" "/out:$installerExe" "/win32icon:$iconPath" "/resource:$payloadZip,payload.zip" "/r:System.Windows.Forms.dll" "/r:System.dll" "/r:System.IO.Compression.dll" "/r:System.IO.Compression.FileSystem.dll" $csFile

if (Test-Path $installerExe) {
    $size = (Get-Item $installerExe).Length / 1MB
    Write-Host "SUCCESS: Local AmnShield Setup Executable built at $installerExe ($([math]::Round($size, 2)) MB)" -ForegroundColor Green
} else {
    Write-Error "Failed to build installer executable."
}
