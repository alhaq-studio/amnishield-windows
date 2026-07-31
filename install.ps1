# AmnShield Windows Service Installer
# MUST BE RUN AS ADMINISTRATOR
#cd d:\Projects\AmnShield_flutter
#Set-ExecutionPolicy Bypass -Scope Process -Force
#.\install.ps1

$ErrorActionPreference = "Stop"

# Define Paths
$installDir = "C:\ProgramData\AmnShield"
$daemonSource = Join-Path $PSScriptRoot "guardian-service\AmnShieldGuardian.exe"
$daemonTarget = Join-Path $installDir "AmnShieldGuardian.exe"
$serviceName = "AmnShieldGuardian"

# Check admin privileges
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator! Please reopen PowerShell with admin privileges."
    exit 1
}

Write-Host "=== Installing AmnShield Guardian Service ===" -ForegroundColor Cyan

# 1. Create directory if not exists
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
    Write-Host "Created installation folder: $installDir" -ForegroundColor Green
}

# 2. Grant Modify permissions to Users group so the Flutter app can read/write configs without UAC
Write-Host "Configuring folder permissions..." -ForegroundColor Yellow
icacls $installDir /grant "Users:(OI)(CI)(M)" /T | Out-Null

# 3. Stop existing service if running
if (Get-Service $serviceName -ErrorAction SilentlyContinue) {
    Write-Host "Stopping existing service..." -ForegroundColor Yellow
    Stop-Service $serviceName -Force -ErrorAction SilentlyContinue
    # Give it a moment to release file handles
    Start-Sleep -Seconds 2
}

# 4. Copy daemon executable
if (-not (Test-Path $daemonSource)) {
    Write-Error "Source daemon file not found at: $daemonSource. Please build the C# service first."
    exit 1
}
Copy-Item $daemonSource $daemonTarget -Force
Write-Host "Copied Guardian service executable to: $daemonTarget" -ForegroundColor Green

# 5. Create service if not exists
if (-not (Get-Service $serviceName -ErrorAction SilentlyContinue)) {
    Write-Host "Registering service in Windows Service Control Manager..." -ForegroundColor Yellow
    sc.exe create $serviceName binPath= "$daemonTarget" start= auto obj= "NT AUTHORITY\SYSTEM" | Out-Null
}

# 6. Start service
Write-Host "Starting AmnShield Guardian service..." -ForegroundColor Yellow
Start-Service $serviceName
Write-Host "Service started successfully!" -ForegroundColor Green

# 7. Create a default config.json if not exists
$configPath = Join-Path $installDir "config.json"
if (-not (Test-Path $configPath)) {
    $defaultConfig = @{
        banned_apps = @()
        banned_domains = @()
        focus_mode_active = $true
    } | ConvertTo-Json
    [IO.File]::WriteAllText($configPath, $defaultConfig)
    Write-Host "Initialized default config.json" -ForegroundColor Green
}

# 8. Register Browser Extension Policies (Chrome & Edge)
try {
    Write-Host "Configuring Chrome & Edge browser extension policy..." -ForegroundColor Yellow
    $chromePolicyPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
    $edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"

    if (-not (Test-Path $chromePolicyPath)) { New-Item -Path $chromePolicyPath -Force | Out-Null }
    if (-not (Test-Path $edgePolicyPath)) { New-Item -Path $edgePolicyPath -Force | Out-Null }

    Set-ItemProperty -Path $chromePolicyPath -Name "1" -Value "llbdoeiphjhnjlohogddiignodbmlomo;https://clients2.google.com/service/update2/crx" -Force
    Set-ItemProperty -Path $edgePolicyPath -Name "1" -Value "llbdoeiphjhnjlohogddiignodbmlomo;https://clients2.google.com/service/update2/crx" -Force
    Write-Host "Registered Chrome & Edge extension force-install policies!" -ForegroundColor Green
} catch {
    Write-Host "Warning: Failed to set browser extension policies. Extension can still be added manually." -ForegroundColor Yellow
}

Write-Host "=== AmnShield Guardian Suite Installation Complete ===" -ForegroundColor Green
