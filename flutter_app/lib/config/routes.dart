/// Configuration des routes de navigation
library;

import 'package:flutter/material.dart';

/// Noms des routes de l'application
class AppRoutes {
  // Routes actives
  static const String welcome = '/';
  static const String campagneList = '/campagnes';
  static const String personnageSelect = '/personnage/select';
  static const String personnageCreate = '/personnage/create';

  // Routes QR Code
  static const String qrDisplay = '/qr/display';
  static const String qrScan = '/qr/scan';
  
  /// Map des routes pour MaterialApp (navigation déclarative via Navigator.push)
  static Map<String, WidgetBuilder> get routes => {};
}

/// Génère les routes de l'application
class AppRouter {
  /// Génère une route avec transition personnalisée
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Pour l'instant, retourne une route vide
    // Sera implémenté quand les écrans seront créés
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(
          child: Text('Route non implémentée'),
        ),
      ),
      settings: settings,
    );
  }

  /// Transition de type slide (par défaut)
  static PageRouteBuilder<T> slideRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Transition de type fade
  static PageRouteBuilder<T> fadeRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}
