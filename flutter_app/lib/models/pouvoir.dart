/// Modèles PouvoirMystique, RituelMystique et leurs associations personnage
library;

import 'talent.dart'; // Pour NiveauTalent
import 'json_helpers.dart';

/// Modèle PouvoirMystique (données de référence)
class PouvoirMystique {
  final int id;
  final String nom;
  final String tradition;
  final String? materiel;
  final String descriptionNovice;
  final String? descriptionAdepte;
  final String? descriptionMaitre;
  final String? exclusif;

  const PouvoirMystique({
    required this.id,
    required this.nom,
    required this.tradition,
    this.materiel,
    required this.descriptionNovice,
    this.descriptionAdepte,
    this.descriptionMaitre,
    this.exclusif,
  });

  factory PouvoirMystique.fromJson(Map<String, dynamic> json) {
    return PouvoirMystique(
      id: json['id'] as int,
      nom: json['nom'] as String,
      tradition: json['tradition'] as String,
      materiel: json['materiel'] as String?,
      descriptionNovice: json['description_novice'] as String? ?? '',
      descriptionAdepte: json['description_adepte'] as String?,
      descriptionMaitre: json['description_maitre'] as String?,
      exclusif: json['exclusif'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'tradition': tradition,
      'materiel': materiel,
      'description_novice': descriptionNovice,
      'description_adepte': descriptionAdepte,
      'description_maitre': descriptionMaitre,
      'exclusif': exclusif,
    };
  }

  /// Retourne la description pour un niveau donné
  String getDescriptionForNiveau(NiveauTalent niveau) {
    switch (niveau) {
      case NiveauTalent.novice:
        return descriptionNovice;
      case NiveauTalent.adepte:
        return descriptionAdepte ?? descriptionNovice;
      case NiveauTalent.maitre:
        return descriptionMaitre ?? descriptionAdepte ?? descriptionNovice;
    }
  }

  @override
  String toString() => nom;
}

/// Extension pour nettoyer les descriptions
extension PouvoirMystiqueExtensions on PouvoirMystique {
  String get cleanDescriptionNovice => cleanString(descriptionNovice);
  String? get cleanDescriptionAdepte => cleanString(descriptionAdepte);
  String? get cleanDescriptionMaitre => cleanString(descriptionMaitre);
  
  String getCleanDescriptionForNiveau(NiveauTalent niveau) {
    return cleanString(getDescriptionForNiveau(niveau));
  }
}

/// Modèle RituelMystique (données de référence)
class RituelMystique {
  final int id;
  final String nom;
  final String tradition;
  final String? materiel;
  final String description;
  final bool coutExperience;
  final String? exclusif;

  const RituelMystique({
    required this.id,
    required this.nom,
    required this.tradition,
    this.materiel,
    required this.description,
    this.coutExperience = false,
    this.exclusif,
  });

  factory RituelMystique.fromJson(Map<String, dynamic> json) {
    return RituelMystique(
      id: json['id'] as int,
      nom: json['nom'] as String,
      tradition: json['tradition'] as String,
      materiel: json['materiel'] as String?,
      description: json['description'] as String? ?? '',
      coutExperience: json['cout_experience'] as bool? ?? false,
      exclusif: json['exclusif'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'tradition': tradition,
      'materiel': materiel,
      'description': description,
      'cout_experience': coutExperience,
      'exclusif': exclusif,
    };
  }

  @override
  String toString() => nom;
}

extension RituelMystiqueExtensions on RituelMystique {
  String get cleanDescription => cleanString(description);
}

/// Pouvoir possédé par un personnage
class PersonnagePouvoir {
  final int id;
  final PouvoirMystique? pouvoir;
  final int niveau; // 1=Novice, 2=Adepte, 3=Maître

  const PersonnagePouvoir({
    required this.id,
    this.pouvoir,
    this.niveau = 1,
  });

  /// Helper pour parser un int qui peut être une String
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory PersonnagePouvoir.fromJson(Map<String, dynamic> json) {
    return PersonnagePouvoir(
      id: _parseInt(json['id'], 0),
      pouvoir: json['pouvoir'] != null
          ? PouvoirMystique.fromJson(json['pouvoir'])
          : null,
      niveau: _parseInt(json['niveau'], 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pouvoir': pouvoir?.toJson(),
      'niveau': niveau,
    };
  }

  /// Niveau sous forme d'enum
  NiveauTalent get niveauEnum => NiveauTalent.fromValue(niveau);

  /// Nom du pouvoir (shortcut)
  String get nom => pouvoir?.nom ?? 'Pouvoir inconnu';
  
  /// Description du pouvoir selon le niveau
  String get description => pouvoir?.getDescriptionForNiveau(niveauEnum) ?? '';

  /// Nom affiché avec niveau
  String get nomComplet {
    if (pouvoir == null) return 'Pouvoir inconnu';
    return '${pouvoir!.nom} (${niveauEnum.label})';
  }

  @override
  String toString() => nomComplet;
}

/// Rituel possédé par un personnage
class PersonnageRituel {
  final int id;
  final RituelMystique? rituel;

  const PersonnageRituel({
    required this.id,
    this.rituel,
  });

  /// Helper pour parser un int qui peut être une String
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory PersonnageRituel.fromJson(Map<String, dynamic> json) {
    return PersonnageRituel(
      id: _parseInt(json['id'], 0),
      rituel: json['rituel'] != null
          ? RituelMystique.fromJson(json['rituel'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rituel': rituel?.toJson(),
    };
  }

  /// Nom du rituel (shortcut)
  String get nom => rituel?.nom ?? 'Rituel inconnu';
  
  /// Description du rituel
  String get description => rituel?.description ?? '';

  @override
  String toString() => rituel?.nom ?? 'Rituel inconnu';
}
