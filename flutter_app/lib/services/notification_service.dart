/// Service global de notifications UI
/// Remplace les logs verbeux par des popups utilisateur
library;

import 'package:flutter/material.dart';

class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = 
      GlobalKey<ScaffoldMessengerState>();

  /// Afficher un message de succès
  static void success(String message) {
    _showSnackBar(
      message,
      backgroundColor: Colors.green.shade700,
      icon: Icons.check_circle,
    );
  }

  /// Afficher un message d'erreur
  static void error(String message) {
    _showSnackBar(
      message,
      backgroundColor: Colors.red.shade700,
      icon: Icons.error,
      duration: const Duration(seconds: 5),
    );
  }

  /// Afficher un message d'info
  static void info(String message) {
    _showSnackBar(
      message,
      backgroundColor: Colors.blue.shade700,
      icon: Icons.info,
    );
  }

  /// Afficher un message d'avertissement
  static void warning(String message) {
    _showSnackBar(
      message,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.warning,
    );
  }

  static void _showSnackBar(
    String message, {
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
