/// Validateur pour les contraintes de création de personnage
library;

/// Résultat de validation des caractéristiques
class CharacteristicsValidation {
  final bool isValid;
  final String? errorMessage;
  final int totalPoints;
  final int pointsUsed;
  final int pointsRemaining;

  CharacteristicsValidation({
    required this.isValid,
    this.errorMessage,
    required this.totalPoints,
    required this.pointsUsed,
    required this.pointsRemaining,
  });
}

/// Validateur de personnage
class CharacterValidator {
  /// Points totaux autorisés pour les caractéristiques
  static const int totalPoints = 80;
  
  /// Valeur de départ pour chaque caractéristique
  static const int startingValue = 10;
  
  /// Valeur minimale absolue
  static const int minValue = 5;
  
  /// Valeur maximale absolue
  static const int maxValue = 15;

  /// Liste des caractéristiques dans l'ordre alphabétique
  static const List<String> characteristicsOrder = [
    'agilite',
    'astuce',
    'discretion',
    'force',
    'persuasion',
    'precision',
    'vigilance',
    'volonte',
  ];

  /// Noms affichables des caractéristiques
  static const Map<String, String> characteristicsDisplayNames = {
    'agilite': 'Agilité',
    'astuce': 'Astuce',
    'discretion': 'Discrétion',
    'force': 'Force',
    'persuasion': 'Persuasion',
    'precision': 'Précision',
    'vigilance': 'Vigilance',
    'volonte': 'Volonté',
  };

  /// Valide les caractéristiques d'un personnage
  /// 
  /// Contraintes :
  /// - Total de 80 points
  /// - Une seule caractéristique à 5 (minimum)
  /// - Une seule caractéristique à 15 (maximum)
  /// - Toutes les autres entre ]5, 15[ (exclusif)
  static CharacteristicsValidation validate(Map<String, int> characteristics) {
    // Filtrer pour ne garder QUE les 8 caractéristiques de base
    final baseCharacteristics = Map<String, int>.fromEntries(
      characteristics.entries.where((entry) => characteristicsOrder.contains(entry.key)),
    );

    // Calculer le total des points utilisés
    int total = 0;
    int countAt5 = 0;
    int countAt15 = 0;
    List<String> errors = [];

    for (var entry in baseCharacteristics.entries) {
      final value = entry.value;
      total += value;

      // Compter les valeurs à 5 et 15
      if (value == minValue) {
        countAt5++;
      } else if (value == maxValue) {
        countAt15++;
      } else if (value < minValue || value > maxValue) {
        errors.add('${characteristicsDisplayNames[entry.key]} doit être entre $minValue et $maxValue');
      }
    }

    // Vérifier les contraintes
    if (countAt5 != 1) {
      errors.add('Une seule caractéristique doit être à $minValue (actuellement: $countAt5)');
    }
    if (countAt15 != 1) {
      errors.add('Une seule caractéristique doit être à $maxValue (actuellement: $countAt15)');
    }

    // Vérifier le total de points
    if (total != totalPoints) {
      errors.add('Total de points: $total/$totalPoints');
    }

    return CharacteristicsValidation(
      isValid: errors.isEmpty,
      errorMessage: errors.isNotEmpty ? errors.join('\n') : null,
      totalPoints: totalPoints,
      pointsUsed: total,
      pointsRemaining: totalPoints - total,
    );
  }

  /// Calcule l'endurance maximale à partir de la Force
  /// Formule : max(Force, 10)
  static int calculateMaxEndurance(int force) {
    return force > 10 ? force : 10;
  }

  /// Calcule la résistance à la douleur à partir de la Force
  /// Formule : ceil(Force / 2)
  static int calculatePainResistance(int force) {
    return (force / 2).ceil();
  }

  /// Calcule le seuil de corruption à partir de la Volonté
  /// Formule : ceil(Volonté / 2)
  static int calculateCorruptionThreshold(int volonte) {
    return (volonte / 2).ceil();
  }

  /// Crée les caractéristiques par défaut avec calculs automatiques
  static Map<String, dynamic> createDefaultCharacteristics() {
    const force = startingValue;
    const volonte = startingValue;

    return {
      'agilite': startingValue,
      'astuce': startingValue,
      'discretion': startingValue,
      'force': force,
      'persuasion': startingValue,
      'precision': startingValue,
      'vigilance': startingValue,
      'volonte': volonte,
      'endurance_actuelle': calculateMaxEndurance(force),
      'endurance_max': calculateMaxEndurance(force),
      'resistance_douleur': calculatePainResistance(force),
      'seuil_corruption': calculateCorruptionThreshold(volonte),
      'corruption': 0,
      'corruption_permanente': 0,
      'experience': 0,
    };
  }

  /// Met à jour les caractéristiques calculées en fonction de Force et Volonté
  static Map<String, dynamic> updateCalculatedCharacteristics(
    Map<String, dynamic> characteristics,
  ) {
    final force = characteristics['force'] as int;
    final volonte = characteristics['volonte'] as int;
    final currentEndurance = characteristics['endurance_actuelle'] as int;
    
    final newMaxEndurance = calculateMaxEndurance(force);
    
    // Ajuster l'endurance actuelle si elle dépasse le nouveau max
    final newCurrentEndurance = currentEndurance > newMaxEndurance 
        ? newMaxEndurance 
        : currentEndurance;

    return {
      ...characteristics,
      'endurance_actuelle': newCurrentEndurance,
      'endurance_max': newMaxEndurance,
      'resistance_douleur': calculatePainResistance(force),
      'seuil_corruption': calculateCorruptionThreshold(volonte),
    };
  }
}
