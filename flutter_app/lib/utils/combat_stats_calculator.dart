/// Combat stats calculator utility
/// 
/// Ported from server/calculs.py to calculate Defense and Protection
/// with full modifier support (talents, traits, equipment, qualities)
library;

/// Defense calculation details
class DefenseDetails {
  final int base; // Agilité
  final int armure;
  final String? armureNom;
  final String? armureQualite;
  final int bouclier;
  final List<ArmeModifier> armes;
  final List<TalentModifier> talents;
  final List<TraitModifier> traits;

  DefenseDetails({
    required this.base,
    required this.armure,
    this.armureNom,
    this.armureQualite,
    required this.bouclier,
    required this.armes,
    required this.talents,
    required this.traits,
  });

  int get total =>
      base +
      armure +
      bouclier +
      armes.fold<int>(0, (sum, a) => sum + a.modificateur) +
      talents.fold<int>(0, (sum, t) => sum + (t.modificateur as int)) +
      traits.fold<int>(0, (sum, t) => sum + (t.modificateur as int));
}

/// Protection calculation details
class ProtectionDetails {
  final String armureDice;
  final String sanctifieDice;
  final int bonusFixe;
  final List<TalentModifier> talents;
  final List<TraitModifier> traits;

  ProtectionDetails({
    required this.armureDice,
    required this.sanctifieDice,
    required this.bonusFixe,
    required this.talents,
    required this.traits,
  });

  String get formule {
    final dices = <String>[];
    if (armureDice != '0') dices.add(armureDice);
    if (sanctifieDice != '0') dices.add(sanctifieDice);

    // Add dice modifiers from talents/traits
    for (final t in talents) {
      if (t.modificateur is String && (t.modificateur as String).contains('D')) {
        dices.add(t.modificateur.toString());
      }
    }
    for (final t in traits) {
      if (t.modificateur is String && (t.modificateur as String).contains('D')) {
        dices.add(t.modificateur.toString());
      }
    }

    if (dices.isEmpty && bonusFixe == 0) return '0';

    String formula = dices.join('+');
    if (bonusFixe > 0) {
      formula += formula.isNotEmpty ? '+$bonusFixe' : bonusFixe.toString();
    } else if (bonusFixe < 0) {
      formula += bonusFixe.toString();
    }

    return formula;
  }
}

/// Weapon quality modifier
class ArmeModifier {
  final String nomArme;
  final String qualite;
  final int modificateur;

  ArmeModifier({
    required this.nomArme,
    required this.qualite,
    required this.modificateur,
  });
}

/// Talent modifier
class TalentModifier {
  final String nom;
  final int niveau;
  final dynamic modificateur; // Can be int or String (for dice like "1D4")

  TalentModifier({
    required this.nom,
    required this.niveau,
    required this.modificateur,
  });
}

/// Trait modifier
class TraitModifier {
  final String nom;
  final int niveau;
  final dynamic modificateur; // Can be int or String (for dice like "1D4")

  TraitModifier({
    required this.nom,
    required this.niveau,
    required this.modificateur,
  });
}

/// Combat stats calculator
class CombatStatsCalculator {
  /// Calculate total defense with detailed breakdown
  /// 
  /// Rule: Defense = Agility + armor_modif + shield_modif + weapon_qualities + talents + traits
  static DefenseDetails calculateDefense({
    required int agilite,
    required List<Map<String, dynamic>> inventaire,
    required List<Map<String, dynamic>> talents,
    required List<Map<String, dynamic>> traits,
  }) {
    Map<String, dynamic>? armureEquipee;
    Map<String, dynamic>? bouclierEquipe;
    final armesEquipees = <Map<String, dynamic>>[];

    // Find equipped items
    for (final item in inventaire) {
      if (item['equipee'] == true) {
        // Armor
        if (item['type'] == 'armure' && item['armure'] != null) {
          armureEquipee = item;
        }
        // Shield (weapon with defense modifier)
        if (item['arme'] != null) {
          final arme = item['arme'] as Map<String, dynamic>;
          final modifDefense = arme['modif_defense'] ?? 0;
          if (modifDefense != 0) {
            bouclierEquipe = item;
          } else {
            armesEquipees.add(item);
          }
        }
      }
    }

    int defense = agilite;
    int armureModif = 0;
    String? armureNom;
    String? armureQualite;

    // Armor modifier
    if (armureEquipee != null && armureEquipee['armure'] != null) {
      final armure = armureEquipee['armure'] as Map<String, dynamic>;
      final categorie = (armure['categorie'] ?? '').toString().toLowerCase();
      armureNom = armure['nom'] as String?;

      // Get armor qualities (multi-quality support)
      final qualitesArmures = armureEquipee['qualites_armures'] as List<dynamic>? ?? [];
      
      // Fallback to single quality for backwards compatibility
      if (qualitesArmures.isEmpty && armureEquipee['qualite_armure'] != null) {
        qualitesArmures.add(armureEquipee['qualite_armure']);
      }

      if (qualitesArmures.isNotEmpty) {
        final qualitesNoms = <String>[];
        int modifTotal = 0;

        for (final qualiteObj in qualitesArmures) {
          final qualite = qualiteObj as Map<String, dynamic>;
          qualitesNoms.add(qualite['nom'] ?? '');

          // Get defense modifier based on armor category
          int modif = 0;
          if (categorie.contains('legere') || categorie.contains('légère')) {
            modif = qualite['modif_defense_legere'] ?? 0;
          } else if (categorie.contains('moyenne')) {
            modif = qualite['modif_defense_moyenne'] ?? 0;
          } else if (categorie.contains('lourde')) {
            modif = qualite['modif_defense_lourde'] ?? 0;
          } else {
            modif = qualite['modif_defense'] ?? 0;
          }

          modifTotal += modif;
        }

        armureQualite = qualitesNoms.join(', ');
        armureModif = modifTotal;
        defense += modifTotal;
      }
    }

    // Shield modifier
    int bouclierModif = 0;
    if (bouclierEquipe != null && bouclierEquipe['arme'] != null) {
      final arme = bouclierEquipe['arme'] as Map<String, dynamic>;
      bouclierModif = arme['modif_defense'] ?? 0;
      defense += bouclierModif;
    }

    // Weapon quality modifiers (e.g., "Équilibré" gives +1 defense)
    final qualitesAvecBonusDefense = {
      'Équilibré': 1,
      'Equilibré': 1, // Support both spellings
    };

    final armesModifiers = <ArmeModifier>[];
    for (final arme in armesEquipees) {
      final qualitesArmes = arme['qualites_armes'] as List<dynamic>? ?? [];
      for (final qualiteObj in qualitesArmes) {
        final qualite = qualiteObj as Map<String, dynamic>;
        final qualiteNom = qualite['nom'] ?? '';
        final bonus = qualitesAvecBonusDefense[qualiteNom] ?? 0;
        if (bonus != 0) {
          armesModifiers.add(ArmeModifier(
            nomArme: arme['nom_objet'] ?? 'Arme',
            qualite: qualiteNom,
            modificateur: bonus,
          ));
          defense += bonus;
        }
      }
    }

    // Talent modifiers
    final talentsModifiers = <TalentModifier>[];
    for (final talentData in talents) {
      final talent = talentData['talent'] as Map<String, dynamic>?;
      if (talent == null) continue;

      dynamic niveauValue = talentData['niveau'] ?? 1;
      int niveau;
      if (niveauValue is String) {
        final niveauMap = {
          '1': 1, '2': 2, '3': 3,
          'novice': 1, 'adepte': 2, 'maitre': 3,
        };
        niveau = niveauMap[niveauValue.toLowerCase()] ?? 1;
      } else {
        niveau = niveauValue as int;
      }

      int modifDef = 0;
      if (niveau == 1) {
        modifDef = talent['modif_defense_novice'] ?? 0;
      } else if (niveau == 2) {
        modifDef = talent['modif_defense_adepte'] ?? 0;
      } else if (niveau == 3) {
        modifDef = talent['modif_defense_maitre'] ?? 0;
      }

      if (modifDef != 0) {
        talentsModifiers.add(TalentModifier(
          nom: talent['nom'] ?? 'Inconnu',
          niveau: niveau,
          modificateur: modifDef,
        ));
        defense += modifDef;
      }
    }

    // Trait modifiers
    final traitsModifiers = <TraitModifier>[];
    for (final traitData in traits) {
      final trait = traitData['trait'] as Map<String, dynamic>?;
      if (trait == null) continue;

      dynamic niveau = traitData['niveau'] ?? 1;
      if (niveau is String) {
        final niveauMap = {
          'I': 1, 'II': 2, 'III': 3,
          'novice': 1, 'adepte': 2, 'maitre': 3,
        };
        niveau = niveauMap[niveau] ?? 1;
      }

      int modifDef = 0;
      if (niveau == 1) {
        modifDef = trait['modif_defense_I'] ?? 0;
      } else if (niveau == 2) {
        modifDef = trait['modif_defense_II'] ?? 0;
      } else if (niveau == 3) {
        modifDef = trait['modif_defense_III'] ?? 0;
      }

      if (modifDef != 0) {
        traitsModifiers.add(TraitModifier(
          nom: trait['nom'] ?? 'Inconnu',
          niveau: niveau,
          modificateur: modifDef,
        ));
        defense += modifDef;
      }
    }

    return DefenseDetails(
      base: agilite,
      armure: armureModif,
      armureNom: armureNom,
      armureQualite: armureQualite,
      bouclier: bouclierModif,
      armes: armesModifiers,
      talents: talentsModifiers,
      traits: traitsModifiers,
    );
  }

  /// Calculate total protection with detailed breakdown
  /// 
  /// Rule: Protection = armor_dice + sanctified_dice + talent_modifs + trait_modifs
  static ProtectionDetails calculateProtection({
    required List<Map<String, dynamic>> inventaire,
    required List<Map<String, dynamic>> talents,
    required List<Map<String, dynamic>> traits,
  }) {
    String armureDice = '0';
    String sanctifieDice = '0';
    int bonusFixe = 0;
    final talentsModifiers = <TalentModifier>[];
    final traitsModifiers = <TraitModifier>[];

    // Find equipped armor
    Map<String, dynamic>? armureEquipee;
    bool estSanctifie = false;

    for (final item in inventaire) {
      if (item['equipee'] == true && 
          item['type'] == 'armure' && 
          item['armure'] != null) {
        armureEquipee = item;
        estSanctifie = item['est_sanctifie'] ?? false;
        break;
      }
    }

    // Armor dice
    if (armureEquipee != null && armureEquipee['armure'] != null) {
      final armure = armureEquipee['armure'] as Map<String, dynamic>;
      armureDice = armure['protection'] ?? '0';

      // Add protection modifiers from armor qualities
      final qualitesArmures = armureEquipee['qualites_armures'] as List<dynamic>? ?? [];
      
      if (qualitesArmures.isEmpty && armureEquipee['qualite_armure'] != null) {
        qualitesArmures.add(armureEquipee['qualite_armure']);
      }

      for (final qualiteObj in qualitesArmures) {
        final qualite = qualiteObj as Map<String, dynamic>;
        final modifProt = qualite['modif_protection'] ?? '0';
        if (modifProt != '0') {
          // Can be dice (e.g., "1D4") or fixed bonus (e.g., "2")
          if (modifProt.toString().toUpperCase().contains('D')) {
            // It's a dice, will be added to formula
          } else {
            try {
              bonusFixe += int.parse(modifProt.toString());
            } catch (_) {}
          }
        }
      }
    }

    // Sanctified (+1D4 protection)
    if (estSanctifie) {
      sanctifieDice = '1D4';
    }

    // Talent modifiers
    for (final talentData in talents) {
      final talent = talentData['talent'] as Map<String, dynamic>?;
      if (talent == null) continue;

      dynamic niveauValue = talentData['niveau'] ?? 1;
      int niveau;
      if (niveauValue is String) {
        final niveauMap = {
          '1': 1, '2': 2, '3': 3,
          'novice': 1, 'adepte': 2, 'maitre': 3,
        };
        niveau = niveauMap[niveauValue.toLowerCase()] ?? 1;
      } else {
        niveau = niveauValue as int;
      }

      String modifProt = '0';
      if (niveau == 1) {
        modifProt = talent['modif_protection_novice']?.toString() ?? '0';
      } else if (niveau == 2) {
        modifProt = talent['modif_protection_adepte']?.toString() ?? '0';
      } else if (niveau == 3) {
        modifProt = talent['modif_protection_maitre']?.toString() ?? '0';
      }

      if (modifProt != '0') {
        if (modifProt.toUpperCase().contains('D')) {
          // Dice modifier
          talentsModifiers.add(TalentModifier(
            nom: talent['nom'] ?? 'Inconnu',
            niveau: niveau,
            modificateur: modifProt,
          ));
        } else {
          // Fixed bonus
          try {
            final bonus = int.parse(modifProt);
            bonusFixe += bonus;
            talentsModifiers.add(TalentModifier(
              nom: talent['nom'] ?? 'Inconnu',
              niveau: niveau,
              modificateur: bonus,
            ));
          } catch (_) {}
        }
      }
    }

    // Trait modifiers
    for (final traitData in traits) {
      final trait = traitData['trait'] as Map<String, dynamic>?;
      if (trait == null) continue;

      dynamic niveau = traitData['niveau'] ?? 1;
      if (niveau is String) {
        final niveauMap = {
          'I': 1, 'II': 2, 'III': 3,
          'novice': 1, 'adepte': 2, 'maitre': 3,
        };
        niveau = niveauMap[niveau] ?? 1;
      }

      String modifProt = '0';
      if (niveau == 1) {
        modifProt = trait['modif_protection_I']?.toString() ?? '0';
      } else if (niveau == 2) {
        modifProt = trait['modif_protection_II']?.toString() ?? '0';
      } else if (niveau == 3) {
        modifProt = trait['modif_protection_III']?.toString() ?? '0';
      }

      if (modifProt != '0') {
        if (modifProt.toUpperCase().contains('D')) {
          // Dice modifier
          traitsModifiers.add(TraitModifier(
            nom: trait['nom'] ?? 'Inconnu',
            niveau: niveau,
            modificateur: modifProt,
          ));
        } else {
          // Fixed bonus
          try {
            final bonus = int.parse(modifProt);
            bonusFixe += bonus;
            traitsModifiers.add(TraitModifier(
              nom: trait['nom'] ?? 'Inconnu',
              niveau: niveau,
              modificateur: bonus,
            ));
          } catch (_) {}
        }
      }
    }

    return ProtectionDetails(
      armureDice: armureDice,
      sanctifieDice: sanctifieDice,
      bonusFixe: bonusFixe,
      talents: talentsModifiers,
      traits: traitsModifiers,
    );
  }
}
