/// Script de test Firebase
/// Vérifie que l'authentification et Storage fonctionnent
/// 
/// Pour exécuter : dart run test_firebase.dart
library;

import 'lib/config/firebase_initialization.dart';
import 'lib/services/firebase_auth_service.dart';
import 'lib/services/firestore_service.dart';
import 'lib/services/firebase_storage_service.dart';

void main() async {
  print('🧪 Test Firebase - Début\n');

  try {
    // 1. Initialiser Firebase
    print('1️⃣ Initialisation de Firebase...');
    await initializeFirebase();
    print('   ✅ Firebase initialisé\n');

    // 2. Tester l'authentification
    print('2️⃣ Test authentification...');
    final authService = FirebaseAuthService.instance;
    
    print('   📧 Connexion avec mj_defacc@test.com...');
    await authService.signInWithEmailAndPassword(
      email: 'mj_defacc@test.com',
      password: 'MjD3f!@cc8426',  // ⚠️ REMPLACE PAR LE VRAI MDP
    );
    
    final user = authService.currentUser;
    if (user != null) {
      print('   ✅ Connecté : ${user.email}');
      print('   UID : ${user.uid}\n');
      
      // Vérifier les rôles
      final isAdmin = await authService.isAdmin();
      print('   👤 Admin : $isAdmin');
      
      final userData = await authService.getUserData();
      print('   📄 Données utilisateur : $userData\n');
    }

    // 3. Tester Firestore
    print('3️⃣ Test Firestore...');
    final firestoreService = FirestoreService.instance;
    
    print('   📚 Récupération des campagnes...');
    final campagnes = await firestoreService.getCampagnes();
    print('   ✅ ${campagnes.length} campagne(s) trouvée(s)');
    
    for (final campagne in campagnes) {
      print('      - ${campagne['nom']} (${campagne['uid']})');
    }
    print('');

    // 4. Tester Storage (récupération URL seulement)
    print('4️⃣ Test Storage...');
    final storageService = FirebaseStorageService.instance;
    
    // Essayer de récupérer un avatar (ne devrait pas exister encore)
    print('   🖼️  Vérification avatar test...');
    final avatarUrl = await storageService.getAvatarUrl('test_perso_123');
    if (avatarUrl != null) {
      print('   ✅ Avatar trouvé : $avatarUrl');
    } else {
      print('   ℹ️  Pas d\'avatar (normal pour un test)');
    }
    print('');

    // 5. Déconnexion
    print('5️⃣ Déconnexion...');
    await authService.signOut();
    print('   ✅ Déconnecté\n');

    print('🎉 Tous les tests sont passés !');
    print('✅ Firebase est correctement configuré');
    
  } catch (e, stackTrace) {
    print('\n❌ ERREUR lors des tests :');
    print('   $e');
    print('\n📚 Stack trace :');
    print('   $stackTrace');
    print('\n💡 Vérifier :');
    print('   - Les credentials dans firebase_config.dart');
    print('   - Le fichier google-services.json');
    print('   - La connexion internet');
    print('   - Le mot de passe dans ce script');
  }
}
