/// Modèles Talent et PersonnageTalent
library;

import 'json_helpers.dart';

/// Niveau de maîtrise d'un talent
enum NiveauTalent {
  novice(1, 'Novice'),
  adepte(2, 'Adepte'),
  maitre(3, 'Maître');

  const NiveauTalent(this.value, this.label);
  final int value;
  final String label;

  static NiveauTalent fromValue(int value) {
    return NiveauTalent.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NiveauTalent.novice,
    );
  }
}

/// Modèle Talent (données de référence)
class Talent {
  final int id;
  final String nom;
  final String? descriptionGenerale;
  final String? descriptionNovice;
  final String? descriptionAdepte;
  final String? descriptionMaitre;
  final String? type; // combat, mystique, général

  // Modificateurs par niveau
  final int modifDefenseNovice;
  final int modifDefenseAdepte;
  final int modifDefenseMaitre;
  final int modifAttaqueNovice;
  final int modifAttaqueAdepte;
  final int modifAttaqueMaitre;
  final String? modifDegatsNovice;
  final String? modifDegatsAdepte;
  final String? modifDegatsMaitre;
  final String? modifProtectionNovice;
  final String? modifProtectionAdepte;
  final String? modifProtectionMaitre;

  const Talent({
    required this.id,
    required this.nom,
    this.descriptionGenerale,
    this.descriptionNovice,
    this.descriptionAdepte,
    this.descriptionMaitre,
    this.type,
    this.modifDefenseNovice = 0,
    this.modifDefenseAdepte = 0,
    this.modifDefenseMaitre = 0,
    this.modifAttaqueNovice = 0,
    this.modifAttaqueAdepte = 0,
    this.modifAttaqueMaitre = 0,
    this.modifDegatsNovice,
    this.modifDegatsAdepte,
    this.modifDegatsMaitre,
    this.modifProtectionNovice,
    this.modifProtectionAdepte,
    this.modifProtectionMaitre,
  });

  factory Talent.fromJson(Map<String, dynamic> json) {
    return Talent(
      id: json['id'] as int,
      nom: json['nom'] as String,
      descriptionGenerale: json['description_generale'] as String?,
      descriptionNovice: json['description_novice'] as String?,
      descriptionAdepte: json['description_adepte'] as String?,
      descriptionMaitre: json['description_maitre'] as String?,
      type: json['type'] as String?,
      modifDefenseNovice: json['modif_defense_novice'] as int? ?? 0,
      modifDefenseAdepte: json['modif_defense_adepte'] as int? ?? 0,
      modifDefenseMaitre: json['modif_defense_maitre'] as int? ?? 0,
      modifAttaqueNovice: json['modif_attaque_novice'] as int? ?? 0,
      modifAttaqueAdepte: json['modif_attaque_adepte'] as int? ?? 0,
      modifAttaqueMaitre: json['modif_attaque_maitre'] as int? ?? 0,
      modifDegatsNovice: json['modif_degats_novice'] as String?,
      modifDegatsAdepte: json['modif_degats_adepte'] as String?,
      modifDegatsMaitre: json['modif_degats_maitre'] as String?,
      modifProtectionNovice: json['modif_protection_novice'] as String?,
      modifProtectionAdepte: json['modif_protection_adepte'] as String?,
      modifProtectionMaitre: json['modif_protection_maitre'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description_generale': descriptionGenerale,
      'description_novice': descriptionNovice,
      'description_adepte': descriptionAdepte,
      'description_maitre': descriptionMaitre,
      'type': type,
      'modif_defense_novice': modifDefenseNovice,
      'modif_defense_adepte': modifDefenseAdepte,
      'modif_defense_maitre': modifDefenseMaitre,
      'modif_attaque_novice': modifAttaqueNovice,
      'modif_attaque_adepte': modifAttaqueAdepte,
      'modif_attaque_maitre': modifAttaqueMaitre,
      'modif_degats_novice': modifDegatsNovice,
      'modif_degats_adepte': modifDegatsAdepte,
      'modif_degats_maitre': modifDegatsMaitre,
      'modif_protection_novice': modifProtectionNovice,
      'modif_protection_adepte': modifProtectionAdepte,
      'modif_protection_maitre': modifProtectionMaitre,
    };
  }

  /// Retourne la description pour un niveau donné
  String? getDescriptionForNiveau(NiveauTalent niveau) {
    switch (niveau) {
      case NiveauTalent.novice:
        return descriptionNovice;
      case NiveauTalent.adepte:
        return descriptionAdepte;
      case NiveauTalent.maitre:
        return descriptionMaitre;
    }
  }

  @override
  String toString() => nom;
}

/// Extension pour nettoyer les descriptions
extension TalentExtensions on Talent {
  String? get cleanDescriptionGenerale => cleanString(descriptionGenerale);
  String? get cleanDescriptionNovice => cleanString(descriptionNovice);
  String? get cleanDescriptionAdepte => cleanString(descriptionAdepte);
  String? get cleanDescriptionMaitre => cleanString(descriptionMaitre);
  
  String? getCleanDescriptionForNiveau(NiveauTalent niveau) {
    return cleanString(getDescriptionForNiveau(niveau));
  }
}

/// Talent possédé par un personnage
class PersonnageTalent {
  final int id;
  final Talent? talent;
  final int niveau; // 1=Novice, 2=Adepte, 3=Maître

  const PersonnageTalent({
    required this.id,
    this.talent,
    this.niveau = 1,
  });

  /// Helper pour parser un int qui peut être une String
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory PersonnageTalent.fromJson(Map<String, dynamic> json) {
    return PersonnageTalent(
      id: _parseInt(json['id'], 0),
      talent:
          json['talent'] != null ? Talent.fromJson(json['talent']) : null,
      niveau: _parseInt(json['niveau'], 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'talent': talent?.toJson(),
      'niveau': niveau,
    };
  }

  /// Niveau sous forme d'enum
  NiveauTalent get niveauEnum => NiveauTalent.fromValue(niveau);

  /// Nom du talent (shortcut)
  String get nom => talent?.nom ?? 'Talent inconnu';
  
  /// Description du talent selon le niveau
  String? get description => talent?.getDescriptionForNiveau(niveauEnum);

  /// Nom affiché avec niveau
  String get nomComplet {
    if (talent == null) return 'Talent inconnu';
    return '${talent!.nom} (${niveauEnum.label})';
  }

  @override
  String toString() => nomComplet;
}
