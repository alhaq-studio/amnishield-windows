# 🤖 AmnShield Release Automation Guide

This guide explains the automated release workflow for AmnShield.

---

## 📋 Overview

AmnShield uses **GitHub Actions** to automatically create releases when you push a version tag. No manual GitHub UI interaction needed!

---

## 🚀 How It Works

### Automatic Workflow

1. **You push a version tag** (e.g., `v0.1.0`)
2. **GitHub Actions triggers** automatically
3. **Release is created** with all files attached
4. **Done!** Release is live at `https://github.com/alhaq-studio/AmnShield_flutter/releases`

### What Gets Automated

- ✅ Release creation on GitHub
- ✅ Automatic file attachment (installers, portable, extensions)
- ✅ Release notes from `releases/RELEASE_NOTES.md`
- ✅ Pre-release marking (experimental)
- ✅ Asset checksums included

---

## 📦 Complete Release Process (Step-by-Step)

### Step 1: Build Release Files

Run the automated build script:

```powershell
.\build_release.ps1
```

This will:
- Clean previous builds
- Build Flutter Windows app
- Embed admin manifest
- Verify admin privileges
- Create installer with Inno Setup
- Generate all release files

**Output Location:** `build\windows\x64\runner\Release\`

---

### Step 2: Package Release Files

Create the release packages:

```powershell
# Create portable ZIP
Compress-Archive -Path "build\windows\x64\runner\Release\*" `
                 -DestinationPath "releases\AmnShield-Portable-v0.1.0.zip" `
                 -Force

# Copy installer (already created by build_release.ps1)
Copy-Item "installer\installer_output\AmnShield-Setup.exe" `
          "releases\AmnShield-Setup-v0.1.0.exe" `
          -Force
```

**Note:** Replace `v0.1.0` with your version number.

---

### Step 3: Package Browser Extensions

```powershell
# Chrome/Edge/Brave/Opera
Compress-Archive -Path "AmnShield_extension\*" `
                 -DestinationPath "releases\AmnShield-Extension-v0.1.0-Chrome.zip" `
                 -Force

# Firefox
Compress-Archive -Path "AmnShield_extension_firefox\*" `
                 -DestinationPath "releases\AmnShield-Extension-v0.1.0-Firefox.zip" `
                 -Force

# All Browsers Bundle
Compress-Archive -Path "AmnShield_extension\*", "AmnShield_extension_firefox\*" `
                 -DestinationPath "releases\AmnShield-Extension-v0.1.0-All-Browsers.zip" `
                 -Force
```

---

### Step 4: Generate Checksums

```powershell
# Calculate SHA256 checksums
Get-ChildItem "releases\*.exe", "releases\*.zip" | ForEach-Object {
    $hash = Get-FileHash $_.FullName -Algorithm SHA256
    "$($hash.Hash)  $($_.Name)"
} | Out-File "releases\SHA256SUMS.txt" -Encoding utf8

# Add timestamp
Add-Content "releases\SHA256SUMS.txt" "`nGenerated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
```

---

### Step 5: Update Release Notes

Edit `releases\RELEASE_NOTES.md` with:
- Version number
- Release date
- New features
- Bug fixes
- Known issues
- Installation instructions

**Template:** See `releases/RELEASE_NOTES.md` for structure.

---

### Step 6: Commit Release Files

```powershell
# Check what will be committed
git status

# Add release files
git add releases/

# Commit with descriptive message
git commit -m "Release: AmnShield v0.1.0 - Experimental Release

Features:
- Desktop guardian application
- Browser extensions (Chrome, Firefox, Edge)
- AI-powered content blocking
- Application blocking
- Zero data collection

Fixes:
- White screen on startup (provider initialization)
- Admin privileges not working (manifest embedding)

Files:
- AmnShield-Setup-v0.1.0.exe (31.98 MB)
- AmnShield-Portable-v0.1.0.zip (33.59 MB)
- Browser extensions (Chrome, Firefox, All)
- SHA256 checksums
- Release notes"

# Push to GitHub
git push origin main
```

---

### Step 7: Create and Push Tag (Triggers Automation!)

```powershell
# Create annotated tag
git tag -a v0.1.0 -m "AmnShield v0.1.0 - Experimental Release

First public release of AmnShield Guardian - Islamic content filtering for Windows.

Features:
- Desktop guardian application with system tray
- Browser extensions (Chrome, Firefox, Edge, Brave, Opera)
- AI-powered content detection (offline, privacy-first)
- Application blocking for Windows programs
- Zero data collection - complete privacy
- Free for personal use

Download: https://github.com/alhaq-studio/AmnShield_flutter/releases/tag/v0.1.0"

# Push tag (this triggers GitHub Actions!)
git push origin v0.1.0
```

**🎉 That's it!** GitHub Actions will automatically:
1. Detect the pushed tag
2. Create the release
3. Attach all files from `releases/`
4. Set as pre-release
5. Publish to https://github.com/alhaq-studio/AmnShield_flutter/releases

---

## ⚙️ GitHub Actions Workflow

The workflow file is located at: `.github/workflows/release.yml`

### Trigger Conditions

```yaml
on:
  push:
    tags:
      - 'v*.*.*'  # Matches: v0.1.0, v1.0.0, v2.3.1, etc.
```

### What It Does

1. **Checks out code** with full git history
2. **Extracts version** from tag name
3. **Checks for release notes** in `releases/RELEASE_NOTES.md`
4. **Creates GitHub Release** with:
   - Title: "AmnShield v0.1.0 - Experimental Release 🕌"
   - Body: Content from `releases/RELEASE_NOTES.md`
   - Pre-release: ✅ Marked as experimental
   - Assets: All files from `releases/` directory
5. **Publishes release** automatically

### Required Files

The workflow expects these files in `releases/`:
- `AmnShield-Setup-v*.exe` (installer)
- `AmnShield-Portable-v*.zip` (portable version)
- `AmnShield-Extension-v*-Chrome.zip` (Chrome extension)
- `AmnShield-Extension-v*-Firefox.zip` (Firefox extension)
- `AmnShield-Extension-v*-All-Browsers.zip` (bundled extensions)
- `SHA256SUMS.txt` (checksums)
- `RELEASE_NOTES.md` (release documentation)

---

## 🔍 Monitoring the Workflow

### View Workflow Status

1. Go to: https://github.com/alhaq-studio/AmnShield_flutter/actions
2. Click on the latest "Create Release" workflow run
3. Watch the progress in real-time

### Check Release

After workflow completes (usually 1-2 minutes):
- **Releases page:** https://github.com/alhaq-studio/AmnShield_flutter/releases
- **Specific release:** https://github.com/alhaq-studio/AmnShield_flutter/releases/tag/v0.1.0

---

## 🛠️ Troubleshooting

### Workflow Not Triggering

**Problem:** Pushed tag but workflow didn't run

**Solutions:**
1. Check tag format matches `v*.*.*` (e.g., `v0.1.0`, not `0.1.0`)
2. Verify workflow file exists at `.github/workflows/release.yml`
3. Check GitHub Actions is enabled: Settings → Actions → Allow all actions
4. Ensure you have push permission to the repository

### Release Creation Failed

**Problem:** Workflow runs but release not created

**Solutions:**
1. Check workflow logs at: https://github.com/alhaq-studio/AmnShield_flutter/actions
2. Verify `releases/` directory exists with all required files
3. Ensure `GITHUB_TOKEN` has `contents: write` permission (automatic in workflow)
4. Check file name patterns match wildcards in workflow

### Files Not Attached

**Problem:** Release created but files missing

**Solutions:**
1. Verify files exist in `releases/` directory before pushing tag
2. Check file naming matches patterns:
   - `AmnShield-Setup-v*.exe`
   - `AmnShield-Portable-v*.zip`
   - etc.
3. Ensure files are committed to git before creating tag
4. Check workflow logs for file attachment errors

---

## 📊 Version Numbering

Follow **Semantic Versioning** (SemVer):

```
v MAJOR . MINOR . PATCH
  |       |       |
  |       |       +-- Bug fixes (v0.1.1)
  |       +---------- New features (v0.2.0)
  +------------------ Breaking changes (v1.0.0)
```

### Examples

- `v0.1.0` - Initial experimental release
- `v0.1.1` - Bug fix update
- `v0.2.0` - New features added
- `v1.0.0` - Stable release (breaking changes)

### Pre-release Versions (Optional)

- `v0.1.0-alpha.1` - Alpha testing
- `v0.1.0-beta.1` - Beta testing
- `v0.1.0-rc.1` - Release candidate

---

## 🔄 Complete Automation Script

Save this as `release.ps1` for one-command releases:

```powershell
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

Write-Host "🚀 Starting release process for $VersionTag..." -ForegroundColor Cyan

# Step 1: Build
Write-Host "`n📦 Building release..." -ForegroundColor Yellow
.\build_release.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

# Step 2: Package portable
Write-Host "`n📦 Creating portable package..." -ForegroundColor Yellow
Compress-Archive -Path "build\windows\x64\runner\Release\*" `
                 -DestinationPath "releases\AmnShield-Portable-$VersionTag.zip" `
                 -Force

# Step 3: Copy installer
Write-Host "`n📦 Copying installer..." -ForegroundColor Yellow
Copy-Item "installer\installer_output\AmnShield-Setup.exe" `
          "releases\AmnShield-Setup-$VersionTag.exe" `
          -Force

# Step 4: Package extensions
Write-Host "`n📦 Packaging extensions..." -ForegroundColor Yellow
Compress-Archive -Path "AmnShield_extension\*" `
                 -DestinationPath "releases\AmnShield-Extension-$VersionTag-Chrome.zip" `
                 -Force

Compress-Archive -Path "AmnShield_extension_firefox\*" `
                 -DestinationPath "releases\AmnShield-Extension-$VersionTag-Firefox.zip" `
                 -Force

Compress-Archive -Path "AmnShield_extension\*", "AmnShield_extension_firefox\*" `
                 -DestinationPath "releases\AmnShield-Extension-$VersionTag-All-Browsers.zip" `
                 -Force

# Step 5: Generate checksums
Write-Host "`n🔐 Generating checksums..." -ForegroundColor Yellow
Get-ChildItem "releases\*.exe", "releases\*.zip" | ForEach-Object {
    $hash = Get-FileHash $_.FullName -Algorithm SHA256
    "$($hash.Hash)  $($_.Name)"
} | Out-File "releases\SHA256SUMS.txt" -Encoding utf8

Add-Content "releases\SHA256SUMS.txt" "`nGenerated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Step 6: Commit
Write-Host "`n💾 Committing release files..." -ForegroundColor Yellow
git add releases/
git commit -m "Release: AmnShield $VersionTag - Experimental Release"
git push origin main

# Step 7: Create and push tag
Write-Host "`n🏷️  Creating tag $VersionTag..." -ForegroundColor Yellow
git tag -a $VersionTag -m "AmnShield $VersionTag - Experimental Release"
git push origin $VersionTag

Write-Host "`n✅ Release process complete!" -ForegroundColor Green
Write-Host "🎉 GitHub Actions will create the release automatically." -ForegroundColor Green
Write-Host "📦 View at: https://github.com/alhaq-studio/AmnShield_flutter/releases/tag/$VersionTag" -ForegroundColor Cyan
Write-Host "`n⏳ Wait 1-2 minutes for workflow to complete..." -ForegroundColor Yellow
```

### Usage

```powershell
# Run complete release automation
.\release.ps1 -Version "0.1.0"
```

---

## ✅ Quick Reference

### One-Line Release (After running release.ps1)

```powershell
# Just push the tag!
git push origin v0.1.0
```

### Manual Steps (If Not Using Automation Script)

```powershell
# 1. Build
.\build_release.ps1

# 2. Package
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath "releases\AmnShield-Portable-v0.1.0.zip" -Force

# 3. Checksums
Get-ChildItem "releases\*.exe", "releases\*.zip" | ForEach-Object { $hash = Get-FileHash $_.FullName -Algorithm SHA256; "$($hash.Hash)  $($_.Name)" } | Out-File "releases\SHA256SUMS.txt" -Encoding utf8

# 4. Commit & Push
git add releases/
git commit -m "Release: AmnShield v0.1.0"
git push origin main

# 5. Tag & Push (triggers automation!)
git tag -a v0.1.0 -m "AmnShield v0.1.0"
git push origin v0.1.0
```

---

## 🎯 Best Practices

1. **Always test builds locally** before releasing
2. **Update RELEASE_NOTES.md** before creating tag
3. **Use semantic versioning** (v0.1.0, v0.2.0, v1.0.0)
4. **Verify checksums** after generation
5. **Test installer and portable** versions
6. **Check workflow status** after pushing tag
7. **Verify download links** after release published

---

## 📞 Support

**Workflow Issues:** Check https://github.com/alhaq-studio/AmnShield_flutter/actions  
**Release Questions:** Open issue at https://github.com/alhaq-studio/AmnShield_flutter/issues

---

**Last Updated:** November 9, 2025  
**Status:** ✅ Fully Automated

**BismAllah - May this automation serve the Ummah efficiently! 🕌**
