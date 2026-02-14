/// Modèle Caracteristiques
/// Représente les caractéristiques d'un personnage (attributs, endurance, corruption)
library;

class Caracteristiques {
  final int id;

  // Attributs primaires
  final int force;
  final int agilite;
  final int precision;
  final int persuasion;
  final int discretion;
  final int vigilance;
  final int volonte;
  final int astuce;

  // Attributs dérivés
  final int enduranceMax;
  final int enduranceActuelle;
  final int resistanceDouleur;
  final int corruption;
  final int corruptionPermanente;
  final int seuilCorruption;
  final int experience;

  const Caracteristiques({
    required this.id,
    this.force = 10,
    this.agilite = 10,
    this.precision = 10,
    this.persuasion = 10,
    this.discretion = 10,
    this.vigilance = 10,
    this.volonte = 10,
    this.astuce = 10,
    this.enduranceMax = 10,
    this.enduranceActuelle = 10,
    this.resistanceDouleur = 5,
    this.corruption = 0,
    this.corruptionPermanente = 0,
    this.seuilCorruption = 5,
    this.experience = 0,
  });

  /// Helper pour parser un int nullable qui peut être une String
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Crée des Caracteristiques depuis un JSON
  factory Caracteristiques.fromJson(Map<String, dynamic> json) {
    return Caracteristiques(
      id: _parseInt(json['id'], 0),
      force: _parseInt(json['force'], 10),
      agilite: _parseInt(json['agilite'], 10),
      precision: _parseInt(json['precision'], 10),
      persuasion: _parseInt(json['persuasion'], 10),
      discretion: _parseInt(json['discretion'], 10),
      vigilance: _parseInt(json['vigilance'], 10),
      volonte: _parseInt(json['volonte'], 10),
      astuce: _parseInt(json['astuce'], 10),
      enduranceMax: _parseInt(json['endurance_max'], 10),
      enduranceActuelle: _parseInt(json['endurance_actuelle'], 10),
      resistanceDouleur: _parseInt(json['resistance_douleur'], 5),
      corruption: _parseInt(json['corruption'], 0),
      corruptionPermanente: _parseInt(json['corruption_permanente'], 0),
      seuilCorruption: _parseInt(json['seuil_corruption'], 5),
      experience: _parseInt(json['experience'], 0),
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'force': force,
      'agilite': agilite,
      'precision': precision,
      'persuasion': persuasion,
      'discretion': discretion,
      'vigilance': vigilance,
      'volonte': volonte,
      'astuce': astuce,
      'endurance_max': enduranceMax,
      'endurance_actuelle': enduranceActuelle,
      'resistance_douleur': resistanceDouleur,
      'corruption': corruption,
      'corruption_permanente': corruptionPermanente,
      'seuil_corruption': seuilCorruption,
      'experience': experience,
    };
  }

  /// Copie avec modifications
  Caracteristiques copyWith({
    int? id,
    int? force,
    int? agilite,
    int? precision,
    int? persuasion,
    int? discretion,
    int? vigilance,
    int? volonte,
    int? astuce,
    int? enduranceMax,
    int? enduranceActuelle,
    int? resistanceDouleur,
    int? corruption,
    int? corruptionPermanente,
    int? seuilCorruption,
    int? experience,
  }) {
    return Caracteristiques(
      id: id ?? this.id,
      force: force ?? this.force,
      agilite: agilite ?? this.agilite,
      precision: precision ?? this.precision,
      persuasion: persuasion ?? this.persuasion,
      discretion: discretion ?? this.discretion,
      vigilance: vigilance ?? this.vigilance,
      volonte: volonte ?? this.volonte,
      astuce: astuce ?? this.astuce,
      enduranceMax: enduranceMax ?? this.enduranceMax,
      enduranceActuelle: enduranceActuelle ?? this.enduranceActuelle,
      resistanceDouleur: resistanceDouleur ?? this.resistanceDouleur,
      corruption: corruption ?? this.corruption,
      corruptionPermanente: corruptionPermanente ?? this.corruptionPermanente,
      seuilCorruption: seuilCorruption ?? this.seuilCorruption,
      experience: experience ?? this.experience,
    );
  }

  /// Retourne la liste des attributs sous forme de Map
  Map<String, int> get attributsMap => {
        'Force': force,
        'Agilite': agilite,
        'Precision': precision,
        'Persuasion': persuasion,
        'Discretion': discretion,
        'Vigilance': vigilance,
        'Volonte': volonte,
        'Astuce': astuce,
      };
}
