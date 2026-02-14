/// Système de gestion des permissions joueur/MJ
library;

import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

/// Type de permission
enum Permission {
  // Campagne
  createCampagne,
  editCampagne,
  deleteCampagne,
  viewAllCampagnes,
  
  // Personnage
  createPersonnage,
  editPersonnageInfos,
  editPersonnageCaracteristiques,
  editPersonnageInventaire,
  editPersonnageCapacites,
  viewPersonnagePrivateNotes,
  deletePersonnage,
  assignPersonnageToPlayer,
  
  // Inventaire
  addInventoryItem,
  removeInventoryItem,
  equipItem,
  modifyItemQuantity,
  modifyMoney,
  
  // Statistiques
  modifyEndurance,
  modifyCorruption,
  modifyExperience,
  modifyLevel,
  
  // Capacités
  addCapacity,
  removeCapacity,
  modifyCapacityLevel,
}

/// Service de gestion des permissions
class PermissionService {
  static PermissionService? _instance;
  final FirebaseAuthService _auth;

  PermissionService._({FirebaseAuthService? auth})
      : _auth = auth ?? FirebaseAuthService.instance;

  static PermissionService get instance {
    _instance ??= PermissionService._();
    return _instance!;
  }

  /// Vérifie si l'utilisateur est MJ de la campagne
  Future<bool> isMJ(String campagneId) async {
    return await _auth.isMJ(campagneId);
  }

  /// Vérifie si l'utilisateur est PJ de la campagne
  Future<bool> isPJ(String campagneId) async {
    return await _auth.isPJ(campagneId);
  }

  /// Vérifie si l'utilisateur a une permission spécifique
  Future<bool> hasPermission(
    Permission permission,
    String campagneId, {
    String? personnageId,
  }) async {
    final isMj = await isMJ(campagneId);

    // Le MJ a toutes les permissions
    if (isMj) return true;

    // Pour les joueurs, vérifier les permissions spécifiques
    final isPj = await isPJ(campagneId);
    if (!isPj) return false;

    // Permissions accordées aux joueurs
    switch (permission) {
      // Campagne - Lecture seule
      case Permission.createCampagne:
      case Permission.editCampagne:
      case Permission.deleteCampagne:
      case Permission.viewAllCampagnes:
        return false;

      // Personnage - Création basique uniquement
      case Permission.createPersonnage:
        return true;

      case Permission.editPersonnageInfos:
      case Permission.editPersonnageCaracteristiques:
        // Le joueur peut modifier son propre personnage (infos de base uniquement)
        return await _isOwnPersonnage(personnageId);

      case Permission.viewPersonnagePrivateNotes:
      case Permission.deletePersonnage:
      case Permission.assignPersonnageToPlayer:
      case Permission.editPersonnageCapacites:
        return false;

      // Inventaire - Gestion limitée
      case Permission.editPersonnageInventaire:
      case Permission.addInventoryItem:
      case Permission.removeInventoryItem:
      case Permission.equipItem:
      case Permission.modifyItemQuantity:
      case Permission.modifyMoney:
        // Le joueur peut gérer l'inventaire de son personnage
        return await _isOwnPersonnage(personnageId);

      // Statistiques - Modifications limitées
      case Permission.modifyEndurance:
      case Permission.modifyCorruption:
        // Le joueur peut modifier endurance et corruption de son personnage
        return await _isOwnPersonnage(personnageId);

      case Permission.modifyExperience:
      case Permission.modifyLevel:
        return false;

      // Capacités - Lecture seule
      case Permission.addCapacity:
      case Permission.removeCapacity:
      case Permission.modifyCapacityLevel:
        return false;
    }
  }

  /// Vérifie si le personnage appartient à l'utilisateur actuel
  Future<bool> _isOwnPersonnage(String? personnageId) async {
    if (personnageId == null) return false;

    final userId = _auth.currentUserId;
    if (userId == null) return false;

    try {
      final doc = await FirestoreService.instance.getDocument(
        collection: 'personnages',
        documentId: personnageId,
      );

      if (doc == null) return false;
      final joueurActifId = doc['joueur_actif_id'] as String?;
      return joueurActifId != null && joueurActifId == userId;
    } catch (_) {
      return false;
    }
  }

  /// Vérifie plusieurs permissions à la fois
  Future<Map<Permission, bool>> checkPermissions(
    List<Permission> permissions,
    String campagneId, {
    String? personnageId,
  }) async {
    final results = <Permission, bool>{};
    for (final permission in permissions) {
      results[permission] = await hasPermission(
        permission,
        campagneId,
        personnageId: personnageId,
      );
    }
    return results;
  }

  /// Vérifie si l'utilisateur peut éditer un personnage (au moins une permission d'édition)
  Future<bool> canEditPersonnage(String campagneId, String personnageId) async {
    final permissions = await checkPermissions(
      [
        Permission.editPersonnageInfos,
        Permission.editPersonnageCaracteristiques,
        Permission.editPersonnageInventaire,
        Permission.editPersonnageCapacites,
      ],
      campagneId,
      personnageId: personnageId,
    );

    return permissions.values.any((hasPermission) => hasPermission);
  }

  /// Obtient un message d'erreur adapté pour une permission refusée
  String getPermissionDeniedMessage(Permission permission) {
    switch (permission) {
      case Permission.createCampagne:
      case Permission.editCampagne:
      case Permission.deleteCampagne:
        return 'Seul le MJ peut gérer les campagnes';

      case Permission.editPersonnageCapacites:
      case Permission.addCapacity:
      case Permission.removeCapacity:
      case Permission.modifyCapacityLevel:
        return 'Seul le MJ peut modifier les capacités';

      case Permission.modifyExperience:
      case Permission.modifyLevel:
        return 'Seul le MJ peut modifier l\'expérience et le niveau';

      case Permission.deletePersonnage:
      case Permission.assignPersonnageToPlayer:
        return 'Seul le MJ peut effectuer cette action';

      case Permission.viewPersonnagePrivateNotes:
        return 'Vous n\'avez pas accès aux notes privées du MJ';

      default:
        return 'Vous n\'avez pas les permissions nécessaires';
    }
  }
}
