import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/config_syncer.dart';

class BlockOverlayDialog extends StatefulWidget {
  final String blockedItemName;
  final VoidCallback? onDismiss;

  const BlockOverlayDialog({
    super.key,
    required this.blockedItemName,
    this.onDismiss,
  });

  static bool _isOverlayShowing = false;

  static Future<void> show(BuildContext context, String blockedItemName) async {
    if (_isOverlayShowing) return;

    final config = await ConfigSyncer.loadLocalConfig();
    final showOverlay = config['show_block_overlay'] ?? true;
    if (!showOverlay) return;

    if (!context.mounted) return;

    _isOverlayShowing = true;

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        builder: (context) => BlockOverlayDialog(blockedItemName: blockedItemName),
      );
    } finally {
      _isOverlayShowing = false;
    }
  }

  @override
  State<BlockOverlayDialog> createState() => _BlockOverlayDialogState();
}

class _BlockOverlayDialogState extends State<BlockOverlayDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  final TextEditingController _passcodeController = TextEditingController();

  late String _motivationalQuote;
  String _unlockError = '';
  bool _showPasscodePrompt = false;
  String _storedPassword = '';

  static const List<String> _quotes = [
    '"Starve your distractions, feed your focus."',
    '"Your future is created by what you do today, not tomorrow."',
    '"Focus is a muscle. The more you practice, the stronger it gets."',
    '"Distraction is temporary. Your long-term goals are permanent."',
    '"Focus on being productive instead of busy."',
    '"Master your focus, master your destiny."',
  ];

  @override
  void initState() {
    super.initState();
    _motivationalQuote = _quotes[Random().nextInt(_quotes.length)];

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadStoredPassword();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredPassword() async {
    final config = await ConfigSyncer.loadLocalConfig();
    if (mounted) {
      setState(() {
        _storedPassword = config['password'] ?? '';
      });
    }
  }

  Future<void> _verifyPasscode() async {
    final text = _passcodeController.text.trim();
    if (_storedPassword.isNotEmpty && text == _storedPassword) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDismiss?.call();
      }
    } else {
      setState(() {
        _unlockError = 'Incorrect master passcode.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Pulsing Shield Icon
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.12),
                  border: Border.all(color: Colors.red.shade400, width: 2),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 56,
                  color: Colors.red.shade400,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            const Text(
              'Access Restricted',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              '${widget.blockedItemName} is blocked by AmnShield Guardian',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Motivational Quote Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _motivationalQuote,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Passcode unlock section if expanded
            if (_showPasscodePrompt) ...[
              TextField(
                controller: _passcodeController,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Master Passcode',
                  border: const OutlineInputBorder(),
                  errorText: _unlockError.isNotEmpty ? _unlockError : null,
                ),
                onSubmitted: (_) => _verifyPasscode(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showPasscodePrompt = false;
                          _unlockError = '';
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _verifyPasscode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Unlock'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onDismiss?.call();
                  },
                  icon: const Icon(Icons.psychology_outlined),
                  label: const Text('RETURN TO FOCUS', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              if (_storedPassword.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showPasscodePrompt = true;
                    });
                  },
                  icon: const Icon(Icons.lock_open, size: 16),
                  label: const Text('Emergency Passcode Unlock'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
