# AmnShield v0.1.0 - Experimental Release 🕌

**Release Date:** November 9, 2025  
**Status:** 🚧 Experimental / Alpha Testing  
**Platform:** Windows 10/11 (64-bit)

---

## 📦 Downloads

### 🖥️ Desktop Application

#### **Option 1: Installer (Recommended)**
📥 **AmnShield-Setup-v0.1.0.exe** (31.98 MB)
- Full Windows installer with admin privileges
- Auto-start on Windows boot
- Creates shortcuts and Start Menu entries
- Easy uninstall via Windows Settings

**SHA256:** `27DEE95D5B764E8E62DF55EB86071316803951659508D9E9BF22CE04BE9EE36B`

#### **Option 2: Portable (No Installation)**
📥 **AmnShield-Portable-v0.1.0.zip** (33.59 MB)
- Extract and run anywhere
- No installation required
- Run from USB drive
- ⚠️ Requires manual admin elevation (right-click → Run as administrator)

**SHA256:** `95889C0B01ADA7348D51E7BF7DB81F3DBE2E5CCE25073A22F776FF9203CF40BD`

---

### 🌐 Browser Extensions

#### **Chrome / Edge / Brave / Opera**
📥 **AmnShield-Extension-v0.1.0-Chrome.zip** (8.67 MB)
- Manifest V3 (latest security standards)
- Manual installation required (not on Chrome Web Store yet)

**SHA256:** `A8D0DF20B1409444E9537330C1BE374C64CC186FE45B22379763C05A35C2C33C`

#### **Firefox**
📥 **AmnShield-Extension-v0.1.0-Firefox.zip** (8.66 MB)
- Manifest V2 (Firefox standard)
- Manual installation required (not on Firefox Add-ons yet)

**SHA256:** `FC99B69FE9D6AADDFDEB39C7C9DAA7863482761E32876A19D6F63896091D0CD3`

#### **All Browsers Bundle**
📥 **AmnShield-Extension-v0.1.0-All-Browsers.zip** (17.34 MB)
- Both Chrome and Firefox extensions
- One download for all browsers

**SHA256:** `3C0B01441BB9BD2B8FBF45FE6F7A3241265E7124D53954BB28699906837FD351`

---

## 🔐 Verify Downloads

**Important:** Verify file integrity before installation!

### Windows PowerShell:
```powershell
Get-FileHash -Path "AmnShield-Setup-v0.1.0.exe" -Algorithm SHA256
# Compare output with SHA256 above
```

### Linux / macOS:
```bash
sha256sum AmnShield-Setup-v0.1.0.exe
# Compare output with SHA256 above
```

📄 **All Checksums:** See [SHA256SUMS.txt](SHA256SUMS.txt) for complete list

---

## 🚀 Quick Start

### Desktop App Installation

#### Using Installer:
1. Download `AmnShield-Setup-v0.1.0.exe`
2. Right-click → Properties → Check "Unblock" (if present) → OK
3. Run installer (UAC prompt will appear - click "Yes")
4. Follow installation wizard
5. Create guardian password
6. App starts in system tray

#### Using Portable:
1. Download `AmnShield-Portable-v0.1.0.zip`
2. Extract to any folder (e.g., `C:\AmnShield\`)
3. Right-click `AmnShield_flutter.exe` → "Run as administrator"
4. Create guardian password
5. App runs without installation

---

### Browser Extension Installation

#### Chrome / Edge:
1. Download `AmnShield-Extension-v0.1.0-Chrome.zip`
2. Extract to permanent location (e.g., `C:\AmnShield Extensions\Chrome\`)
3. Open `chrome://extensions/` (or `edge://extensions/`)
4. Enable "Developer mode" (top-right)
5. Click "Load unpacked"
6. Select extracted folder
7. Pin extension to toolbar

#### Firefox:
1. Download `AmnShield-Extension-v0.1.0-Firefox.zip`
2. Open `about:addons`
3. Click gear icon ⚙️ → "Install Add-on From File..."
4. Select the ZIP file
5. Click "Add" to confirm
6. Pin extension to toolbar

---

## ✨ What's New in v0.1.0

### Desktop Guardian Features
✅ **Application Blocking** - Block any Windows .exe program  
✅ **Guardian Password Protection** - Secure admin access  
✅ **System Tray Integration** - Runs silently in background  
✅ **Auto-Start Support** - Launch with Windows automatically  
✅ **Extension Connection** - HTTP API for browser sync  
✅ **Admin Privilege Support** - Now properly requests elevation  
✅ **Islamic-Themed UI** - Beautiful Arabic-inspired design  
✅ **Dashboard Statistics** - Monitor protection activity  

### Browser Extension Features
✅ **AI Content Filtering** - Offline inappropriate content detection  
✅ **Category-Based Blocking** - Adult, gambling, dating, etc.  
✅ **Desktop Sync** - Connects to guardian app via localhost  
✅ **Password Override** - Temporary unblock with authentication  
✅ **Zero Data Collection** - 100% privacy-respecting  
✅ **Multi-Browser Support** - Chrome, Firefox, Edge, Brave, Opera  

---

## ⚠️ Known Issues & Limitations

**This is an EXPERIMENTAL release. Please report bugs!**

### Known Limitations:
- ❌ **No automatic updates** - Manual reinstall required for updates
- ❌ **No password recovery** - Write down your guardian password!
- ❌ **Admin bypass possible** - Tech-savvy users can disable protection
- ❌ **Not code signed** - Windows SmartScreen may show warning
- ❌ **AI model ~85-90% accurate** - Some false positives/negatives
- ❌ **Extensions not on official stores** - Manual installation required

### Workarounds:
- **SmartScreen warning:** Click "More info" → "Run anyway" (file is verified safe)
- **Password loss:** Reinstall app (settings will be lost)
- **Admin bypass:** Use Standard User accounts for children, admin for parents
- **Extension updates:** Re-download and reinstall manually

---

## 🐛 Bug Fixes in This Release

✅ **Fixed:** White screen on startup (provider initialization)  
✅ **Fixed:** Admin privileges not detected correctly  
✅ **Fixed:** Window not showing after installation  
✅ **Fixed:** Extension connection issues with localhost API  
✅ **Fixed:** Build script paths and manifest embedding  

---

## 📋 System Requirements

### Desktop Application:
- **OS:** Windows 10 version 1809+ or Windows 11 (64-bit only)
- **RAM:** 4 GB minimum (8 GB recommended)
- **Disk:** 150 MB free space
- **Permissions:** Administrator access for installation
- **Display:** 1280x800 minimum resolution

### Browser Extensions:
- **Chrome:** Version 88 or later
- **Edge:** Version 88 or later
- **Firefox:** Version 78 or later
- **Brave:** Latest version
- **Opera:** Latest version

---

## 📖 Documentation

Comprehensive guides available in the repository:

- 📘 **[Installation Guide](docs/INSTALLATION_GUIDE.md)** - Step-by-step setup
- ❓ **[FAQ](docs/FAQ.md)** - Frequently asked questions (40+ Q&A)
- 🔒 **[Privacy Policy](docs/PRIVACY_POLICY.md)** - Zero data collection details
- 🛡️ **[Security Policy](docs/SECURITY.md)** - Responsible disclosure
- 🗺️ **[Roadmap](docs/ROADMAP.md)** - Future plans (v0.2 through v1.0)
- 📜 **[License](docs/LICENSE.md)** - Usage terms and conditions

---

## 🆘 Troubleshooting

### Installer Shows SmartScreen Warning
**Cause:** Executable is not code-signed (costs $200-500/year)  
**Solution:** Click "More info" → "Run anyway"  
**Verification:** Check SHA256 checksum matches above

### App Shows "Limited Access Mode"
**Cause:** App not running with admin privileges  
**Solution:** 
- Installer version: Should auto-elevate (UAC prompt)
- Portable version: Right-click exe → "Run as administrator"

### Extension Shows "Disconnected"
**Cause:** Desktop app not running  
**Solution:**
1. Check system tray for AmnShield icon
2. If not there, launch from Start Menu
3. Test: Visit `http://localhost:47147/status` (should show JSON)

### Forgot Guardian Password
**Current:** No password recovery in v0.1.0  
**Workaround:** Reinstall application (settings will be lost)  
**Coming:** Password recovery in v0.2.0 (Q1 2026)

---

## 🐛 Reporting Issues

Found a bug? Help us improve!

**GitHub Issues:** https://github.com/alhaqdigital/AmnShield-releases/issues

**Include in your report:**
- AmnShield version (v0.1.0)
- Windows version (e.g., Windows 11 22H2)
- Browser and version (if extension issue)
- Steps to reproduce
- Screenshots (if applicable)
- Error messages (if any)

---

## 🤝 Contributing

### How You Can Help:

**Without Coding:**
- 🤲 **Donate:** Support ongoing development (Sadaqah Jariyah)
- 🗣️ **Spread the word:** Tell other Muslims about AmnShield
- 🧪 **Test:** Report bugs and suggest improvements
- 📝 **Translate:** Help localize to Arabic, Urdu, Turkish, etc.
- ⭐ **Star the repo:** Show your support on GitHub

**Donations:**
- 💚 GitHub Sponsors: https://github.com/sponsors/alhaqdigital
- 💰 PayPal: https://paypal.me/alhaqdigital
- ☕ Ko-fi: https://ko-fi.com/AmnShield

**Every donation is Sadaqah Jariyah (continuous charity)!**

---

## 🔮 What's Next?

### v0.2.0 - Stability & Recovery (Q1 2026)

**Planned Features:**
- 🔐 Password recovery system
- 🔄 Automatic updates
- 👨‍👩‍👧‍👦 Multi-user profiles (parent/child accounts)
- 🌐 Network-level blocking (DNS filtering)
- 📊 Enhanced dashboard with weekly reports
- ✅ Code signing certificate (no more SmartScreen warnings!)

See full [Roadmap](docs/ROADMAP.md) for complete timeline through v1.0.

---

## 📞 Support & Community

**Get Help:**
- 💬 GitHub Discussions: https://github.com/alhaqdigital/AmnShield-releases/discussions
- 📧 Email: support@alhaqdigital.com
- 🔒 Security: security@alhaqdigital.com

**Stay Updated:**
- ⭐ Star this repo for release notifications
- 🐦 Twitter: [@AmnShield](https://twitter.com/AmnShield) (coming soon)
- 📧 Newsletter: Monthly updates (opt-in)

---

## 🕌 Islamic Perspective

> *"Tell the believing men to lower their gaze and guard their private parts. That is purer for them. Indeed, Allah is Acquainted with what they do."* (Quran 24:30)

AmnShield is built on Islamic principles:
- **Haya (Modesty):** Protecting your gaze and heart
- **Taqwa (God-consciousness):** Fearing Allah in private
- **Amanah (Trust):** Safeguarding your family's digital life
- **Ihsan (Excellence):** Striving for digital purity

**This is a tool to help those who want to protect themselves.** It should be used alongside:
- Islamic education about modesty and purity
- Parental supervision and guidance
- Personal taqwa (God-consciousness)
- Open family communication

---

## 📜 License

**Proprietary License** - Free for personal, family, educational, and non-profit use.

**Restrictions:**
- ❌ No redistribution or modification
- ❌ Commercial use requires licensing
- ❌ Source code remains confidential

**Permissions:**
- ✅ Personal and family use
- ✅ Islamic schools and madrasahs
- ✅ Mosques and Islamic centers
- ✅ Non-profit Islamic organizations

See [LICENSE.md](docs/LICENSE.md) for full terms.

**Commercial Licensing:** Contact business@alhaqdigital.com

---

## 🤲 Dua for the Project

> *"O Allah, make this software a means of protection for the believers, a source of guidance for those seeking purity, and continuous charity (Sadaqah Jariyah) for those who support it. Accept it from us and forgive our shortcomings. Make it a benefit for the entire Ummah. Ameen."*

---

## 🙏 Acknowledgments

**JazakAllahu Khair** to:
- Early testers who provided valuable feedback
- Security researchers who reviewed the code
- The Muslim community for support and duas
- Open source projects that made this possible

---

**May Allah (SWT) protect you and your family from all harm. 🤲**

**Developed by:** Alhaq Digital Services (ADS)  
**Website:** www.alhaqdigital.com  
**Support:** support@alhaqdigital.com  
**Security:** security@alhaqdigital.com

---

**BismAllah - In the Name of Allah, the Most Merciful**

**Version:** 0.1.0  
**Build Date:** November 9, 2025  
**Build Number:** 001
