# 🚀 Quick Release Reference

## ⚡ One-Command Release (Future Releases)

### Bug Fixes (v0.1.1, v0.1.2, v0.1.3...)
```powershell
.\release.ps1 -Version "0.1.1"  # First bug fix
.\release.ps1 -Version "0.1.2"  # Second bug fix
.\release.ps1 -Version "0.1.3"  # Third bug fix
```

### New Features (v0.2.0, v0.3.0, v0.4.0...)
```powershell
.\release.ps1 -Version "0.2.0"  # First feature
.\release.ps1 -Version "0.3.0"  # Second feature
```

**That's it!** Fully automated from build to GitHub release.

---

## 📊 Current Release Status

**Version:** v0.1.0  
**Status:** 🔄 **GitHub Actions Running**  
**Monitor:** https://github.com/alhaq-studio/AmnShield_flutter/actions  
**Release:** https://github.com/alhaq-studio/AmnShield_flutter/releases/tag/v0.1.0

**Wait:** 1-2 minutes for completion

---

## 🔢 Version Numbering

**Format:** `vMAJOR.MINOR.PATCH`

- **PATCH (v0.1.X):** Bug fixes → v0.1.1, v0.1.2, v0.1.3...
- **MINOR (v0.X.0):** New features → v0.2.0, v0.3.0, v0.4.0...
- **MAJOR (vX.0.0):** Breaking changes → v1.0.0, v2.0.0...

**Current:** v0.1.0  
**Next bug fix:** v0.1.1  
**Next feature:** v0.2.0

📖 **Full guide:** See `docs/VERSIONING_GUIDE.md`

---

## 🤖 What Happens Automatically

When `release.ps1` runs or you push a tag:

1. ✅ Builds Flutter app with admin manifest
2. ✅ Creates installer and portable packages
3. ✅ Packages browser extensions
4. ✅ Generates SHA256 checksums
5. ✅ Updates release notes
6. ✅ Commits files to git
7. ✅ Creates and pushes version tag
8. 🤖 **GitHub Actions creates release automatically!**

---

## 📦 GitHub Actions Workflow

Triggered on: Tag push (`v*.*.*`)

**Actions:**
- Creates GitHub release page
- Attaches all files from `releases/`
- Uses `RELEASE_NOTES.md` as description
- Marks as pre-release (experimental)
- Publishes automatically

**No manual steps required!**

---

## 📁 Files Created

- `.github/workflows/release.yml` - Workflow definition
- `release.ps1` - Automation script
- `docs/RELEASE_AUTOMATION.md` - Full documentation

---

## 🎯 Next Steps

After GitHub Actions completes (1-2 minutes):

1. ✅ Verify release at: https://github.com/alhaq-studio/AmnShield_flutter/releases
2. ✅ Test download links work
3. ✅ Share on social media
4. ✅ Announce in communities

---

**BismAllah - May this serve the Ummah! 🕌**
