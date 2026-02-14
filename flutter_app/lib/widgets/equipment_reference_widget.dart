/// Widget "Catalogue d'Équipement" - Livre de référence pour l'équipement
/// Permet de rechercher et consulter les armes, armures, équipements,
/// artefacts et qualités directement depuis l'écran de gestion.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../providers/firebase_providers.dart';

/// Catégories du catalogue d'équipement
enum EquipmentCategory {
  armes('Armes', Icons.gavel, Colors.red),
  armures('Armures', Icons.shield, Colors.blue),
  equipements('Équipements', Icons.inventory_2, Colors.brown),
  artefacts('Artefacts', Icons.diamond, Colors.purple),
  qualitesArmes('Qualités d\'armes', Icons.auto_awesome, Colors.deepOrange),
  qualitesArmures('Qualités d\'armures', Icons.security, Colors.indigo);

  final String label;
  final IconData icon;
  final Color color;
  const EquipmentCategory(this.label, this.icon, this.color);
}

/// Widget principal du catalogue d'équipement
class EquipmentReferenceWidget extends ConsumerStatefulWidget {
  const EquipmentReferenceWidget({super.key});

  @override
  ConsumerState<EquipmentReferenceWidget> createState() => _EquipmentReferenceWidgetState();
}

class _EquipmentReferenceWidgetState extends ConsumerState<EquipmentReferenceWidget> {
  bool _isExpanded = false;
  EquipmentCategory? _selectedCategory;
  String? _selectedSubCategory;
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: SymbaroumTheme.darkBrown.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.brown.withOpacity(0.4),
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
                    Colors.brown.withOpacity(0.2),
                    Colors.brown.withOpacity(0.05),
                  ],
                ),
                borderRadius: _isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.backpack,
                    color: SymbaroumTheme.gold,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CATALOGUE D\'ÉQUIPEMENT',
                          style: GoogleFonts.cinzel(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: SymbaroumTheme.gold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Armes · Armures · Objets · Artefacts · Qualités',
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
              hintText: 'Rechercher un équipement...',
              hintStyle: GoogleFonts.lora(
                color: SymbaroumTheme.parchment.withOpacity(0.4),
              ),
              prefixIcon: Icon(Icons.search, color: SymbaroumTheme.gold),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: SymbaroumTheme.parchment.withOpacity(0.5)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _selectedSubCategory = null;
                        });
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
              ...EquipmentCategory.values.map((cat) =>
                  _buildCategoryChip(cat, cat.label, cat.icon, cat.color)),
            ],
          ),
        ),

        // Sous-catégories pour équipements (si catégorie sélectionnée)
        if (_selectedCategory == EquipmentCategory.equipements)
          _buildSubCategoryChips(),

        // Résultats
        if (_searchQuery.isNotEmpty || _selectedCategory != null)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.50,
            child: _buildResults(),
          ),
      ],
    );
  }

  Widget _buildSubCategoryChips() {
    final data = ref.watch(equipementsProvider);
    return data.when(
      data: (items) {
        final categories = items
            .map((e) => e['categorie'] as String? ?? 'autre')
            .toSet()
            .toList()
          ..sort();
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _buildSubCategoryChipWidget(null, 'Tout'),
              ...categories.map((cat) => _buildSubCategoryChipWidget(cat, _formatCategoryLabel(cat))),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSubCategoryChipWidget(String? subCategory, String label) {
    final isSelected = _selectedSubCategory == subCategory;
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: GoogleFonts.lora(
          fontSize: 10,
          color: isSelected ? Colors.white : SymbaroumTheme.parchment.withOpacity(0.7),
        ),
      ),
      selectedColor: Colors.brown.withOpacity(0.6),
      backgroundColor: Colors.black.withOpacity(0.2),
      side: BorderSide(color: isSelected ? Colors.brown : Colors.transparent),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (_) {
        setState(() {
          _selectedSubCategory = isSelected ? null : subCategory;
        });
      },
    );
  }

  String _formatCategoryLabel(String category) {
    switch (category) {
      case 'equipement': return 'Équipement';
      case 'elixir': return 'Élixirs';
      case 'piege': return 'Pièges';
      case 'recipient': return 'Récipients';
      case 'animal': return 'Animaux';
      case 'batiment': return 'Bâtiments';
      case 'boisson': return 'Boissons';
      case 'depense': return 'Dépenses';
      case 'instrument': return 'Instruments';
      case 'marchandise': return 'Marchandises';
      case 'nourriture': return 'Nourriture';
      case 'outil': return 'Outils';
      case 'service': return 'Services';
      case 'tabac': return 'Tabac';
      case 'transport': return 'Transports';
      case 'vetement': return 'Vêtements';
      default: return category[0].toUpperCase() + category.substring(1);
    }
  }

  Widget _buildCategoryChip(EquipmentCategory? category, String label, IconData icon, Color color) {
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
          if (isSelected) {
            _selectedCategory = null;
          } else {
            _selectedCategory = category;
          }
          _selectedSubCategory = null;
        });
      },
    );
  }

  Widget _buildResults() {
    final categories = _selectedCategory != null
        ? [_selectedCategory!]
        : EquipmentCategory.values.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      children: categories.map((cat) => _buildCategoryResults(cat)).toList(),
    );
  }

  Widget _buildCategoryResults(EquipmentCategory category) {
    AsyncValue<List<Map<String, dynamic>>> data;
    switch (category) {
      case EquipmentCategory.armes:
        data = ref.watch(armesProvider);
        break;
      case EquipmentCategory.armures:
        data = ref.watch(armuresProvider);
        break;
      case EquipmentCategory.equipements:
        data = ref.watch(equipementsProvider);
        break;
      case EquipmentCategory.artefacts:
        data = ref.watch(artefactsProvider);
        break;
      case EquipmentCategory.qualitesArmes:
        data = ref.watch(qualitesArmesProvider);
        break;
      case EquipmentCategory.qualitesArmures:
        data = ref.watch(qualitesArmuresProvider);
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

  List<Map<String, dynamic>> _filterItems(List<Map<String, dynamic>> items, EquipmentCategory category) {
    var result = List<Map<String, dynamic>>.from(items);
    
    // Filtre par sous-catégorie (pour équipements)
    if (category == EquipmentCategory.equipements && _selectedSubCategory != null) {
      result = result.where((item) => item['categorie'] == _selectedSubCategory).toList();
    }

    if (_searchQuery.isEmpty && _selectedCategory != null) {
      result.sort((a, b) => _getName(a).toLowerCase().compareTo(_getName(b).toLowerCase()));
      return result;
    }
    if (_searchQuery.isEmpty) return [];

    final normalizedQuery = _normalizeString(_searchQuery);

    result = result.where((item) {
      final nom = _normalizeString(_getName(item).toLowerCase());
      final description = _normalizeString(_getSearchableText(item, category).toLowerCase());
      return nom.contains(normalizedQuery) || description.contains(normalizedQuery);
    }).toList();

    result.sort((a, b) => _getName(a).toLowerCase().compareTo(_getName(b).toLowerCase()));
    return result;
  }

  String _getName(Map<String, dynamic> item) {
    return item['nom'] as String? ?? 'Sans nom';
  }

  String _getSearchableText(Map<String, dynamic> item, EquipmentCategory category) {
    final parts = <String>[];
    final desc = item['description'] as String?;
    if (desc != null) parts.add(desc);
    final descGen = item['description_generale'] as String?;
    if (descGen != null) parts.add(descGen);
    final categorie = item['categorie'] as String?;
    if (categorie != null) parts.add(categorie);
    final effets = item['effets'] as String?;
    if (effets != null) parts.add(effets);
    final tradition = item['tradition'] as String?;
    if (tradition != null) parts.add(tradition);
    final traditionLiee = item['tradition_liee'] as String?;
    if (traditionLiee != null) parts.add(traditionLiee);
    final qualites = item['qualites'] as String?;
    if (qualites != null) parts.add(qualites);
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

  Widget _buildItemCard(Map<String, dynamic> item, EquipmentCategory category) {
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
              // Prix si disponible
              if (_getPrice(item) != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: SymbaroumTheme.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getPrice(item)!,
                    style: GoogleFonts.lora(
                      fontSize: 10,
                      color: SymbaroumTheme.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
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

  String _getSubtitle(Map<String, dynamic> item, EquipmentCategory category) {
    switch (category) {
      case EquipmentCategory.armes:
        final portee = item['portee'] as String? ?? '';
        final categorie = item['categorie'] as String? ?? '';
        return '$categorie · $portee';
      case EquipmentCategory.armures:
        final categorie = item['categorie'] as String? ?? '';
        return categorie;
      case EquipmentCategory.equipements:
        return _formatCategoryLabel(item['categorie'] as String? ?? '');
      case EquipmentCategory.artefacts:
        final categorie = item['categorie'] as String? ?? '';
        final tradition = item['tradition'] as String?;
        final parts = [categorie[0].toUpperCase() + categorie.substring(1)];
        if (tradition != null && tradition.isNotEmpty) parts.add(tradition);
        return parts.join(' · ');
      case EquipmentCategory.qualitesArmes:
      case EquipmentCategory.qualitesArmures:
        return '';
    }
  }

  String? _getPrice(Map<String, dynamic> item) {
    final prix = item['prix'];
    if (prix == null) return null;
    
    // Équipements ont une unité de mesure
    final unite = item['unite_mesure'] as String?;
    if (unite != null) {
      final prixNum = prix is num ? prix : num.tryParse(prix.toString());
      if (prixNum == null) return null;
      final prixStr = prixNum == prixNum.toInt() ? prixNum.toInt().toString() : prixNum.toString();
      switch (unite) {
        case 'thaler': return '$prixStr Th.';
        case 'shilling': return '$prixStr Sh.';
        case 'orteg': return '$prixStr Or.';
        default: return '$prixStr $unite';
      }
    }
    
    // Armes/armures: prix en thalers par défaut
    final prixNum = prix is num ? prix : num.tryParse(prix.toString());
    if (prixNum == null) return null;
    final prixStr = prixNum == prixNum.toInt() ? prixNum.toInt().toString() : prixNum.toString();
    return '$prixStr Th.';
  }

  void _showItemDetails(BuildContext context, Map<String, dynamic> item, EquipmentCategory category) {
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
              Flexible(
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

  Widget _buildDetailsContent(Map<String, dynamic> item, EquipmentCategory category) {
    switch (category) {
      case EquipmentCategory.armes:
        return _buildArmeDetails(item);
      case EquipmentCategory.armures:
        return _buildArmureDetails(item);
      case EquipmentCategory.equipements:
        return _buildEquipementDetails(item);
      case EquipmentCategory.artefacts:
        return _buildArtefactDetails(item);
      case EquipmentCategory.qualitesArmes:
      case EquipmentCategory.qualitesArmures:
        return _buildQualiteDetails(item, category);
    }
  }

  // ── Détails Arme ──────────────────────────────────────────────────────

  Widget _buildArmeDetails(Map<String, dynamic> item) {
    final widgets = <Widget>[];

    // Statistiques
    widgets.add(_buildStatsRow([
      if (item['degats'] != null) _StatItem('Dégâts', item['degats'].toString(), Colors.red),
      if (item['portee'] != null) _StatItem('Portée', item['portee'].toString(), Colors.blue),
      if (item['categorie'] != null) _StatItem('Catégorie', item['categorie'].toString(), Colors.brown),
    ]));

    // Modificateurs
    final modDef = item['modif_defense'];
    if (modDef != null && modDef != 0) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(_buildInfoBadge(
        'Modificateur défense',
        modDef >= 0 ? '+$modDef' : '$modDef',
        modDef >= 0 ? Colors.green : Colors.red,
      ));
    }

    // Qualités
    final qualitesStr = item['qualites'] as String?;
    if (qualitesStr != null && qualitesStr.isNotEmpty) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(_buildQualitesSection(qualitesStr));
    }

    // Prix
    final price = _getPrice(item);
    if (price != null) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(_buildPriceBadge(price));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  // ── Détails Armure ────────────────────────────────────────────────────

  Widget _buildArmureDetails(Map<String, dynamic> item) {
    final widgets = <Widget>[];

    // Statistiques
    widgets.add(_buildStatsRow([
      if (item['protection'] != null) _StatItem('Protection', item['protection'].toString(), Colors.blue),
      if (item['categorie'] != null) _StatItem('Catégorie', item['categorie'].toString(), Colors.brown),
    ]));

    // Malus défense
    final malusDef = item['malus_defense'];
    if (malusDef != null && malusDef != 0) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(_buildInfoBadge(
        'Malus défense',
        '$malusDef',
        Colors.red,
      ));
    }

    // Qualités
    final qualitesStr = item['qualites'] as String?;
    if (qualitesStr != null && qualitesStr.isNotEmpty) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(_buildQualitesSection(qualitesStr));
    }

    // Prix
    final price = _getPrice(item);
    if (price != null) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(_buildPriceBadge(price));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  // ── Détails Équipement ────────────────────────────────────────────────

  Widget _buildEquipementDetails(Map<String, dynamic> item) {
    final widgets = <Widget>[];

    // Description
    final description = item['description'] as String?;
    if (description != null && description.isNotEmpty) {
      widgets.add(_buildSection('Description', description));
      widgets.add(const SizedBox(height: 12));
    }

    // Effets
    final effets = item['effets'] as String?;
    if (effets != null && effets.isNotEmpty) {
      widgets.add(_buildSection('Effets', effets));
      widgets.add(const SizedBox(height: 12));
    }

    // Durée d'effet
    final dureeEffet = item['duree_effet'] as String?;
    if (dureeEffet != null && dureeEffet.isNotEmpty) {
      widgets.add(_buildInfoBadge('Durée d\'effet', dureeEffet, Colors.teal));
      widgets.add(const SizedBox(height: 8));
    }

    // Tradition liée
    final traditionLiee = item['tradition_liee'] as String?;
    if (traditionLiee != null && traditionLiee.isNotEmpty) {
      widgets.add(_buildInfoBadge('Tradition liée', traditionLiee, Colors.purple));
      widgets.add(const SizedBox(height: 8));
    }

    // Niveau requis
    final niveauRequis = item['niveau_requis'] as String?;
    if (niveauRequis != null && niveauRequis.isNotEmpty) {
      widgets.add(_buildInfoBadge('Niveau requis', niveauRequis, Colors.orange));
      widgets.add(const SizedBox(height: 8));
    }

    // Corruption
    final corruption = item['corruption'] as String?;
    if (corruption != null && corruption.isNotEmpty) {
      widgets.add(_buildInfoBadge('Corruption', corruption, Colors.deepPurple));
      widgets.add(const SizedBox(height: 8));
    }

    // Bonus talent
    final bonusTalent = item['bonus_talent'] as String?;
    if (bonusTalent != null && bonusTalent.isNotEmpty) {
      widgets.add(_buildInfoBadge('Bonus talent', bonusTalent, Colors.blue));
      widgets.add(const SizedBox(height: 8));
    }

    // Usage unique
    final usageUnique = item['usage_unique'];
    if (usageUnique == 1 || usageUnique == true) {
      widgets.add(_buildInfoBadge('Usage', 'Usage unique', Colors.amber));
      widgets.add(const SizedBox(height: 8));
    }

    // Marché noir
    final marcheNoir = item['marche_noir'];
    if (marcheNoir == 1 || marcheNoir == true) {
      widgets.add(_buildInfoBadge('Disponibilité', 'Marché noir uniquement', Colors.grey));
      widgets.add(const SizedBox(height: 8));
    }

    // Prix
    final price = _getPrice(item);
    final prixVariable = item['prix_variable'] as String?;
    if (price != null || (prixVariable != null && prixVariable.isNotEmpty)) {
      widgets.add(const SizedBox(height: 4));
      if (prixVariable != null && prixVariable.isNotEmpty) {
        widgets.add(_buildPriceBadge(prixVariable));
      } else if (price != null) {
        widgets.add(_buildPriceBadge(price));
      }
    }

    if (widgets.isEmpty) {
      widgets.add(Text(
        'Aucune description disponible',
        style: GoogleFonts.lora(
          color: SymbaroumTheme.parchment.withOpacity(0.5),
          fontStyle: FontStyle.italic,
        ),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  // ── Détails Artefact ──────────────────────────────────────────────────

  Widget _buildArtefactDetails(Map<String, dynamic> item) {
    final widgets = <Widget>[];

    // Badges de méta-info
    final badges = <Widget>[];
    final niveau = item['niveau'] as String?;
    if (niveau != null) {
      badges.add(_buildSmallBadge(niveau, Colors.orange));
    }
    final categorie = item['categorie'] as String?;
    if (categorie != null) {
      badges.add(_buildSmallBadge(
        categorie[0].toUpperCase() + categorie.substring(1),
        Colors.purple,
      ));
    }
    final tradition = item['tradition'] as String?;
    if (tradition != null && tradition.isNotEmpty) {
      badges.add(_buildSmallBadge(tradition, Colors.blue));
    }
    final usageUnique = item['usage_unique'];
    if (usageUnique == 1 || usageUnique == true) {
      badges.add(_buildSmallBadge('Usage unique', Colors.amber));
    }
    if (badges.isNotEmpty) {
      widgets.add(Wrap(spacing: 6, runSpacing: 4, children: badges));
      widgets.add(const SizedBox(height: 12));
    }

    // Description générale
    final descGen = item['description_generale'] as String?;
    if (descGen != null && descGen.isNotEmpty) {
      widgets.add(_buildSection('Description', descGen));
      widgets.add(const SizedBox(height: 12));
    }

    // Histoire
    final histoire = item['histoire'] as String?;
    if (histoire != null && histoire.isNotEmpty) {
      widgets.add(_buildSection('Histoire', histoire));
      widgets.add(const SizedBox(height: 12));
    }

    // Pouvoirs (JSON-encoded)
    final pouvoirsStr = item['pouvoirs'] as String?;
    if (pouvoirsStr != null && pouvoirsStr.isNotEmpty) {
      try {
        final pouvoirs = json.decode(pouvoirsStr) as Map<String, dynamic>;
        if (pouvoirs.isNotEmpty) {
          widgets.add(Text(
            'Pouvoirs',
            style: GoogleFonts.cinzel(
              color: SymbaroumTheme.gold,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ));
          widgets.add(const SizedBox(height: 6));
          for (final entry in pouvoirs.entries) {
            final pouvoir = entry.value as Map<String, dynamic>;
            final nomPouvoir = pouvoir['nom'] as String? ?? entry.key;
            final effet = pouvoir['effet'] as String? ?? '';
            final action = pouvoir['action'] as String? ?? '';
            final corruption = pouvoir['corruption'] as String? ?? '';

            widgets.add(Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomPouvoir,
                    style: GoogleFonts.cinzel(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade200,
                    ),
                  ),
                  if (action.isNotEmpty || corruption.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (action.isNotEmpty)
                          Text('Action: $action',
                            style: GoogleFonts.lora(fontSize: 11, color: SymbaroumTheme.parchment.withOpacity(0.6))),
                        if (corruption.isNotEmpty)
                          Text('Corruption: $corruption',
                            style: GoogleFonts.lora(fontSize: 11, color: SymbaroumTheme.parchment.withOpacity(0.6))),
                      ],
                    ),
                  ],
                  if (effet.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      effet,
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        color: SymbaroumTheme.parchment.withOpacity(0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ));
          }
          widgets.add(const SizedBox(height: 8));
        }
      } catch (_) {
        // Fallback: afficher le texte brut
        widgets.add(_buildSection('Pouvoirs', pouvoirsStr));
        widgets.add(const SizedBox(height: 12));
      }
    }

    // Corruption de liaison
    final corruptionLiaison = item['corruption_liaison'] as String?;
    if (corruptionLiaison != null && corruptionLiaison.isNotEmpty) {
      widgets.add(_buildInfoBadge('Corruption de liaison', corruptionLiaison, Colors.deepPurple));
      widgets.add(const SizedBox(height: 8));
    }

    // Source
    final source = item['source'] as String?;
    if (source != null && source.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          source,
          style: GoogleFonts.lora(
            fontSize: 11,
            color: SymbaroumTheme.parchment.withOpacity(0.4),
            fontStyle: FontStyle.italic,
          ),
        ),
      ));
    }

    // Prix
    final price = _getPrice(item);
    if (price != null) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(_buildPriceBadge(price));
    }

    if (widgets.isEmpty) {
      widgets.add(Text(
        'Aucune description disponible',
        style: GoogleFonts.lora(
          color: SymbaroumTheme.parchment.withOpacity(0.5),
          fontStyle: FontStyle.italic,
        ),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  // ── Détails Qualité ───────────────────────────────────────────────────

  Widget _buildQualiteDetails(Map<String, dynamic> item, EquipmentCategory category) {
    final widgets = <Widget>[];

    // Description
    final description = item['description'] as String?;
    if (description != null && description.isNotEmpty) {
      widgets.add(_buildSection('Effet', description));
      widgets.add(const SizedBox(height: 12));
    }

    // Modificateurs (qualités d'armures uniquement)
    if (category == EquipmentCategory.qualitesArmures) {
      final modifiers = <Widget>[];
      
      final modDef = item['modif_defense'];
      if (modDef != null && modDef != 0) {
        modifiers.add(_buildInfoBadge('Mod. défense (général)', '$modDef', Colors.red));
      }
      final modDefLegere = item['modif_defense_legere'];
      if (modDefLegere != null && modDefLegere != 0) {
        modifiers.add(_buildInfoBadge('Mod. défense (légère)', '$modDefLegere', Colors.green));
      }
      final modDefMoyenne = item['modif_defense_moyenne'];
      if (modDefMoyenne != null && modDefMoyenne != 0) {
        modifiers.add(_buildInfoBadge('Mod. défense (moyenne)', '$modDefMoyenne', Colors.orange));
      }
      final modDefLourde = item['modif_defense_lourde'];
      if (modDefLourde != null && modDefLourde != 0) {
        modifiers.add(_buildInfoBadge('Mod. défense (lourde)', '$modDefLourde', Colors.red));
      }
      final modProt = item['modif_protection'] as String?;
      if (modProt != null && modProt != '0' && modProt.isNotEmpty) {
        modifiers.add(_buildInfoBadge('Mod. protection', modProt, Colors.blue));
      }

      if (modifiers.isNotEmpty) {
        for (final mod in modifiers) {
          widgets.add(mod);
          widgets.add(const SizedBox(height: 6));
        }
      }
    }

    if (widgets.isEmpty) {
      widgets.add(Text(
        'Aucune description disponible',
        style: GoogleFonts.lora(
          color: SymbaroumTheme.parchment.withOpacity(0.5),
          fontStyle: FontStyle.italic,
        ),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  // ── Widgets utilitaires ───────────────────────────────────────────────

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

  Widget _buildStatsRow(List<_StatItem> stats) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: stats.map((stat) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: stat.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: stat.color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              stat.value,
              style: GoogleFonts.cinzel(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: stat.color,
              ),
            ),
            Text(
              stat.label,
              style: GoogleFonts.lora(
                fontSize: 10,
                color: SymbaroumTheme.parchment.withOpacity(0.6),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildInfoBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label : ',
            style: GoogleFonts.lora(
              fontSize: 12,
              color: SymbaroumTheme.parchment.withOpacity(0.7),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.cinzel(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.lora(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriceBadge(String price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SymbaroumTheme.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: SymbaroumTheme.gold.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on, size: 16, color: SymbaroumTheme.gold),
          const SizedBox(width: 6),
          Text(
            'Prix : $price',
            style: GoogleFonts.cinzel(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: SymbaroumTheme.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualitesSection(String qualitesStr) {
    try {
      final qualites = json.decode(qualitesStr) as List<dynamic>;
      if (qualites.isEmpty) return const SizedBox.shrink();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qualités',
            style: GoogleFonts.cinzel(
              color: SymbaroumTheme.gold,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: qualites.map((q) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: Text(
                q.toString(),
                style: GoogleFonts.lora(
                  fontSize: 12,
                  color: Colors.teal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )).toList(),
          ),
        ],
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

/// Helper pour les statistiques d'armes/armures
class _StatItem {
  final String label;
  final String value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);
}
