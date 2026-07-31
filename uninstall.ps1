# AmnShield Windows Service Uninstaller
# MUST BE RUN AS ADMINISTRATOR

$ErrorActionPreference = "Stop"

$installDir = "C:\ProgramData\AmnShield"
$serviceName = "AmnShieldGuardian"

# Check admin privileges
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator! Please reopen PowerShell with admin privileges."
    exit 1
}

Write-Host "=== Uninstalling AmnShield Guardian Service ===" -ForegroundColor Cyan

# 1. Stop and delete service
if (Get-Service $serviceName -ErrorAction SilentlyContinue) {
    Write-Host "Stopping service..." -ForegroundColor Yellow
    Stop-Service $serviceName -Force -ErrorAction SilentlyContinue
    
    Write-Host "Unregistering service..." -ForegroundColor Yellow
    sc.exe delete $serviceName | Out-Null
    Write-Host "Service unregistered successfully." -ForegroundColor Green
} else {
    Write-Host "Service $serviceName is not installed." -ForegroundColor Yellow
}

# 2. Restore hosts file redirects (removes blocked list entries)
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
if (Test-Path $hostsPath) {
    Write-Host "Cleaning up hosts file domain blocks..." -ForegroundColor Yellow
    $lines = Get-Content $hostsPath
    $cleanLines = @()
    $inBlock = $false
    
    foreach ($line in $lines) {
        if ($line.Contains("# AmnShield Blocklist Start")) {
            $inBlock = $true
            continue
        }
        if ($line.Contains("# AmnShield Blocklist End")) {
            $inBlock = $false
            continue
        }
        if (-not $inBlock) {
            $cleanLines += $line
        }
    }
    [IO.File]::WriteAllLines($hostsPath, $cleanLines)
    Write-Host "Hosts file restored." -ForegroundColor Green
}

# 3. Clean up folder
if (Test-Path $installDir) {
    Write-Host "Removing configuration and executables..." -ForegroundColor Yellow
    Remove-Item $installDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Removed folder: $installDir" -ForegroundColor Green
}

# 4. Remove Extension Policy Entries
try {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" -Name "1" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist" -Name "1" -ErrorAction SilentlyContinue
} catch {}

Write-Host "=== AmnShield Guardian Uninstalled ===" -ForegroundColor Green
