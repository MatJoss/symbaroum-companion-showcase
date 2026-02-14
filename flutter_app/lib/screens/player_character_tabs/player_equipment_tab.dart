import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

/// Onglet Équipement - Style MMORPG avec slots d'équipement
class PlayerEquipmentTab extends ConsumerWidget {
  final String personnageId;
  final Map<String, dynamic> data;

  const PlayerEquipmentTab({
    super.key,
    required this.personnageId,
    required this.data,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventaire = data['inventaire'] as List<dynamic>? ?? [];
    
    // Récupérer les équipements actuels
    final equipements = inventaire.where((item) {
      final itemMap = item as Map<String, dynamic>;
      return itemMap['equipe'] == true;
    }).toList();

    // Identifier les slots
    Map<String, dynamic>? mainGauche;
    Map<String, dynamic>? mainDroite;
    Map<String, dynamic>? armure;

    for (final equip in equipements) {
      final item = equip as Map<String, dynamic>;
      final type = item['type'] as String?;
      final slot = item['slot'] as String?;

      if (type == 'arme') {
        if (slot == 'main_gauche') {
          mainGauche = item;
        } else {
          mainDroite = item;
        }
      } else if (type == 'armure') {
        armure = item;
      }
    }

    // Calculer les bonus
    final bonusDefense = _calculateDefenseBonus(armure);
    final bonusDegatsGauche = _calculateDamageBonus(mainGauche);
    final bonusDegatsD = _calculateDamageBonus(mainDroite);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques de combat
          _buildCombatStats(bonusDefense, bonusDegatsGauche + bonusDegatsD),
          const SizedBox(height: 24),

          // Slots d'équipement
          Text(
            'ÉQUIPEMENT',
            style: GoogleFonts.cinzel(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SymbaroumColors.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),

          // Main Gauche
          _buildEquipmentSlot(
            context,
            'Main Gauche',
            Icons.back_hand,  // Même icône que main droite
            mainGauche,
            'main_gauche',
            flipIcon: true,  // Flip horizontal
          ),
          const SizedBox(height: 12),

          // Main Droite
          _buildEquipmentSlot(
            context,
            'Main Droite',
            Icons.back_hand,
            mainDroite,
            'main_droite',
            flipIcon: false,
          ),
          const SizedBox(height: 12),

          // Armure
          _buildEquipmentSlot(
            context,
            'Armure',
            Icons.shield,
            armure,
            'armure',
          ),
        ],
      ),
    );
  }

  Widget _buildCombatStats(int defense, int degats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SymbaroumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SymbaroumColors.primary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            'DÉFENSE',
            '$defense',
            Icons.shield,
            Colors.blue[400]!,
          ),
          Container(
            width: 2,
            height: 40,
            color: SymbaroumColors.textPrimary.withValues(alpha: 0.3),
          ),
          _buildStatColumn(
            'DÉGÂTS',
            '+$degats',
            Icons.hardware,
            Colors.red[400]!,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.cinzel(
            color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cinzel(
            color: SymbaroumColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentSlot(
    BuildContext context,
    String slotName,
    IconData icon,
    Map<String, dynamic>? equipment,
    String slotId, {
    bool flipIcon = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SymbaroumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: equipment != null
              ? SymbaroumColors.primary
              : SymbaroumColors.textPrimary.withValues(alpha: 0.2),
          width: equipment != null ? 2 : 1,
        ),
      ),
      child: equipment != null
          ? _buildEquippedItem(context, equipment, slotId)
          : _buildEmptySlot(slotName, icon, flipIcon),
    );
  }

  Widget _buildEmptySlot(String slotName, IconData icon, bool flipIcon) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: SymbaroumColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: SymbaroumColors.textPrimary.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: flipIcon
                ? Transform.flip(
                    flipX: true,
                    child: Icon(
                      icon,
                      size: 32,
                      color: SymbaroumColors.textPrimary.withValues(alpha: 0.3),
                    ),
                  )
                : Icon(
                    icon,
                    size: 32,
                    color: SymbaroumColors.textPrimary.withValues(alpha: 0.3),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slotName,
                style: GoogleFonts.cinzel(
                  color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Vide',
                style: GoogleFonts.lato(
                  color: SymbaroumColors.textPrimary.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEquippedItem(
    BuildContext context,
    Map<String, dynamic> equipment,
    String slotId,
  ) {
    final nom = equipment['nom'] as String? ?? 'Sans nom';
    final degats = equipment['degats'] as String? ?? '';
    final qualite = equipment['qualite'] as int? ?? 0;

    return Row(
      children: [
        // Icône de l'équipement
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: SymbaroumColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: SymbaroumColors.primary,
              width: 2,
            ),
          ),
          child: Icon(
            _getItemIcon(equipment),
            size: 32,
            color: SymbaroumColors.primary,
          ),
        ),
        const SizedBox(width: 16),

        // Infos de l'équipement
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nom,
                style: GoogleFonts.cinzel(
                  color: SymbaroumColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (degats.isNotEmpty)
                Text(
                  'Dégâts: $degats',
                  style: GoogleFonts.lato(
                    color: SymbaroumColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              if (qualite > 0)
                Text(
                  'Qualité: $qualite',
                  style: GoogleFonts.lato(
                    color: SymbaroumColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),

        // Bouton déséquiper
        IconButton(
          onPressed: () => _unequipItem(context, equipment),
          icon: const Icon(Icons.close),
          color: Colors.red[400],
          tooltip: 'Déséquiper',
        ),
      ],
    );
  }

  IconData _getItemIcon(Map<String, dynamic> item) {
    final type = item['type'] as String?;
    if (type == 'arme') {
      return Icons.hardware;
    } else if (type == 'armure') {
      return Icons.shield;
    }
    return Icons.inventory;
  }

  int _calculateDefenseBonus(Map<String, dynamic>? armure) {
    if (armure == null) return 0;
    return armure['qualite'] as int? ?? 0;
  }

  int _calculateDamageBonus(Map<String, dynamic>? arme) {
    if (arme == null) return 0;
    // Simplification : on retourne la qualité comme bonus
    return arme['qualite'] as int? ?? 0;
  }

  Future<void> _unequipItem(BuildContext context, Map<String, dynamic> equipment) async {
    try {
      final firestoreService = FirestoreService.instance;
      final inventaire = List<Map<String, dynamic>>.from(
        data['inventaire'] as List<dynamic>? ?? [],
      );

      // Trouver l'index de l'équipement
      final index = inventaire.indexWhere((item) {
        return item['nom'] == equipment['nom'] &&
            item['type'] == equipment['type'];
      });

      if (index != -1) {
        inventaire[index]['equipe'] = false;
        inventaire[index].remove('slot');

        await firestoreService.updateDocument(
          collection: 'personnages',
          documentId: personnageId,
          data: {'inventaire': inventaire},
        );

        NotificationService.success('Équipement retiré');
      }
    } catch (e) {
      NotificationService.error('Erreur: $e');
    }
  }
}
