/// Modèles Trait et PersonnageTrait
library;

import 'json_helpers.dart';

/// Type de niveau d'un trait
enum TraitNiveauType {
  sansNiveau('sans_niveau'),
  noviceAdepteMaitre('novice_adepte_maitre'),
  monstrueux('monstrueux');

  const TraitNiveauType(this.value);
  final String value;

  static TraitNiveauType fromValue(String? value) {
    return TraitNiveauType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TraitNiveauType.noviceAdepteMaitre,
    );
  }
}

/// Modèle Trait (données de référence)
class Trait {
  final int id;
  final String nom;
  final String? type; // "racial", "monstrueux", "social"
  final String? descriptionGenerale;
  final String niveauType; // 'sans_niveau', 'novice_adepte_maitre', 'monstrueux'

  // Descriptions par niveau (novice/adepte/maitre)
  final String? descriptionNovice;
  final String? descriptionAdepte;
  final String? descriptionMaitre;

  // Descriptions par niveau (monstrueux I/II/III)
  final String? descriptionI;
  final String? descriptionII;
  final String? descriptionIII;

  final bool gratuit;

  // Modificateurs (I/II/III utilisés pour les deux systèmes)
  final int modifDefenseI;
  final int modifDefenseII;
  final int modifDefenseIII;
  final int modifAttaqueI;
  final int modifAttaqueII;
  final int modifAttaqueIII;
  final String? modifDegatsI;
  final String? modifDegatsII;
  final String? modifDegatsIII;
  final String? modifProtectionI;
  final String? modifProtectionII;
  final String? modifProtectionIII;

  const Trait({
    required this.id,
    required this.nom,
    this.type,
    this.descriptionGenerale,
    this.niveauType = 'novice_adepte_maitre',
    this.descriptionNovice,
    this.descriptionAdepte,
    this.descriptionMaitre,
    this.descriptionI,
    this.descriptionII,
    this.descriptionIII,
    this.gratuit = false,
    this.modifDefenseI = 0,
    this.modifDefenseII = 0,
    this.modifDefenseIII = 0,
    this.modifAttaqueI = 0,
    this.modifAttaqueII = 0,
    this.modifAttaqueIII = 0,
    this.modifDegatsI,
    this.modifDegatsII,
    this.modifDegatsIII,
    this.modifProtectionI,
    this.modifProtectionII,
    this.modifProtectionIII,
  });

  factory Trait.fromJson(Map<String, dynamic> json) {
    return Trait(
      id: json['id'] as int,
      nom: json['nom'] as String,
      type: json['type'] as String?,
      descriptionGenerale: json['description_generale'] as String?,
      niveauType: json['niveau_type'] as String? ?? 'novice_adepte_maitre',
      descriptionNovice: json['description_novice'] as String?,
      descriptionAdepte: json['description_adepte'] as String?,
      descriptionMaitre: json['description_maitre'] as String?,
      descriptionI: json['description_I'] as String?,
      descriptionII: json['description_II'] as String?,
      descriptionIII: json['description_III'] as String?,
      gratuit: json['gratuit'] as bool? ?? false,
      modifDefenseI: json['modif_defense_I'] as int? ?? 0,
      modifDefenseII: json['modif_defense_II'] as int? ?? 0,
      modifDefenseIII: json['modif_defense_III'] as int? ?? 0,
      modifAttaqueI: json['modif_attaque_I'] as int? ?? 0,
      modifAttaqueII: json['modif_attaque_II'] as int? ?? 0,
      modifAttaqueIII: json['modif_attaque_III'] as int? ?? 0,
      modifDegatsI: json['modif_degats_I'] as String?,
      modifDegatsII: json['modif_degats_II'] as String?,
      modifDegatsIII: json['modif_degats_III'] as String?,
      modifProtectionI: json['modif_protection_I'] as String?,
      modifProtectionII: json['modif_protection_II'] as String?,
      modifProtectionIII: json['modif_protection_III'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'type': type,
      'description_generale': descriptionGenerale,
      'niveau_type': niveauType,
      'description_novice': descriptionNovice,
      'description_adepte': descriptionAdepte,
      'description_maitre': descriptionMaitre,
      'description_I': descriptionI,
      'description_II': descriptionII,
      'description_III': descriptionIII,
      'gratuit': gratuit,
    };
  }

  /// Vérifie si c'est un trait monstrueux
  bool get isMonstrueux => niveauType == 'monstrueux';

  /// Vérifie si le trait a des niveaux
  bool get hasNiveaux => niveauType != 'sans_niveau';

  @override
  String toString() => nom;
}

/// Extension pour nettoyer les descriptions
extension TraitExtensions on Trait {
  String? get cleanDescriptionGenerale => cleanString(descriptionGenerale);
  String? get cleanDescriptionNovice => cleanString(descriptionNovice);
  String? get cleanDescriptionAdepte => cleanString(descriptionAdepte);
  String? get cleanDescriptionMaitre => cleanString(descriptionMaitre);
  String? get cleanDescriptionI => cleanString(descriptionI);
  String? get cleanDescriptionII => cleanString(descriptionII);
  String? get cleanDescriptionIII => cleanString(descriptionIII);
}

/// Trait possédé par un personnage
class PersonnageTrait {
  final int id;
  final Trait? trait;
  final int niveau; // 1, 2, 3

  const PersonnageTrait({
    required this.id,
    this.trait,
    this.niveau = 1,
  });

  /// Helper pour parser un int qui peut être une String
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory PersonnageTrait.fromJson(Map<String, dynamic> json) {
    return PersonnageTrait(
      id: _parseInt(json['id'], 0),
      trait: json['trait'] != null ? Trait.fromJson(json['trait']) : null,
      niveau: _parseNiveau(json['niveau']),
    );
  }
  
  /// Parse le niveau depuis le JSON (peut être int ou String)
  static int _parseNiveau(dynamic value) {
    if (value == null) return 1;
    if (value is int) return value;
    if (value is String) {
      // Convertir les strings en int
      switch (value.toLowerCase()) {
        case 'novice':
        case 'i':
        case '1':
          return 1;
        case 'adepte':
        case 'ii':
        case '2':
          return 2;
        case 'maitre':
        case 'maître':
        case 'iii':
        case '3':
          return 3;
        default:
          return 1;
      }
    }
    return 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trait': trait?.toJson(),
      'niveau': niveau,
    };
  }

  /// Label du niveau selon le type de trait
  String get niveauLabel {
    if (trait == null) return '';
    if (trait!.isMonstrueux) {
      return ['', 'I', 'II', 'III'][niveau.clamp(0, 3)];
    } else {
      return ['', 'Novice', 'Adepte', 'Maître'][niveau.clamp(0, 3)];
    }
  }

  /// Nom du trait (shortcut)
  String get nom => trait?.nom ?? 'Trait inconnu';
  
  /// Description du trait
  String? get description => trait?.descriptionGenerale;

  /// Nom affiché avec niveau
  String get nomComplet {
    if (trait == null) return 'Trait inconnu';
    if (!trait!.hasNiveaux) return trait!.nom;
    return '${trait!.nom} ($niveauLabel)';
  }

  @override
  String toString() => nomComplet;
}
