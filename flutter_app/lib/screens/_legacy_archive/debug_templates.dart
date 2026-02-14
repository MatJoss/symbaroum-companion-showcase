/// Script de debug pour examiner les templates Firestore
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'config/firebase_initialization.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await initializeFirebase();
  
  final firestore = FirestoreService.instance;
  
  print('\n=== ANALYSE DES TEMPLATES FIRESTORE ===\n');
  
  // Template campagne
  try {
    print('📋 Récupération de template_campagne...');
    final templateCampagne = await firestore.getTemplate('template_campagne');
    if (templateCampagne != null) {
      print('\n✅ template_campagne:');
      print(JsonEncoder.withIndent('  ').convert(templateCampagne));
      print('\nChamps disponibles (${templateCampagne.keys.length}):');
      for (var key in templateCampagne.keys) {
        print('  - $key');
      }
    } else {
      print('❌ template_campagne introuvable');
    }
  } catch (e) {
    print('❌ Erreur template_campagne: $e');
  }
  
  print('\n${'='*60}\n');
  
  // Template personnage nested
  try {
    print('📋 Récupération de template_personnage_nested...');
    final templatePerso = await firestore.getTemplate('template_personnage_nested');
    if (templatePerso != null) {
      print('\n✅ template_personnage_nested:');
      print(JsonEncoder.withIndent('  ').convert(templatePerso));
      print('\nChamps disponibles (${templatePerso.keys.length}):');
      for (var key in templatePerso.keys) {
        print('  - $key');
      }
    } else {
      print('❌ template_personnage_nested introuvable');
    }
  } catch (e) {
    print('❌ Erreur template_personnage_nested: $e');
  }
  
  print('\n${'='*60}');
  print('\n🔍 Analyse terminée\n');
}
