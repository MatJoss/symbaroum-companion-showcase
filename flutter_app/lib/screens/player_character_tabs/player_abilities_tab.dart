import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/firebase_providers.dart';

/// Onglet Capacités - Affichage des talents, pouvoirs, traits, rituels
/// (lecture seule pour le joueur, descriptions limitées aux niveaux obtenus)
class PlayerAbilitiesTab extends ConsumerStatefulWidget {
  final String personnageId;
  final Map<String, dynamic> data;

  const PlayerAbilitiesTab({
    super.key,
    required this.personnageId,
    required this.data,
  });

  @override
  ConsumerState<PlayerAbilitiesTab> createState() => _PlayerAbilitiesTabState();
}

class _PlayerAbilitiesTabState extends ConsumerState<PlayerAbilitiesTab> {
  String _filterType = 'tous';

  // Helper pour parser int/string depuis Firestore
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final talents = List<Map<String, dynamic>>.from(widget.data['talents'] ?? []);
    final pouvoirs = List<Map<String, dynamic>>.from(widget.data['pouvoirs'] ?? []);
    final traits = List<Map<String, dynamic>>.from(widget.data['traits'] ?? []);
    final rituels = List<Map<String, dynamic>>.from(widget.data['rituels'] ?? []);

    // Combiner toutes les capacités avec leur type
    final allAbilities = <Map<String, dynamic>>[];
    
    for (final talent in talents) {
      final t = Map<String, dynamic>.from(talent);
      t['_type'] = 'talent';
      allAbilities.add(t);
    }
    for (final pouvoir in pouvoirs) {
      final p = Map<String, dynamic>.from(pouvoir);
      p['_type'] = 'pouvoir';
      allAbilities.add(p);
    }
    for (final trait in traits) {
      final t = Map<String, dynamic>.from(trait);
      t['_type'] = 'trait';
      allAbilities.add(t);
    }
    for (final rituel in rituels) {
      final r = Map<String, dynamic>.from(rituel);
      r['_type'] = 'rituel';
      allAbilities.add(r);
    }

    // Filtrer
    final filtered = allAbilities.where((ability) {
      if (_filterType == 'tous') return true;
      return ability['_type'] == _filterType;
    }).toList();

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildAbilityCard(filtered[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tous', 'tous'),
            const SizedBox(width: 8),
            _buildFilterChip('Talents', 'talent'),
            const SizedBox(width: 8),
            _buildFilterChip('Pouvoirs', 'pouvoir'),
            const SizedBox(width: 8),
            _buildFilterChip('Traits', 'trait'),
            const SizedBox(width: 8),
            _buildFilterChip('Rituels', 'rituel'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _filterType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterType = type);
      },
      selectedColor: SymbaroumColors.primary,
      backgroundColor: SymbaroumColors.cardBackground,
      labelStyle: GoogleFonts.cinzel(
        color: isSelected ? Colors.black : SymbaroumColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: SymbaroumColors.textPrimary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune capacité',
            style: GoogleFonts.cinzel(
              color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilityCard(Map<String, dynamic> ability) {
    final type = ability['_type'] as String;
    final niveau = _parseInt(ability['niveau']) == 0 ? 1 : _parseInt(ability['niveau']);
    
    // Récupérer l'ID selon le type
    String? refId;
    String collection = '';
    
    switch (type) {
      case 'talent':
        refId = ability['talent_id']?.toString();
        collection = 'talents';
        break;
      case 'pouvoir':
        refId = ability['pouvoir_id']?.toString();
        collection = 'pouvoirs';
        break;
      case 'trait':
        refId = ability['trait_id']?.toString();
        collection = 'traits';
        break;
      case 'rituel':
        refId = ability['rituel_id']?.toString();
        collection = 'rituels';
        break;
    }

    if (refId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(firestoreServiceProvider).getDocumentWithFallback(
        collection: collection,
        id: refId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: SymbaroumColors.cardBackground,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: SymbaroumColors.cardBackground.withValues(alpha: 0.5),
            child: ListTile(
              leading: Icon(_getTypeIcon(type), color: Colors.grey),
              title: Text(
                '${_getTypeLabel(type)} #$refId',
                style: GoogleFonts.cinzel(color: Colors.grey),
              ),
              subtitle: const Text('Données non disponibles'),
            ),
          );
        }

        final data = snapshot.data!;
        final nom = data['nom'] as String? ?? 'Sans nom';
        final tradition = data['tradition'] as String?;
        final materiel = data['materiel'] as String?;

        // Récupérer les descriptions
        final descriptionGenerale = data['description_generale'] as String? ?? '';
        final descriptionNovice = data['description_novice'] as String? ?? '';
        final descriptionAdepte = data['description_adepte'] as String? ?? '';
        final descriptionMaitre = data['description_maitre'] as String? ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: SymbaroumColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _getTypeColor(type).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: ExpansionTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getTypeColor(type).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getTypeColor(type),
                ),
              ),
              child: Icon(
                _getTypeIcon(type),
                color: _getTypeColor(type),
              ),
            ),
            title: Text(
              nom,
              style: GoogleFonts.cinzel(
                color: SymbaroumColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTypeLabel(type),
                  style: GoogleFonts.lato(
                    color: _getTypeColor(type).withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                if (niveau > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildLevelBadge(1, niveau >= 1),
                      const SizedBox(width: 4),
                      _buildLevelBadge(2, niveau >= 2),
                      const SizedBox(width: 4),
                      _buildLevelBadge(3, niveau >= 3),
                    ],
                  ),
                ],
              ],
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tradition / Matériel
                    if (tradition != null && tradition.isNotEmpty) ...[
                      _buildInfoRow('Tradition', tradition),
                      const SizedBox(height: 8),
                    ],
                    if (materiel != null && materiel.isNotEmpty) ...[
                      _buildInfoRow('Matériel', materiel),
                      const SizedBox(height: 8),
                    ],

                    // Description générale
                    if (descriptionGenerale.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        descriptionGenerale,
                        style: GoogleFonts.lato(
                          color: SymbaroumColors.textPrimary.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],

                    // Descriptions par niveau (seulement les niveaux obtenus)
                    if (niveau >= 1 && descriptionNovice.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildLevelDescription('NOVICE', descriptionNovice, true),
                    ],

                    if (niveau >= 2 && descriptionAdepte.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildLevelDescription('ADEPTE', descriptionAdepte, true),
                    ],

                    if (niveau >= 3 && descriptionMaitre.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildLevelDescription('MAÎTRE', descriptionMaitre, true),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelBadge(int level, bool isAcquired) {
    final labels = ['', 'N', 'A', 'M'];
    final color = isAcquired ? SymbaroumColors.primary : Colors.grey[700]!;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          labels[level],
          style: GoogleFonts.cinzel(
            color: isAcquired ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelDescription(String levelLabel, String description, bool isAcquired) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SymbaroumColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SymbaroumColors.primary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            levelLabel,
            style: GoogleFonts.cinzel(
              color: SymbaroumColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.lato(
              color: SymbaroumColors.textPrimary.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.lato(
            color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.lato(
              color: SymbaroumColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'talent':
        return Colors.blue[400]!;
      case 'pouvoir':
        return Colors.purple[400]!;
      case 'trait':
        return Colors.green[400]!;
      case 'rituel':
        return Colors.orange[400]!;
      default:
        return SymbaroumColors.textPrimary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'talent':
        return Icons.star;
      case 'pouvoir':
        return Icons.auto_awesome;
      case 'trait':
        return Icons.psychology;
      case 'rituel':
        return Icons.menu_book;
      default:
        return Icons.help;
    }
  }

  String _getTypeLabel(String type) {
    const labels = {
      'talent': 'Talent',
      'pouvoir': 'Pouvoir',
      'trait': 'Trait',
      'rituel': 'Rituel',
    };
    return labels[type] ?? type;
  }
}
