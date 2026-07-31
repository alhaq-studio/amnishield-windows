import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/app_icon_service.dart';

class AppIconWidget extends StatelessWidget {
  final String executable;
  final String displayName;
  final String? path;
  final bool isWhitelisted;

  const AppIconWidget({
    super.key,
    required this.executable,
    required this.displayName,
    this.path,
    this.isWhitelisted = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AppIconService.getIconBase64(executable, path),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          return SizedBox(
            width: 36,
            height: 36,
            child: Image.memory(
              base64Decode(snapshot.data!),
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _buildAvatar(context),
            ),
          );
        }
        return _buildAvatar(context);
      },
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      backgroundColor: isWhitelisted
          ? Colors.green.shade100
          : Theme.of(context).colorScheme.secondaryContainer,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isWhitelisted
              ? Colors.green.shade800
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
