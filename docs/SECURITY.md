# Security Policy

## 🔒 Reporting Security Vulnerabilities

**Alhaq Digital Services (ADS)** takes security seriously. We appreciate the efforts of security researchers in helping us protect the Muslim community.

### Responsible Disclosure

If you discover a security vulnerability in AmnShield, please report it responsibly:

1. **DO NOT** create a public GitHub issue
2. **DO NOT** exploit the vulnerability
3. **DO NOT** disclose it publicly until we've addressed it

### How to Report

📧 **Email:** security@alhaqdigital.com

**Include in your report:**
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Any proof-of-concept code (if applicable)
- Your name/alias for acknowledgment (optional)

### Response Timeline

- **Initial Response:** Within 48 hours
- **Status Update:** Within 7 days
- **Fix Timeline:** Varies by severity (critical issues prioritized)
- **Public Disclosure:** After fix is released and users have time to update

---

## 🛡️ Security Features

### Data Protection
- **No External Data Transmission:** All processing happens locally
- **Encrypted Passwords:** Windows DPAPI encryption for guardian passwords
- **Local Database:** Hive encrypted database for settings
- **No Telemetry:** Zero data collection or analytics

### Browser Extension Security
- **Manifest V3 (Chrome):** Latest security standards
- **Minimal Permissions:** Only `activeTab`, `storage`, `tabs`
- **Local Communication:** Only talks to `localhost:47147`
- **Content Isolation:** Cannot access other extensions or browser data

### Application Security
- **Admin Privileges:** Properly requested when needed (app blocking)
- **Process Isolation:** Flutter's sandboxing protection
- **No Remote Code Execution:** No dynamic code loading from internet
- **Signed Installer:** Inno Setup installer (future: code signing certificate)

---

## 🔍 Known Limitations

### v0.1.0 Experimental Release
- **Not Code Signed:** Installer not yet digitally signed (SmartScreen may warn)
- **Admin Bypass:** Technically savvy users with admin rights can disable protection
- **Browser-Only Protection:** Desktop apps can access internet directly if unblocked
- **AI Model Accuracy:** Content detection is ~85-90% accurate (not 100%)

### Future Improvements
- ✅ Code signing certificate (planned for v0.2)
- ✅ Kernel-level driver for app blocking (planned for v1.0)
- ✅ Tamper protection (planned for v0.3)
- ✅ Multi-user conflict resolution (planned for v0.2)

---

## 🎯 Threat Model

### What AmnShield Protects Against

✅ **Accidental Access**
- Children stumbling upon inappropriate content
- Unintentional visits to harmful websites
- Impulsive browsing decisions

✅ **Social Engineering**
- Phishing attempts with inappropriate content
- Misleading links to adult content
- "Curiosity clicks" on suspicious links

✅ **Moderate Technical Users**
- Average users who respect the protection
- Families seeking digital purity
- Muslims committed to lowering their gaze

### What AmnShield Does NOT Protect Against

❌ **Determined Attackers**
- Advanced users with admin rights can disable protection
- Alternative browsers without extension installed
- VPNs or proxies to bypass network-level blocks (not implemented yet)

❌ **Physical Access**
- Someone with physical access can uninstall AmnShield
- Booting into Safe Mode bypasses auto-start protection
- BIOS/UEFI level attacks (out of scope)

❌ **Zero-Day Exploits**
- Unknown vulnerabilities in Windows, Flutter, or Chromium
- Hardware-level exploits (CPU vulnerabilities)

---

## 🔐 Security Best Practices

### For Users

1. **Strong Guardian Password**
   - Use 12+ characters with mix of upper, lower, numbers, symbols
   - Don't share with children or untrusted individuals
   - Store securely (password manager recommended)

2. **Regular Updates**
   - Install updates promptly when notified
   - Check GitHub releases page monthly
   - Subscribe to security announcements (optional)

3. **Layered Protection**
   - Use AmnShield + parental supervision
   - Combine with network-level filtering (router settings)
   - Educate family about Islamic digital ethics

4. **Limited Admin Rights**
   - Don't give children admin accounts on Windows
   - Use Standard User accounts for daily use
   - Admin account only for installations/updates

### For Administrators

1. **Secure Installation**
   - Download only from official sources (GitHub releases)
   - Verify file size matches published checksums (when available)
   - Run installer with admin rights from trusted account

2. **Configuration**
   - Set strong guardian password immediately
   - Configure blocked apps based on family needs
   - Test blocking before relying on it

3. **Monitoring**
   - Periodically check if AmnShield is running
   - Verify browser extensions are active
   - Review app blocking list for changes

---

## 🧪 Security Testing

We encourage responsible security testing:

### Allowed Activities
- ✅ Testing on your own devices
- ✅ Analyzing network traffic (you'll find only localhost communication)
- ✅ Reverse engineering for security research (not for bypassing)
- ✅ Fuzzing and penetration testing
- ✅ Code review (request access for audit)

### Prohibited Activities
- ❌ Testing on others' devices without permission
- ❌ Distributing bypass tools or techniques
- ❌ Attacking our infrastructure (we don't have servers!)
- ❌ Social engineering attempts against users

---

## 🏆 Recognition

We believe in acknowledging security researchers:

### Hall of Fame
Security researchers who responsibly disclose vulnerabilities will be:
- Listed in our Security Hall of Fame (with permission)
- Acknowledged in release notes
- Eligible for rewards (optional donations/gifts based on severity)

**Current Hall of Fame:**
- *No reports yet - be the first!*

---

## 📋 Security Checklist

Before each release, we verify:

- [ ] No hardcoded secrets or API keys
- [ ] All dependencies updated to latest secure versions
- [ ] Sensitive data encrypted (passwords, tokens)
- [ ] No external network communication (except localhost)
- [ ] Admin privileges requested only when necessary
- [ ] Error messages don't leak sensitive information
- [ ] Input validation on all user inputs
- [ ] Browser extension permissions minimized
- [ ] Installer integrity (future: code signing)

---

## 🔄 Update Policy

### Security Updates
- **Critical:** Released within 24-48 hours
- **High:** Released within 7 days
- **Medium:** Released in next regular update
- **Low:** Addressed in future version

### Notification Methods
- GitHub Security Advisories
- Release notes on GitHub
- In-app notification (if internet connection available)

---

## 📞 Contact

**Security Team:** security@alhaqdigital.com  
**General Support:** support@alhaqdigital.com  
**Website:** www.alhaqdigital.com

**PGP Key:** (Coming soon for encrypted communication)

---

## 🕌 Islamic Perspective

> *"Whoever conceals the faults of a Muslim, Allah will conceal their faults in this world and the Hereafter."* - Prophet Muhammad ﷺ

We ask security researchers to:
- Report vulnerabilities privately (concealing the "fault")
- Give us time to fix issues before disclosure
- Intend benefit for the Muslim community (Niyyah)

**JazakAllahu Khair** for helping us protect Muslim families online.

---

**Last Updated:** November 9, 2025  
**Version:** 1.0

**Alhaq Digital Services (ADS)**  
*Serving the Muslim Community Through Technology*
