/// Modèle Argent
/// Représente l'argent d'un personnage (thalers, shillings, ortegs)
library;

class Argent {
  final int id;
  final int thalers;
  final int shillings;
  final int ortegs;

  const Argent({
    required this.id,
    this.thalers = 0,
    this.shillings = 0,
    this.ortegs = 0,
  });

  /// Helper pour parser un int qui peut être une String
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory Argent.fromJson(Map<String, dynamic> json) {
    return Argent(
      id: _parseInt(json['id'], 0),
      thalers: _parseInt(json['thalers'], 0),
      shillings: _parseInt(json['shillings'], 0),
      ortegs: _parseInt(json['ortegs'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thalers': thalers,
      'shillings': shillings,
      'ortegs': ortegs,
    };
  }

  Argent copyWith({
    int? id,
    int? thalers,
    int? shillings,
    int? ortegs,
  }) {
    return Argent(
      id: id ?? this.id,
      thalers: thalers ?? this.thalers,
      shillings: shillings ?? this.shillings,
      ortegs: ortegs ?? this.ortegs,
    );
  }

  /// Valeur totale en ortegs (1 thaler = 10 shillings = 100 ortegs)
  int get totalOrtegs => thalers * 100 + shillings * 10 + ortegs;

  /// Format d'affichage
  String get formatted {
    final parts = <String>[];
    if (thalers > 0) parts.add('$thalers th');
    if (shillings > 0) parts.add('$shillings sh');
    if (ortegs > 0 || parts.isEmpty) parts.add('$ortegs or');
    return parts.join(' ');
  }

  @override
  String toString() => formatted;
}
