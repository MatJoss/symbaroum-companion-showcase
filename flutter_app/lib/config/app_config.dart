/// Configuration de l'application Symbaroum Companion
/// Contient les URLs serveur et constantes globales
library;

import 'package:flutter/foundation.dart';

/// Configuration du serveur backend
class ServerConfig {
  /// URL de base du serveur (Google Cloud Run)
  static const String baseUrl = 'https://YOUR_CLOUD_RUN_URL.run.app';

  /// URL locale pour le développement
  static const String localUrl = 'http://127.0.0.1:5000';

  /// Timeout par défaut pour les requêtes HTTP (en secondes)
  static const int defaultTimeout = 30;

  /// Nombre de tentatives de reconnexion SSE (legacy)
  static const int sseReconnectAttempts = 5;

  /// Délai entre les tentatives de reconnexion SSE (legacy, en secondes)
  static const int sseReconnectDelay = 2;

  /// Nombre de tentatives de reconnexion WebSocket
  static const int socketReconnectAttempts = 5;

  /// Délai entre les tentatives de reconnexion WebSocket (en secondes)
  static const int socketReconnectDelay = 2;

  /// Utiliser le serveur local en mode debug
  static const bool useLocalInDebug = false;

  /// Retourne l'URL appropriée selon l'environnement
  static String get url {
    // En mode release, toujours utiliser le serveur distant
    const bool isRelease = bool.fromEnvironment('dart.vm.product');
    if (isRelease || !useLocalInDebug) {
      return baseUrl;
    }
    return localUrl;
  }
}

/// Configuration de l'application
class AppConfig {
  /// Nom de l'application
  static const String appName = 'Symbaroum Companion';

  /// Version de l'application
  static const String version = '1.0.0';

  /// Durée d'affichage des snackbars (en secondes)
  static const int snackbarDuration = 3;

  /// Nombre maximum de messages chat à charger initialement
  static const int chatInitialLoadCount = 50;

  /// Intervalle de rafraîchissement auto (en secondes) - fallback si SSE échoue
  static const int fallbackRefreshInterval = 30;
  
  // ==================== ALIAS POUR COMPATIBILITÉ ====================
  
  /// Host du serveur (extrait de l'URL)
  static String get serverHost => Uri.parse(ServerConfig.baseUrl).host;
  
  /// Port du serveur (extrait de l'URL)
  static int get serverPort => Uri.parse(ServerConfig.baseUrl).port;
  
  /// Utilise HTTPS
  static bool get useHttps => ServerConfig.baseUrl.startsWith('https');
  
  /// URL de base (alias pour ServerConfig)
  static String get baseUrl => ServerConfig.baseUrl;
  
  // ==================== LOGGING ====================
  
  /// Mode debug - active les logs détaillés
  /// En production (release mode), automatiquement désactivé
  static bool get enableDebugLogs => kDebugMode;
  
  /// Log helper - affiche uniquement en mode debug
  static void debugLog(String message) {
    if (enableDebugLogs) {
      debugPrint('🔍 $message');
    }
  }
  
  /// Log d'erreur - toujours affiché
  static void errorLog(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('❌ ERROR: $message');
    if (error != null) {
      debugPrint('Error details: $error');
    }
    if (stackTrace != null && enableDebugLogs) {
      debugPrint('Stack trace: $stackTrace');
    }
  }
  
  /// Log d'information - affiché même en production (pour infos importantes)
  static void infoLog(String message) {
    debugPrint('ℹ️ $message');
  }
}
