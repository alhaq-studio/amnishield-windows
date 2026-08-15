import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PaymentManager {
  static const String _supabaseCheckoutUrl =
      'https://jrgpmcomvibgklmvnxud.supabase.co/functions/v1/stripe-checkout';
  static const String _fallbackPricingUrl =
      'https://amnishield.com/#pricing';

  /// Triggers direct Stripe Checkout via Supabase Edge Function
  static Future<String?> createStripeCheckoutSession({
    String plan = 'annual',
    String? customerEmail,
  }) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.postUrl(Uri.parse(_supabaseCheckoutUrl));
      request.headers.set('content-type', 'application/json');

      final body = jsonEncode({
        'plan': plan,
        'customerEmail': customerEmail,
        'successUrl': 'https://app.amnishield.com/?checkout=success',
        'cancelUrl': 'https://amnishield.com/#pricing',
      });

      request.write(body);
      final response = await request.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        return json['url'] as String?;
      } else {
        debugPrint('Stripe Checkout Edge Function error status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating Stripe Checkout session: $e');
      return null;
    }
  }

  /// Launch external system browser to complete checkout
  static Future<bool> openStripeCheckout({
    String plan = 'annual',
    String? customerEmail,
  }) async {
    final checkoutUrl = await createStripeCheckoutSession(
      plan: plan,
      customerEmail: customerEmail,
    );

    final urlToOpen = (checkoutUrl != null && checkoutUrl.isNotEmpty)
        ? checkoutUrl
        : '$_fallbackPricingUrl?plan=$plan';

    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', urlToOpen]);
        return true;
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [urlToOpen]);
        return true;
      } else if (Platform.isMacOS) {
        await Process.run('open', [urlToOpen]);
        return true;
      }
    } catch (e) {
      debugPrint('Failed to launch browser: $e');
    }
    return false;
  }
}
