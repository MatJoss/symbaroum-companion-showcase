import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../services/notification_service.dart';
import '../../../providers/firebase_providers.dart';
import '../widgets/widgets.dart';
import '../dialogs/dialogs.dart';

/// Tab pour la gestion de l'inventaire d'un personnage.
/// 
/// Gère:
/// - Argent (thalers/shillings/ortegs)
/// - Objets équipés et non équipés
/// - Ajout/édition/suppression d'items (armes, armures, équipements, artefacts)
/// - Navigation hiérarchique pour la sélection d'items
/// - Section séparée pour Artefacts & Trésors
class InventaireTab extends ConsumerStatefulWidget {
  final String personnageId;
  final Map<String, dynamic> document;
  final List<Map<String, dynamic>>? modifiedInventaire;
  final Map<String, dynamic>? modifiedArgent;
  final Function(List<Map<String, dynamic>>?) onInventaireChanged;
  final Function(Map<String, dynamic>?) onArgentChanged;
  final VoidCallback onModified;

  const InventaireTab({
    super.key,
    required this.personnageId,
    required this.document,
    this.modifiedInventaire,
    this.modifiedArgent,
    required this.onInventaireChanged,
    required this.onArgentChanged,
    required this.onModified,
  });

  @override
  ConsumerState<InventaireTab> createState() => _InventaireTabState();
}

class _InventaireTabState extends ConsumerState<InventaireTab> {
  int _refreshKey = 0;
  String _filterType = 'tout'; // 'tout', 'arme', 'armure', 'equipement'

  @override
  Widget build(BuildContext context) {
    final inventaire = widget.modifiedInventaire ?? 
      List<Map<String, dynamic>>.from(widget.document['inventaire'] ?? []);
    
    // Séparer les artefacts du reste de l'inventaire
    final artefacts = inventaire.where((item) => item['type'] == 'artefact').toList();
    var autresItems = inventaire.where((item) => item['type'] != 'artefact').toList();
    
    // Appliquer le filtre
    if (_filterType != 'tout') {
      autresItems = autresItems.where((item) => item['type'] == _filterType).toList();
    }
    
    final argent = widget.modifiedArgent ?? 
      (widget.document['argent'] as Map<String, dynamic>? ?? 
        {'thalers': 5, 'shillings': 0, 'ortegs': 0});
    final thalers = argent['thalers'] as int? ?? 5;
    final shillings = argent['shillings'] as int? ?? 0;
    final ortegs = argent['ortegs'] as int? ?? 0;

    return ListView(
      key: ValueKey(_refreshKey),
      padding: const EdgeInsets.all(16),
      children: [
        // Argent (Bourse)
        Card(
          color: SymbaroumTheme.darkBrown.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.monetization_on, color: SymbaroumTheme.parchment, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'Bourse',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: SymbaroumTheme.parchment,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.edit, color: SymbaroumTheme.parchment),
                      onPressed: () => _editArgent(argent),
                      tooltip: 'Modifier l\'argent',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMoneyDisplay('Thalers', thalers, SymbaroumTheme.parchment),
                    _buildMoneyDisplay('Shillings', shillings, SymbaroumTheme.parchment),
                    _buildMoneyDisplay('Ortegs', ortegs, SymbaroumTheme.parchment),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '1 Thaler = 10 Shillings = 100 Ortegs',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Items (armes, armures, équipements) - tous dans Inventaire
        Row(
          children: [
            const Icon(Icons.backpack, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Inventaire',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: SymbaroumTheme.parchment),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.grey),
              onPressed: _addItem,
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Boutons de filtrage
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Tout', 'tout', Icons.all_inclusive),
              const SizedBox(width: 8),
              _buildFilterChip('Armes', 'arme', Icons.gavel),
              const SizedBox(width: 8),
              _buildFilterChip('Armures', 'armure', Icons.shield),
              const SizedBox(width: 8),
              _buildFilterChip('Équipements', 'equipement', Icons.inventory_2),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (autresItems.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Inventaire vide',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          )
        else
          ...autresItems.map((item) => _buildInventaireCard(item, item['equipee'] == true)),
        
        const SizedBox(height: 16),

        // Artéfacts & Trésors (section séparée)
        const Row(
          children: [
            Icon(Icons.diamond, color: Colors.purple),
            SizedBox(width: 8),
            Text(
              'Artéfacts & Trésors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (artefacts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Aucun artéfact',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          )
        else
          ...artefacts.map((item) => _buildInventaireCard(item, false)),
      ],
    );
  }

  Widget _buildFilterChip(String label, String type, IconData icon) {
    final isSelected = _filterType == type;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = type;
        });
      },
      selectedColor: Colors.blue.shade700,
      backgroundColor: Colors.grey.shade800,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildMoneyDisplay(String label, int amount, Color color) {
    return Column(
      children: [
        Text(
          '$amount',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  Future<void> _editArgent(Map<String, dynamic> argent) async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) {
        final thalersController = TextEditingController(text: (argent['thalers'] ?? 0).toString());
        final shillingsController = TextEditingController(text: (argent['shillings'] ?? 0).toString());
        final ortegsController = TextEditingController(text: (argent['ortegs'] ?? 0).toString());
        
        return AlertDialog(
          title: const Text('Modifier l\'argent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: thalersController,
                decoration: const InputDecoration(
                  labelText: 'Thalers',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: shillingsController,
                decoration: const InputDecoration(
                  labelText: 'Shillings',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ortegsController,
                decoration: const InputDecoration(
                  labelText: 'Ortegs',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              const Text(
                '1 Thaler = 10 Shillings = 100 Ortegs',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final result = {
                  'thalers': int.tryParse(thalersController.text) ?? 0,
                  'shillings': int.tryParse(shillingsController.text) ?? 0,
                  'ortegs': int.tryParse(ortegsController.text) ?? 0,
                };
                Navigator.of(context).pop(result);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    
    if (result != null) {
      widget.onArgentChanged(result);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Argent modifié (pensez à sauvegarder)');
      }
    }
  }

  Widget _buildInventaireCard(Map<String, dynamic> item, bool isEquipped) {
    return InventaireCard(
      item: item,
      isEquipped: isEquipped,
      onEquip: () => _equipItem(item),
      onUnequip: () => _unequipItem(item),
      onEdit: () => _editItem(item),
      onDelete: () => _deleteItem(item),
      onShowDetails: () => _showItemDetails(item),
    );
  }
  
  Future<void> _showItemDetails(Map<String, dynamic> item) async {
    final type = item['type'] as String? ?? 'objet';
    final nom = item['nom_objet'] as String? ?? 'Objet';
    final description = item['description'] as String? ?? '';
    final estSanctifie = item['est_sanctifie'] as bool? ?? false;
    final estSouille = item['est_souille'] as bool? ?? false;
    final qualitesArmes = List<int>.from(item['qualites_armes'] ?? []);
    final qualitesArmures = List<int>.from(item['qualites_armures'] ?? []);
    
    // Récupérer les données complètes de l'objet depuis Firestore
    final firestore = ref.read(firestoreServiceProvider);
    Map<String, dynamic>? itemData;
    
    if (type == 'arme' && item['arme_id'] != null) {
      itemData = await firestore.getDocumentWithFallback(collection: 'armes', id: item['arme_id']);
    } else if (type == 'armure' && item['armure_id'] != null) {
      itemData = await firestore.getDocumentWithFallback(collection: 'armures', id: item['armure_id']);
    } else if (type == 'equipement' && item['equipement_id'] != null) {
      itemData = await firestore.getDocumentWithFallback(collection: 'equipements', id: item['equipement_id']);
    } else if (type == 'artefact' && item['artefact_id'] != null) {
      itemData = await firestore.getDocumentWithFallback(collection: 'artefacts', id: item['artefact_id']);
    }
    
    // Récupérer les noms des qualités
    List<String> qualitesNoms = [];
    
    if (type == 'arme' && qualitesArmes.isNotEmpty) {
      qualitesNoms = await _fetchQualitesNames('qualites_armes', qualitesArmes);
    } else if (type == 'armure' && qualitesArmures.isNotEmpty) {
      qualitesNoms = await _fetchQualitesNames('qualites_armures', qualitesArmures);
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nom),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (itemData != null) ...[
                if (type == 'arme') ...[
                  _buildDetailRow('Dégâts', itemData['degats']?.toString() ?? 'N/A'),
                  _buildDetailRow('Portée', itemData['portee']?.toString() ?? 'N/A'),
                  _buildDetailRow('Prix', '${itemData['prix'] ?? 0} ortegs'),
                ],
                if (type == 'armure') ...[
                  _buildDetailRow('Protection', itemData['protection']?.toString() ?? 'N/A'),
                  _buildDetailRow('Malus défense', itemData['malus_defense']?.toString() ?? '0'),
                  _buildDetailRow('Prix', '${itemData['prix'] ?? 0} ortegs'),
                ],
                if (type == 'equipement') ...[
                  if (itemData['prix'] != null)
                    _buildDetailRow('Prix', '${itemData['prix']} ${itemData['unite_mesure'] ?? 'ortegs'}'),
                  if (itemData['effets'] != null && itemData['effets'].toString().isNotEmpty)
                    _buildDetailRow('Effets', itemData['effets'].toString()),
                ],
                if (type == 'artefact') ...[
                  // Badges: niveau, catégorie, tradition
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (itemData['niveau'] != null)
                        Chip(
                          label: Text(itemData['niveau'].toString(), style: const TextStyle(fontSize: 11, color: Colors.white)),
                          backgroundColor: Colors.orange.shade700,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                      if (itemData['categorie'] != null)
                        Chip(
                          label: Text(
                            (itemData['categorie'] as String).isNotEmpty 
                              ? '${(itemData['categorie'] as String)[0].toUpperCase()}${(itemData['categorie'] as String).substring(1)}'
                              : '',
                            style: const TextStyle(fontSize: 11, color: Colors.white),
                          ),
                          backgroundColor: Colors.purple.shade700,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                      if (itemData['tradition'] != null && (itemData['tradition'] as String).isNotEmpty)
                        Chip(
                          label: Text(itemData['tradition'].toString(), style: const TextStyle(fontSize: 11, color: Colors.white)),
                          backgroundColor: Colors.blue.shade700,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                      if (itemData['usage_unique'] == 1 || itemData['usage_unique'] == true)
                        Chip(
                          label: const Text('Usage unique', style: TextStyle(fontSize: 11, color: Colors.white)),
                          backgroundColor: Colors.amber.shade700,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description générale
                  if (itemData['description_generale'] != null && (itemData['description_generale'] as String).isNotEmpty) ...[
                    const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(itemData['description_generale'].toString(), style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 10),
                  ],
                  // Histoire
                  if (itemData['histoire'] != null && (itemData['histoire'] as String).isNotEmpty) ...[
                    const Text('Histoire', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(itemData['histoire'].toString(), style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 10),
                  ],
                  // Pouvoirs (JSON-encoded)
                  if (itemData['pouvoirs'] != null && (itemData['pouvoirs'] as String).isNotEmpty) ...[
                    const Text('Pouvoirs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ..._buildArtefactPouvoirs(itemData['pouvoirs'] as String),
                    const SizedBox(height: 10),
                  ],
                  // Corruption de liaison
                  if (itemData['corruption_liaison'] != null && (itemData['corruption_liaison'] as String).isNotEmpty)
                    _buildDetailRow('Corruption de liaison', itemData['corruption_liaison'].toString()),
                  // Prix
                  if (itemData['prix'] != null)
                    _buildDetailRow('Prix', '${itemData['prix']} Thalers'),
                  // Source
                  if (itemData['source'] != null && (itemData['source'] as String).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        itemData['source'].toString(),
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
                const SizedBox(height: 8),
              ],
              if (qualitesNoms.isNotEmpty) ...[
                const Text('Qualités:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: qualitesNoms.map((q) => Chip(
                    label: Text(q, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    backgroundColor: type == 'arme' ? Colors.red.shade700 : Colors.blue.shade700,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  )).toList(),
                ),
                const SizedBox(height: 8),
              ],
              if (estSanctifie || estSouille) ...[
                const Text('État:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (estSanctifie)
                  Row(
                    children: const [
                      Icon(Icons.stars, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text('Sanctifié', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    ],
                  ),
                if (estSouille)
                  Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.deepPurple, size: 16),
                      SizedBox(width: 4),
                      Text('Souillé', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                    ],
                  ),
                const SizedBox(height: 8),
              ],
              if (description.isNotEmpty) ...[
                const Text('Description personnalisée:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<Widget> _buildArtefactPouvoirs(String pouvoirsJson) {
    try {
      final Map<String, dynamic> pouvoirs = json.decode(pouvoirsJson) as Map<String, dynamic>;
      final widgets = <Widget>[];
      for (final entry in pouvoirs.entries) {
        final data = entry.value as Map<String, dynamic>;
        final nom = data['nom'] as String? ?? entry.key;
        final effet = data['effet'] as String? ?? '';
        final action = data['action'] as String? ?? '';
        final corruption = data['corruption'] as String? ?? '';

        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SymbaroumColors.corruption.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SymbaroumColors.corruption.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple.shade200)),
                if (action.isNotEmpty || corruption.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (action.isNotEmpty)
                        Text('Action: $action', style: TextStyle(fontSize: 11, color: SymbaroumTheme.parchment.withValues(alpha: 0.6))),
                      if (corruption.isNotEmpty)
                        Text('Corruption: $corruption', style: TextStyle(fontSize: 11, color: SymbaroumTheme.parchment.withValues(alpha: 0.6))),
                    ],
                  ),
                ],
                if (effet.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(effet, style: TextStyle(fontSize: 12, color: SymbaroumTheme.parchment.withValues(alpha: 0.85), height: 1.4)),
                ],
              ],
            ),
          ),
        );
      }
      return widgets;
    } catch (e) {
      return [Text('Pouvoirs: $pouvoirsJson', style: const TextStyle(fontSize: 12))];
    }
  }

  Future<List<String>> _fetchQualitesNames(String collection, List<int> ids) async {
    final firestore = ref.read(firestoreServiceProvider);
    final names = <String>[];
    
    for (final id in ids) {
      final doc = await firestore.getDocumentWithFallback(collection: collection, id: id);
      if (doc != null) {
        names.add(doc['nom'] as String? ?? 'Qualité #$id');
      }
    }
    
    return names;
  }

  // ============================================================================
  // CRUD METHODS - Inventaire
  // ============================================================================

  Future<void> _addItem() async {
    final firestore = ref.read(firestoreServiceProvider);
    
    // Navigation en boucles imbriquées au lieu de récursion
    bool continueAdding = true;
    
    while (continueAdding) {
      // Étape 1: Sélectionner le type d'item
      final type = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Type d\'objet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.search, color: Colors.teal),
                title: const Text('Recherche globale'),
                onTap: () => Navigator.of(context).pop('recherche'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.gavel, color: Colors.red),
                title: const Text('Arme'),
                onTap: () => Navigator.of(context).pop('arme'),
              ),
              ListTile(
                leading: const Icon(Icons.shield, color: Colors.blue),
                title: const Text('Armure'),
                onTap: () => Navigator.of(context).pop('armure'),
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2, color: Colors.grey),
                title: const Text('Équipement'),
                onTap: () => Navigator.of(context).pop('equipement'),
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: Colors.purple),
                title: const Text('Artefact'),
                onTap: () => Navigator.of(context).pop('artefact'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );
      
      if (type == null || !mounted) return; // Annulation
      
      // Étape 2: Sélectionner catégorie et charger items
      List<Map<String, dynamic>> allItems = [];
      String? selectedCategory;
      Map<String, dynamic>? selectedItem;
      
      // Gestion de la recherche globale
      if (type == 'recherche') {
        // Charger tous les items de toutes les collections
        final armes = await firestore.getArmes();
        final armures = await firestore.getArmures();
        final equipements = await firestore.listCollection(collection: 'equipements');
        final artefacts = await firestore.listCollection(collection: 'artefacts');
        
        // Fusionner tous les items avec un marqueur de type
        allItems = [
          ...armes.map((a) => {...a, '_type': 'arme'}),
          ...armures.map((a) => {...a, '_type': 'armure'}),
          ...equipements.map((e) => {...e, '_type': 'equipement'}),
          ...artefacts.map((a) => {...a, '_type': 'artefact'}),
        ];
        
        // Aller directement à la sélection d'item
        if (!mounted) return;
        selectedItem = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => SelectItemDialog(
            title: 'Rechercher un objet',
            items: allItems,
            type: 'recherche',
            showBackButton: true,
          ),
        );
        
        if (selectedItem != null && selectedItem['__BACK__'] == true) {
          continue; // Retour au choix de type
        }
        if (selectedItem == null || !mounted) return; // Annulation
        
        // Récupérer le type réel de l'item sélectionné et créer une variable locale non-nullable
        final item = selectedItem;
        final realType = item['_type'] as String?;
        if (realType != null) {
          item.remove('_type'); // Retirer le marqueur temporaire
          // Continuer avec la configuration en utilisant le type réel
          // On va directement à l'étape 4 (configuration)
          if (!mounted) return;
          final config = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => ConfigureItemDialog(
              item: item,
              type: realType,
              showBackButton: true,
            ),
          );
          
          if (config != null && config['__BACK__'] == true) {
            selectedItem = null;
            continue; // Retour au début
          }
          if (config == null || !mounted) return; // Annulation
          
          // Créer l'item avec la config (structure identique à l'ajout normal)
          final newId = DateTime.now().millisecondsSinceEpoch;
          final newItem = {
            'id': newId,
            'type': realType,
            'nom_objet': item['nom'] as String,
            'description': config['description'] as String? ?? '',
            'quantite': config['quantite'] as int,
            'poids': item['poids'] ?? 0,
            'equipee': false,
            'est_sanctifie': config['est_sanctifie'] as bool? ?? false,
            'est_souille': config['est_souille'] as bool? ?? false,
            'arme_id': realType == 'arme' ? item['id'] : null,
            'armure_id': realType == 'armure' ? item['id'] : null,
            'equipement_id': realType == 'equipement' ? item['id'] : null,
            'artefact_id': realType == 'artefact' ? item['id'] : null,
            'qualites_armes': realType == 'arme' ? (config['qualites_armes'] as List<int>? ?? []) : [],
            'qualites_armures': realType == 'armure' ? (config['qualites_armures'] as List<int>? ?? []) : [],
            'personnage_id': int.tryParse(widget.personnageId) ?? 0,
          };
          
          final currentInventaire = widget.modifiedInventaire ?? 
            List<Map<String, dynamic>>.from(widget.document['inventaire'] ?? []);
          currentInventaire.add(newItem);
          
          widget.onInventaireChanged(currentInventaire);
          widget.onModified();
          
          setState(() {
            _refreshKey++;
          });
          
          if (mounted) {
            NotificationService.info('Objet ajouté (pensez à sauvegarder)');
          }
          
          // Sortir de la boucle après ajout
          continueAdding = false;
          
          continue; // Recommencer la boucle ou sortir
        }
      }
      
      if (type == 'arme') {
        // Navigation imbriquée pour les armes: portée → catégorie → item
        String? portee;
        
        // Boucle portée
        while (true) {
          if (!mounted) return;
          portee = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Type d\'arme'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Corps à corps'),
                    onTap: () => Navigator.of(context).pop('Corps à corps'),
                  ),
                  ListTile(
                    title: const Text('Distance'),
                    onTap: () => Navigator.of(context).pop('Distance'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          );
          
          if (portee == null || !mounted) return; // Annulation complète
          
          allItems = await firestore.getArmes();
          allItems = allItems.where((a) => a['portee'] == portee).toList();
          
          // Vérifier si on a plusieurs catégories
          final categories = allItems.map((a) => a['categorie'] as String? ?? '').where((c) => c.isNotEmpty).toSet().toList()..sort();
          
          if (categories.length > 1) {
            // Boucle catégorie
            while (true) {
              if (!mounted) return;
              selectedCategory = await showDialog<String>(
                context: context,
                builder: (context) => SelectCategoryDialog(
                  title: 'Catégorie d\'arme',
                  categories: categories,
                  showBackButton: true,
                ),
              );
              
              if (selectedCategory == '__BACK__') break; // Retour à la portée
              if (selectedCategory == null || !mounted) return; // Annulation
              
              final filteredItems = allItems.where((a) => a['categorie'] == selectedCategory).toList();
              
              // Boucle sélection item
              while (true) {
                if (!mounted) return;
                selectedItem = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => SelectItemDialog(
                    title: 'Choisir une arme',
                    items: filteredItems,
                    type: type,
                    showBackButton: true,
                  ),
                );
                
                if (selectedItem != null && selectedItem['__BACK__'] == true) {
                  selectedItem = null; // Réinitialiser pour indiquer qu'on veut revenir en arrière
                  break; // Retour à la catégorie
                }
                if (selectedItem == null || !mounted) return; // Annulation
                
                // Item sélectionné validement
                allItems = filteredItems;
                break;
              }
              
              // Si on a un item valide, sortir de la boucle catégorie
              if (selectedItem != null) {
                break; // Item valide, sortir de la boucle catégorie
              }
              // Sinon (retour arrière avec selectedItem == null), on reste dans la boucle catégorie
            }
            
            if (selectedCategory == '__BACK__') {
              continue; // Retour à la boucle portée
            }
          } else {
            // Pas de catégorie multiple, aller directement à la sélection
            if (categories.isNotEmpty) {
              selectedCategory = categories.first;
              allItems = allItems.where((a) => a['categorie'] == selectedCategory).toList();
            }
          }
          
          // Si on arrive ici et qu'on n'a pas de selectedItem, c'est qu'il n'y avait pas de catégories multiples
          // On doit faire la sélection maintenant
          if (selectedItem == null && categories.length <= 1) {
            break; // Sortir pour faire la sélection normale à l'étape 3
          }
          
          if (selectedItem != null) {
            break; // On a un item, sortir de la boucle portée
          }
        }
      } else if (type == 'armure') {
        if (!mounted) return;
        selectedCategory = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Type d\'armure'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Légère'),
                  onTap: () => Navigator.of(context).pop('Légère'),
                ),
                ListTile(
                  title: const Text('Moyenne'),
                  onTap: () => Navigator.of(context).pop('Moyenne'),
                ),
                ListTile(
                  title: const Text('Lourde'),
                  onTap: () => Navigator.of(context).pop('Lourde'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('__BACK__'),
                child: const Text('Annuler'),
              ),
            ],
          ),
        );
        
        if (selectedCategory == '__BACK__') continue; // Retour au type
        if (selectedCategory == null || !mounted) return; // Annulation
        
        allItems = await firestore.getArmures();
        allItems = allItems.where((a) => a['categorie'] == selectedCategory).toList();
      } else if (type == 'artefact') {
        allItems = await firestore.listCollection(collection: 'artefacts');
      } else {
        // Équipements
        allItems = await firestore.listCollection(collection: 'equipements');
        final categories = allItems.map((e) => e['categorie'] as String? ?? 'autre').toSet().toList()..sort();
        
        if (!mounted) return;
        selectedCategory = await showDialog<String>(
          context: context,
          builder: (context) => SelectCategoryDialog(
            title: 'Catégorie d\'équipement',
            categories: categories,
            showBackButton: true,
          ),
        );
        
        if (selectedCategory == '__BACK__') continue; // Retour au type
        if (selectedCategory == null || !mounted) return; // Annulation
        
        allItems = allItems.where((e) => e['categorie'] == selectedCategory).toList();
      }
      
      if (!mounted) return;
      
      // Étape 3 et 4: Boucle sélection item + configuration
      while (true) {
        // Étape 3: Sélectionner l'item (sauf si déjà sélectionné pour les armes)
        if (selectedItem == null) {
          if (!mounted) return;
          selectedItem = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => SelectItemDialog(
              title: 'Choisir ${type == 'artefact' ? 'un artefact' : type == 'equipement' ? 'un équipement' : type == 'arme' ? 'une arme' : 'une armure'}',
              items: allItems,
              type: type,
              showBackButton: true,
            ),
          );
          
          if (selectedItem != null && selectedItem['__BACK__'] == true) {
            break; // Retour au choix de type/catégorie (sortir de cette boucle)
          }
          if (selectedItem == null || !mounted) return; // Annulation
        }
        
        // Étape 4: Configurer l'item
        if (!mounted) return;
        final itemConfig = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => ConfigureItemDialog(
            item: selectedItem!,
            type: type,
            showBackButton: true,
          ),
        );
        
        if (itemConfig != null && itemConfig['__BACK__'] == true) {
          selectedItem = null; // Réinitialiser pour revenir à la sélection d'item
          continue; // Retour à la sélection d'item
        }
        if (itemConfig == null || !mounted) return; // Annulation complète
        
        // Configuration validée, ajouter l'item
        final currentInventaire = widget.modifiedInventaire ?? 
          List<Map<String, dynamic>>.from(widget.document['inventaire'] ?? []);
        
        final newId = DateTime.now().millisecondsSinceEpoch;
        final newItem = {
          'id': newId,
          'type': type,
          'nom_objet': selectedItem['nom'] as String,
          'description': itemConfig['description'] as String? ?? '',
          'quantite': itemConfig['quantite'] as int,
          'poids': selectedItem['poids'] ?? 0,
          'equipee': false,
          'est_sanctifie': itemConfig['est_sanctifie'] as bool? ?? false,
          'est_souille': itemConfig['est_souille'] as bool? ?? false,
          'arme_id': type == 'arme' ? selectedItem['id'] : null,
          'armure_id': type == 'armure' ? selectedItem['id'] : null,
          'equipement_id': type == 'equipement' ? selectedItem['id'] : null,
          'artefact_id': type == 'artefact' ? selectedItem['id'] : null,
          'qualites_armes': type == 'arme' ? (itemConfig['qualites_armes'] as List<int>? ?? []) : [],
          'qualites_armures': type == 'armure' ? (itemConfig['qualites_armures'] as List<int>? ?? []) : [],
          'personnage_id': int.tryParse(widget.personnageId) ?? 0,
        };
        
        currentInventaire.add(newItem);
        widget.onInventaireChanged(currentInventaire);
        widget.onModified();
        
        setState(() {
          _refreshKey++;
        });
        
        if (mounted) {
          NotificationService.info('Objet ajouté (pensez à sauvegarder)');
        }
        
        return; // Succès, sortie complète
      }
      
      // Si on arrive ici c'est qu'on a fait retour depuis la sélection d'item, retourner au type
      continue;
    }
  }
  
  Future<void> _editItem(Map<String, dynamic> item) async {
    final type = item['type'] as String?;
    if (type == null) return;
    
    final itemConfig = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ConfigureItemDialog(
        item: item,
        type: type,
        isEdit: true,
      ),
    );
    
    if (itemConfig == null || !mounted) return;
    
    final currentInventaire = widget.modifiedInventaire ?? 
      List<Map<String, dynamic>>.from(widget.document['inventaire'] ?? []);
    
    final index = currentInventaire.indexWhere((i) => i['id'] == item['id']);
    if (index != -1) {
      currentInventaire[index] = {
        ...currentInventaire[index],
        'description': itemConfig['description'] as String? ?? '',
        'quantite': itemConfig['quantite'] as int,
        'est_sanctifie': itemConfig['est_sanctifie'] as bool? ?? false,
        'est_souille': itemConfig['est_souille'] as bool? ?? false,
        'qualites_armes': type == 'arme' ? (itemConfig['qualites_armes'] as List<int>? ?? []) : currentInventaire[index]['qualites_armes'],
        'qualites_armures': type == 'armure' ? (itemConfig['qualites_armures'] as List<int>? ?? []) : currentInventaire[index]['qualites_armures'],
      };
      
      widget.onInventaireChanged(currentInventaire);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Objet modifié (pensez à sauvegarder)');
      }
    }
  }
  
  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${item['nom_objet']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final currentInventaire = widget.modifiedInventaire ?? 
        List<Map<String, dynamic>>.from(widget.document['inventaire'] ?? []);
      currentInventaire.removeWhere((i) => i['id'] == item['id']);
      
      widget.onInventaireChanged(currentInventaire);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Objet supprimé (pensez à sauvegarder)');
      }
    }
  }
  
  Future<void> _equipItem(Map<String, dynamic> item) async {
    final currentInventaire = widget.modifiedInventaire ?? 
      List<Map<String, dynamic>>.from(widget.document['inventaire'] ?? []);
    
    final index = currentInventaire.indexWhere((i) => i['id'] == item['id']);
    if (index != -1) {
      currentInventaire[index]['equipee'] = true;
      
      widget.onInventaireChanged(currentInventaire);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Objet équipé (pensez à sauvegarder)');
      }
    }
  }
  
  Future<void> _unequipItem(Map<String, dynamic> item) async {
    final currentInventaire = widget.modifiedInventaire ?? 
      List<Map<String, dynamic>>.from(widget.document['inventaire'] ?? []);
    
    final index = currentInventaire.indexWhere((i) => i['id'] == item['id']);
    if (index != -1) {
      currentInventaire[index]['equipee'] = false;
      
      widget.onInventaireChanged(currentInventaire);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Objet déséquipé (pensez à sauvegarder)');
      }
    }
  }
}
