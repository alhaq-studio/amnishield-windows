; Inno Setup Compiler Script for AmnShield Windows Guardian
; Compatible with Inno Setup 6+

[Setup]
AppId={{91A39BE9-4A73-4019-9430-8D3E64AE1B42}
AppName=AmnShield Guardian
AppVersion=7.29.2026
AppPublisher=Al-Haq Studio
AppPublisherURL=https://alhaq.uk
AppSupportURL=https://alhaq.uk
AppUpdatesURL=https://alhaq.uk
DefaultDirName={commonpf}\AmnShield
DefaultGroupName=AmnShield
OutputDir=installer_output
OutputBaseFilename=AmnShield-Setup-v7.29.2026
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main Flutter Application files
Source: "build\windows\x64\runner\Release\amnshield_flutter.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\dartjni.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\screen_retriever_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\window_manager_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; C# Guardian Service files
Source: "guardian-service\AmnShieldGuardian.exe"; DestDir: "{app}\guardian-service"; Flags: ignoreversion
Source: "guardian-service\AmnShieldNativeHost.exe"; DestDir: "{app}\guardian-service"; Flags: ignoreversion

; Installation PowerShell scripts
Source: "install.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "uninstall.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\AmnShield Guardian"; Filename: "{app}\amnshield_flutter.exe"
Name: "{group}\{cm:UninstallProgram,AmnShield Guardian}"; Filename: "{uninstdevelfile}"
Name: "{autodesktop}\AmnShield Guardian"; Filename: "{app}\amnshield_flutter.exe"; Tasks: desktopicon

[Run]
; Run the PowerShell installation script to register and start the Windows service
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\install.ps1"""; Flags: runhidden runascurrentuser
; Launch AmnShield Desktop application at the end of setup
Filename: "{app}\amnshield_flutter.exe"; Description: "{cm:LaunchProgram,AmnShield Guardian}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Stop and unregister the service before deleting files
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\uninstall.ps1"""; Flags: runhidden runascurrentuser
