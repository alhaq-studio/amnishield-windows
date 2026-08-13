# 🔢 AmnShield Version Numbering Guide

**Format:** `v MAJOR . MINOR . PATCH`

Example: `v0.1.2` means:
- `0` = Major version (pre-1.0 = experimental)
- `1` = Minor version (features)
- `2` = Patch version (bug fixes)

---

## 📊 Semantic Versioning (SemVer)

### PATCH Version (v0.1.X) - Bug Fixes Only

**Increment when:** You fix bugs, typos, or minor issues  
**User impact:** Safe to update immediately  
**Examples:**
- v0.1.0 → v0.1.1 (fixed crash bug)
- v0.1.1 → v0.1.2 (fixed admin privileges)
- v0.1.2 → v0.1.3 (fixed UI glitch)

**Usage:**
```powershell
.\release.ps1 -Version "0.1.1"  # Bug fix
.\release.ps1 -Version "0.1.2"  # Another bug fix
.\release.ps1 -Version "0.1.3"  # More fixes
```

---

### MINOR Version (v0.X.0) - New Features

**Increment when:** You add new features  
**User impact:** New capabilities added  
**Examples:**
- v0.1.3 → v0.2.0 (added website blocking feature)
- v0.2.0 → v0.3.0 (added schedule feature)
- v0.3.0 → v0.4.0 (added statistics dashboard)

**Usage:**
```powershell
.\release.ps1 -Version "0.2.0"  # New feature
.\release.ps1 -Version "0.3.0"  # Another feature
```

**Note:** Reset PATCH to 0 when incrementing MINOR

---

### MAJOR Version (vX.0.0) - Breaking Changes

**Increment when:** You make breaking changes or go stable  
**User impact:** Major overhaul, may require user action  
**Examples:**
- v0.9.0 → v1.0.0 (stable release!)
- v1.5.0 → v2.0.0 (complete rewrite)

**Usage:**
```powershell
.\release.ps1 -Version "1.0.0"  # Stable release!
```

---

## 🎯 Decision Tree

### Did you fix a bug?
→ Increment PATCH: `v0.1.0` → `v0.1.1`

### Did you add a new feature?
→ Increment MINOR: `v0.1.5` → `v0.2.0`

### Did you make breaking changes?
→ Increment MAJOR: `v0.9.0` → `v1.0.0`

---

## 📝 Real-World Examples

### Scenario 1: Multiple Bug Fixes

You're at v0.1.0 and fix 3 bugs:

```powershell
# Fix bug #1: White screen
.\release.ps1 -Version "0.1.1"

# Fix bug #2: Admin privileges
.\release.ps1 -Version "0.1.2"

# Fix bug #3: Extension sync
.\release.ps1 -Version "0.1.3"
```

**Result:** v0.1.0 → v0.1.1 → v0.1.2 → v0.1.3

---

### Scenario 2: Bug Fixes + New Feature

You're at v0.1.3 and add a new feature:

```powershell
# Add new feature: Website blocking
.\release.ps1 -Version "0.2.0"  # Jump to v0.2.0 (reset patch to 0)

# Then fix a bug in the new feature
.\release.ps1 -Version "0.2.1"
```

**Result:** v0.1.3 → v0.2.0 → v0.2.1

---

### Scenario 3: Going Stable

After extensive testing at v0.9.5:

```powershell
# Stable release!
.\release.ps1 -Version "1.0.0"

# Bug fix in stable
.\release.ps1 -Version "1.0.1"

# New feature in stable
.\release.ps1 -Version "1.1.0"
```

**Result:** v0.9.5 → v1.0.0 → v1.0.1 → v1.1.0

---

## 🔧 Practical Guidelines

### When to Release v0.1.1, v0.1.2, v0.1.3...

**Release immediately for:**
- 🐛 Critical bugs (crashes, data loss)
- 🔒 Security vulnerabilities
- ⚠️ Admin privileges not working
- 💥 App won't start

**Batch together for:**
- 🎨 Minor UI tweaks
- 📝 Typo fixes
- 🔧 Small improvements

**Example workflow:**
```powershell
# Day 1: Find critical crash bug
.\release.ps1 -Version "0.1.1"  # Emergency release

# Week 1: Fix 3 minor bugs, batch them
.\release.ps1 -Version "0.1.2"  # Contains 3 fixes

# Week 2: Fix 2 more bugs
.\release.ps1 -Version "0.1.3"
```

---

### When to Release v0.2.0, v0.3.0...

**Increment MINOR for:**
- ✨ New feature (website blocking)
- 📊 New dashboard panel
- 🎯 New filtering mode
- 🔌 New extension capability

**Reset PATCH to 0:**
```powershell
# You're at v0.1.7 (lots of bug fixes)
# Now adding new feature

.\release.ps1 -Version "0.2.0"  # NOT 0.1.8!
```

---

## 📋 Version History Example

Typical progression for AmnShield:

```
v0.1.0  - Initial release
v0.1.1  - Fixed white screen bug
v0.1.2  - Fixed admin privileges
v0.1.3  - Fixed extension sync
v0.2.0  - Added website blocking feature
v0.2.1  - Fixed website blocking crash
v0.2.2  - Fixed whitelist not saving
v0.3.0  - Added schedule feature
v0.3.1  - Fixed schedule timezone bug
v0.4.0  - Added statistics dashboard
v0.5.0  - Added parental controls
v0.5.1  - Fixed parental control bypass
v0.9.0  - Release candidate (feature complete)
v0.9.1  - Bug fixes
v0.9.2  - More bug fixes
v1.0.0  - STABLE RELEASE! 🎉
v1.0.1  - Post-release bug fix
v1.1.0  - Added notification system
v1.1.1  - Fixed notification spam
v2.0.0  - Major rewrite with cloud sync
```

---

## 🚀 Quick Commands Reference

### Current Version: v0.1.0

**Bug Fixes (Increment PATCH):**
```powershell
.\release.ps1 -Version "0.1.1"  # First bug fix
.\release.ps1 -Version "0.1.2"  # Second bug fix
.\release.ps1 -Version "0.1.3"  # Third bug fix
# ... up to v0.1.99 if needed!
```

**New Features (Increment MINOR):**
```powershell
.\release.ps1 -Version "0.2.0"  # First feature
.\release.ps1 -Version "0.3.0"  # Second feature
.\release.ps1 -Version "0.4.0"  # Third feature
```

**Bug fix after feature:**
```powershell
# At v0.2.0, fixed a bug
.\release.ps1 -Version "0.2.1"  # Bug fix in v0.2.0

# Added another feature
.\release.ps1 -Version "0.3.0"  # New feature (reset to .0)
```

---

## 📖 Release Notes Template

### For PATCH releases (bug fixes):

```markdown
# AmnShield v0.1.1 Release Notes

**Release Date:** November 10, 2025
**Type:** Bug Fix Release

## 🐛 Bug Fixes

- Fixed white screen on startup
- Fixed admin privileges not working
- Fixed extension sync issues

## 📋 Installation

Update from v0.1.0 by downloading and installing v0.1.1.
```

### For MINOR releases (features):

```markdown
# AmnShield v0.2.0 Release Notes

**Release Date:** November 15, 2025
**Type:** Feature Release

## ✨ New Features

- Website blocking (domain-level filtering)
- Whitelist management
- Block statistics

## 🐛 Bug Fixes

- Fixed admin privileges
- Fixed UI glitches

## 📋 Installation

Update from v0.1.x by installing v0.2.0.
```

---

## ⚠️ Common Mistakes to Avoid

### ❌ Wrong: Skipping numbers
```powershell
v0.1.0 → v0.1.2  # DON'T skip v0.1.1!
```

### ✅ Right: Sequential
```powershell
v0.1.0 → v0.1.1 → v0.1.2
```

---

### ❌ Wrong: Not resetting PATCH
```powershell
v0.1.7 → v0.1.8  # Should be v0.2.0 if adding feature!
```

### ✅ Right: Reset to .0
```powershell
v0.1.7 → v0.2.0  # New feature = reset patch
```

---

### ❌ Wrong: Mixing changes
```powershell
v0.1.0 → v0.2.1  # Jump from 0.1.0 to 0.2.1
```

### ✅ Right: Step by step
```powershell
v0.1.0 → v0.2.0 → v0.2.1  # Feature first, then bug fix
```

---

## 🎓 Pro Tips

1. **Keep a CHANGELOG.md:**
   ```markdown
   # Changelog
   
   ## [0.1.1] - 2025-11-10
   ### Fixed
   - White screen on startup
   - Admin privileges
   
   ## [0.1.0] - 2025-11-09
   ### Added
   - Initial release
   ```

2. **Tag messages should match release notes:**
   ```powershell
   git tag -a v0.1.1 -m "Bug fix release: White screen and admin privileges"
   ```

3. **Test thoroughly before releasing:**
   ```powershell
   # Build locally first
   .\build_release.ps1
   
   # Test the build
   # Then release
   .\release.ps1 -Version "0.1.1"
   ```

4. **Document what changed:**
   Update `releases/RELEASE_NOTES.md` before running `release.ps1`

---

## 📊 Version Strategy for AmnShield

### Phase 1: Experimental (v0.x.x)
- **Current:** v0.1.0
- **Goal:** Gather feedback, fix bugs, add features
- **Release frequency:** High (weekly or as needed)
- **Users:** Early adopters, testers

### Phase 2: Beta (v0.9.x)
- **Target:** v0.9.0 when feature-complete
- **Goal:** Stabilization, extensive testing
- **Release frequency:** Medium (bi-weekly)
- **Users:** Beta testers, brave users

### Phase 3: Stable (v1.x.x)
- **Target:** v1.0.0 when thoroughly tested
- **Goal:** Production-ready, reliable
- **Release frequency:** Low (monthly for features, immediate for critical bugs)
- **Users:** General public

---

## 🔍 Check Current Version

```powershell
# View all tags
git tag -l

# View latest tag
git describe --tags

# View current release on GitHub
# https://github.com/alhaq-studio/AmnShield_flutter/releases
```

---

## 📞 Quick Help

**Bug fix today?**
```powershell
.\release.ps1 -Version "0.1.1"
```

**Multiple bugs this week?**
```powershell
# Batch them, release once
.\release.ps1 -Version "0.1.1"
```

**Added a new feature?**
```powershell
.\release.ps1 -Version "0.2.0"
```

**Going stable?**
```powershell
.\release.ps1 -Version "1.0.0"
```

---

**Current Version:** v0.1.0  
**Next Bug Fix:** v0.1.1  
**Next Feature:** v0.2.0  
**Stable Release:** v1.0.0 (future)

**BismAllah - Version wisely! 🕌**
