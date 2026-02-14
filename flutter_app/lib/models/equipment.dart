/// Modèles d'équipement: Arme, Armure, Equipement
library;

import 'json_helpers.dart';

/// Modèle Arme
class Arme {
  final int id;
  final String nom;
  final String? portee; // "Corps à corps", "Distance"
  final String? categorie; // "Courte", "Une main", "Longue", "Lourde", "Bouclier"
  final String? degats; // "1D8", "1D10", etc.
  final int? prix;
  final List<String> qualites;
  final int modifDefense;

  const Arme({
    required this.id,
    required this.nom,
    this.portee,
    this.categorie,
    this.degats,
    this.prix,
    this.qualites = const [],
    this.modifDefense = 0,
  });

  factory Arme.fromJson(Map<String, dynamic> json) {
    return Arme(
      id: parseInt(json['id'], 0),
      nom: json['nom'] as String,
      portee: json['portee'] as String?,
      categorie: json['categorie'] as String?,
      degats: json['degats'] as String?,
      prix: parseIntOrNull(json['prix']),
      qualites: (json['qualites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      modifDefense: parseInt(json['modif_defense'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'portee': portee,
      'categorie': categorie,
      'degats': degats,
      'prix': prix,
      'qualites': qualites,
      'modif_defense': modifDefense,
    };
  }

  /// Vérifie si c'est un bouclier
  bool get estBouclier => categorie?.toLowerCase() == 'bouclier';

  /// Vérifie si c'est une arme à distance
  bool get estDistance => portee?.toLowerCase() == 'distance';

  @override
  String toString() => nom;
}

/// Modèle Armure
class Armure {
  final int id;
  final String nom;
  final String? categorie; // "Légère", "Moyenne", "Lourde"
  final String? protection; // "1D4", "1D6", etc.
  final int malusDefense;
  final int? prix;
  final List<String> qualites;

  const Armure({
    required this.id,
    required this.nom,
    this.categorie,
    this.protection,
    this.malusDefense = 0,
    this.prix,
    this.qualites = const [],
  });

  factory Armure.fromJson(Map<String, dynamic> json) {
    return Armure(
      id: parseInt(json['id'], 0),
      nom: json['nom'] as String,
      categorie: json['categorie'] as String?,
      protection: json['protection'] as String?,
      malusDefense: parseInt(json['malus_defense'], 0),
      prix: parseIntOrNull(json['prix']),
      qualites: (json['qualites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'categorie': categorie,
      'protection': protection,
      'malus_defense': malusDefense,
      'prix': prix,
      'qualites': qualites,
    };
  }
  
  /// Alias pour entrave (= malus défense)
  int get entrave => malusDefense;

  @override
  String toString() => nom;
}

/// Modèle Equipement (objets génériques)
class Equipement {
  final int id;
  final String nom;
  final String? categorie;
  final String? sousCategorie;
  final double? prix;
  final String? uniteMesure;
  final String? description;
  final String? effets;
  final bool marcheNoir;
  final String? corruption;
  final String? niveauRequis;
  final String? bonusTalent;
  final bool usageUnique;
  final String? dureeEffet;

  const Equipement({
    required this.id,
    required this.nom,
    this.categorie,
    this.sousCategorie,
    this.prix,
    this.uniteMesure,
    this.description,
    this.effets,
    this.marcheNoir = false,
    this.corruption,
    this.niveauRequis,
    this.bonusTalent,
    this.usageUnique = false,
    this.dureeEffet,
  });

  factory Equipement.fromJson(Map<String, dynamic> json) {
    return Equipement(
      id: parseInt(json['id'], 0),
      nom: json['nom'] as String,
      categorie: json['categorie'] as String?,
      sousCategorie: json['sous_categorie'] as String?,
      prix: parseDoubleOrNull(json['prix']),
      uniteMesure: json['unite_mesure'] as String?,
      description: json['description'] as String?,
      effets: json['effets'] as String?,
      marcheNoir: json['marche_noir'] as bool? ?? false,
      corruption: json['corruption'] as String?,
      niveauRequis: json['niveau_requis'] as String?,
      bonusTalent: json['bonus_talent'] as String?,
      usageUnique: json['usage_unique'] as bool? ?? false,
      dureeEffet: json['duree_effet'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'categorie': categorie,
      'sous_categorie': sousCategorie,
      'prix': prix,
      'unite_mesure': uniteMesure,
      'description': description,
      'effets': effets,
      'marche_noir': marcheNoir,
      'corruption': corruption,
      'niveau_requis': niveauRequis,
      'bonus_talent': bonusTalent,
      'usage_unique': usageUnique,
      'duree_effet': dureeEffet,
    };
  }

  @override
  String toString() => nom;
}

/// Qualité d'arme
class QualiteArme {
  final int id;
  final String nom;
  final String? description;

  const QualiteArme({
    required this.id,
    required this.nom,
    this.description,
  });

  factory QualiteArme.fromJson(Map<String, dynamic> json) {
    return QualiteArme(
      id: parseInt(json['id'], 0),
      nom: json['nom'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
    };
  }
}

/// Qualité d'armure
class QualiteArmure {
  final int id;
  final String nom;
  final String? description;
  final int modifDefenseLegere;
  final int modifDefenseMoyenne;
  final int modifDefenseLourde;
  final String? modifProtection;

  const QualiteArmure({
    required this.id,
    required this.nom,
    this.description,
    this.modifDefenseLegere = 0,
    this.modifDefenseMoyenne = 0,
    this.modifDefenseLourde = 0,
    this.modifProtection,
  });

  factory QualiteArmure.fromJson(Map<String, dynamic> json) {
    return QualiteArmure(
      id: parseInt(json['id'], 0),
      nom: json['nom'] as String,
      description: json['description'] as String?,
      modifDefenseLegere: parseInt(json['modif_defense_legere'], 0),
      modifDefenseMoyenne: parseInt(json['modif_defense_moyenne'], 0),
      modifDefenseLourde: parseInt(json['modif_defense_lourde'], 0),
      modifProtection: json['modif_protection'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'modif_defense_legere': modifDefenseLegere,
      'modif_defense_moyenne': modifDefenseMoyenne,
      'modif_defense_lourde': modifDefenseLourde,
      'modif_protection': modifProtection,
    };
  }
}
