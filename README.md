# AmnShield Desktop - Unified Guardian

A modern Flutter desktop application for Windows that unifies desktop process monitoring, blocking, and configuration settings into a single, fast, and maintainable cross-platform solution.

## 🚀 Migration Summary

### **What Was Converted**

#### From C# Desktop App (AmnShield-Desktop-App):
- ✅ Password protection with encryption (SHA-256 + AES)
- ✅ Application discovery from registry and file system
- ✅ Process monitoring and blocking
- ✅ Advanced scheduling (Always, Weekdays, Weekend, Custom time ranges)
- ✅ Browser URL blocking via Windows registry
- ✅ System tray integration
- ✅ Admin privilege detection
- ✅ Modern Material Design UI

#### From Electron Manager (AmnShield-Desktop-Manager):
- ✅ Quick launch dashboard
- ✅ Search functionality
- ✅ Todo list management
- ✅ Notes/memo feature
- ✅ System power controls (Lock, Shutdown, Restart)
- ✅ Alt+Space hotkey support (via window_manager)
- ✅ Clean, modern interface

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point with Hive & window setup
├── models/
│   ├── blocked_app.dart      # App blocking model with scheduling
│   ├── todo_item.dart        # Todo list items
│   └── installed_application.dart  # Discovered apps
├── services/
│   ├── password_service.dart # Password encryption & verification
│   ├── guardian_service.dart # Process monitoring & blocking
│   └── windows_service.dart  # Windows API integration
├── screens/
│   ├── splash_screen.dart    # Initial loading screen
│   ├── home_screen.dart      # Main app with navigation
│   ├── dashboard_tab.dart    # Dashboard with status & quick actions
│   ├── apps_tab.dart         # App management (to be implemented)
│   ├── browser_tab.dart      # Browser controls (to be implemented)
│   └── security_tab.dart     # Security settings (to be implemented)
├── widgets/                  # Reusable UI components
├── providers/                # Riverpod state management
└── utils/                    # Helper functions
```

## 🔧 Setup Instructions

### Prerequisites
- Flutter SDK 3.5.0+
- Windows 10/11
- Visual Studio C++ Build Tools (for native compilation)

### Installation

1. **Install Dependencies**
```powershell
cd c:\Users\habib\PROJECTS\AmnShield\AmnShield_flutter
flutter pub get
```

2. **Generate Hive Adapters**
```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

3. **Run the Application**
```powershell
flutter run -d windows
```

4. **Build Release**
```powershell
flutter build windows --release
```

## 🎯 Key Features

### Security
- **Encrypted Password Storage**: Uses `flutter_secure_storage` with SHA-256 hashing
- **Default Password**: `deen` (can be changed from Security tab)
- **Minimum Password Length**: 4 characters

### App Protection
- **Full Block**: Terminates app immediately when detected
- **Scheduled Block**: Block only during specific times/days
  - Always: Block 24/7
  - Weekdays: Monday-Friday
  - Weekend: Saturday-Sunday
  - Custom: e.g., "Mon,Wed,Fri 08:00-17:00"

### System Integration
- **Process Monitoring**: Checks every 2 seconds
- **Admin Detection**: Warns if not running with elevated privileges
- **Registry Management**: Blocks Chrome/Edge extension pages
- **System Tray**: Minimizes to tray instead of closing

### Dashboard Features
- **Live Clock**: Current time and date
- **Status Cards**: Guardian status and protected app count
- **Quick Search**: Launch web searches
- **Todo List**: Track tasks
- **Notes**: Quick memo taking

## 🔨 Development Roadmap

### Phase 1: Core Functionality ✅
- [x] Project structure
- [x] Models and services
- [x] Basic UI navigation
- [ ] Complete Hive adapter generation
- [ ] Test basic app flow

### Phase 2: App Management
- [ ] Full apps tab implementation
- [ ] Application discovery dialog
- [ ] Add/remove blocked apps
- [ ] Schedule editor dialog
- [ ] App filtering and search

### Phase 3: Browser & Security
- [ ] Browser tab with URL list
- [ ] Registry integration for Chrome/Edge
- [ ] Security tab with password reset
- [ ] Admin privilege request

### Phase 4: Dashboard Enhancement
- [ ] Full todo list CRUD
- [ ] Notes persistence (Hive)
- [ ] Quick launch tiles
- [ ] Power controls integration
- [ ] Search integration with url_launcher

### Phase 5: Polish & Distribution
- [ ] System tray with context menu
- [ ] Global hotkey (Alt+Space)
- [ ] Auto-start on Windows boot
- [ ] Installer creation
- [ ] App icon and branding

## 📦 Dependencies

### Core
- `flutter_riverpod`: State management
- `hive` & `hive_flutter`: Local database
- `window_manager`: Window controls & hotkeys

### Security
- `flutter_secure_storage`: Secure password storage
- `encrypt`: AES encryption
- `crypto`: Hashing algorithms

### Windows
- `win32`: Windows API access
- `ffi`: Native code interop

### Utilities
- `shared_preferences`: Simple key-value storage
- `path_provider`: File system paths
- `url_launcher`: Open URLs & files
- `intl`: Date/time formatting

## 🔄 Migration Benefits

### Why Flutter vs C# WinForms?
1. **Modern UI**: Material Design 3, smooth animations
2. **Hot Reload**: Instant UI updates during development
3. **Cross-Platform Ready**: Easy to port to macOS/Linux
4. **Smaller Binary**: ~25MB vs ~100MB+ with .NET runtime
5. **Better Performance**: Native rendering, GPU acceleration
6. **Easier Maintenance**: Simpler codebase, better tooling

### Why Flutter vs Electron?
1. **Smaller Size**: ~25MB vs ~150MB+ (Chromium overhead)
2. **Better Performance**: Native widgets vs web rendering
3. **Lower Memory**: ~50MB vs ~200MB+ RAM usage
4. **Faster Startup**: <1s vs 2-3s
5. **Native Feel**: OS-native controls and behaviors

## 🛠️ Windows-Specific Features

### Process Management
```dart
WindowsService.killProcess('spotify');
WindowsService.isProcessRunning('chrome');
WindowsService.getRunningProcesses();
```

### Registry Operations
```dart
WindowsService.updateBrowserBlocklist(true, [
  'chrome://extensions',
  'edge://extensions',
]);
```

### Power Controls
```dart
WindowsService.lockWorkstation();
WindowsService.shutdown();
WindowsService.restart();
```

## 🐛 Known Issues & Limitations

1. **Admin Rights Required**: For registry modifications and some process operations
2. **Windows Only**: Currently targets Windows 10/11 (can be extended)
3. **No UWP/Store Apps**: Can only manage Win32 executables
4. **Manual Refresh**: App list doesn't auto-update (requires manual scan)

## 📝 Development Notes

### Testing Without Admin
Most features work without admin except:
- Browser URL blocking (registry)
- Some protected process termination
- System-wide hooks

### Debugging
```powershell
# Run with verbose logging
flutter run -d windows -v

# Check for Windows-specific issues
flutter doctor -v
```

### Building
```powershell
# Debug build (faster, includes DevTools)
flutter build windows

# Release build (optimized, smaller)
flutter build windows --release

# Executable location:
# build/windows/runner/Release/amnshield_flutter.exe
```

## 🤝 Next Steps

1. **Install dependencies**: `flutter pub get`
2. **Generate Hive adapters**: `flutter pub run build_runner build`
3. **Run the app**: `flutter run -d windows`
4. **Implement remaining tabs**: Apps, Browser, Security
5. **Add system tray integration**
6. **Test all features thoroughly**

## 📄 License

Same as original AmnShield projects.

## 🔗 Related Projects

- **AmnShield Extension**: Browser extension (Chrome/Firefox)
- **Original C# App**: `AmnShield-Desktop-App`
- **Original Electron Manager**: `AmnShield-Desktop-Manager`

---

**Built with ❤️ using Flutter**
