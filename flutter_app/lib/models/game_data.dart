/// Modèle Race
/// Représente une race jouable (Humain, Gobelin, Ogre, etc.)
library;

class Race {
  final int id;
  final String nom;
  final String? description;

  const Race({
    required this.id,
    required this.nom,
    this.description,
  });

  /// Helper pour parser un int qui peut être une String
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      id: _parseInt(json['id'], 0),
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

  @override
  String toString() => nom;
}

/// Modèle Archetype
/// Représente un archétype de personnage (Guerrier, Mystique, etc.)
class Archetype {
  final int id;
  final String nom;
  final String? description;

  const Archetype({
    required this.id,
    required this.nom,
    this.description,
  });

  /// Helper pour parser un int qui peut être une String
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory Archetype.fromJson(Map<String, dynamic> json) {
    return Archetype(
      id: _parseInt(json['id'], 0),
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

  @override
  String toString() => nom;
}

/// Modèle Classe
/// Représente une classe/profession liée à un archétype
class Classe {
  final int id;
  final String nom;
  final String? description;
  final int? archetypeId;

  const Classe({
    required this.id,
    required this.nom,
    this.description,
    this.archetypeId,
  });

  /// Helper pour parser un int qui peut être une String
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Helper pour parser un int nullable qui peut être une String
  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory Classe.fromJson(Map<String, dynamic> json) {
    return Classe(
      id: _parseInt(json['id'], 0),
      nom: json['nom'] as String,
      description: json['description'] as String?,
      archetypeId: _parseIntOrNull(json['archetype_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'archetype_id': archetypeId,
    };
  }

  @override
  String toString() => nom;
}
