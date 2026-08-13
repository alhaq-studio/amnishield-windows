# 🎯 Release Decision Guide

## Quick Answer: What version should I use?

```
┌─────────────────────────────────────┐
│  What did you change?               │
└─────────────────────────────────────┘
           ↓
    ┌──────┴──────┐
    │             │
    ↓             ↓
┌───────┐    ┌─────────┐
│ Bugs? │    │ Feature?│
└───┬───┘    └────┬────┘
    │             │
    ↓             ↓
v0.1.X        v0.X.0
(Patch)      (Minor)
```

---

## 🐛 Fixed Bugs? → Increment PATCH

**Current:** v0.1.0  
**Next:** v0.1.1

```powershell
.\release.ps1 -Version "0.1.1"
```

**Then:** v0.1.1 → v0.1.2 → v0.1.3 → v0.1.4...

---

## ✨ Added Feature? → Increment MINOR

**Current:** v0.1.5  
**Next:** v0.2.0 *(reset to .0)*

```powershell
.\release.ps1 -Version "0.2.0"
```

**Then:** v0.2.0 → v0.3.0 → v0.4.0 → v0.5.0...

---

## 💥 Breaking Change? → Increment MAJOR

**Current:** v0.9.5  
**Next:** v1.0.0 *(stable release)*

```powershell
.\release.ps1 -Version "1.0.0"
```

---

## 📊 Real Examples

### Scenario: You fixed 3 bugs today

```powershell
# Fix all 3 bugs
# Then release once:
.\release.ps1 -Version "0.1.1"
```

### Scenario: You fixed 1 bug, then another next week

```powershell
# Week 1
.\release.ps1 -Version "0.1.1"

# Week 2
.\release.ps1 -Version "0.1.2"
```

### Scenario: You added website blocking feature

```powershell
# You're at v0.1.3 (after 3 bug fixes)
# Now adding new feature:
.\release.ps1 -Version "0.2.0"  # Jump to 0.2.0, not 0.1.4!
```

### Scenario: Feature has a bug, fix it

```powershell
# At v0.2.0, found a bug
.\release.ps1 -Version "0.2.1"  # Bug fix
```

---

## 🎯 Simple Rules

1. **Bug fix only?** → Add 1 to last number (0.1.0 → 0.1.1)
2. **New feature?** → Add 1 to middle number, reset last (0.1.5 → 0.2.0)
3. **Going stable?** → Change first number to 1 (0.9.0 → 1.0.0)

---

## ⚡ Quick Commands

**Current version:** v0.1.0

```powershell
# Bug fixes
.\release.ps1 -Version "0.1.1"
.\release.ps1 -Version "0.1.2"
.\release.ps1 -Version "0.1.3"

# Features
.\release.ps1 -Version "0.2.0"
.\release.ps1 -Version "0.3.0"

# Stable
.\release.ps1 -Version "1.0.0"
```

---

## 📖 More Details

See full guide: `docs/VERSIONING_GUIDE.md`
