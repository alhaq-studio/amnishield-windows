# AmnShield Privacy Policy

**Effective Date:** November 9, 2025  
**Last Updated:** November 9, 2025

---

## Our Commitment to Privacy

At **Alhaq Digital Services (ADS)**, we take your privacy extremely seriously. AmnShield is designed with **privacy-first principles** rooted in Islamic values of trust, confidentiality, and respect for personal boundaries.

> *"O you who believe, avoid much suspicion. Indeed, some suspicion is sin. And do not spy..."* (Quran 49:12)

---

## What Information We DO NOT Collect

AmnShield operates with **zero data collection**. We do not collect, store, or transmit:

- ❌ **Personal Information:** Names, emails, addresses, phone numbers
- ❌ **Browsing History:** URLs visited, search queries, web content
- ❌ **Usage Statistics:** Feature usage, session durations, click patterns
- ❌ **Telemetry Data:** Crash reports, performance metrics, analytics
- ❌ **Blocked Content:** Screenshots, logs of blocked websites/apps
- ❌ **Guardian Passwords:** Stored only locally using Windows encryption
- ❌ **Device Information:** Hardware IDs, IP addresses, location data
- ❌ **Communication Content:** Messages, emails, or any user-generated content

---

## How AmnShield Works

### 100% Local Processing
All content filtering, analysis, and blocking happens **entirely on your device**:
- No external servers process your data
- No cloud-based filtering or analysis
- No network communication with AmnShield servers (because we don't have any!)
- Browser extension communicates only with local desktop app via `localhost:47147`

### Data Storage
The only data stored locally includes:
- ✅ **User Preferences:** Settings, theme choices, language preferences
- ✅ **Blocked Apps List:** Apps you've chosen to block (stored in local database)
- ✅ **Guardian Password Hash:** Encrypted password for admin access (Windows DPAPI)
- ✅ **AI Model Cache:** Pre-downloaded Islamic content detection model (optional feature)

**Storage Location:** All data is stored in:
- Windows: `%APPDATA%\AmnShield\`
- Database: Encrypted Hive database (local only)

---

## Browser Extension Privacy

### Chrome Extension
- Permissions: `activeTab`, `storage`, `tabs`
- Purpose: Analyze webpage content for Islamic compliance
- Data Transmission: Only to `localhost:47147` (your own computer)
- No External Servers: Does not connect to any external APIs

### Firefox Extension
- Same privacy guarantees as Chrome extension
- Manifest V2 with minimal permissions
- Local processing only

### Content Analysis
When analyzing web content:
1. Extension reads page text and images
2. Sends content to **local desktop app** (not internet)
3. Desktop app analyzes using offline AI model
4. Blocking decision made locally
5. **No data leaves your computer**

---

## Third-Party Services

AmnShield does **not** use any third-party services, including:
- ❌ Analytics platforms (Google Analytics, Mixpanel, etc.)
- ❌ Error tracking (Sentry, Crashlytics, etc.)
- ❌ Cloud hosting or storage
- ❌ Advertising networks
- ❌ Social media integrations

---

## Data Security

### Local Data Protection
- **Encryption:** Sensitive data (passwords) encrypted using Windows DPAPI
- **Access Control:** Guardian password required for sensitive operations
- **Integrity:** Database files are not transmitted or shared
- **Isolation:** Each user account has separate data storage

### No Network Vulnerabilities
Since AmnShield doesn't communicate with external servers:
- No risk of man-in-the-middle attacks on our services
- No data breaches from compromised servers
- No unauthorized access to cloud-stored data
- No tracking or surveillance by third parties

---

## Children's Privacy

AmnShield is designed to **protect** children and does not collect any information from users of any age. Parents can:
- Configure settings without providing child's information
- Monitor usage through local logs (optional, disabled by default)
- All monitoring happens locally on the family device

---

## Data Retention

Since we don't collect data, there's nothing to retain. Local data on your device:
- Remains until you uninstall AmnShield
- Can be manually deleted by removing `%APPDATA%\AmnShield\`
- Uninstallation removes all app files automatically

---

## Your Rights

You have complete control over AmnShield's data:
- ✅ **Access:** All your data is on your device (`%APPDATA%\AmnShield\`)
- ✅ **Modify:** Change settings and configurations anytime
- ✅ **Delete:** Uninstall to remove all data permanently
- ✅ **Export:** Database files can be backed up manually
- ✅ **Transparency:** Source code audit available (contact us for security research)

---

## Updates to This Policy

We may update this privacy policy to reflect:
- New features in AmnShield
- Changes in privacy regulations
- Improvements to our privacy practices

Changes will be communicated through:
- Updated policy in the app (Help → Privacy Policy)
- Release notes on GitHub
- Email notification (if you opt-in to our mailing list)

**You are not required to provide an email to use AmnShield.** Email opt-in is completely separate and optional.

---

## Open Source Transparency

While AmnShield's source code is proprietary, we offer:
- **Security Audits:** Request access for privacy/security review
- **Independent Verification:** Network traffic can be monitored to confirm no external data transmission
- **Community Trust:** GitHub discussions and issue tracking for transparency

---

## Islamic Principles

Our privacy approach is guided by Islamic teachings:

> *"The believer's honor is inviolable."* - Prophet Muhammad ﷺ (Hadith)

- **Amanah (Trust):** We are entrusted with protecting your digital life
- **Sitr (Concealment):** Your private matters remain private
- **Ihsan (Excellence):** We strive for the highest standards of data protection
- **Taqwa (God-consciousness):** We fear Allah in handling user data

---

## Contact Us

For privacy concerns or questions:

- 📧 **Email:** privacy@alhaqdigital.com
- 🌐 **Website:** www.alhaqdigital.com
- 💬 **GitHub Discussions:** [github.com/alhaqdigital/AmnShield-releases](https://github.com/alhaqdigital/AmnShield-releases/discussions)

**Response Time:** Within 48 hours (Insha'Allah)

---

## Compliance

AmnShield is designed to respect:
- **GDPR:** European privacy regulations (no data collection = compliance)
- **COPPA:** Children's Online Privacy Protection Act (no data from children)
- **CCPA:** California Consumer Privacy Act (no data sales or sharing)
- **Islamic Law:** Principles of privacy, trust, and dignity

---

## Verification

You can verify our privacy claims by:
1. **Network Monitoring:** Use Wireshark or Fiddler to inspect traffic (you'll see only localhost communication)
2. **File System Audit:** Check `%APPDATA%\AmnShield\` for stored files
3. **Code Review:** Request security audit access (security@alhaqdigital.com)

---

## Your Trust is Our Priority

We built AmnShield because we care about protecting Muslim families online. Your privacy is not a feature—it's the foundation of everything we do.

**JazakAllahu Khair** for trusting us to help safeguard your digital life.

---

**Alhaq Digital Services (ADS)**  
*Serving the Muslim Community Through Technology*

**May Allah (SWT) accept this effort and make it a means of benefit for the Ummah. Ameen.**
