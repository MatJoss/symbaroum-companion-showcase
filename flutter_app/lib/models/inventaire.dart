/// Modèle Inventaire
/// Représente un item dans l'inventaire d'un personnage
library;

import 'equipment.dart';

class InventaireItem {
  final int id;
  final String nomObjet;
  final String? description;
  final int quantite;
  final double poids;
  final String? type; // arme, armure, consommable, etc.
  final bool equipee;

  // Références aux équipements
  final int? armeId;
  final int? armureId;
  final int? equipementId;

  // Propriétés mystiques
  final bool estSanctifie;
  final bool estSouille;

  // Relations chargées
  final Arme? arme;
  final Armure? armure;
  final Equipement? equipement;
  final List<QualiteArme> qualitesArmes;
  final List<QualiteArmure> qualitesArmures;

  const InventaireItem({
    required this.id,
    required this.nomObjet,
    this.description,
    this.quantite = 1,
    this.poids = 0.0,
    this.type,
    this.equipee = false,
    this.armeId,
    this.armureId,
    this.equipementId,
    this.estSanctifie = false,
    this.estSouille = false,
    this.arme,
    this.armure,
    this.equipement,
    this.qualitesArmes = const [],
    this.qualitesArmures = const [],
  });

  /// Helper pour parser un int nullable qui peut être une String
  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Helper pour parser un int qui peut être une String
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory InventaireItem.fromJson(Map<String, dynamic> json) {
    return InventaireItem(
      id: _parseInt(json['id'], 0),
      nomObjet: json['nom_objet'] as String,
      description: json['description'] as String?,
      quantite: _parseInt(json['quantite'], 1),
      poids: (json['poids'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String?,
      equipee: json['equipee'] as bool? ?? false,
      armeId: _parseIntOrNull(json['arme_id']),
      armureId: _parseIntOrNull(json['armure_id']),
      equipementId: _parseIntOrNull(json['equipement_id']),
      estSanctifie: json['est_sanctifie'] as bool? ?? false,
      estSouille: json['est_souille'] as bool? ?? false,
      arme: json['arme'] != null ? Arme.fromJson(json['arme']) : null,
      armure: json['armure'] != null ? Armure.fromJson(json['armure']) : null,
      equipement: json['equipement'] != null
          ? Equipement.fromJson(json['equipement'])
          : null,
      qualitesArmes: (json['qualites_armes'] as List<dynamic>?)
              ?.map((e) => QualiteArme.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      qualitesArmures: (json['qualites_armures'] as List<dynamic>?)
              ?.map((e) => QualiteArmure.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_objet': nomObjet,
      'description': description,
      'quantite': quantite,
      'poids': poids,
      'type': type,
      'equipee': equipee,
      'arme_id': armeId,
      'armure_id': armureId,
      'equipement_id': equipementId,
      'est_sanctifie': estSanctifie,
      'est_souille': estSouille,
    };
  }

  /// Copie avec modifications
  InventaireItem copyWith({
    int? id,
    String? nomObjet,
    String? description,
    int? quantite,
    double? poids,
    String? type,
    bool? equipee,
    int? armeId,
    int? armureId,
    int? equipementId,
    bool? estSanctifie,
    bool? estSouille,
    Arme? arme,
    Armure? armure,
    Equipement? equipement,
    List<QualiteArme>? qualitesArmes,
    List<QualiteArmure>? qualitesArmures,
  }) {
    return InventaireItem(
      id: id ?? this.id,
      nomObjet: nomObjet ?? this.nomObjet,
      description: description ?? this.description,
      quantite: quantite ?? this.quantite,
      poids: poids ?? this.poids,
      type: type ?? this.type,
      equipee: equipee ?? this.equipee,
      armeId: armeId ?? this.armeId,
      armureId: armureId ?? this.armureId,
      equipementId: equipementId ?? this.equipementId,
      estSanctifie: estSanctifie ?? this.estSanctifie,
      estSouille: estSouille ?? this.estSouille,
      arme: arme ?? this.arme,
      armure: armure ?? this.armure,
      equipement: equipement ?? this.equipement,
      qualitesArmes: qualitesArmes ?? this.qualitesArmes,
      qualitesArmures: qualitesArmures ?? this.qualitesArmures,
    );
  }

  /// Vérifie si c'est une arme
  bool get estArme => type == 'arme' || armeId != null;

  /// Vérifie si c'est une armure
  bool get estArmure => type == 'armure' || armureId != null;

  /// Vérifie si c'est un bouclier
  bool get estBouclier => arme?.estBouclier ?? false;

  /// Vérifie si l'item peut être équipé
  bool get peutEquiper => estArme || estArmure;

  /// Retourne le nom affiché
  String get nomAffiche {
    if (arme != null) return arme!.nom;
    if (armure != null) return armure!.nom;
    if (equipement != null) return equipement!.nom;
    return nomObjet;
  }
  
  /// Alias pour compatibilité - nom
  String get nom => nomAffiche;

  /// Retourne les dégâts (si arme)
  String? get degats => arme?.degats;

  /// Retourne la protection (si armure)
  String? get protection => armure?.protection;

  @override
  String toString() => nomAffiche;
}
