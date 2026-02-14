import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme.dart';
import 'config/firebase_initialization.dart';
import 'screens/firebase_login_screen.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  // S'assurer que Flutter est initialisé
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await initializeFirebase();
  
  // Initialiser le service de stockage
  await StorageService.instance.init();
  
  // Forcer l'orientation portrait pour une app mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Personnaliser la barre de statut pour le thème sombre
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: SymbaroumColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  runApp(
    // ProviderScope est le conteneur racine pour Riverpod
    const ProviderScope(
      child: SymbaroumCompanionApp(),
    ),
  );
}

/// Application principale Symbaroum Companion
class SymbaroumCompanionApp extends StatelessWidget {
  const SymbaroumCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Symbaroum - Test',
      
      // Désactiver le bandeau debug
      debugShowCheckedModeBanner: false,
      
      // Clé globale pour les notifications
      scaffoldMessengerKey: NotificationService.messengerKey,
      
      // Thème Symbaroum personnalisé
      theme: SymbaroumTheme.darkTheme,
      
      // Écran de connexion Firebase MJ
      home: const FirebaseLoginScreen(),
      
      // Configuration du scroll pour un comportement fluide
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
    );
  }
}
