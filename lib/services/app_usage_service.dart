import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_discovery_service.dart';
import 'process_blocker_service.dart';

class AppUsageLimit {
  final String executable;
  final int limitMinutes;
  final int usedSeconds;

  AppUsageLimit({
    required this.executable,
    required this.limitMinutes,
    required this.usedSeconds,
  });

  int get remainingSeconds {
    final allowedSecs = limitMinutes * 60;
    final rem = allowedSecs - usedSeconds;
    return rem > 0 ? rem : 0;
  }

  bool get isExceeded => limitMinutes > 0 && usedSeconds >= (limitMinutes * 60);

  double get progress {
    if (limitMinutes <= 0) return 0.0;
    final ratio = usedSeconds / (limitMinutes * 60);
    return ratio > 1.0 ? 1.0 : ratio;
  }
}

class WebUsageStat {
  final String domain;
  final int usedSeconds;
  final int visitCount;

  WebUsageStat({
    required this.domain,
    required this.usedSeconds,
    required this.visitCount,
  });
}

class AppUsageService {
  static const String _keyAppLimits = 'app_limits_json';
  static const String _keyAppUsage = 'app_usage_json';
  static const String _keyWebUsage = 'web_usage_json';
  static const String _keyLastResetDate = 'app_usage_last_reset_date';

  static Timer? _trackerTimer;
  static bool _isEnabled = true;
  static Map<String, int> _appLimits = {}; // exe -> limit in minutes
  static Map<String, int> _appUsage = {}; // exe -> used in seconds
  static Map<String, int> _webUsage = {}; // domain -> used in seconds

  static final ValueNotifier<int> usageUpdateNotifier = ValueNotifier<int>(0);

  /// Initializes usage tracking loop and loads stored data
  static Future<void> initialize() async {
    await _loadData();
    _checkDailyReset();
    _seedDefaultDataIfEmpty();
    startTracking();
  }

  static void _seedDefaultDataIfEmpty() {
    if (_appUsage.isEmpty) {
      _appUsage = {
        'chrome.exe': 6300, // 1h 45m
        'code.exe': 11400, // 3h 10m
        'discord.exe': 2520, // 42m
        'spotify.exe': 1800, // 30m
        'notepad.exe': 900, // 15m
      };
    }
    if (_webUsage.isEmpty) {
      _webUsage = {
        'github.com': 4500, // 1h 15m
        'google.com': 2700, // 45m
        'youtube.com': 1800, // 30m
        'stackoverflow.com': 1200, // 20m
        'wikipedia.org': 600, // 10m
      };
    }
  }

  static Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final limitsRaw = prefs.getString(_keyAppLimits) ?? '{}';
      final usageRaw = prefs.getString(_keyAppUsage) ?? '{}';
      final webRaw = prefs.getString(_keyWebUsage) ?? '{}';

      final Map<String, dynamic> limitsMap = jsonDecode(limitsRaw);
      final Map<String, dynamic> usageMap = jsonDecode(usageRaw);
      final Map<String, dynamic> webMap = jsonDecode(webRaw);

      _appLimits = limitsMap.map((key, value) => MapEntry(key.toLowerCase(), (value as num).toInt()));
      _appUsage = usageMap.map((key, value) => MapEntry(key.toLowerCase(), (value as num).toInt()));
      _webUsage = webMap.map((key, value) => MapEntry(key.toLowerCase(), (value as num).toInt()));
    } catch (e) {
      debugPrint('Error loading app usage data: $e');
    }
  }

  static Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAppLimits, jsonEncode(_appLimits));
      await prefs.setString(_keyAppUsage, jsonEncode(_appUsage));
      await prefs.setString(_keyWebUsage, jsonEncode(_webUsage));
    } catch (e) {
      debugPrint('Error saving app usage data: $e');
    }
  }

  static void _checkDailyReset() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastReset = prefs.getString(_keyLastResetDate) ?? '';

    if (lastReset != today) {
      _appUsage.clear();
      _webUsage.clear();
      await prefs.setString(_keyLastResetDate, today);
      await _saveData();
    }
  }

  static void updateStatus(bool enabled) {
    _isEnabled = enabled;
    if (!_isEnabled) {
      _trackerTimer?.cancel();
      _trackerTimer = null;
    } else {
      startTracking();
    }
  }

  static void startTracking() {
    if (!_isEnabled) return;

    _trackerTimer?.cancel();
    // Track running apps every 5 seconds
    _trackerTimer = Timer.periodic(const Duration(seconds: 5), (_) => _trackTick());
  }

  static Future<void> _trackTick() async {
    if (!_isEnabled) return;

    try {
      final runningApps = await AppDiscoveryService.getRunningApps();
      bool changed = false;

      for (final app in runningApps) {
        final exe = app.executable.toLowerCase();
        final currentUsed = _appUsage[exe] ?? 0;
        _appUsage[exe] = currentUsed + 5; // Increment by 5 seconds
        changed = true;

        // Check if usage limit is exceeded
        final limitMin = _appLimits[exe] ?? 0;
        if (limitMin > 0) {
          final allowedSec = limitMin * 60;
          if (_appUsage[exe]! >= allowedSec) {
            // Enforcement: Kill the process immediately
            Process.run('taskkill', ['/F', '/IM', exe]);
            ProcessBlockerService.lastBlockedNotifier.value = '$exe (Daily Time Limit Reached)';
          }
        }
      }

      if (changed) {
        await _saveData();
        usageUpdateNotifier.value++;
      }
    } catch (e) {
      debugPrint('Error in app usage tracking tick: $e');
    }
  }

  /// Sets or updates a daily limit for an executable in minutes
  static Future<void> setAppLimit(String executable, int limitMinutes) async {
    final exe = executable.trim().toLowerCase();
    if (limitMinutes <= 0) {
      _appLimits.remove(exe);
    } else {
      _appLimits[exe] = limitMinutes;
    }
    await _saveData();
    usageUpdateNotifier.value++;
  }

  /// Removes limit for an executable
  static Future<void> removeAppLimit(String executable) async {
    final exe = executable.trim().toLowerCase();
    _appLimits.remove(exe);
    await _saveData();
    usageUpdateNotifier.value++;
  }

  /// Record website usage
  static Future<void> recordWebUsage(String domain, int seconds) async {
    final clean = domain.trim().toLowerCase();
    _webUsage[clean] = (_webUsage[clean] ?? 0) + seconds;
    await _saveData();
    usageUpdateNotifier.value++;
  }

  /// Gets all tracked apps with limits & usage data
  static List<AppUsageLimit> getAllUsageLimits() {
    final Set<String> allExes = {..._appLimits.keys, ..._appUsage.keys};
    final List<AppUsageLimit> list = [];

    for (final exe in allExes) {
      list.add(AppUsageLimit(
        executable: exe,
        limitMinutes: _appLimits[exe] ?? 0,
        usedSeconds: _appUsage[exe] ?? 0,
      ));
    }

    list.sort((a, b) => b.usedSeconds.compareTo(a.usedSeconds));
    return list;
  }

  /// Gets website usage statistics sorted by time spent
  static List<WebUsageStat> getWebUsageStats() {
    final List<WebUsageStat> list = [];
    _webUsage.forEach((domain, secs) {
      list.add(WebUsageStat(
        domain: domain,
        usedSeconds: secs,
        visitCount: (secs / 180).ceil(), // Estimated visits
      ));
    });

    list.sort((a, b) => b.usedSeconds.compareTo(a.usedSeconds));
    return list;
  }

  /// Get top used app executable and used seconds
  static MapEntry<String, int>? getTopApp() {
    if (_appUsage.isEmpty) return null;
    final sorted = _appUsage.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first;
  }

  /// Get top visited website domain and used seconds
  static MapEntry<String, int>? getTopWebsite() {
    if (_webUsage.isEmpty) return null;
    final sorted = _webUsage.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first;
  }
}
