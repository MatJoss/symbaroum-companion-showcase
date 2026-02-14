/// Modèles AtoutFardeau et PersonnageAtoutFardeau
library;

import 'json_helpers.dart';

/// Modèle AtoutFardeau (données de référence)
class AtoutFardeau {
  final int id;
  final String nom;
  final String type; // 'atout' ou 'fardeau'
  final int coutXp; // 5 pour atout, -5 pour fardeau généralement
  final String description;
  final Map<String, dynamic>? effets; // Effets mécaniques en JSON
  final bool repetable;
  final int maxNiveau; // 1 ou 3 généralement

  const AtoutFardeau({
    required this.id,
    required this.nom,
    required this.type,
    required this.coutXp,
    required this.description,
    this.effets,
    this.repetable = false,
    this.maxNiveau = 1,
  });

  factory AtoutFardeau.fromJson(Map<String, dynamic> json) {
    return AtoutFardeau(
      id: json['id'] as int,
      nom: json['nom'] as String,
      type: json['type'] as String,
      coutXp: json['cout_xp'] as int,
      description: json['description'] as String? ?? '',
      effets: json['effets'] as Map<String, dynamic>?,
      repetable: json['repetable'] as bool? ?? false,
      maxNiveau: json['max_niveau'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'type': type,
      'cout_xp': coutXp,
      'description': description,
      'effets': effets,
      'repetable': repetable,
      'max_niveau': maxNiveau,
    };
  }

  /// Est un atout ?
  bool get isAtout => type == 'atout';

  /// Est un fardeau ?
  bool get isFardeau => type == 'fardeau';

  @override
  String toString() => nom;
}

/// Extension pour nettoyer les descriptions
extension AtoutFardeauExtensions on AtoutFardeau {
  String get cleanDescription => cleanString(description);
}

/// AtoutFardeau possédé par un personnage
class PersonnageAtoutFardeau {
  final int id;
  final AtoutFardeau? atoutFardeau;
  final int niveau; // Pour les répétables

  const PersonnageAtoutFardeau({
    required this.id,
    this.atoutFardeau,
    this.niveau = 1,
  });

  /// Helper pour parser un int qui peut être une String
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory PersonnageAtoutFardeau.fromJson(Map<String, dynamic> json) {
    return PersonnageAtoutFardeau(
      id: _parseInt(json['id'], 0),
      atoutFardeau: json['atout_fardeau'] != null
          ? AtoutFardeau.fromJson(json['atout_fardeau'])
          : null,
      niveau: _parseInt(json['niveau'], 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'atout_fardeau': atoutFardeau?.toJson(),
      'niveau': niveau,
    };
  }

  /// Nom (shortcut)
  String get nom => atoutFardeau?.nom ?? 'Inconnu';

  /// Nom complet avec niveau si répétable
  String get nomComplet {
    if (atoutFardeau == null) return 'Inconnu';
    if (atoutFardeau!.repetable && niveau > 1) {
      return '${atoutFardeau!.nom} (x$niveau)';
    }
    return atoutFardeau!.nom;
  }

  /// Type (atout/fardeau)
  String get type => atoutFardeau?.type ?? '';

  /// Est un atout ?
  bool get isAtout => atoutFardeau?.isAtout ?? false;

  /// Est un fardeau ?
  bool get isFardeau => atoutFardeau?.isFardeau ?? false;

  @override
  String toString() => nomComplet;
}
