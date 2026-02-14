import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

/// Onglet Vue d'ensemble - Style MMORPG avec équipement + caractéristiques + stats
class PlayerOverviewTab extends ConsumerWidget {
  final String personnageId;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? race;
  final Map<String, dynamic>? classe;

  // Helper pour parser int/string depuis Firestore
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  const PlayerOverviewTab({
    super.key,
    required this.personnageId,
    required this.data,
    this.race,
    this.classe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caracteristiques = data['caracteristiques'] as Map<String, dynamic>? ?? {};
    final inventaire = data['inventaire'] as List<dynamic>? ?? [];

    // Trouver les équipements équipés
    final equippedItems = <Map<String, dynamic>>[];
    for (final item in inventaire) {
      final itemMap = item as Map<String, dynamic>;
      final equipee = itemMap['equipee'] as bool? ?? false;
      if (equipee) {
        equippedItems.add(itemMap);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Équipement équipé
          _buildSectionTitle('ÉQUIPEMENT'),
          const SizedBox(height: 12),
          _buildEquipmentSection(equippedItems),
          const SizedBox(height: 24),

          // Caractéristiques (triées alphabétiquement)
          _buildSectionTitle('CARACTÉRISTIQUES'),
          const SizedBox(height: 12),
          _buildCharacteristicsGrid(caracteristiques),
          const SizedBox(height: 24),

          // Stats de combat
          _buildSectionTitle('STATISTIQUES DE COMBAT'),
          const SizedBox(height: 12),
          _buildCombatStats(caracteristiques),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.cinzel(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: SymbaroumColors.primary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildEquipmentSection(List<Map<String, dynamic>> equippedItems) {
    if (equippedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: SymbaroumColors.cardBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: SymbaroumColors.textPrimary.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            'Aucun équipement équipé',
            style: GoogleFonts.lato(
              color: SymbaroumColors.textPrimary.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: equippedItems.map((item) => _buildEquippedItemChip(item)).toList(),
    );
  }

  Widget _buildEquippedItemChip(Map<String, dynamic> item) {
    // Utiliser nom_objet en priorité
    final nom = item['nom_objet'] as String? ?? item['nom'] as String? ?? 'Sans nom';
    final type = item['type'] as String? ?? 'equipement';
    
    IconData icon;
    Color color;
    
    switch (type) {
      case 'arme':
        icon = Icons.hardware;
        color = Colors.red[400]!;
        break;
      case 'armure':
        icon = Icons.shield;
        color = Colors.blue[400]!;
        break;
      default:
        icon = Icons.inventory;
        color = Colors.grey[400]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SymbaroumColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            nom,
            style: GoogleFonts.lato(
              color: SymbaroumColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacteristicsGrid(Map<String, dynamic> caracteristiques) {
    // Caractéristiques principales triées alphabétiquement
    final mainCharacteristics = [
      'agilite',
      'astuce',
      'discretion',
      'force',
      'persuasion',
      'precision',
      'vigilance',
      'volonte',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: mainCharacteristics.length,
      itemBuilder: (context, index) {
        final key = mainCharacteristics[index];
        final value = _parseInt(caracteristiques[key], 10);
        return _buildCharacteristicCard(
          _getCharacteristicDisplayName(key),
          value,
        );
      },
    );
  }

  Widget _buildCharacteristicCard(String name, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SymbaroumColors.cardBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SymbaroumColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.cinzel(
                color: SymbaroumColors.textPrimary,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: SymbaroumColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$value',
              style: GoogleFonts.cinzel(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombatStats(Map<String, dynamic> caracteristiques) {
    final enduranceActuelle = _parseInt(caracteristiques['endurance_actuelle'], 10);
    final enduranceMax = _parseInt(caracteristiques['endurance_max'], 10);
    final corruption = _parseInt(caracteristiques['corruption'], 0);
    final corruptionPermanente = _parseInt(caracteristiques['corruption_permanente'], 0);
    final resistanceDouleur = _parseInt(caracteristiques['resistance_douleur'], 5);
    final seuilCorruption = _parseInt(caracteristiques['seuil_corruption'], 5);
    
    // Défense de base (Agilité)
    final agilite = _parseInt(caracteristiques['agilite'], 10);
    final defense = agilite; // La défense de base = Agilité

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SymbaroumColors.cardBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SymbaroumColors.textPrimary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _buildStatRow(
            'Endurance',
            '$enduranceActuelle / $enduranceMax',
            Icons.favorite,
            Colors.red[400]!,
          ),
          const Divider(height: 20, color: Colors.white12),
          _buildStatRow(
            'Défense',
            '$defense',
            Icons.shield,
            Colors.blue[400]!,
          ),
          const Divider(height: 20, color: Colors.white12),
          _buildStatRow(
            'Résistance Douleur',
            '$resistanceDouleur',
            Icons.healing,
            Colors.green[400]!,
          ),
          const Divider(height: 20, color: Colors.white12),
          _buildStatRow(
            'Corruption',
            '$corruption / $seuilCorruption',
            Icons.warning,
            Colors.purple[400]!,
          ),
          const Divider(height: 20, color: Colors.white12),
          _buildStatRow(
            'Corruption Permanente',
            '$corruptionPermanente',
            Icons.dangerous,
            Colors.deepPurple[400]!,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.lato(
              color: SymbaroumColors.textPrimary.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lato(
            color: SymbaroumColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getCharacteristicDisplayName(String key) {
    const names = {
      'force': 'Force',
      'agilite': 'Agilité',
      'precision': 'Précision',
      'discretion': 'Discrétion',
      'persuasion': 'Persuasion',
      'astuce': 'Astuce',
      'vigilance': 'Vigilance',
      'volonte': 'Volonté',
    };
    return names[key] ?? key;
  }
}
