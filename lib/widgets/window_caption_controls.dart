import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowCaptionControls extends StatefulWidget {
  final Color? color;

  const WindowCaptionControls({super.key, this.color});

  @override
  State<WindowCaptionControls> createState() => _WindowCaptionControlsState();
}

class _WindowCaptionControlsState extends State<WindowCaptionControls> {
  bool _isMaximized = false;

  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      _checkMaximized();
    }
  }

  Future<void> _checkMaximized() async {
    if (!_isDesktop) return;
    try {
      final max = await windowManager.isMaximized();
      if (mounted) {
        setState(() {
          _isMaximized = max;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleMaximize() async {
    if (!_isDesktop) return;
    if (_isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    await _checkMaximized();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) {
      return const SizedBox.shrink();
    }

    final iconColor = widget.color ?? Theme.of(context).colorScheme.onPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minimize Button (-)
        InkWell(
          onTap: () => windowManager.minimize(),
          hoverColor: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 44,
            height: 38,
            alignment: Alignment.center,
            child: Icon(Icons.remove, color: iconColor, size: 18),
          ),
        ),

        // Maximize / Restore Button (🗖)
        InkWell(
          onTap: _toggleMaximize,
          hoverColor: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 44,
            height: 38,
            alignment: Alignment.center,
            child: Icon(
              _isMaximized ? Icons.filter_none : Icons.crop_square,
              color: iconColor,
              size: _isMaximized ? 14 : 16,
            ),
          ),
        ),

        // Close Button (✕)
        InkWell(
          onTap: () => windowManager.close(),
          hoverColor: Colors.red.shade700,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 44,
            height: 38,
            alignment: Alignment.center,
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}
