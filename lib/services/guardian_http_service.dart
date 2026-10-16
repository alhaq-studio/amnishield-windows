import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'config_syncer.dart';
import 'license_service.dart';

class GuardianHttpService {
  static HttpServer? _server;
  static bool _isRunning = false;

  static bool get isRunning => _isRunning;

  static Future<void> start() async {
    if (kIsWeb || _isRunning) return;

    try {
      // Bind to 127.0.0.1:48192 using standard non-admin socket binding
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        48192,
        shared: true,
      );
      _isRunning = true;
      debugPrint('[GuardianHttpService] HTTP API server listening on http://127.0.0.1:48192/');

      _server!.listen((HttpRequest request) async {
        _handleRequest(request);
      }, onError: (e) {
        debugPrint('[GuardianHttpService] Server error: $e');
      });
    } catch (e) {
      _isRunning = false;
      debugPrint('[GuardianHttpService] Failed to bind HTTP server on 48192: $e');
    }
  }

  static Future<void> stop() async {
    if (kIsWeb) return;
    _isRunning = false;
    await _server?.close(force: true);
    _server = null;
  }

  static Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;

    // CORS Headers for browser extensions
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.noContent;
      await response.close();
      return;
    }

    if (request.uri.path == '/status' || request.uri.path == '/') {
      final config = await ConfigSyncer.loadLocalConfig();

      final focusModeActive = config['focus_mode_active'] ?? true;
      final appBlockerEnabled = config['app_blocker_enabled'] ?? true;
      final webFilterEnabled = config['web_filter_enabled'] ?? true;

      final isWebActive = webFilterEnabled;
      final isAppActive = focusModeActive && appBlockerEnabled;

      final customDomains = List<String>.from(config['blocked_domains'] ?? []);
      final adultActive = config['adult_pack_active'] ?? false;
      final socialActive = config['social_pack_active'] ?? false;

      final allDomains = <String>{};

      if (isWebActive) {
        allDomains.addAll(customDomains.map((d) => d.trim().toLowerCase()));

        if (socialActive) {
          allDomains.addAll([
            'facebook.com', 'www.facebook.com', 'fb.com', 'instagram.com', 'www.instagram.com',
            'twitter.com', 'www.twitter.com', 'x.com', 'www.x.com', 'tiktok.com', 'www.tiktok.com',
            'reddit.com', 'www.reddit.com', 'snapchat.com', 'www.snapchat.com'
          ]);
        }

        if (adultActive) {
          try {
            String data = await rootBundle.loadString('assets/blocklists/adult_domains.txt');
            final lines = data.split('\n');
            for (final line in lines) {
              final trimmed = line.trim().toLowerCase();
              if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
                allDomains.add(trimmed);
              }
            }
          } catch (e) {
            debugPrint('[GuardianHttpService] Error loading adult pack asset: $e');
          }
        }
      }

      final isPrem = await LicenseService.isPremium();

      final statusJson = {
        'status': 'online',
        'is_premium': isPrem,
        'web_filter_enabled': isWebActive,
        'focus_mode_active': focusModeActive,
        'adult_pack_active': adultActive,
        'social_pack_active': socialActive,
        'custom_domains': customDomains,
        'windows_custom_domains': customDomains,
        'banned_apps_count': isAppActive ? (config['blocked_apps'] as List? ?? []).length : 0,
        'banned_domains_count': allDomains.length,
        'banned_domains': allDomains.toList(),
      };

      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode(statusJson));
      await response.close();
      return;
    }

    if ((request.uri.path == '/update-domains' || request.uri.path == '/update-domains/') && request.method == 'POST') {
      try {
        final content = await utf8.decoder.bind(request).join();
        final body = jsonDecode(content) as Map<String, dynamic>;
        final newDomains = List<String>.from(body['blocked_domains'] ?? []);

        final config = await ConfigSyncer.loadLocalConfig();
        final apps = List<String>.from(config['blocked_apps'] ?? []);
        final focus = config['focus_mode_active'] ?? true;
        final adult = config['adult_pack_active'] ?? false;
        final social = config['social_pack_active'] ?? false;

        await ConfigSyncer.syncConfig(
          blockedApps: apps,
          customDomains: newDomains,
          focusModeActive: focus,
          adultPackActive: adult,
          socialPackActive: social,
        );

        response.statusCode = HttpStatus.ok;
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode({'success': true, 'updated_domains': newDomains}));
        await response.close();
        return;
      } catch (e) {
        response.statusCode = HttpStatus.badRequest;
        response.write(jsonEncode({'error': e.toString()}));
        await response.close();
        return;
      }
    }

    response.statusCode = HttpStatus.notFound;
    await response.close();
  }
}
