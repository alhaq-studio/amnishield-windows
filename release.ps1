param(
    [Parameter(Mandatory=$true)]
    [string]$Version  # e.g., "0.1.0" (without 'v' prefix)
)

# Validate version format
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Error "Invalid version format. Use: X.Y.Z (e.g., 0.1.0)"
    exit 1
}

$VersionTag = "v$Version"
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 DeenShield Release Automation" -ForegroundColor Cyan
Write-Host "   Version: $VersionTag" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Verify prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow

# Check if git is clean
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "⚠️  Warning: Working directory has uncommitted changes" -ForegroundColor Yellow
    Write-Host $gitStatus
    $continue = Read-Host "`nContinue anyway? (y/n)"
    if ($continue -ne 'y') {
        Write-Host "❌ Aborted by user" -ForegroundColor Red
        exit 1
    }
}

# Check if releases directory exists
if (-not (Test-Path "releases")) {
    Write-Host "📁 Creating releases directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "releases" | Out-Null
}

# Step 1: Build
Write-Host "`n📦 Step 1/7: Building release..." -ForegroundColor Green
if (Test-Path "build_release.ps1") {
    .\build_release.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed! Check errors above."
        exit 1
    }
} else {
    Write-Error "build_release.ps1 not found! Cannot proceed."
    exit 1
}

# Verify build output
if (-not (Test-Path "build\windows\x64\runner\Release\deenshield_flutter.exe")) {
    Write-Error "Build output not found! Expected: build\windows\x64\runner\Release\deenshield_flutter.exe"
    exit 1
}

# Step 2: Package portable
Write-Host "`n📦 Step 2/7: Creating portable package..." -ForegroundColor Green
$portablePath = "releases\DeenShield-Portable-$VersionTag.zip"
if (Test-Path $portablePath) {
    Remove-Item $portablePath -Force
}
Compress-Archive -Path "build\windows\x64\runner\Release\*" `
                 -DestinationPath $portablePath `
                 -Force
Write-Host "   ✅ Created: $portablePath" -ForegroundColor White

# Step 3: Copy installer
Write-Host "`n📦 Step 3/7: Copying installer..." -ForegroundColor Green
$installerSource = "installer\installer_output\DeenShield-Setup.exe"
$installerDest = "releases\DeenShield-Setup-$VersionTag.exe"

if (-not (Test-Path $installerSource)) {
    Write-Error "Installer not found at: $installerSource"
    Write-Host "Make sure build_release.ps1 created the installer successfully." -ForegroundColor Yellow
    exit 1
}

Copy-Item $installerSource $installerDest -Force
Write-Host "   ✅ Created: $installerDest" -ForegroundColor White

# Step 4: Package extensions
Write-Host "`n📦 Step 4/7: Packaging browser extensions..." -ForegroundColor Green

# Check if extension directories exist
$chromeExtPath = "deenshield_extension"
$firefoxExtPath = "deenshield_extension_firefox"

if (-not (Test-Path $chromeExtPath)) {
    Write-Warning "Chrome extension not found at: $chromeExtPath (skipping)"
} else {
    $chromeZip = "releases\DeenShield-Extension-$VersionTag-Chrome.zip"
    if (Test-Path $chromeZip) { Remove-Item $chromeZip -Force }
    Compress-Archive -Path "$chromeExtPath\*" -DestinationPath $chromeZip -Force
    Write-Host "   ✅ Created: $chromeZip" -ForegroundColor White
}

if (-not (Test-Path $firefoxExtPath)) {
    Write-Warning "Firefox extension not found at: $firefoxExtPath (skipping)"
} else {
    $firefoxZip = "releases\DeenShield-Extension-$VersionTag-Firefox.zip"
    if (Test-Path $firefoxZip) { Remove-Item $firefoxZip -Force }
    Compress-Archive -Path "$firefoxExtPath\*" -DestinationPath $firefoxZip -Force
    Write-Host "   ✅ Created: $firefoxZip" -ForegroundColor White
}

# All browsers bundle (if both exist)
if ((Test-Path $chromeExtPath) -and (Test-Path $firefoxExtPath)) {
    $allBrowsersZip = "releases\DeenShield-Extension-$VersionTag-All-Browsers.zip"
    if (Test-Path $allBrowsersZip) { Remove-Item $allBrowsersZip -Force }
    
    # Create temp directory for bundling
    $tempBundle = "temp_extensions"
    if (Test-Path $tempBundle) { Remove-Item $tempBundle -Recurse -Force }
    New-Item -ItemType Directory -Path "$tempBundle\Chrome-Edge-Brave-Opera" | Out-Null
    New-Item -ItemType Directory -Path "$tempBundle\Firefox" | Out-Null
    
    Copy-Item "$chromeExtPath\*" "$tempBundle\Chrome-Edge-Brave-Opera\" -Recurse
    Copy-Item "$firefoxExtPath\*" "$tempBundle\Firefox\" -Recurse
    
    Compress-Archive -Path "$tempBundle\*" -DestinationPath $allBrowsersZip -Force
    Remove-Item $tempBundle -Recurse -Force
    
    Write-Host "   ✅ Created: $allBrowsersZip" -ForegroundColor White
}

# Step 5: Generate checksums
Write-Host "`n🔐 Step 5/7: Generating SHA256 checksums..." -ForegroundColor Green
$checksumFile = "releases\SHA256SUMS.txt"
$checksums = @()

Get-ChildItem "releases\*.exe", "releases\*.zip" | ForEach-Object {
    $hash = Get-FileHash $_.FullName -Algorithm SHA256
    $checksums += "$($hash.Hash)  $($_.Name)"
    Write-Host "   $($_.Name)" -ForegroundColor White
}

$checksums | Out-File $checksumFile -Encoding utf8
Add-Content $checksumFile "`nGenerated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "   ✅ Created: $checksumFile" -ForegroundColor White

# Step 6: Update release notes check
Write-Host "`n📝 Step 6/7: Checking release notes..." -ForegroundColor Green
if (-not (Test-Path "releases\RELEASE_NOTES.md")) {
    Write-Warning "RELEASE_NOTES.md not found in releases directory!"
    Write-Host "Creating template..." -ForegroundColor Yellow
    
    $template = @"
# DeenShield $VersionTag Release Notes

**Release Date:** $(Get-Date -Format 'MMMM d, yyyy')  
**Status:** Experimental Pre-Release

## 📦 Downloads

- **Windows Installer:** DeenShield-Setup-$VersionTag.exe
- **Portable Version:** DeenShield-Portable-$VersionTag.zip
- **Browser Extensions:** Available for Chrome, Firefox, Edge, Brave, Opera

## ✨ Features

- Desktop guardian application with system tray integration
- Browser extensions for content filtering
- AI-powered content detection (offline, privacy-first)
- Application blocking for Windows programs
- Zero data collection - complete privacy

## 🐛 Bug Fixes

- Fixed white screen issue on startup
- Fixed admin privileges not working

## 📋 Installation

See [Installation Guide](../docs/INSTALLATION_GUIDE.md) for detailed instructions.

## 🔒 Security

SHA256 checksums available in SHA256SUMS.txt

## ⚠️ Known Issues

None currently known. Please report issues at: https://github.com/Afrasyaab-GH/deenshield_flutter/issues

---

**BismAllah - In the Name of Allah** 🕌
"@
    
    $template | Out-File "releases\RELEASE_NOTES.md" -Encoding utf8
    Write-Host "   ⚠️  Template created. Please edit releases\RELEASE_NOTES.md before continuing!" -ForegroundColor Yellow
    
    $continue = Read-Host "`nPress Enter after editing RELEASE_NOTES.md, or 'n' to abort"
    if ($continue -eq 'n') {
        Write-Host "❌ Aborted by user" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "   ✅ RELEASE_NOTES.md found" -ForegroundColor White
}

# Step 7: Git operations
Write-Host "`n💾 Step 7/7: Git operations..." -ForegroundColor Green

# Add release files
Write-Host "   Adding files to git..." -ForegroundColor White
git add releases/
git add .github/

# Commit
Write-Host "   Committing release files..." -ForegroundColor White
$commitMessage = @"
Release: DeenShield $VersionTag - Experimental Release

Features:
- Desktop guardian application with system tray
- Browser extensions (Chrome, Firefox, Edge, Brave, Opera)
- AI-powered content blocking (offline)
- Application blocking for Windows programs
- Zero data collection - complete privacy

Fixes:
- White screen on startup (provider initialization)
- Admin privileges not working (manifest embedding)

Files:
- DeenShield-Setup-$VersionTag.exe
- DeenShield-Portable-$VersionTag.zip
- Browser extensions (Chrome, Firefox, All)
- SHA256 checksums
- Release notes
- GitHub Actions workflow for automated releases
"@

git commit -m $commitMessage

# Push to main
Write-Host "   Pushing to origin/main..." -ForegroundColor White
git push origin main

# Create tag
Write-Host "   Creating tag $VersionTag..." -ForegroundColor White
$tagMessage = @"
DeenShield $VersionTag - Experimental Release

First public release of DeenShield Guardian - Islamic content filtering for Windows.

Features:
- Desktop guardian application with system tray integration
- Browser extensions (Chrome, Firefox, Edge, Brave, Opera)
- AI-powered content detection (offline, privacy-first)
- Application blocking for Windows programs
- Zero data collection - complete privacy
- Free for personal use

Download: https://github.com/Afrasyaab-GH/deenshield_flutter/releases/tag/$VersionTag

BismAllah - In the Name of Allah 🕌
"@

git tag -a $VersionTag -m $tagMessage

# Push tag (this triggers GitHub Actions!)
Write-Host "   Pushing tag $VersionTag..." -ForegroundColor White
git push origin $VersionTag

# Summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "✅ RELEASE PROCESS COMPLETE!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "📦 Release Details:" -ForegroundColor Cyan
Write-Host "   Version: $VersionTag" -ForegroundColor White
Write-Host "   Commit: $(git rev-parse --short HEAD)" -ForegroundColor White
Write-Host "   Tag: $VersionTag" -ForegroundColor White

Write-Host "`n🎉 GitHub Actions Workflow:" -ForegroundColor Cyan
Write-Host "   Status: Triggered automatically" -ForegroundColor White
Write-Host "   Monitor: https://github.com/Afrasyaab-GH/deenshield_flutter/actions" -ForegroundColor White

Write-Host "`n📦 Release Page:" -ForegroundColor Cyan
Write-Host "   URL: https://github.com/Afrasyaab-GH/deenshield_flutter/releases/tag/$VersionTag" -ForegroundColor White
Write-Host "   Wait: 1-2 minutes for workflow to complete" -ForegroundColor Yellow

Write-Host "`n📋 Release Files:" -ForegroundColor Cyan
Get-ChildItem "releases\*.exe", "releases\*.zip" | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 2)
    Write-Host "   ✅ $($_.Name) ($size MB)" -ForegroundColor White
}

Write-Host "`n🤲 Dua:" -ForegroundColor Cyan
Write-Host "   'O Allah, accept this work and make it beneficial for the Ummah. Ameen.'" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Green
