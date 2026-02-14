/// Service Firestore complet
/// Gère toutes les opérations CRUD sur Firestore
library;

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../config/firebase_config.dart';
import 'firebase_auth_service.dart';

// Logs désactivés pour éviter la saturation mémoire
final _logger = Logger(level: Level.off);

/// Exception Firestore
class FirestoreException implements Exception {
  final String message;
  final dynamic originalError;

  FirestoreException(this.message, [this.originalError]);

  @override
  String toString() => 'FirestoreException: $message';
}

/// Service Firestore
class FirestoreService {
  static FirestoreService? _instance;
  final FirebaseFirestore _firestore;
  final FirebaseAuthService _auth;

  FirestoreService._({
    FirebaseFirestore? firestore,
    FirebaseAuthService? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuthService.instance {
    _logger.i('FirestoreService initialisé');
  }

  /// Singleton
  static FirestoreService get instance {
    _instance ??= FirestoreService._();
    return _instance!;
  }

  // ===================== OPÉRATIONS GÉNÉRIQUES =====================

  /// Récupérer un document par ID
  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      _logger.d('GET $collection/$documentId');

      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        _logger.w('⚠️ Document non trouvé: $collection/$documentId');
        return null;
      }

      return doc.data();
    } catch (e) {
      _logger.e('❌ Erreur GET document: $e');
      throw FirestoreException('Erreur lors de la récupération du document',
e);
    }
  }

  /// Récupérer un document par ID avec fallback sur champ 'id'
  Future<Map<String, dynamic>?> getDocumentWithFallback({
    required String collection,
    required dynamic id,
  }) async {
    try {
      final idStr = id?.toString();
      if (idStr == null) return null;

      _logger.d('GET (with fallback) $collection/$idStr');

      // Try doc ref by id first
      final docRef = _firestore.collection(collection).doc(idStr);
      final docSnap = await docRef.get();
      if (docSnap.exists && docSnap.data() != null) {
        return docSnap.data();
      }

      // Fallback: query where 'id' == id
      final querySnap = await _firestore
          .collection(collection)
          .where('id', isEqualTo: id)
          .limit(1)
          .get();

      if (querySnap.docs.isNotEmpty) {
        return querySnap.docs.first.data();
      }

      // Also try string value if stored as string
      final querySnap2 = await _firestore
          .collection(collection)
          .where('id', isEqualTo: idStr)
          .limit(1)
          .get();

      if (querySnap2.docs.isNotEmpty) {
        return querySnap2.docs.first.data();
      }

      _logger.w('⚠️ Document non trouvé: $collection/$idStr');
      return null;
    } catch (e) {
      _logger.e('❌ Erreur GET document with fallback: $e');
      throw FirestoreException('Erreur lors de la récupération du document',
e);
    }
  }

  /// Créer un document
  Future<String> createDocument({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      _logger.d('CREATE $collection/${documentId ?? 'auto'}');

      final ref = documentId == null
          ? _firestore.collection(collection).doc()
          : _firestore.collection(collection).doc(documentId);

      // Ajouter automatiquement le uid au document
      final dataWithUid = {...data, 'uid': ref.id};
      await ref.set(dataWithUid);

      _logger.i('✅ Document créé: ${ref.id}');
      return ref.id;
    } catch (e) {
      _logger.e('❌ Erreur CREATE document: $e');
      throw FirestoreException('Erreur lors de la création du document', e);
    }
  }

  /// Mettre à jour un document
  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      _logger.d('UPDATE $collection/$documentId');

      await _firestore.collection(collection).doc(documentId).update(data);

      _logger.i('✅ Document mis à jour: $documentId');
    } catch (e) {
      _logger.e('❌ Erreur UPDATE document: $e');
      throw FirestoreException('Erreur lors de la mise à jour du document',
e);
    }
  }

  /// Supprimer un document
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      _logger.d('DELETE $collection/$documentId');

      await _firestore.collection(collection).doc(documentId).delete();

      _logger.i('✅ Document supprimé: $documentId');
    } catch (e) {
      _logger.e('❌ Erreur DELETE document: $e');
      throw FirestoreException('Erreur lors de la suppression du document',
e);
    }
  }

  /// Lister tous les documents d'une collection
  Future<List<Map<String, dynamic>>> listCollection({
    required String collection,
    int? limit,
  }) async {
    try {
      _logger.d('LIST $collection ${limit != null ? "(limit: $limit)" : ""}');

      var query = _firestore.collection(collection) as Query;

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'uid': doc.id})
          .toList();
    } catch (e) {
      _logger.e('❌ Erreur LIST collection: $e');
      throw FirestoreException('Erreur lors du listage de la collection', e);
    }
  }

  /// Requête sur une collection avec filtre
  Future<List<Map<String, dynamic>>> queryCollection({
    required String collection,
    required String field,
    required dynamic value,
    int? limit,
  }) async {
    try {
      var query =
          _firestore.collection(collection).where(field, isEqualTo: value);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      final results = snapshot.docs
          .map((doc) {
        final data = {...doc.data(), 'uid': doc.id};
        return data;
      })
          .toList();

      return results;
    } catch (e) {
      _logger.e('❌ Erreur QUERY collection: $e');
      throw FirestoreException('Erreur lors de la requête sur la collection',
e);
    }
  }

  /// Requête sur une collection avec filtre array-contains
  Future<List<Map<String, dynamic>>> queryCollectionArrayContains({
    required String collection,
    required String field,
    required dynamic value,
    int? limit,
  }) async {
    try {
      var query =
          _firestore.collection(collection).where(field, arrayContains: value);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      final results = snapshot.docs
          .map((doc) => {...doc.data(), 'uid': doc.id})
          .toList();

      return results;
    } catch (e) {
      _logger.e('❌ Erreur QUERY collection (array-contains): $e');
      throw FirestoreException('Erreur lors de la requête sur la collection',
e);
    }
  }

  /// Stream d'un document
  Stream<Map<String, dynamic>?> documentStream({
    required String collection,
    required String documentId,
  }) {
    return _firestore
        .collection(collection)
        .doc(documentId)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  /// Stream d'une collection
  Stream<List<Map<String, dynamic>>> collectionStream({
    required String collection,
    int? limit,
  }) {
    var query = _firestore.collection(collection) as Query;

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'uid': doc.id})
        .toList());
  }

  // ===================== CAMPAGNES =====================

  /// Récupérer toutes les campagnes accessibles par l'utilisateur
  /// Celles où il est créateur ou MJ + les campagnes publiques
  Future<List<Map<String, dynamic>>> getCampagnes() async {
    try {
      if (!_auth.isAuthenticated) {
        throw FirestoreException('Utilisateur non authentifié');
      }

      final userId = _auth.currentUserId!;
      final results = <Map<String, dynamic>>[];
      final seenIds = <String>{};

      // 1️⃣ Récupérer les campagnes via les rôles utilisateur (MJ uniquement)
      final userData = await _auth.getUserData();
      if (userData != null) {
        final roles = userData['roles'] as Map<String, dynamic>?;
        final campagnesRoles = roles?['campagnes'] as Map<String, dynamic>? ?? {};
        
        for (final entry in campagnesRoles.entries) {
          final campagneId = entry.key;
          final role = entry.value as String;
          
          // ⚠️ FILTRAGE : Uniquement MJ, pas Joueur/PJ
          if (role != 'MJ') continue;
          
          if (seenIds.contains(campagneId)) continue;
          
          try {
            final campagne = await getDocument(
              collection: FirebaseConfig.campagnesCollection,
              documentId: campagneId,
            );
            if (campagne != null) {
              results.add({...campagne, 'uid': campagneId});
              seenIds.add(campagneId);
            }
          } catch (e) {
            _logger.w('⚠️ Campagne inaccessible: $campagneId');
          }
        }
      }

      // 2️⃣ Récupérer les campagnes créées par l'utilisateur
      // (même si pas encore de rôle MJ explicite)
      try {
        final userCampagnes = await _firestore
            .collection(FirebaseConfig.campagnesCollection)
            .where('createur', isEqualTo: userId)
            .get();

        for (final doc in userCampagnes.docs) {
          if (!seenIds.contains(doc.id)) {
            results.add({...doc.data(), 'uid': doc.id});
            seenIds.add(doc.id);
          }
        }
      } catch (e) {
        _logger.w('⚠️ Erreur récupération campagnes créateur: $e');
      }

      // 3️⃣ Récupérer les campagnes publiques (accessibles à tous en tant que MJ)
      try {
        final publicCampagnes = await _firestore
            .collection(FirebaseConfig.campagnesCollection)
            .where('isPublic', isEqualTo: true)
            .get();

        for (final doc in publicCampagnes.docs) {
          if (!seenIds.contains(doc.id)) {
            results.add({...doc.data(), 'uid': doc.id});
            seenIds.add(doc.id);
          }
        }
      } catch (e) {
        _logger.w('⚠️ Erreur récupération campagnes publiques: $e');
      }

      _logger.i('✅ ${results.length} campagnes récupérées (MJ)');
      return results;
    } catch (e) {
      _logger.e('❌ Erreur getCampagnes: $e');
      throw FirestoreException('Erreur lors de la récupération des campagnes', e);
    }
  }

  /// Récupérer les campagnes où l'utilisateur est JOUEUR uniquement
  Future<List<Map<String, dynamic>>> getCampagnesAsPlayer() async {
    try {
      if (!_auth.isAuthenticated) {
        throw FirestoreException('Utilisateur non authentifié');
      }

      final results = <Map<String, dynamic>>[];
      final seenIds = <String>{};
      
      // 1️⃣ Campagnes où l'utilisateur a le rôle Joueur/PJ
      final userData = await _auth.getUserData();
      if (userData != null) {
        final roles = userData['roles'] as Map<String, dynamic>?;
        final campagnesRoles = roles?['campagnes'] as Map<String, dynamic>? ?? {};
        
        for (final entry in campagnesRoles.entries) {
          final campagneId = entry.key;
          final role = entry.value as String;
          
          // ✅ Filtrer uniquement les rôles Joueur/PJ
          if (role != 'Joueur' && role != 'PJ') continue;
          
          try {
            final campagne = await getDocument(
              collection: FirebaseConfig.campagnesCollection,
              documentId: campagneId,
            );
            if (campagne != null) {
              results.add({...campagne, 'uid': campagneId});
              seenIds.add(campagneId);
            }
          } catch (e) {
            _logger.w('⚠️ Campagne joueur inaccessible: $campagneId');
          }
        }
      }
      
      // 2️⃣ Campagnes publiques (accessibles à tous)
      try {
        final publicCampagnes = await _firestore
            .collection(FirebaseConfig.campagnesCollection)
            .where('isPublic', isEqualTo: true)
            .get();

        for (final doc in publicCampagnes.docs) {
          if (!seenIds.contains(doc.id)) {
            results.add({...doc.data(), 'uid': doc.id});
            seenIds.add(doc.id);
          }
        }
      } catch (e) {
        _logger.w('⚠️ Erreur récupération campagnes publiques: $e');
      }
      
      _logger.i('✅ ${results.length} campagnes récupérées (Joueur)');
      return results;
    } catch (e) {
      _logger.e('❌ Erreur getCampagnesAsPlayer: $e');
      throw FirestoreException('Erreur lors de la récupération des campagnes joueur', e);
    }
  }

  /// Permet à un utilisateur de rejoindre explicitement une campagne publique (ajoute l'ID dans son profil)
  Future<void> joinPublicCampagne(String campagneId) async {
    try {
      if (!_auth.isAuthenticated) {
        throw FirestoreException('Utilisateur non authentifié');
      }
      final userId = _auth.currentUserId;
      if (userId == null) {
        throw FirestoreException('Utilisateur non authentifié');
      }
      // Ajoute la campagne comme "Joueur" par défaut
      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userId)
          .update({
        'roles.campagnes.$campagneId': 'PJ',
      });
    } catch (e) {
      throw FirestoreException('Erreur lors de la tentative de rejoindre la campagne publique', e);
    }
  }

  Future<String> createCampagne({
    required String nom,
    String? description,
    bool isPublic = false,
    String? invitationToken,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw FirestoreException('Utilisateur non authentifié');
      }

      final userId = _auth.currentUserId!;
      final now = Timestamp.now();
      
      // Générer un token d'invitation si absent
      String finalToken = invitationToken ?? '';
      if (finalToken.isEmpty) {
        const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        final random = Random.secure();
        finalToken = List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
      }
      
      // Récupérer le template de campagne
      final templateData = await createFromTemplate(
        templateId: 'template_campagne',
        overrides: {
          'nom': nom,
          'description': description ?? '',
          'createur': userId,
          'isPublic': isPublic,
          'invitationToken': finalToken,
          'date_creation': now,
          'date_derniere_session': now,
        },
      );

      // ⚡ BATCH: Créer campagne + ajouter rôle en une seule transaction
      final batch = _firestore.batch();
      
      // 1. Créer la campagne
      final campagneRef = _firestore
          .collection(FirebaseConfig.campagnesCollection)
          .doc();
      batch.set(campagneRef, {...templateData, 'uid': campagneRef.id});
      
      // 2. Ajouter le rôle MJ à l'utilisateur
      final userRef = _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userId);
      batch.update(userRef, {
        'roles.campagnes.${campagneRef.id}': FirebaseConfig.roleMJ,
      });
      
      // Commit atomique
      await batch.commit();

      _logger.i('✅ Campagne créée avec rôle MJ: ${campagneRef.id}');
      return campagneRef.id;
    } catch (e) {
      if (e.toString().contains('PERMISSION_DENIED')) {
        throw FirestoreException(
          'Permissions insuffisantes. Vérifiez les règles Firestore.',
          e,
        );
      }
      throw FirestoreException('Erreur lors de la création de la campagne', e);
    }
  }

  /// Ajouter un rôle à l'utilisateur pour une campagne
  Future<void> _addUserRoleToCampagne({
    required String campagneId,
    required String role,
  }) async {
    try {
      final userId = _auth.currentUserId;
      if (userId == null) {
        throw FirestoreException('Utilisateur non authentifié');
      }

      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userId)
          .update({
        'roles.campagnes.$campagneId': role,
      });

      _logger.i('✅ Rôle $role ajouté pour campagne $campagneId');
    } catch (e) {
      _logger.e('❌ Erreur ajout rôle utilisateur: $e');
      rethrow;
    }
  }

  /// Récupérer une campagne par ID
  Future<Map<String, dynamic>?> getCampagne(String campagneId) async {
    try {
      return await getDocument(
        collection: FirebaseConfig.campagnesCollection,
        documentId: campagneId,
      );
    } catch (e) {
      _logger.e('❌ Erreur récupération campagne: $e');
      throw FirestoreException('Erreur lors de la récupération de la campagne',
e);
    }
  }

  /// Mettre à jour une campagne
  Future<void> updateCampagne({
    required String campagneId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Vérifier que l'utilisateur est MJ de la campagne
      final isMJ = await _auth.isMJ(campagneId);
      final isAdmin = await _auth.isAdmin();

      if (!isMJ && !isAdmin) {
        throw FirestoreException(
            'Vous n\'avez pas les droits pour modifier cette campagne');
      }

      await updateDocument(
        collection: FirebaseConfig.campagnesCollection,
        documentId: campagneId,
        data: data,
      );
    } catch (e) {
      _logger.e('❌ Erreur mise à jour campagne: $e');
      throw FirestoreException('Erreur lors de la mise à jour de la campagne',
e);
    }
  }

  /// Rejoindre une campagne via un token d'invitation
  Future<Map<String, dynamic>?> joinCampagneByToken(String invitationToken) async {
    try {
      if (!_auth.isAuthenticated) {
        throw FirestoreException('Utilisateur non authentifié');
      }

      final userId = _auth.currentUserId!;
      _logger.d('Recherche campagne avec token: $invitationToken');

      // 🔍 Query pour trouver la campagne par token
      final querySnapshot = await _firestore
          .collection(FirebaseConfig.campagnesCollection)
          .where('invitationToken', isEqualTo: invitationToken.trim().toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _logger.w('❌ Aucune campagne trouvée avec ce token');
        return null;
      }

      final campagneDoc = querySnapshot.docs.first;
      final campagneId = campagneDoc.id;
      final campagneData = {...campagneDoc.data(), 'uid': campagneId};

      _logger.i('✅ Campagne trouvée: $campagneId (${campagneData['nom']})');

      // 🎭 Vérifier si l'utilisateur a déjà un rôle
      final userData = await _auth.getUserData();
      final roles = userData?['roles'] as Map<String, dynamic>?;
      final campagnesRoles = roles?['campagnes'] as Map<String, dynamic>? ?? {};
      
      if (campagnesRoles.containsKey(campagneId)) {
        _logger.i('ℹ️ Utilisateur déjà membre de la campagne');
        return campagneData; // Déjà membre, retourner les données quand même
      }

      // ➕ Ajouter le rôle "Joueur" avec merge
      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userId)
          .set({
        'roles': {
          'campagnes': {
            campagneId: 'PJ',
          }
        }
      }, SetOptions(merge: true));

      _logger.i('✅ Rôle Joueur ajouté pour campagne $campagneId');
      return campagneData;
      
    } catch (e) {
      _logger.e('❌ Erreur joinCampagneByToken: $e');
      
      // Messages d'erreur plus clairs
      if (e.toString().contains('PERMISSION_DENIED')) {
        throw FirestoreException(
          'Vous n\'avez pas les droits pour accéder à cette campagne',
          e,
        );
      }
      
      throw FirestoreException(
        'Impossible de rejoindre la campagne. Vérifiez le token.',
        e,
      );
    }
  }
  
  /// Permet à un joueur de quitter une campagne (retire son rôle PJ et libère ses personnages)
  Future<void> leaveCampagne(String campagneId) async {
    try {
      if (!_auth.isAuthenticated) {
        throw FirestoreException('Utilisateur non authentifié');
      }
      
      final userId = _auth.currentUserId;
      if (userId == null) {
        throw FirestoreException('Utilisateur non authentifié');
      }
      
      // Vérifier que la campagne existe et n'est pas publique
      final campagne = await getDocument(
        collection: FirebaseConfig.campagnesCollection,
        documentId: campagneId,
      );
      
      if (campagne == null) {
        throw FirestoreException('Campagne introuvable');
      }
      
      final isPublic = campagne['isPublic'] as bool? ?? false;
      if (isPublic) {
        throw FirestoreException('Impossible de quitter une campagne publique');
      }
      
      // ⚡ BATCH: Retirer le rôle ET libérer les personnages en une seule transaction
      final batch = _firestore.batch();
      
      // 1. Retirer le rôle de l'utilisateur
      final userRef = _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userId);
      batch.update(userRef, {
        'roles.campagnes.$campagneId': FieldValue.delete(),
      });
      
      // 2. Libérer tous les personnages de cette campagne possédés par l'utilisateur
      final personnagesSnapshot = await _firestore
          .collection(FirebaseConfig.personnagesCollection)
          .where('campagnes_ids', arrayContains: campagneId)
          .where('joueur_actif_id', isEqualTo: userId)
          .get();
      
      for (final doc in personnagesSnapshot.docs) {
        batch.update(doc.reference, {
          'joueur_actif_id': null,
        });
      }
      
      // Commit atomique
      await batch.commit();
      
      _logger.i('✅ Utilisateur $userId a quitté la campagne $campagneId et libéré ${personnagesSnapshot.docs.length} personnage(s)');
    } catch (e) {
      _logger.e('❌ Erreur leaveCampagne: $e');
      throw FirestoreException('Erreur lors de la sortie de la campagne', e);
    }
  }

  // ===================== USERS =====================

  /// Créer un nouvel utilisateur avec la structure correcte
  Future<void> createUser({
    required String uid,
    required String email,
    String? displayedName,
    bool verifiedMail = false,
  }) async {
    try {
      final now = Timestamp.now();

      // Créer la structure utilisateur correcte
      final userData = {
        'uid': uid,
        'email': email,
        'displayedName': displayedName ?? email.split('@')[0],
        'verifiedMail': verifiedMail,
        'preferences': {
          'langue': 'fr',
          'notifications': true,
          'statut': 'actif',
          'theme': 'dark',
        },
        'roles': {
          'admin': false,
          'campagnes': {}, // Vide au départ, sera rempli lors de la création de campagne
        },
        'date_creation': now,
        'derniere_connexion': now,
      };

      // Créer le document utilisateur avec l'UID comme ID
      await createDocument(
        collection: FirebaseConfig.usersCollection,
        data: userData,
        documentId: uid,
      );

      _logger.i('✅ Utilisateur créé avec structure correcte');
    } catch (e) {
      _logger.e('❌ Erreur création utilisateur: $e');
      throw FirestoreException('Erreur lors de la création de l\'utilisateur', e);
    }
  }

  /// Mettre à jour les données de l'utilisateur
  Future<void> updateUserData({
    String? userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final uid = userId ?? _auth.currentUserId;
      if (uid == null) {
        throw FirestoreException('Utilisateur non authentifié');
      }

      // Ajouter le timestamp de la dernière modification
      updates['derniere_modification'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(uid)
          .update(updates);

      _logger.i('✅ Données utilisateur mises à jour');
    } catch (e) {
      _logger.e('❌ Erreur mise à jour données utilisateur: $e');
      rethrow;
    }
  }

  /// Mettre à jour le displayedName de l'utilisateur
  Future<void> updateDisplayedName(String newDisplayedName) async {
    try {
      if (newDisplayedName.trim().isEmpty) {
        throw FirestoreException('Le nom affiché ne peut pas être vide');
      }

      await updateUserData(
        updates: {
          'displayedName': newDisplayedName.trim(),
          'lastDisplayedNameChange': FieldValue.serverTimestamp(),
        },
      );

      _logger.i('✅ Nom affiché mis à jour');
    } catch (e) {
      _logger.e('❌ Erreur mise à jour nom affiché: $e');
      rethrow;
    }
  }

  // ===================== PERSONNAGES =====================

  /// Créer un nouveau personnage (toujours nested)
  Future<String> createPersonnage({
    required String campagneId,
    required String nom,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw FirestoreException('Utilisateur non authentifié');
      }

      _logger.d('CREATE personnage nested: $nom');

      final now = Timestamp.now();
      
      // Vérifier userId
      final userId = _auth.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw FirestoreException('Impossible de récupérer l\'ID utilisateur');
      }
      
      // Extraire estPJ des additionalData s'il existe
      final estPJ = additionalData?['estPJ'] as bool? ?? true;
      
      // Retirer estPJ et campagnes_ids des additionalData pour éviter la duplication
      final cleanedAdditionalData = {...?additionalData}
        ..remove('estPJ')
        ..remove('campagnes_ids')
        ..remove('createur')
        ..remove('joueur_connecte');
      
      // Récupérer le template et appliquer les overrides
      final templateData = await createFromTemplate(
        templateId: 'template_personnage_nested',
        overrides: {
          'nom': nom,
          ...cleanedAdditionalData,
        },
      );
      

      // Normalize template fields to match client expectations
      // e.g. convert 'avatar_url' -> 'avatarUrl' used by the UI
      if (templateData.containsKey('avatar_url')) {
        templateData['avatarUrl'] = templateData.remove('avatar_url');
      }

      // Structure du document personnage :
      // - uid: auto-généré
      // - estPJ: bool (filtrage rapide)
      // - createur: userId (qui l'a créé)
      // - campagnes_ids: array de strings (appartenance)
      // - joueur_actif_id: null par défaut (verrouillage)
      // - date_creation, date_modification
      // - document: { ...données du template (normalisées)... }
      final personnageDoc = {
        'estPJ': estPJ,
        'createur': userId,
        'campagnes_ids': [campagneId],
        'joueur_actif_id': null,
        'date_creation': now,
        'date_modification': now,
        'document': templateData,
      };
      

      // Créer le personnage (uid ajouté automatiquement par createDocument)
      final personnageId = await createDocument(
        collection: FirebaseConfig.personnagesCollection,
        data: personnageDoc,
      );

      _logger.i('✅ Personnage créé: $personnageId');
      return personnageId;
    } catch (e) {
      _logger.e('❌ Erreur création personnage: $e');
      throw FirestoreException('Erreur lors de la création du personnage', e);
    }
  }

  /// Importer un personnage existant dans une campagne
  /// Le personnage doit appartenir à l'utilisateur courant (createur).
  /// Ajoute simplement le campagneId à campagnes_ids du personnage.
  Future<void> importPersonnageToCampagne({
    required String personnageId,
    required String campagneId,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw FirestoreException('Utilisateur non authentifié');
      }

      final userId = _auth.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw FirestoreException('Impossible de récupérer l\'ID utilisateur');
      }

      // Récupérer le personnage
      final personnage = await getDocument(
        collection: FirebaseConfig.personnagesCollection,
        documentId: personnageId,
      );

      if (personnage == null) {
        throw FirestoreException('Personnage introuvable');
      }

      // Vérifier que l'utilisateur est le créateur
      final createur = personnage['createur'] as String?;
      if (createur != userId) {
        throw FirestoreException('Vous ne pouvez importer que vos propres personnages');
      }

      // Vérifier que le personnage n'est pas déjà dans cette campagne
      final campagnesIds = List<String>.from(personnage['campagnes_ids'] ?? []);
      if (campagnesIds.contains(campagneId)) {
        throw FirestoreException('Ce personnage est déjà dans cette campagne');
      }

      // Ajouter la campagne au personnage
      campagnesIds.add(campagneId);
      await updateDocument(
        collection: FirebaseConfig.personnagesCollection,
        documentId: personnageId,
        data: {
          'campagnes_ids': campagnesIds,
          'date_modification': Timestamp.now(),
        },
      );

      _logger.i('✅ Personnage $personnageId importé dans campagne $campagneId');
    } catch (e) {
      _logger.e('❌ Erreur import personnage: $e');
      if (e is FirestoreException) rethrow;
      throw FirestoreException('Erreur lors de l\'import du personnage', e);
    }
  }

  /// Récupérer tous les personnages créés par l'utilisateur courant
  Future<List<Map<String, dynamic>>> getMyPersonnages() async {
    try {
      if (!_auth.isAuthenticated) {
        throw FirestoreException('Utilisateur non authentifié');
      }

      final userId = _auth.currentUserId;
      if (userId == null || userId.isEmpty) {
        return [];
      }

      final results = await queryCollection(
        collection: FirebaseConfig.personnagesCollection,
        field: 'createur',
        value: userId,
      );

      return results;
    } catch (e) {
      _logger.e('❌ Erreur récupération mes personnages: $e');
      throw FirestoreException('Erreur lors de la récupération des personnages', e);
    }
  }

  // ===================== GAME DATA (READ-ONLY) =====================

  /// Récupérer les archetypes
  Future<List<Map<String, dynamic>>> getArchetypes() async {
    return await listCollection(
      collection: FirebaseConfig.archetypesCollection,
    );
  }

  /// Récupérer les races
  Future<List<Map<String, dynamic>>> getRaces() async {
    return await listCollection(
      collection: FirebaseConfig.racesCollection,
    );
  }

  /// Récupérer les classes
  Future<List<Map<String, dynamic>>> getClasses() async {
    return await listCollection(
      collection: FirebaseConfig.classesCollection,
    );
  }

  /// Récupérer les talents
  Future<List<Map<String, dynamic>>> getTalents() async {
    return await listCollection(
      collection: FirebaseConfig.talentsCollection,
    );
  }

  /// Récupérer les armes
  Future<List<Map<String, dynamic>>> getArmes() async {
    return await listCollection(
      collection: FirebaseConfig.armesCollection,
    );
  }

  /// Récupérer les armures
  Future<List<Map<String, dynamic>>> getArmures() async {
    return await listCollection(
      collection: FirebaseConfig.armuresCollection,
    );
  }

  /// Récupérer les atouts/fardeaux
  Future<List<Map<String, dynamic>>> getAtoutsFardeaux() async {
    return await listCollection(
      collection: FirebaseConfig.atoutsFardeauxCollection,
    );
  }

  /// Récupérer les pouvoirs mystiques
  Future<List<Map<String, dynamic>>> getPouvoirsMystiques() async {
    return await listCollection(
      collection: FirebaseConfig.pouvoirsMystiquesCollection,
    );
  }

  /// Récupérer les rituels
  Future<List<Map<String, dynamic>>> getRituels() async {
    return await listCollection(
      collection: FirebaseConfig.rituelsCollection,
    );
  }

  /// Récupérer les traits
  Future<List<Map<String, dynamic>>> getTraits() async {
    return await listCollection(
      collection: 'traits',
    );
  }

  // ===================== TEMPLATES =====================

  /// Récupérer un template par ID depuis sa collection
  /// Les templates sont maintenant dans leurs collections respectives
  Future<Map<String, dynamic>?> getTemplate(String templateId) async {
    try {
      
      // Déterminer la collection selon le template
      String collection;
      if (templateId.contains('nested')) {
        // Les templates nested sont toujours dans templates_samples
        collection = FirebaseConfig.templatesCollection;
      } else if (templateId.contains('campagne')) {
        collection = FirebaseConfig.campagnesCollection;
      } else if (templateId.contains('personnage')) {
        collection = FirebaseConfig.personnagesCollection;
      } else if (templateId.contains('user')) {
        collection = FirebaseConfig.usersCollection;
      } else {
        // Fallback sur templates_samples si ancien format
        collection = FirebaseConfig.templatesCollection;
      }
      
      
      final template = await getDocument(
        collection: collection,
        documentId: templateId,
      );
      
      if (template == null) {
        return null;
      }
      
      
      // Les templates sont maintenant directement les documents
      // Plus besoin d'extraire un champ 'document'
      return template;
    } catch (e) {
      throw FirestoreException('Erreur lors de la récupération du template', e);
    }
  }

  /// Créer un document à partir d'un template
  Future<Map<String, dynamic>> createFromTemplate({
    required String templateId,
    Map<String, dynamic>? overrides,
  }) async {
    try {
      _logger.d('CREATE FROM TEMPLATE: $templateId');
      
      // Récupérer le template
      final template = await getTemplate(templateId);
      if (template == null) {
        throw FirestoreException('Template non trouvé: $templateId');
      }
      
      
      // Si le template contient un champ 'document', on l'extrait
      final templateContent = template.containsKey('document') 
          ? template['document'] as Map<String, dynamic>
          : template;
      
      
      // Copier le template et appliquer les overrides
      final data = Map<String, dynamic>.from(templateContent);
      
      if (overrides != null) {
        data.addAll(overrides);
      }
      
      _logger.i('✅ Document créé depuis template $templateId');
      return data;
    } catch (e) {
      _logger.e('❌ Erreur création depuis template: $e');
      throw FirestoreException('Erreur lors de la création depuis le template', e);
    }
  }

  // ===================== BATCH OPERATIONS =====================

  /// Effectuer plusieurs opérations en batch
  Future<void> batchWrite({
    required List<BatchOperation> operations,
  }) async {
    try {
      _logger.d('BATCH WRITE (${operations.length} operations)');

      final batch = _firestore.batch();

      for (final operation in operations) {
        final ref = _firestore
            .collection(operation.collection)
            .doc(operation.documentId);

        switch (operation.type) {
          case BatchOperationType.set:
            batch.set(ref, operation.data!);
            break;
          case BatchOperationType.update:
            batch.update(ref, operation.data!);
            break;
          case BatchOperationType.delete:
            batch.delete(ref);
            break;
        }
      }

      await batch.commit();
      _logger.i('✅ Batch commit réussi');
    } catch (e) {
      _logger.e('❌ Erreur batch write: $e');
      throw FirestoreException('Erreur lors de l\'opération batch', e);
    }
  }
}

// ===================== CLASSES UTILITAIRES =====================

/// Type d'opération batch
enum BatchOperationType {
  set,
  update,
  delete,
}

/// Opération batch
class BatchOperation {
  final String collection;
  final String documentId;
  final BatchOperationType type;
  final Map<String, dynamic>? data;

  BatchOperation({
    required this.collection,
    required this.documentId,
    required this.type,
    this.data,
  });

  factory BatchOperation.set({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return BatchOperation(
      collection: collection,
      documentId: documentId,
      type: BatchOperationType.set,
      data: data,
    );
  }

  factory BatchOperation.update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return BatchOperation(
      collection: collection,
      documentId: documentId,
      type: BatchOperationType.update,
      data: data,
    );
  }

  factory BatchOperation.delete({
    required String collection,
    required String documentId,
  }) {
    return BatchOperation(
      collection: collection,
      documentId: documentId,
      type: BatchOperationType.delete,
    );
  }
}
