/// Service d'authentification Firebase
/// Gère la connexion, déconnexion et gestion des utilisateurs
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';
import 'firestore_service.dart';

final _logger = Logger(printer: SimplePrinter());

/// Exception d'authentification
class AuthException implements Exception {
  final String message;
  final dynamic originalError;

  AuthException(this.message, [this.originalError]);

  @override
  String toString() => 'AuthException: $message';
}

/// Exception indiquant qu'une vérification d'email est requise (pas une erreur)
class EmailVerificationRequired extends AuthException {
  EmailVerificationRequired(super.message);
}

/// Service d'authentification
class FirebaseAuthService {
  static FirebaseAuthService? _instance;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthService._({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _logger.i('FirebaseAuthService initialisé');
  }

  /// Singleton
  static FirebaseAuthService get instance {
    _instance ??= FirebaseAuthService._();
    return _instance!;
  }

  /// Utilisateur courant
  User? get currentUser => _auth.currentUser;

  /// Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// UID de l'utilisateur courant
  String? get currentUserId => currentUser?.uid;

  /// Email de l'utilisateur courant
  String? get currentUserEmail => currentUser?.email;

  /// Est connecté
  bool get isAuthenticated => currentUser != null;

  // ===================== CONNEXION =====================

  /// Connexion avec email et mot de passe
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _logger.d('Connexion avec email: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw AuthException('Échec de la connexion');
      }


      // Bloquer les comptes dont l'email n'est pas vérifié
      if (!credential.user!.emailVerified) {
        try {
          await credential.user!.sendEmailVerification();
          _logger.i('✅ Email de vérification renvoyé à ${credential.user!.email}');
        } catch (e) {
          _logger.w('⚠️ Impossible d\'envoyer l\'email de vérification: $e');
        }

        // Déconnexion immédiate pour forcer la vérification
        await _auth.signOut();
        throw EmailVerificationRequired('Inscription réussie. Un email de vérification a été envoyé — veuillez vérifier votre adresse avant de vous connecter.');
      }

      // Synchroniser le flag verifiedMail dans Firestore
      try {
        await FirestoreService.instance.updateUserData(
          updates: {'verifiedMail': true, 'derniere_connexion': FieldValue.serverTimestamp()},
        );
      } catch (e) {
        _logger.w('⚠️ Impossible de synchroniser verifiedMail dans Firestore: $e');
      }

      _logger.i('✅ Connexion réussie: ${credential.user!.uid}');
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      _logger.e('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } on EmailVerificationRequired {
      // Propager la vérification demandée sans la re-wrapper
      rethrow;
    } on EmailVerificationRequired {
      // Propager la vérification demandée sans la re-wrapper
      rethrow;
    } catch (e) {
      _logger.e('❌ Erreur connexion: $e');
      throw AuthException('Erreur lors de la connexion', e);
    }
  }

  /// Inscription avec email et mot de passe
  Future<User> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _logger.d('Inscription avec email: $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw AuthException('Échec de l\'inscription');
      }

      // Créer le document utilisateur dans Firestore
      await _createUserDocument(credential.user!);

        // Envoyer l'email de vérification et déconnecter l'utilisateur pour forcer la vérification
        try {
          if (!credential.user!.emailVerified) {
            await credential.user!.sendEmailVerification();
            _logger.i('✅ Email de vérification envoyé à ${credential.user!.email}');
          }
        } catch (e) {
          _logger.w('⚠️ Impossible d\'envoyer l\'email de vérification: $e');
        }

        // Déconnexion immédiate pour empêcher l'accès tant que le mail n'est pas vérifié
        await _auth.signOut();

        // Informer l'appelant que la vérification est requise (utiliser exception dédiée)
        throw EmailVerificationRequired('Inscription réussie. Un email de vérification a été envoyé — veuillez vérifier votre adresse avant de vous connecter.');
    } on FirebaseAuthException catch (e) {
      _logger.e('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } on EmailVerificationRequired {
      // Propager la vérification demandée sans la re-wrapper
      rethrow;
    } catch (e) {
      _logger.e('❌ Erreur inscription: $e');
      throw AuthException('Erreur lors de l\'inscription', e);
    }
  }

  /// Connexion anonyme
  Future<User> signInAnonymously() async {
    try {
      _logger.d('Connexion anonyme');

      final credential = await _auth.signInAnonymously();

      if (credential.user == null) {
        throw AuthException('Échec de la connexion anonyme');
      }

      _logger.i('✅ Connexion anonyme réussie: ${credential.user!.uid}');
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      _logger.e('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('❌ Erreur connexion anonyme: $e');
      throw AuthException('Erreur lors de la connexion anonyme', e);
    }
  }

  /// Connexion avec Google
  Future<User> signInWithGoogle() async {
    try {
      _logger.d('Connexion avec Google');
      // Déclencher le flux d'authentification Google
      if (kIsWeb) {
        _logger.d('Google web client id: ${FirebaseConfig.googleWebClientId.isNotEmpty ? FirebaseConfig.googleWebClientId : '<EMPTY>'}');
      }

      final googleSignIn = kIsWeb
          ? GoogleSignIn(clientId: FirebaseConfig.googleWebClientId)
          : GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthException('Connexion Google annulée');
      }

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Créer une nouvelle credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Connexion à Firebase avec la credential Google
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw AuthException('Échec de la connexion Google');
      }

      // Créer/mettre à jour le document utilisateur dans Firestore
      await _createUserDocument(userCredential.user!);

      // Si l'email n'est pas vérifié (rare pour Google), bloquer l'accès
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        try {
          await userCredential.user!.sendEmailVerification();
          _logger.i('✅ Email de vérification renvoyé à ${userCredential.user!.email}');
        } catch (e) {
          _logger.w('⚠️ Impossible d\'envoyer l\'email de vérification: $e');
        }

        await _auth.signOut();
        throw EmailVerificationRequired('Votre adresse email n\'est pas vérifiée. Un email de vérification a été envoyé.');
      }

      // Synchroniser le flag verifiedMail dans Firestore
      try {
        await FirestoreService.instance.updateUserData(
          updates: {'verifiedMail': true, 'derniere_connexion': FieldValue.serverTimestamp()},
        );
      } catch (e) {
        _logger.w('⚠️ Impossible de synchroniser verifiedMail dans Firestore: $e');
      }

      _logger.i('✅ Connexion Google réussie: ${userCredential.user!.uid}');
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      _logger.e('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e, st) {
      _logger.e('❌ Erreur connexion Google: $e');
      _logger.d('Stack trace: $st');
      // Provide a more actionable message for common web issues
        final message = kIsWeb
          ? 'Erreur Google Sign-In (web). Vérifiez que le client OAuth Web est configuré et que l\'origine de votre site est ajoutée aux "Authorized JavaScript origins" du client OAuth dans Google Cloud Console.'
          : 'Erreur lors de la connexion Google';
      if (e is EmailVerificationRequired) rethrow;
      throw AuthException(message, e);
    }
  }

  // ===================== DÉCONNEXION =====================

  /// Déconnexion
  Future<void> signOut() async {
    try {
      _logger.d('Déconnexion');
      await _auth.signOut();
      _logger.i('✅ Déconnexion réussie');
    } catch (e) {
      _logger.e('❌ Erreur déconnexion: $e');
      throw AuthException('Erreur lors de la déconnexion', e);
    }
  }

  // ===================== GESTION MOT DE PASSE =====================

  /// Réinitialisation du mot de passe
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _logger.d('Envoi email de réinitialisation à: $email');
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      //  actionCodeSettings: ActionCodeSettings(
      //    url: 'https://YOUR_PROJECT_ID.web.app/__/auth/action',
      //    handleCodeInApp: true,
      //    androidPackageName: 'com.symbaroum.companion',
      //    androidInstallApp: true,
      //    iOSBundleId: 'com.symbaroum.companion.ios',
      //  ),
      );
      _logger.i('✅ Email de réinitialisation envoyé');
    } on FirebaseAuthException catch (e) {
      _logger.e('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('❌ Erreur envoi email: $e');
      throw AuthException('Erreur lors de l\'envoi de l\'email', e);
    }
  }

  /// Envoyer un email de vérification à l'utilisateur courant
  /// Retourne true si l'email a été demandé, false sinon.
  Future<bool> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('⚠️ Aucun utilisateur connecté; impossible d\'envoyer l\'email via le SDK client.');
        // Do not throw: caller will show a friendly message instead.
        return false;
      }

      await user.sendEmailVerification(
        ActionCodeSettings(
          url: 'https://YOUR_PROJECT_ID.web.app/__/auth/action',
          handleCodeInApp: true,
          androidPackageName: 'com.symbaroum.companion',
          androidInstallApp: true,
          iOSBundleId: 'com.symbaroum.companion.ios',
        ),
      );
      _logger.i('✅ Email de vérification envoyé à ${user.email}');
      return true;
    } catch (e) {
      _logger.w('⚠️ Erreur envoi email de vérification: $e');
      // Do not propagate as an error to UI; return false so the UI can show a friendly message.
      return false;
    }
  }

  /// Vérifier si l'email est vérifié et synchroniser le flag dans Firestore
  Future<bool> checkAndSyncEmailVerification({User? user}) async {
    try {
      final u = user ?? _auth.currentUser;
      if (u == null) return false;

      await u.reload();
      final verified = u.emailVerified;
      if (verified) {
        await FirestoreService.instance.updateUserData(
          updates: {'verifiedMail': true},
        );
      }
      return verified;
    } catch (e) {
      _logger.w('⚠️ Erreur lors de la vérification email: $e');
      return false;
    }
  }

  /// Sign in for verification check without enforcing the emailVerified check in
  /// the main sign-in flow. Returns true if the account is verified after sign-in.
  Future<bool> signInForVerificationCheck({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      final user = credential.user;
      if (user == null) return false;

      final verified = await checkAndSyncEmailVerification(user: user);
      if (!verified) {
        // If still not verified, sign out to keep behavior consistent
        await _auth.signOut();
        return false;
      }

      return true;
    } on FirebaseAuthException catch (e) {
      _logger.w('⚠️ signInForVerificationCheck failed: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _logger.w('⚠️ signInForVerificationCheck unexpected error: $e');
      return false;
    }
  }

  /// Modifier le mot de passe
  Future<void> updatePassword(String newPassword) async {
    try {
      if (currentUser == null) {
        throw AuthException('Aucun utilisateur connecté');
      }

      _logger.d('Modification du mot de passe');
      await currentUser!.updatePassword(newPassword);
      _logger.i('✅ Mot de passe modifié');
    } on FirebaseAuthException catch (e) {
      _logger.e('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('❌ Erreur modification mot de passe: $e');
      throw AuthException('Erreur lors de la modification du mot de passe', e);
    }
  }

  // ===================== GESTION PROFIL =====================

  /// Mettre à jour le profil utilisateur
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (currentUser == null) {
        throw AuthException('Aucun utilisateur connecté');
      }

      _logger.d('Mise à jour du profil');
      await currentUser!.updateDisplayName(displayName);
      await currentUser!.updatePhotoURL(photoURL);
      await currentUser!.reload();
      _logger.i('✅ Profil mis à jour');
    } catch (e) {
      _logger.e('❌ Erreur mise à jour profil: $e');
      throw AuthException('Erreur lors de la mise à jour du profil', e);
    }
  }

  /// Récupérer les données utilisateur depuis Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser == null) {
        return null;
      }

      final doc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(currentUser!.uid)
          .get();

      if (!doc.exists) {
        _logger.w('⚠️ Document utilisateur n\'existe pas');
        return null;
      }

      return doc.data();
    } catch (e) {
      _logger.e('❌ Erreur récupération données utilisateur: $e');
      return null;
    }
  }

  /// Vérifier si l'utilisateur est admin
  Future<bool> isAdmin() async {
    final userData = await getUserData();
    if (userData == null) return false;

    final roles = userData['roles'] as Map<String, dynamic>?;
    return roles?['admin'] == true;
  }

  /// Récupérer les rôles de l'utilisateur pour une campagne
  Future<String?> getRoleForCampagne(String campagneId) async {
    final userData = await getUserData();
    if (userData == null) return null;

    final roles = userData['roles'] as Map<String, dynamic>?;
    final campagnes = roles?['campagnes'] as Map<String, dynamic>?;
    return campagnes?[campagneId] as String?;
  }

  /// Vérifier si l'utilisateur est MJ d'une campagne
  Future<bool> isMJ(String campagneId) async {
    final role = await getRoleForCampagne(campagneId);
    return role == FirebaseConfig.roleMJ;
  }

  /// Vérifier si l'utilisateur est PJ d'une campagne
  Future<bool> isPJ(String campagneId) async {
    final role = await getRoleForCampagne(campagneId);
    return role == FirebaseConfig.rolePJ;
  }

  // ===================== HELPERS PRIVÉS =====================

  /// Créer le document utilisateur dans Firestore (seulement s'il n'existe pas)
  Future<void> _createUserDocument(User user) async {
    try {
      // Vérifier si le document existe déjà
      final existingUser = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(user.uid)
          .get();

      if (existingUser.exists) {
        _logger.i('✅ Document utilisateur existe déjà, pas de modification');
        return;
      }

      // Créer l'utilisateur uniquement s'il n'existe pas
      await FirestoreService.instance.createUser(
        uid: user.uid,
        email: user.email ?? 'unknown@example.com',
      );
      _logger.i('✅ Document utilisateur créé');
    } catch (e) {
      _logger.e('❌ Erreur création document utilisateur: $e');
      rethrow;
    }
  }

  /// Gérer les exceptions Firebase Auth
  AuthException _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('Aucun utilisateur trouvé avec cet email');
      case 'wrong-password':
        return AuthException('Mot de passe incorrect');
      case 'email-already-in-use':
        return AuthException('Cet email est déjà utilisé');
      case 'invalid-email':
        return AuthException('Email invalide');
      case 'weak-password':
        return AuthException('Le mot de passe est trop faible');
      case 'user-disabled':
        return AuthException('Ce compte a été désactivé');
      case 'too-many-requests':
        return AuthException('Trop de tentatives. Réessayez plus tard');
      case 'requires-recent-login':
        return AuthException('Cette action nécessite une connexion récente');
      default:
        return AuthException('Erreur d\'authentification: ${e.message}', e);
    }
  }
}
