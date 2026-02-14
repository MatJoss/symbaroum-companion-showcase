/// Widget "Livre de Référence" pour le MJ
/// Permet de rechercher et consulter les talents, pouvoirs mystiques,
/// traits, rituels et atouts/fardeaux directement depuis l'écran de gestion.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../providers/firebase_providers.dart';

/// Catégories du livre de référence
enum ReferenceCategory {
  talents('Talents', Icons.star, Colors.blue),
  pouvoirs('Pouvoirs Mystiques', Icons.auto_awesome, Colors.purple),
  traits('Traits', Icons.psychology, Colors.orange),
  rituels('Rituels', Icons.self_improvement, Colors.green),
  atoutsFardeaux('Atouts & Fardeaux', Icons.balance, Colors.teal);

  final String label;
  final IconData icon;
  final Color color;
  const ReferenceCategory(this.label, this.icon, this.color);
}

/// Widget principal du livre de référence
class ReferenceBookWidget extends ConsumerStatefulWidget {
  const ReferenceBookWidget({super.key});

  @override
  ConsumerState<ReferenceBookWidget> createState() => _ReferenceBookWidgetState();
}

class _ReferenceBookWidgetState extends ConsumerState<ReferenceBookWidget> {
  bool _isExpanded = true;
  ReferenceCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: SymbaroumTheme.darkBrown.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: SymbaroumTheme.gold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - toujours visible
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SymbaroumTheme.gold.withOpacity(0.15),
                    SymbaroumTheme.gold.withOpacity(0.05),
                  ],
                ),
                borderRadius: _isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color: SymbaroumTheme.gold,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LIVRE DE RÉFÉRENCE',
                          style: GoogleFonts.cinzel(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: SymbaroumTheme.gold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Talents · Pouvoirs · Traits · Rituels · Atouts',
                          style: GoogleFonts.lora(
                            fontSize: 11,
                            color: SymbaroumTheme.parchment.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: SymbaroumTheme.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenu expansible
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
            style: GoogleFonts.lora(color: SymbaroumTheme.parchment),
            decoration: InputDecoration(
              hintText: 'Rechercher dans tout le livre...',
              hintStyle: GoogleFonts.lora(
                color: SymbaroumTheme.parchment.withOpacity(0.4),
              ),
              prefixIcon: Icon(Icons.search, color: SymbaroumTheme.gold),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: SymbaroumTheme.parchment.withOpacity(0.5)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: SymbaroumTheme.gold.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: SymbaroumTheme.gold.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: SymbaroumTheme.gold),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),

        // Chips de catégories
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildCategoryChip(null, 'Tout', Icons.apps, SymbaroumTheme.gold),
              ...ReferenceCategory.values.map((cat) =>
                  _buildCategoryChip(cat, cat.label, cat.icon, cat.color)),
            ],
          ),
        ),

        // Résultats (hauteur fixée, scroll interne indépendant)
        if (_searchQuery.isNotEmpty || _selectedCategory != null)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.50,
            child: _buildResults(),
          ),
      ],
    );
  }

  Widget _buildCategoryChip(ReferenceCategory? category, String label, IconData icon, Color color) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cinzel(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : SymbaroumTheme.parchment.withOpacity(0.8),
            ),
          ),
        ],
      ),
      selectedColor: color.withOpacity(0.6),
      backgroundColor: Colors.black.withOpacity(0.2),
      side: BorderSide(color: isSelected ? color : Colors.transparent),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (_) {
        setState(() {
          _selectedCategory = isSelected ? null : category;
        });
      },
    );
  }

  Widget _buildResults() {
    // Collect all categories to query
    final categories = _selectedCategory != null
        ? [_selectedCategory!]
        : ReferenceCategory.values.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      children: categories.map((cat) => _buildCategoryResults(cat)).toList(),
    );
  }

  Widget _buildCategoryResults(ReferenceCategory category) {
    AsyncValue<List<Map<String, dynamic>>> data;
    switch (category) {
      case ReferenceCategory.talents:
        data = ref.watch(talentsProvider);
        break;
      case ReferenceCategory.pouvoirs:
        data = ref.watch(pouvoirsProvider);
        break;
      case ReferenceCategory.traits:
        data = ref.watch(traitsProvider);
        break;
      case ReferenceCategory.rituels:
        data = ref.watch(rituelsProvider);
        break;
      case ReferenceCategory.atoutsFardeaux:
        data = ref.watch(atoutsFardeauxProvider);
        break;
    }

    return data.when(
      data: (items) {
        final filtered = _filterItems(items, category);
        if (filtered.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de catégorie (quand en mode "Tout")
            if (_selectedCategory == null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                child: Row(
                  children: [
                    Icon(category.icon, color: category.color, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${category.label} (${filtered.length})',
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: category.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ...filtered.map((item) => _buildItemCard(item, category)),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Erreur: $e', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  List<Map<String, dynamic>> _filterItems(List<Map<String, dynamic>> items, ReferenceCategory category) {
    if (_searchQuery.isEmpty && _selectedCategory != null) {
      // Show all when a category is selected but no search
      final sorted = List<Map<String, dynamic>>.from(items);
      sorted.sort((a, b) => _getName(a).toLowerCase().compareTo(_getName(b).toLowerCase()));
      return sorted;
    }
    if (_searchQuery.isEmpty) return [];

    final normalizedQuery = _normalizeString(_searchQuery);

    final filtered = items.where((item) {
      final nom = _normalizeString(_getName(item).toLowerCase());
      final description = _normalizeString(_getDescription(item, category).toLowerCase());
      return nom.contains(normalizedQuery) || description.contains(normalizedQuery);
    }).toList();

    filtered.sort((a, b) => _getName(a).toLowerCase().compareTo(_getName(b).toLowerCase()));
    return filtered;
  }

  String _getName(Map<String, dynamic> item) {
    return item['nom'] as String? ?? 'Sans nom';
  }

  String _getDescription(Map<String, dynamic> item, ReferenceCategory category) {
    final parts = <String>[];
    // General description
    final descGen = item['description_generale'] as String?;
    if (descGen != null) parts.add(descGen);
    // Level descriptions
    for (final key in ['description_novice', 'description_adepte', 'description_maitre', 
                        'description_i', 'description_ii', 'description_iii', 'description']) {
      final desc = item[key] as String?;
      if (desc != null) parts.add(desc);
    }
    // Tradition
    final tradition = item['tradition'] as String?;
    if (tradition != null) parts.add(tradition);
    return parts.join(' ');
  }

  String _normalizeString(String str) {
    const withAccents = 'àáâãäåèéêëìíîïòóôõöùúûüýÿñçœæ';
    const withoutAccents = 'aaaaaaeeeeiiiioooouuuuyyncoeae';
    String result = str;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  Widget _buildItemCard(Map<String, dynamic> item, ReferenceCategory category) {
    final nom = _getName(item);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      color: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: category.color.withOpacity(0.15)),
      ),
      child: InkWell(
        onTap: () => _showItemDetails(context, item, category),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(category.icon, color: category.color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: SymbaroumTheme.parchment,
                      ),
                    ),
                    if (_getSubtitle(item, category).isNotEmpty)
                      Text(
                        _getSubtitle(item, category),
                        style: GoogleFonts.lora(
                          fontSize: 11,
                          color: SymbaroumTheme.parchment.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.info_outline,
                color: SymbaroumTheme.parchment.withOpacity(0.3),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitle(Map<String, dynamic> item, ReferenceCategory category) {
    switch (category) {
      case ReferenceCategory.pouvoirs:
      case ReferenceCategory.rituels:
        return item['tradition'] as String? ?? '';
      case ReferenceCategory.traits:
        final type = item['niveau_type'] as String? ?? '';
        if (type == 'monstrueux') return 'Monstrueux';
        if (type == 'sans_niveau') return 'Sans niveau';
        return 'Novice / Adepte / Maître';
      case ReferenceCategory.atoutsFardeaux:
        final type = item['type'] as String? ?? '';
        return type == 'atout' ? 'Atout' : type == 'fardeau' ? 'Fardeau' : '';
      case ReferenceCategory.talents:
        return '';
    }
  }

  void _showItemDetails(BuildContext context, Map<String, dynamic> item, ReferenceCategory category) {
    final nom = _getName(item);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: SymbaroumTheme.darkBrown,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: category.color, width: 2),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(category.icon, color: category.color, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nom,
                          style: GoogleFonts.cinzel(
                            color: SymbaroumTheme.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_getSubtitle(item, category).isNotEmpty)
                          Text(
                            _getSubtitle(item, category),
                            style: GoogleFonts.lora(
                              color: category.color.withOpacity(0.8),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (item['materiel'] != null && (item['materiel'] as String).isNotEmpty)
                          Text(
                            'Matériel: ${item['materiel']}',
                            style: GoogleFonts.lora(
                              color: SymbaroumTheme.parchment.withOpacity(0.6),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: SymbaroumTheme.parchment),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              Divider(color: category.color.withOpacity(0.5), thickness: 2),
              const SizedBox(height: 8),

              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  child: _buildDetailsContent(item, category),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsContent(Map<String, dynamic> item, ReferenceCategory category) {
    final widgets = <Widget>[];

    // Description générale
    final descGen = item['description_generale'] as String?;
    if (descGen != null && descGen.isNotEmpty) {
      widgets.add(_buildSection('Description', descGen));
      widgets.add(const SizedBox(height: 12));
    }

    // Descriptions par niveau
    switch (category) {
      case ReferenceCategory.talents:
      case ReferenceCategory.pouvoirs:
        _addLevelDescriptions(widgets, item, ['Novice', 'Adepte', 'Maître'],
            ['description_novice', 'description_adepte', 'description_maitre']);
        break;
      case ReferenceCategory.traits:
        final niveauType = item['niveau_type'] as String? ?? '';
        if (niveauType == 'monstrueux') {
          _addLevelDescriptions(widgets, item, ['Niveau I', 'Niveau II', 'Niveau III'],
              ['description_i', 'description_ii', 'description_iii']);
        } else if (niveauType == 'sans_niveau') {
          final desc = item['description'] as String? ?? item['description_novice'] as String? ?? '';
          if (desc.isNotEmpty) {
            widgets.add(_buildSection('Effet', desc));
          }
        } else {
          _addLevelDescriptions(widgets, item, ['Novice', 'Adepte', 'Maître'],
              ['description_novice', 'description_adepte', 'description_maitre']);
        }
        break;
      case ReferenceCategory.rituels:
        final desc = item['description'] as String? ?? '';
        if (desc.isNotEmpty) {
          widgets.add(_buildSection('Effet', desc));
        }
        break;
      case ReferenceCategory.atoutsFardeaux:
        final desc = item['description'] as String? ?? '';
        if (desc.isNotEmpty) {
          widgets.add(_buildSection('Description', desc));
          widgets.add(const SizedBox(height: 12));
        }
        // Effets structurés (JSON string)
        final effetsRaw = item['effets'];
        if (effetsRaw is String && effetsRaw.isNotEmpty) {
          try {
            final effets = json.decode(effetsRaw) as Map<String, dynamic>;
            if (effets.isNotEmpty) {
              widgets.add(
                Text(
                  'Effets',
                  style: GoogleFonts.cinzel(
                    color: SymbaroumTheme.gold,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
              widgets.add(const SizedBox(height: 6));
              for (final entry in effets.entries) {
                final label = entry.key[0].toUpperCase() + entry.key.substring(1);
                widgets.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$label : ',
                          style: GoogleFonts.lora(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: SymbaroumTheme.parchment.withOpacity(0.9),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${entry.value}',
                            style: GoogleFonts.lora(
                              fontSize: 13,
                              color: SymbaroumTheme.parchment.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              widgets.add(const SizedBox(height: 12));
            }
          } catch (_) {
            // Fallback: afficher le texte brut des effets
            widgets.add(_buildSection('Effets', effetsRaw));
            widgets.add(const SizedBox(height: 12));
          }
        }
        // Infos complémentaires
        final pertinentPour = item['pertinent_pour'] as String? ?? '';
        if (pertinentPour.isNotEmpty) {
          widgets.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Pertinent pour : $pertinentPour',
                style: GoogleFonts.lora(
                  fontSize: 12,
                  color: SymbaroumTheme.parchment.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
          widgets.add(const SizedBox(height: 8));
        }
        final maxNiveau = item['max_niveau'];
        // Coût XP & Niveau max
        final coutXp = item['cout_xp'];
        if (coutXp != null || (maxNiveau != null && maxNiveau > 1)) {
          widgets.add(const SizedBox(height: 8));
          widgets.add(
            Wrap(
              spacing: 8,
              children: [
                if (coutXp != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: SymbaroumTheme.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Coût XP: $coutXp',
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        color: SymbaroumTheme.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (maxNiveau != null && maxNiveau > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Niveau max: $maxNiveau',
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
        break;
    }

    if (widgets.isEmpty) {
      widgets.add(
        Text(
          'Aucune description disponible',
          style: GoogleFonts.lora(
            color: SymbaroumTheme.parchment.withOpacity(0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  void _addLevelDescriptions(List<Widget> widgets, Map<String, dynamic> item,
      List<String> labels, List<String> keys) {
    for (int i = 0; i < labels.length; i++) {
      final desc = item[keys[i]] as String?;
      if (desc != null && desc.isNotEmpty) {
        widgets.add(_buildLevelSection(labels[i], desc));
        widgets.add(const SizedBox(height: 10));
      }
    }
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cinzel(
            color: SymbaroumTheme.gold,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: GoogleFonts.lora(
            color: SymbaroumTheme.parchment.withOpacity(0.9),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelSection(String level, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: SymbaroumTheme.gold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: SymbaroumTheme.gold.withOpacity(0.3)),
          ),
          child: Text(
            level,
            style: GoogleFonts.cinzel(
              color: SymbaroumTheme.gold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: GoogleFonts.lora(
            color: SymbaroumTheme.parchment.withOpacity(0.9),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
