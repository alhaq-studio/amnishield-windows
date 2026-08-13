# AmnShield v0.1.0 - Installation & Setup Guide

**Quick Start Guide for Windows Users**

---

## 🖥️ Desktop Application Installation

### System Requirements
- **OS:** Windows 10 version 1809 or later (64-bit)
- **RAM:** 4 GB minimum (8 GB recommended)
- **Disk Space:** 150 MB for installation
- **Permissions:** Administrator access required for installation

### Installation Steps

1. **Download the Installer**
   - Download `AmnShield-Setup-v0.1.0.exe` from:
     - GitHub Releases: https://github.com/alhaqdigital/AmnShield-releases/releases/tag/v0.1.0
     - Official Website: www.alhaqdigital.com/downloads

2. **Run the Installer**
   - Double-click `AmnShield-Setup-v0.1.0.exe`
   - Windows will show a UAC (User Account Control) prompt
   - Click **"Yes"** to allow installation with administrator privileges
   - *This is normal and required for proper installation*

3. **Installation Wizard**
   - **Welcome Screen:** Click "Next"
   - **License Agreement:** Read and accept (Click "I accept")
   - **Destination Folder:** Default is `C:\Program Files\AmnShield`
     - You can change this if needed
   - **Select Components:** All components are required (pre-selected)
   - **Additional Options:**
     - ☐ Create Desktop Icon (optional)
     - ☐ Create Quick Launch Icon (optional)
     - ☑ **Start AmnShield automatically when Windows starts** (RECOMMENDED)
   - Click "Install"

4. **Installation Progress**
   - Wait for files to be copied (about 30-60 seconds)
   - The installer will:
     - Copy application files
     - Install plugin DLLs
     - Create Start Menu shortcuts
     - Register the application in Windows
     - Configure auto-start (if selected)

5. **Completion**
   - ☑ Launch AmnShield Desktop Guardian (recommended)
   - Click "Finish"

---

## 🔐 First-Time Setup (Guardian Password)

When you launch AmnShield for the first time:

1. **Welcome Screen**
   - You'll see a welcome message explaining AmnShield's purpose
   - Click "Continue to Setup"

2. **Create Guardian Password**
   - **IMPORTANT:** This password protects all settings and blocks
   - Requirements:
     - Minimum 8 characters
     - Mix of uppercase and lowercase letters
     - At least one number
     - At least one special character (!@#$%^&*)
   - Enter your password
   - Re-enter to confirm
   - Click "Create Password"

3. **Setup Complete**
   - You'll be taken to the main dashboard
   - The app will minimize to system tray (look for icon near clock)

⚠️ **IMPORTANT:** Write down your guardian password somewhere safe!  
Currently, there is no password recovery in v0.1.0 (planned for v0.2).

---

## 🌐 Browser Extension Installation

### Chrome / Edge Extension

#### Method 1: Chrome Web Store (Coming Soon)
*The extension is pending approval for Chrome Web Store*

#### Method 2: Manual Installation (Current)

1. **Download the Extension**
   - Download `AmnShield-chrome-v0.1.0.zip`
   - Extract the ZIP file to a permanent location (e.g., `C:\AmnShield Extensions\Chrome\`)
   - **DO NOT delete this folder** - Chrome will use it directly

2. **Enable Developer Mode**
   - Open Chrome/Edge
   - Navigate to: `chrome://extensions/` (or `edge://extensions/`)
   - Toggle **"Developer mode"** ON (top-right corner)

3. **Load the Extension**
   - Click **"Load unpacked"**
   - Browse to the extracted folder: `AmnShield-chrome-v0.1.0\`
   - Select the folder and click "Select Folder"

4. **Verify Installation**
   - You should see "Deen Shield" in your extensions list
   - The AmnShield icon should appear in your browser toolbar
   - If not visible, click the puzzle icon and pin AmnShield

5. **Grant Permissions**
   - Click the AmnShield icon
   - Review and accept requested permissions:
     - Read and change all your data on websites (for content filtering)
     - Display notifications (for block alerts)
     - Communicate with native applications (for desktop app sync)

### Firefox Extension

#### Method 1: Firefox Add-ons (Coming Soon)
*The extension is pending approval for Firefox Add-ons*

#### Method 2: Manual Installation (Current)

1. **Download the Extension**
   - Download `AmnShield-firefox-v0.1.0.zip`
   - **Keep the ZIP file** - Firefox will install from it

2. **Install from File**
   - Open Firefox
   - Navigate to: `about:addons`
   - Click the gear icon (⚙️) → **"Install Add-on From File..."**
   - Select `AmnShield-firefox-v0.1.0.zip`
   - Click "Open"

3. **Approve Installation**
   - Firefox will show a confirmation prompt
   - Click **"Add"**
   - The extension will be installed permanently

4. **Verify Installation**
   - You should see "Deen Shield" in your extensions list
   - The AmnShield icon should appear in your browser toolbar

---

## 🔗 Connecting Extension to Desktop App

### Automatic Connection

If both the desktop app and browser extension are installed:

1. **Start the Desktop App**
   - Launch from Start Menu or system tray

2. **Open Your Browser**
   - The extension will automatically detect the desktop app
   - You'll see a "✓ Connected to Desktop App" indicator

3. **Connection Status**
   - Click the AmnShield extension icon
   - Go to Settings
   - Look for "Desktop Connection Status"
   - Should show: **"Connected ✓"**

### Troubleshooting Connection Issues

If the connection fails:

1. **Check Desktop App is Running**
   - Look for AmnShield icon in system tray (near clock)
   - If not there, launch from Start Menu

2. **Verify Port is Open**
   - Desktop app uses port **47147**
   - Ensure no firewall is blocking `localhost:47147`

3. **Test Connection Manually**
   - Open browser
   - Visit: `http://localhost:47147/status`
   - Should show: `{"status":"online","version":"0.1.0"}`

4. **Restart Both**
   - Close browser completely
   - Restart desktop app from Start Menu
   - Re-open browser

---

## ⚙️ Basic Configuration

### Desktop App Settings

1. **Access Settings**
   - Open desktop app (from tray or Start Menu)
   - Click "Settings" tab
   - Enter your guardian password when prompted

2. **Application Blocking**
   - Go to "Apps" tab
   - Click "Add Application"
   - Browse and select `.exe` files you want to block
   - Click "Block Application"

3. **Browser Extension Sync**
   - Ensure "Enable Extension Connection" is ON
   - Click "Sync Now" to push settings to browser extensions

### Browser Extension Settings

1. **Access Extension Settings**
   - Click AmnShield icon in toolbar
   - Click "Settings" (gear icon)

2. **Configure Blocking**
   - **Block Lists:** Enable/disable categories:
     - Adult Content ☑
     - Gambling Sites ☑
     - Interest-Based Finance (Riba) ☑
     - Alcohol/Drugs ☑
     - Dating Websites ☑
   - **Custom Sites:** Add specific URLs to block

3. **Override Password**
   - Set an override password (must match desktop app guardian password)
   - This allows temporary unblocking with authentication

---

## 🎯 Using AmnShield

### Browsing with Protection

1. **Normal Browsing**
   - Browse as usual
   - Inappropriate sites will be automatically blocked
   - You'll see a block page with an Islamic message

2. **When Content is Blocked**
   - **Block Page** shows:
     - Reason for blocking (category)
     - Islamic reminder about purity
     - Option to go back
     - Option to override (with password)

3. **Temporary Override**
   - Click "Override Block" on block page
   - Enter guardian password
   - Site will be allowed for this session only
   - Block resets when you close the tab

### Managing Desktop App

1. **System Tray Usage**
   - **Left-click icon:** Open dashboard
   - **Right-click icon:** Quick menu
     - Open Dashboard
     - Settings
     - Sync Extensions
     - Exit (requires password)

2. **Dashboard Overview**
   - **Statistics:** Blocked attempts, active time
   - **Recent Blocks:** Last 10 blocked applications/sites
   - **Connection Status:** Extension sync indicator

3. **Exiting the App**
   - Click system tray icon → Exit
   - Enter guardian password
   - Confirmation required to prevent unauthorized closing

---

## 🔄 Updating AmnShield

### Desktop App Updates

*Automatic updates are not available in v0.1.0*

To update manually:
1. Download new installer version
2. Run installer (will replace old version)
3. Your settings and passwords are preserved

### Browser Extension Updates

#### Chrome/Edge:
- Once on Chrome Web Store, updates will be automatic
- For manual installs: Download new ZIP and replace folder

#### Firefox:
- Once on Firefox Add-ons, updates will be automatic
- For manual installs: Download new ZIP and reinstall

---

## 🗑️ Uninstalling AmnShield

### Uninstall Desktop App

1. **Via Start Menu**
   - Start Menu → AmnShield → Uninstall AmnShield

2. **Via Windows Settings**
   - Settings → Apps → Apps & features
   - Find "AmnShield"
   - Click → Uninstall

3. **During Uninstallation**
   - Enter guardian password
   - Choose whether to keep settings:
     - ☐ Remove all settings and data (clean uninstall)
     - ☑ Keep settings for future reinstall
   - Click "Uninstall"

### Remove Browser Extension

#### Chrome/Edge:
- Go to `chrome://extensions/`
- Find "Deen Shield"
- Click "Remove"

#### Firefox:
- Go to `about:addons`
- Find "Deen Shield"
- Click "..." → Remove

---

## 🆘 Troubleshooting

### Desktop App Won't Start

**Problem:** Double-clicking does nothing

**Solutions:**
1. Check Task Manager → Processes tab
   - If "AmnShield_flutter.exe" is running, end it
   - Try launching again
2. Reinstall the application
3. Check Windows Event Viewer for error logs

### Forgot Guardian Password

**Problem:** Can't access settings or uninstall

**Solution (v0.1.0):**
- Currently, there's no password recovery
- Workaround:
  1. Download password reset tool (coming soon)
  2. Or reinstall application (settings will be lost)

**Prevention:**
- Write password down in a secure location
- Use a memorable but strong passphrase

### Extension Not Blocking Sites

**Problem:** Inappropriate sites still loading

**Solutions:**
1. Check extension is enabled:
   - `chrome://extensions/` or `about:addons`
   - Ensure toggle is ON
2. Verify permissions granted
3. Reload extension:
   - Chrome: Click "↻" reload button
   - Firefox: Disable and re-enable
4. Check block list settings:
   - Open extension settings
   - Ensure categories are enabled

### Connection to Desktop App Fails

**Problem:** Extension shows "Disconnected"

**Solutions:**
1. Verify desktop app is running (check system tray)
2. Test connection:
   - Open browser
   - Visit `http://localhost:47147/status`
   - Should show JSON response
3. Check Windows Firewall:
   - Allow `AmnShield_flutter.exe` for local connections
4. Restart both app and browser

---

## 📧 Getting Help

### Resources
- **GitHub Issues:** https://github.com/alhaqdigital/AmnShield-releases/issues
- **Discussions:** https://github.com/alhaqdigital/AmnShield-releases/discussions
- **Email Support:** support@alhaqdigital.com

### Reporting Bugs
When reporting issues, include:
- AmnShield version (v0.1.0)
- Windows version (e.g., Windows 11 22H2)
- Browser and version (e.g., Chrome 120)
- Steps to reproduce the problem
- Screenshots if applicable

---

## 🤲 May Allah Protect You

**"O you who believe! Enter into Islam completely and do not follow the footsteps of Satan. Indeed, he is to you a clear enemy." (Quran 2:208)**

Thank you for using AmnShield. May it help you maintain your digital purity and strengthen your connection with Allah (SWT).

**JazakAllahu Khair!**

---

**Developed by:** Alhaq Digital Services (ADS)  
**Version:** 0.1.0  
**Last Updated:** November 9, 2025
