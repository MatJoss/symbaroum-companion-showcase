import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../utils/combat_stats_calculator.dart';

/// Widget to display detailed combat statistics (Defense & Protection)
/// Shows formula breakdown with all modifiers from talents, traits, and equipment
class CombatStatsWidget extends StatelessWidget {
  final Map<String, dynamic> personnage;

  const CombatStatsWidget({
    super.key,
    required this.personnage,
  });

  @override
  Widget build(BuildContext context) {
    final caracteristiques = personnage['caracteristiques'] as Map<String, dynamic>? ?? {};
    final inventaire = List<Map<String, dynamic>>.from(personnage['inventaire'] ?? []);
    final talents = List<Map<String, dynamic>>.from(personnage['talents'] ?? []);
    final traits = List<Map<String, dynamic>>.from(personnage['traits'] ?? []);

    final agilite = caracteristiques['agilite'] ?? 10;

    // Calculate defense and protection
    final defenseDetails = CombatStatsCalculator.calculateDefense(
      agilite: agilite,
      inventaire: inventaire,
      talents: talents,
      traits: traits,
    );

    final protectionDetails = CombatStatsCalculator.calculateProtection(
      inventaire: inventaire,
      talents: talents,
      traits: traits,
    );

    return Container(
      decoration: BoxDecoration(
        color: SymbaroumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SymbaroumColors.primary.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(Icons.shield, color: SymbaroumColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Statistiques de Combat',
                style: GoogleFonts.cinzel(
                  color: SymbaroumColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),

          // Defense Section
          _buildDefenseSection(defenseDetails),
          const SizedBox(height: 16),

          // Protection Section
          _buildProtectionSection(protectionDetails),
        ],
      ),
    );
  }

  Widget _buildDefenseSection(DefenseDetails details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Defense Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Défense',
              style: GoogleFonts.lato(
                color: SymbaroumColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SymbaroumColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SymbaroumColors.primary),
              ),
              child: Text(
                '${details.total}',
                style: GoogleFonts.lato(
                  color: SymbaroumColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Formula breakdown
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatLine('Base (Agilité)', details.base),
              if (details.armure != 0) ...[
                _buildStatLine(
                  details.armureNom ?? 'Armure',
                  details.armure,
                  subtitle: details.armureQualite,
                ),
              ],
              if (details.bouclier != 0)
                _buildStatLine('Bouclier', details.bouclier),
              
              // Weapon quality modifiers
              if (details.armes.isNotEmpty)
                ...details.armes.map((a) => _buildStatLine(
                  '${a.nomArme} (${a.qualite})',
                  a.modificateur,
                )),

              // Talent modifiers
              if (details.talents.isNotEmpty)
                ...details.talents.map((t) => _buildStatLine(
                  '${t.nom} (${_niveauToString(t.niveau)})',
                  t.modificateur as int,
                  isTalent: true,
                )),

              // Trait modifiers
              if (details.traits.isNotEmpty)
                ...details.traits.map((t) => _buildStatLine(
                  '${t.nom} (${_niveauToRoman(t.niveau)})',
                  t.modificateur as int,
                  isTrait: true,
                )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProtectionSection(ProtectionDetails details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Protection Total (formula)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Protection',
              style: GoogleFonts.lato(
                color: SymbaroumColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SymbaroumColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SymbaroumColors.primary),
              ),
              child: Text(
                details.formule,
                style: GoogleFonts.lato(
                  color: SymbaroumColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Formula breakdown
        if (details.formule != '0')
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (details.armureDice != '0')
                  _buildProtectionLine('Dés d\'armure', details.armureDice),
                if (details.sanctifieDice != '0')
                  _buildProtectionLine('Sanctifié', details.sanctifieDice),
                if (details.bonusFixe != 0)
                  _buildProtectionLine('Bonus fixe', '+${details.bonusFixe}'),

                // Talent modifiers
                if (details.talents.isNotEmpty)
                  ...details.talents.map((t) => _buildProtectionLine(
                    '${t.nom} (${_niveauToString(t.niveau)})',
                    t.modificateur.toString(),
                    isTalent: true,
                  )),

                // Trait modifiers
                if (details.traits.isNotEmpty)
                  ...details.traits.map((t) => _buildProtectionLine(
                    '${t.nom} (${_niveauToRoman(t.niveau)})',
                    t.modificateur.toString(),
                    isTrait: true,
                  )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatLine(String label, int value, {String? subtitle, bool isTalent = false, bool isTrait = false}) {
    Color iconColor = SymbaroumColors.textPrimary;
    IconData icon = Icons.add_circle_outline;
    
    if (isTalent) {
      iconColor = Colors.blue[300]!;
      icon = Icons.auto_awesome;
    } else if (isTrait) {
      iconColor = Colors.purple[300]!;
      icon = Icons.psychology;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lato(
                    color: SymbaroumColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(
                      color: SymbaroumColors.textPrimary.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value >= 0 ? '+$value' : '$value',
            style: GoogleFonts.lato(
              color: value >= 0 ? Colors.green[300] : Colors.red[300],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionLine(String label, String value, {bool isTalent = false, bool isTrait = false}) {
    Color iconColor = SymbaroumColors.textPrimary;
    IconData icon = Icons.add_circle_outline;
    
    if (isTalent) {
      iconColor = Colors.blue[300]!;
      icon = Icons.auto_awesome;
    } else if (isTrait) {
      iconColor = Colors.purple[300]!;
      icon = Icons.psychology;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.lato(
                color: SymbaroumColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.lato(
              color: SymbaroumColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _niveauToString(int niveau) {
    switch (niveau) {
      case 1: return 'Novice';
      case 2: return 'Adepte';
      case 3: return 'Maître';
      default: return 'Niveau $niveau';
    }
  }

  String _niveauToRoman(int niveau) {
    switch (niveau) {
      case 1: return 'I';
      case 2: return 'II';
      case 3: return 'III';
      default: return '$niveau';
    }
  }
}
