library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/services.dart';

// ===================== SERVICES PROVIDERS =====================

/// Provider pour StorageService (singleton)
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

/// Provider pour FirebaseAuthService (singleton)
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService.instance;
});

/// Provider pour FirestoreService (singleton)
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService.instance;
});

/// Provider pour FirebaseStorageService (singleton)
final firebaseStorageServiceProvider = Provider<FirebaseStorageService>((ref) {
  return FirebaseStorageService.instance;
});

// ===================== AUTH STATE =====================

/// État de l'authentification Firebase
class AuthState {
  final bool isLoading;
  final String? userId; // Firebase UID
  final String? campagneId; // ID campagne Firestore
  final String? role; // 'MJ' ou 'PJ'
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.userId,
    this.campagneId,
    this.role,
    this.error,
  });

  bool get isMJ => role == 'MJ';
  bool get isPJ => role == 'PJ';
  bool get isAuthenticated => userId != null && campagneId != null && role != null;

  AuthState copyWith({
    bool? isLoading,
    String? userId,
    String? campagneId,
    String? role,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      campagneId: campagneId ?? this.campagneId,
      role: role ?? this.role,
      error: error,
    );
  }
}

/// Notifier pour l'authentification Firebase
class FirebaseAuthNotifier extends Notifier<AuthState> {
  late final FirebaseAuthService _auth;
  late final FirestoreService _firestore;

  @override
  AuthState build() {
    _auth = ref.read(firebaseAuthServiceProvider);
    _firestore = ref.read(firestoreServiceProvider);
    
    // Écouter les changements d'état d'authentification
    _auth.authStateChanges.listen((user) {
      if (user == null) {
        state = const AuthState();
      } else {
        // Utilisateur connecté : mettre à jour le state avec son userId
        state = AuthState(userId: user.uid);
      }
    });
    
    return const AuthState();
  }

  /// Créer une nouvelle campagne (mode MJ)
  Future<String?> createCampagne(
    String nom, 
    String? description, {
    bool isPublic = false,
    String? invitationToken,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Non authentifié');
      }

      // Créer la campagne dans Firestore (la méthode gère tout)
      final campagneId = await _firestore.createCampagne(
        nom: nom,
        description: description,
        isPublic: isPublic,
        invitationToken: invitationToken,
      );

      state = AuthState(
        userId: user.uid,
        campagneId: campagneId,
        role: 'MJ',
      );

      return campagneId;
    } catch (e) {
      state = AuthState(error: e.toString());
      return null;
    }
  }

  /// Se connecter à une campagne existante
  Future<bool> joinCampagne(String campagneId, String role) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Non authentifié');
      }

      // Vérifier que la campagne existe
      final campagne = await _firestore.getDocument(
        collection: 'campagnes',
        documentId: campagneId,
      );
      if (campagne == null) {
        throw Exception('Campagne introuvable');
      }

      // Mettre à jour le rôle de l'utilisateur
      await _firestore.updateDocument(
        collection: 'users',
        documentId: user.uid,
        data: {
          'role': role,
          'campagne_id': campagneId,
        },
      );

      state = AuthState(
        userId: user.uid,
        campagneId: campagneId,
        role: role,
      );

      return true;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  /// Charger l'état d'authentification au démarrage
  Future<void> loadAuthState() async {
    final user = _auth.currentUser;
    if (user == null) {
      state = const AuthState();
      return;
    }

    try {
      // Récupérer les infos utilisateur depuis Firestore
      final userData = await _firestore.getDocument(
        collection: 'users',
        documentId: user.uid,
      );
      if (userData != null) {
        state = AuthState(
          userId: user.uid,
          campagneId: userData['campagne_id'],
          role: userData['role'],
        );
      }
    } catch (e) {
      state = const AuthState();
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    await _auth.signOut();
    state = const AuthState();
  }
}

/// Provider pour l'authentification
final authProvider = NotifierProvider<FirebaseAuthNotifier, AuthState>(
  FirebaseAuthNotifier.new,
);

// ===================== CAMPAGNES =====================

/// Provider pour la liste des campagnes d'un MJ
final campagnesMJProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final firestore = ref.read(firestoreServiceProvider);
  
  if (auth.userId == null) {
    return [];
  }
  
  final result = await firestore.getCampagnes();
  return result;
});

/// Provider pour une campagne spécifique
final campagneProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, campagneId) async {
  final firestore = ref.read(firestoreServiceProvider);
  return await firestore.getDocument(
    collection: 'campagnes',
    documentId: campagneId,
  );
});

/// Notifier pour la campagne actuellement sélectionnée
class CurrentCampagneNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void setCampagne(Map<String, dynamic>? campagne) {
    state = campagne;
  }

  void clear() {
    state = null;
  }
}

/// Provider pour la campagne actuellement sélectionnée
final currentCampagneProvider = NotifierProvider<CurrentCampagneNotifier, Map<String, dynamic>?>(
  CurrentCampagneNotifier.new,
);

// ===================== PERSONNAGES =====================

/// Provider pour les personnages d'une campagne
final personnagesCampagneProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, campagneId) async {
    final firestore = ref.read(firestoreServiceProvider);
    
    // Requête array-contains pour trouver tous les personnages qui ont cette campagne dans campagnes_ids
    final personnages = await firestore.queryCollectionArrayContains(
      collection: 'personnages',
      field: 'campagnes_ids',
      value: campagneId,
    );
    
    return personnages;
  },
);

/// Provider pour un personnage spécifique
final personnageProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
  (ref, personnageId) async {
    final firestore = ref.watch(firestoreServiceProvider);
    return firestore.getDocument(
      collection: 'personnages',
      documentId: personnageId,
    );
  },
);

// ===================== GAME DATA PROVIDERS =====================

/// Provider pour toutes les races (cache avec autoDispose après 5min)
final racesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final firestore = ref.read(firestoreServiceProvider);
    return firestore.listCollection(collection: 'races');
  },
);

/// Provider pour toutes les classes (cache avec autoDispose après 5min)
final classesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final firestore = ref.read(firestoreServiceProvider);
    return firestore.listCollection(collection: 'classes');
  },
);

final archetypesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final firestore = ref.read(firestoreServiceProvider);
    return firestore.getArchetypes();
  },
);

/// Provider pour une race spécifique par ID
final raceByIdProvider = FutureProvider.autoDispose.family<String, int>(
  (ref, raceId) async {
    final races = await ref.watch(racesProvider.future);
    final race = races.firstWhere(
      (r) => r['id'] == raceId,
      orElse: () => {'nom': 'Race inconnue'},
    );
    return race['nom'] as String? ?? 'Race #$raceId';
  },
);

/// Provider pour une classe spécifique par ID
final classeByIdProvider = FutureProvider.autoDispose.family<String, int>(
  (ref, classeId) async {
    final classes = await ref.watch(classesProvider.future);
    final classe = classes.firstWhere(
      (c) => c['id'] == classeId,
      orElse: () => {'nom': 'Classe inconnue'},
    );
    return classe['nom'] as String? ?? 'Classe #$classeId';
  },
);

/// Provider pour tous les talents
final talentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final firestore = ref.read(firestoreServiceProvider);
    return firestore.listCollection(collection: 'talents');
  },
);

/// Provider pour tous les pouvoirs mystiques
final pouvoirsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final firestore = ref.read(firestoreServiceProvider);
    return firestore.listCollection(collection: 'pouvoirs_mystiques');
  },
);

/// Provider pour tous les atouts/fardeaux
final atoutsFardeauxProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final firestore = ref.read(firestoreServiceProvider);
    return firestore.listCollection(collection: 'atouts_fardeaux');
  },
);

/// Provider pour tous les traits
final traitsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final firestore = ref.read(firestoreServiceProvider);
    return firestore.listCollection(collection: 'traits');
  },
);

/// Provider pour tous les rituels
final rituelsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final firestore = ref.read(firestoreServiceProvider);
    return firestore.listCollection(collection: 'rituels');
  },
);

/// Provider pour toutes les armes
final armesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final firestore = ref.read(firestoreServiceProvider);
    return firestore.listCollection(collection: 'armes');
  },
);

/// Provider pour toutes les armures
final armuresProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final firestore = ref.read(firestoreServiceProvider);
    return firestore.listCollection(collection: 'armures');
  },
);

/// Provider pour tous les équipements
final equipementsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final firestore = ref.read(firestoreServiceProvider);
    return firestore.listCollection(collection: 'equipements');
  },
);

// TODO: Ajouter les autres providers au fur et à mesure de la migration
