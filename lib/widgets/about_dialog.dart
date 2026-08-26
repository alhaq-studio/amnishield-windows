import 'package:flutter/material.dart';

class AboutAmnShieldDialog extends StatelessWidget {
  const AboutAmnShieldDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AboutAmnShieldDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(24),
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AmnShield Guardian',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'v8.26.2026 - Windows Desktop Edition',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AmnShield Guardian is a next-generation distraction blocking and digital focus platform engineered for Windows desktop.',
              style: TextStyle(height: 1.4, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              'Core Capabilities & Technologies',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            _buildFeatureRow(Icons.security, 'Real-Time Process Interceptor', 'C# Guardian Background Service'),
            _buildFeatureRow(Icons.apps, '100% App Discovery & Icon Engine', 'Native Win32 Resource Extractor'),
            _buildFeatureRow(Icons.verified_user, 'User Whitelist & Custom Protection', 'Zero False Termination Guarantee'),
            _buildFeatureRow(Icons.web, 'System-Wide Web Filter', 'Hosts File & Domain Filter Packs'),
            _buildFeatureRow(Icons.psychology, 'Focus Overlay & Quotes Engine', 'Motivational Overlay Warning'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/alhaq_logo.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, size: 36),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Built by Al-Haq Studio',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Developed by Afrasyaab Meranai | Al-Haq.uk',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '© 2026 Al-Haq Studio. All rights reserved.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  'All Rights Reserved',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
