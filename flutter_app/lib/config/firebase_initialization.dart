/// Initialisation Firebase
/// Configure et initialise Firebase au démarrage de l'application
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'firebase_config.dart';

final _logger = Logger(printer: SimplePrinter());

/// Options Firebase pour Web
class WebFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: FirebaseConfig.webApiKey,
      authDomain: FirebaseConfig.webAuthDomain,
      projectId: FirebaseConfig.projectId,
      storageBucket: FirebaseConfig.storageBucket,
      messagingSenderId: FirebaseConfig.webMessagingSenderId,
      appId: FirebaseConfig.webAppId,
    );
  }
}

/// Options Firebase pour Android
class AndroidFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: FirebaseConfig.androidApiKey,
      appId: FirebaseConfig.androidAppId,
      projectId: FirebaseConfig.projectId,
      storageBucket: FirebaseConfig.storageBucket,
      messagingSenderId: FirebaseConfig.webMessagingSenderId,
    );
  }
}

/// Initialise Firebase
Future<void> initializeFirebase() async {
  try {
    _logger.i('🔥 Initialisation de Firebase...');

    // Sélectionner les options selon la plateforme
    FirebaseOptions? options;
    
    if (kIsWeb) {
      options = WebFirebaseOptions.currentPlatform;
      _logger.d('Plateforme: Web');
    } else {
      // TODO: Détecter Android/iOS
      options = AndroidFirebaseOptions.currentPlatform;
      _logger.d('Plateforme: Android');
    }

    await Firebase.initializeApp(options: options);

    // === Firebase App Check ===
    // If running on Web, try to use reCAPTCHA v3 provider when a site key is configured.
    // On native platforms, use Play Integrity (Android) / App Attest (iOS) in release,
    // and use the debug provider in debug mode/emulator for development.
    try {
      if (kIsWeb) {
        if (FirebaseConfig.recaptchaSiteKey.isNotEmpty) {
          await FirebaseAppCheck.instance.activate(
            webProvider: ReCaptchaV3Provider(FirebaseConfig.recaptchaSiteKey),
          );
          _logger.i('✅ App Check activated for Web (reCAPTCHA v3)');
        } else {
          _logger.w('⚠️ No reCAPTCHA site key configured; skipping Web App Check activation');
        }
      } else {
        if (kDebugMode) {
          // Use debug provider during development/emulator to avoid enforcement blocking
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.debug,
            appleProvider: AppleProvider.debug,
          );
          _logger.w('⚠️ App Check running in debug mode (debug provider)');
        } else {
          // Production defaults
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.playIntegrity,
            appleProvider: AppleProvider.appAttest,
          );
          _logger.i('✅ App Check activated (Play Integrity / App Attest)');
        }
      }
    } catch (e) {
      _logger.e('❌ App Check activation failed: $e');
      // Do not rethrow: App Check activation failure should not block app initialization
    }

    _logger.i('✅ Firebase initialisé avec succès');
  } catch (e, stackTrace) {
    _logger.e('❌ Erreur lors de l\'initialisation de Firebase');
    _logger.e('Erreur: $e');
    _logger.e('Stack trace: $stackTrace');
    rethrow;
  }
}

/// Vérifie si Firebase est initialisé
bool isFirebaseInitialized() {
  try {
    Firebase.app();
    return true;
  } catch (e) {
    return false;
  }
}
