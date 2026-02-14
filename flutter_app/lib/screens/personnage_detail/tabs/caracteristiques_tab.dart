import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../utils/character_validator.dart';

/// Onglet de modification des caractéristiques avec validation
class CaracteristiquesTab extends StatefulWidget {
  final Map<String, int> caracteristiques;
  final Function(Map<String, int>) onCaracteristiquesChanged;
  final VoidCallback onModified;

  const CaracteristiquesTab({
    super.key,
    required this.caracteristiques,
    required this.onCaracteristiquesChanged,
    required this.onModified,
  });

  @override
  State<CaracteristiquesTab> createState() => _CaracteristiquesTabState();
}

class _CaracteristiquesTabState extends State<CaracteristiquesTab> {
  late Map<String, int> _characteristics;
  CharacteristicsValidation? _validation;

  @override
  void initState() {
    super.initState();
    _characteristics = Map<String, int>.from(widget.caracteristiques);
    _validateCharacteristics();
  }

  void _validateCharacteristics() {
    setState(() {
      _validation = CharacterValidator.validate(_characteristics);
    });
  }

  void _updateCharacteristic(String key, int value) {
    setState(() {
      _characteristics[key] = value;
      _validateCharacteristics();
    });
    widget.onCaracteristiquesChanged(_characteristics);
    widget.onModified();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Titre
        Text(
          'CARACTÉRISTIQUES',
          style: GoogleFonts.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SymbaroumTheme.gold,
            letterSpacing: 2,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Explications des contraintes
        _buildConstraintsInfo(),
        
        const SizedBox(height: 16),
        
        // Indicateur de points
        _buildPointsIndicator(),
        
        const SizedBox(height: 16),
        
        // Liste des caractéristiques (ordre alphabétique)
        ...CharacterValidator.characteristicsOrder.map(
          (char) => _buildCharacteristicSlider(char),
        ),
        
        const SizedBox(height: 24),
        
        // Caractéristiques calculées
        _buildCalculatedStats(),
      ],
    );
  }

  Widget _buildConstraintsInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SymbaroumTheme.gold.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: SymbaroumTheme.gold),
              const SizedBox(width: 8),
              Text(
                'CONTRAINTES',
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: SymbaroumTheme.gold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Total de 80 points\n'
            '• Une seule caractéristique à 5 (minimum)\n'
            '• Une seule caractéristique à 15 (maximum)\n'
            '• Les autres entre 6 et 14',
            style: GoogleFonts.crimsonText(
              fontSize: 14,
              color: SymbaroumTheme.parchment.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsIndicator() {
    final validation = _validation!;
    final isValid = validation.isValid;
    final remaining = validation.pointsRemaining;
    
    Color indicatorColor;
    IconData indicatorIcon;
    
    if (isValid) {
      indicatorColor = Colors.green;
      indicatorIcon = Icons.check_circle;
    } else if (remaining == 0) {
      indicatorColor = Colors.orange;
      indicatorIcon = Icons.warning;
    } else {
      indicatorColor = Colors.red;
      indicatorIcon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: indicatorColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(indicatorIcon, color: indicatorColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Points: ${validation.pointsUsed} / ${validation.totalPoints}',
                  style: GoogleFonts.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: indicatorColor,
                  ),
                ),
                if (!isValid && validation.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    validation.errorMessage!,
                    style: GoogleFonts.crimsonText(
                      fontSize: 13,
                      color: indicatorColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacteristicSlider(String key) {
    final value = _characteristics[key]!;
    final displayName = CharacterValidator.characteristicsDisplayNames[key]!;
    
    // Déterminer la couleur en fonction de la valeur
    Color valueColor;
    if (value == CharacterValidator.minValue) {
      valueColor = Colors.red;
    } else if (value == CharacterValidator.maxValue) {
      valueColor = Colors.green;
    } else {
      valueColor = SymbaroumTheme.parchment;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SymbaroumTheme.gold.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayName,
                style: GoogleFonts.crimsonText(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SymbaroumTheme.parchment,
                ),
              ),
              Text(
                value.toString(),
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Bouton -
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: SymbaroumTheme.gold,
                iconSize: 28,
                onPressed: value > CharacterValidator.minValue
                    ? () => _updateCharacteristic(key, value - 1)
                    : null,
              ),
              // Slider
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: SymbaroumTheme.gold,
                    inactiveTrackColor: SymbaroumTheme.gold.withValues(alpha: 0.2),
                    thumbColor: SymbaroumTheme.gold,
                    overlayColor: SymbaroumTheme.gold.withValues(alpha: 0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: CharacterValidator.minValue.toDouble(),
                    max: CharacterValidator.maxValue.toDouble(),
                    divisions: CharacterValidator.maxValue - CharacterValidator.minValue,
                    onChanged: (newValue) {
                      _updateCharacteristic(key, newValue.round());
                    },
                  ),
                ),
              ),
              // Bouton +
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: SymbaroumTheme.gold,
                iconSize: 28,
                onPressed: value < CharacterValidator.maxValue
                    ? () => _updateCharacteristic(key, value + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatedStats() {
    final force = _characteristics['force']!;
    final volonte = _characteristics['volonte']!;
    
    final maxEndurance = CharacterValidator.calculateMaxEndurance(force);
    final painResistance = CharacterValidator.calculatePainResistance(force);
    final corruptionThreshold = CharacterValidator.calculateCorruptionThreshold(volonte);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SymbaroumTheme.gold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATISTIQUES CALCULÉES',
            style: GoogleFonts.cinzel(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: SymbaroumTheme.gold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildCalculatedStatRow('Endurance Max', maxEndurance, '(max(Force, 10))'),
          _buildCalculatedStatRow('Résistance Douleur', painResistance, '(Force ÷ 2 arrondi)'),
          _buildCalculatedStatRow('Seuil Corruption', corruptionThreshold, '(Volonté ÷ 2 arrondi)'),
        ],
      ),
    );
  }

  Widget _buildCalculatedStatRow(String label, int value, String formula) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.crimsonText(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: SymbaroumTheme.parchment,
                ),
              ),
              Text(
                formula,
                style: GoogleFonts.crimsonText(
                  fontSize: 11,
                  color: SymbaroumTheme.parchment.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          Text(
            value.toString(),
            style: GoogleFonts.cinzel(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SymbaroumTheme.gold,
            ),
          ),
        ],
      ),
    );
  }
}
