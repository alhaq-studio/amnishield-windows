import 'package:flutter/material.dart';
import '../services/config_syncer.dart';
import '../services/license_service.dart';

import '../services/payment_manager.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onOnboardingComplete;

  const OnboardingScreen({super.key, required this.onOnboardingComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;

  // Targeting options
  bool _targetWeb = true;
  bool _targetReels = true;
  bool _targetFocus = false;

  // Account choice
  bool _isLocalMode = true;

  // License Key entry
  final TextEditingController _keyController = TextEditingController();
  String _keyStatus = '';

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _finishOnboarding() async {
    // Apply targeting defaults
    await ConfigSyncer.savePackStates(
      adultPackActive: _targetWeb,
      socialPackActive: _targetReels,
    );
    await ConfigSyncer.saveOnboardingCompleted(true);
    widget.onOnboardingComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          margin: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Step Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isActive = index == _currentStep;
                      final isDone = index < _currentStep;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 32 : 12,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : isDone
                                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                  : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Step Content
                  Flexible(
                    child: SingleChildScrollView(
                      child: _buildStepContent(theme),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Navigation Buttons
                  Row(
                    children: [
                      if (_currentStep > 0)
                        OutlinedButton(
                          onPressed: _prevStep,
                          child: const Text('Back'),
                        )
                      else
                        const SizedBox.shrink(),
                      const Spacer(),
                      if (_currentStep < 3)
                        FilledButton(
                          onPressed: _nextStep,
                          child: Text(_currentStep == 0 ? 'Get Started' : 'Continue'),
                        )
                      else
                        FilledButton(
                          onPressed: _finishOnboarding,
                          child: const Text('Finish & Start AmnShield'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(theme);
      case 1:
        return _buildAccountStep(theme);
      case 2:
        return _buildTargetingStep(theme);
      case 3:
        return _buildSupportStep(theme);
      default:
        return Container();
    }
  }

  // Step 0: Welcome
  Widget _buildWelcomeStep(ThemeData theme) {
    return Column(
      children: [
        const Text('🛡️', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(
          'Welcome to AmnShield',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your unified, privacy-first desktop guardian. Designed by Al-Haq Initiative to protect your eyes, focus, and digital well-being.',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('✨ Key Principles:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• 100% Free & Open Source (No Forced Paywalls)'),
              Text('• Privacy-First: All filtering runs locally on your device'),
              Text('• Customizable Rules & Cross-Platform Sync'),
            ],
          ),
        ),
      ],
    );
  }

  // Step 1: Account Choice
  Widget _buildAccountStep(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Choose How You Want to Use AmnShield',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'You can sign in to sync rules across devices or use local offline mode.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          elevation: _isLocalMode ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isLocalMode ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              width: _isLocalMode ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const Text('🔒', style: TextStyle(fontSize: 32)),
            title: const Text('Use Local Mode (No Account Required)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Keep everything local on this PC. Zero cloud interaction required.'),
            trailing: Radio<bool>(
              value: true,
              // ignore: deprecated_member_use
              groupValue: _isLocalMode,
              // ignore: deprecated_member_use
              onChanged: (val) => setState(() => _isLocalMode = val!),
            ),
            onTap: () => setState(() => _isLocalMode = true),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: !_isLocalMode ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: !_isLocalMode ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              width: !_isLocalMode ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const Text('☁️', style: TextStyle(fontSize: 32)),
            title: const Text('Sign In with AmnShield Account', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Sync rules, blocklists, and settings across Android, Windows, and Browser Extensions.'),
            trailing: Radio<bool>(
              value: false,
              // ignore: deprecated_member_use
              groupValue: _isLocalMode,
              // ignore: deprecated_member_use
              onChanged: (val) => setState(() => _isLocalMode = val!),
            ),
            onTap: () => setState(() => _isLocalMode = false),
          ),
        ),
      ],
    );
  }

  // Step 2: Protection Goals
  Widget _buildTargetingStep(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Smart Protection Goals',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Select your primary protection priorities for Windows.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        CheckboxListTile(
          value: false,
          onChanged: null,
          title: const Text('👁️ Gaze & Eye-Guarding (Coming Soon)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          subtitle: const Text('[Under Development] Real-time image & video blurring', style: TextStyle(color: Colors.grey)),
        ),
        CheckboxListTile(
          value: _targetWeb,
          onChanged: (val) => setState(() => _targetWeb = val!),
          title: const Text('🛡️ Web & Adult Content Filter', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Block explicit websites & harmful domain searches'),
        ),
        CheckboxListTile(
          value: _targetReels,
          onChanged: (val) => setState(() => _targetReels = val!),
          title: const Text('📱 Reels & Short Video Blocker', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Block addictive social video feeds'),
        ),
        CheckboxListTile(
          value: _targetFocus,
          onChanged: (val) => setState(() => _targetFocus = val!),
          title: const Text('🎯 Focus & App Launch Blocker', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Enforce app usage rules & focus sessions'),
        ),
      ],
    );
  }

  // Step 3: Support Al-Haq Initiative
  Widget _buildSupportStep(ThemeData theme) {
    return Column(
      children: [
        const Text('👑', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(
          'AmnShield Pro & Supporter',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Core content blocking is 100% Free. Upgrade to Pro to unlock advanced security & cloud features across all your devices.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withAlpha(100)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✨ Included in AmnShield Pro:',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 8),
              const Text('🔄 Cross-Platform Cloud Sync (Android, Windows, Web)'),
              const SizedBox(height: 4),
              const Text('🔒 Anti-Uninstall & Extension Removal Protection'),
              const SizedBox(height: 4),
              const Text('🔑 Passcode & PIN Settings Protection'),
              const SizedBox(height: 4),
              const Text('💖 Support Open-Source AI Filter Development'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final launched = await PaymentManager.openStripeCheckout(plan: 'monthly');
                  if (!launched && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch Stripe Checkout browser.')),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Column(
                  children: [
                    Text('MONTHLY PASS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('\$4.99 / mo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final launched = await PaymentManager.openStripeCheckout(plan: 'annual');
                  if (!launched && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch Stripe Checkout browser.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Column(
                  children: [
                    Text('ANNUAL PASS ⭐', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('\$39.99 / yr', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _keyController,
          decoration: InputDecoration(
            labelText: 'Have a Pro License Key?',
            hintText: 'Paste key here',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () {
                final key = _keyController.text.trim();
                if (key.isNotEmpty) {
                  final payload = LicenseService.verifyLicense(key);
                  setState(() {
                    _keyStatus = (payload != null && !payload.isExpired)
                        ? '✅ Valid Pro Key! Thank you for your support!'
                        : '❌ Invalid or Expired License Key.';
                  });
                }
              },
            ),
          ),
        ),
        if (_keyStatus.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_keyStatus, style: TextStyle(color: _keyStatus.startsWith('✅') ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }
}
