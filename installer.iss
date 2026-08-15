; Inno Setup Compiler Script for AmnShield Windows Guardian
; Compatible with Inno Setup 6+

[Setup]
AppId={{91A39BE9-4A73-4019-9430-8D3E64AE1B42}
AppName=AmnShield Guardian
AppVersion=07.08.2026
AppPublisher=Al-Haq Studio
AppPublisherURL=https://alhaq.uk
AppSupportURL=https://alhaq.uk
AppUpdatesURL=https://amnishield.com/download
DefaultDirName={commonpf}\AmnShield
DefaultGroupName=AmnShield
OutputDir=releases
OutputBaseFilename=AmnShield-Setup-v07.08.2026
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
DirExistsWarning=no
UsePreviousAppDir=yes
CloseApplications=yes
CloseApplicationsFilter=*.exe;*.dll
RestartApplications=no
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\amnshield_flutter.exe
UninstallDisplayName=AmnShield Guardian
CreateUninstallRegKey=yes
Uninstallable=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main Flutter Application files (Includes all DLLs, executables, and data folders)
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; C# Guardian Service files
Source: "guardian-service\AmnShieldGuardian.exe"; DestDir: "{app}\guardian-service"; Flags: ignoreversion
Source: "guardian-service\AmnShieldNativeHost.exe"; DestDir: "{app}\guardian-service"; Flags: ignoreversion

; Installation PowerShell scripts
Source: "install.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "uninstall.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\AmnShield Guardian"; Filename: "{app}\amnshield_flutter.exe"
Name: "{group}\{cm:UninstallProgram,AmnShield Guardian}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\AmnShield Guardian"; Filename: "{app}\amnshield_flutter.exe"; Tasks: desktopicon

[Run]
; Run the PowerShell installation script to register and start the Windows service
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\install.ps1"""; Flags: runhidden runascurrentuser
; Launch AmnShield Desktop application at the end of setup
Filename: "{app}\amnshield_flutter.exe"; Description: "{cm:LaunchProgram,AmnShield Guardian}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Stop and unregister the service before deleting files
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\uninstall.ps1"""; Flags: runhidden runascurrentuser

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep = ssInstall then
  begin
    Exec('taskkill.exe', '/F /T /IM amnshield_flutter.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec('taskkill.exe', '/F /T /IM AmnShieldGuardian.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec('taskkill.exe', '/F /T /IM AmnShieldNativeHost.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec('net.exe', 'stop AmnShieldGuardian', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Sleep(1000);
  end;
end;
