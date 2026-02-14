/// Modèle Campagne
/// Représente une campagne de jeu avec ses personnages associés
library;

class Campagne {
  final int id;
  final String nom;
  final String? description;
  final DateTime? dateCreation;
  final DateTime? dateDerniereSession;

  const Campagne({
    required this.id,
    required this.nom,
    this.description,
    this.dateCreation,
    this.dateDerniereSession,
  });

  /// Crée une Campagne depuis un JSON
  factory Campagne.fromJson(Map<String, dynamic> json) {
    return Campagne(
      id: json['id'] as int,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'] as String)
          : null,
      dateDerniereSession: json['date_derniere_session'] != null
          ? DateTime.parse(json['date_derniere_session'] as String)
          : null,
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'date_creation': dateCreation?.toIso8601String(),
      'date_derniere_session': dateDerniereSession?.toIso8601String(),
    };
  }

  /// Copie avec modifications
  Campagne copyWith({
    int? id,
    String? nom,
    String? description,
    DateTime? dateCreation,
    DateTime? dateDerniereSession,
  }) {
    return Campagne(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      dateCreation: dateCreation ?? this.dateCreation,
      dateDerniereSession: dateDerniereSession ?? this.dateDerniereSession,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Campagne &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Campagne(id: $id, nom: $nom)';
  
  // ===================== ALIAS POUR COMPATIBILITÉ =====================
  
  /// Alias - date de création
  DateTime? get createdAt => dateCreation;
  
  /// Liste des personnages (sera remplie par l'API si demandé)
  /// Note: Ce getter est un placeholder, normalement chargé via API séparée
  List<dynamic> get personnages => [];
}
