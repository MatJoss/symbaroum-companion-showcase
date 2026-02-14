import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/firebase_providers.dart';
import '../../../services/notification_service.dart';
import '../../../config/theme.dart';
import '../../personnage_detail/dialogs/dialogs.dart';

/// Onglet Inventaire - Affichage de l'inventaire (éditable pour joueur)
class PlayerInventaireTab extends ConsumerStatefulWidget {
  final String personnageId;
  final Map<String, dynamic> personnage;
  final Map<String, dynamic> document;
  final bool canModify;
  final bool canEditInventory;

  const PlayerInventaireTab({
    super.key,
    required this.personnageId,
    required this.personnage,
    required this.document,
    this.canModify = true,
    this.canEditInventory = false,
  });

  @override
  ConsumerState<PlayerInventaireTab> createState() => _PlayerInventaireTabState();
}

class _PlayerInventaireTabState extends ConsumerState<PlayerInventaireTab> {
  String _filterType = 'tout'; // 'tout', 'arme', 'armure', 'equipement'

  // Helper pour parser int/string depuis Firestore
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    // Surveiller le provider pour avoir les données fraîches
    final personnageAsync = ref.watch(personnageProvider(widget.personnageId));
    
    return personnageAsync.when(
      data: (freshData) {
        // L'inventaire correct est dans document, pas à la racine
        final document = freshData?['document'] as Map<String, dynamic>? ?? {};
        final inventaire = List<Map<String, dynamic>>.from(document['inventaire'] ?? []);
        
    final argent = document['argent'] as Map<String, dynamic>? ?? 
      {'thalers': 5, 'shillings': 0, 'ortegs': 0};
    
    // Séparer les artéfacts du reste
    final artefacts = inventaire.where((item) => item['type'] == 'artefact').toList();
    
    // Filtrer selon le type sélectionné
    List<Map<String, dynamic>> autresItems;
    if (_filterType == 'tout') {
      autresItems = inventaire.where((item) => item['type'] != 'artefact').toList();
      // Trier par type puis alphabétique
      autresItems.sort((a, b) {
        final typeA = a['type'] as String? ?? 'equipement';
        final typeB = b['type'] as String? ?? 'equipement';
        
        // Ordre des types: arme -> armure -> munition -> equipement
        final typeOrder = {'arme': 1, 'armure': 2, 'munition': 3, 'equipement': 4};
        final orderA = typeOrder[typeA] ?? 5;
        final orderB = typeOrder[typeB] ?? 5;
        
        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }
        
        // Si même type, trier alphabétiquement
        final nomA = (a['nom_objet'] as String? ?? '').toLowerCase();
        final nomB = (b['nom_objet'] as String? ?? '').toLowerCase();
        return nomA.compareTo(nomB);
      });
    } else if (_filterType == 'equipement') {
      autresItems = inventaire.where((item) => 
        item['type'] != 'artefact' && 
        item['type'] != 'arme' && 
        item['type'] != 'armure' &&
        item['type'] != 'munition'
      ).toList();
      // Trier alphabétiquement
      autresItems.sort((a, b) {
        final nomA = (a['nom_objet'] as String? ?? '').toLowerCase();
        final nomB = (b['nom_objet'] as String? ?? '').toLowerCase();
        return nomA.compareTo(nomB);
      });
    } else {
      autresItems = inventaire.where((item) => item['type'] == _filterType).toList();
      // Trier alphabétiquement
      autresItems.sort((a, b) {
        final nomA = (a['nom_objet'] as String? ?? '').toLowerCase();
        final nomB = (b['nom_objet'] as String? ?? '').toLowerCase();
        return nomA.compareTo(nomB);
      });
    }
    
    final thalers = _parseInt(argent['thalers'], 5);
    final shillings = _parseInt(argent['shillings'], 0);
    final ortegs = _parseInt(argent['ortegs'], 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Argent (éditable si autorisé)
        Card(
          color: Colors.brown.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.monetization_on, color: SymbaroumTheme.parchment, size: 32),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                '$thalers',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: SymbaroumTheme.parchment,
                                ),
                              ),
                              Text(
                                'Thalers',
                                style: TextStyle(fontSize: 11, color: SymbaroumTheme.parchment),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Column(
                            children: [
                              Text(
                                '$shillings',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: SymbaroumTheme.parchment,
                                ),
                              ),
                              Text(
                                'Shillings',
                                style: TextStyle(fontSize: 11, color: SymbaroumTheme.parchment),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Column(
                            children: [
                              Text(
                                '$ortegs',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: SymbaroumTheme.parchment,
                                ),
                              ),
                              Text(
                                'Ortegs',
                                style: TextStyle(fontSize: 11, color: SymbaroumTheme.parchment),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.canModify || widget.canEditInventory)
                      IconButton(
                        icon: Icon(Icons.edit, color: SymbaroumTheme.parchment),
                        onPressed: () => _editAllMoney(context, ref, thalers, shillings, ortegs),
                        tooltip: 'Modifier l\'argent',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '1 Thaler = 10 Shillings = 100 Ortegs',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Filtres d'inventaire
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Tout', 'tout'),
              const SizedBox(width: 8),
              _buildFilterChip('Armes', 'arme'),
              const SizedBox(width: 8),
              _buildFilterChip('Armures', 'armure'),
              const SizedBox(width: 8),
              _buildFilterChip('Équipement', 'equipement'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Inventaire
        Row(
          children: [
            const Icon(Icons.backpack, color: Colors.grey),
            const SizedBox(width: 8),
            const Text(
              'Inventaire',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${autresItems.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (widget.canEditInventory)
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.teal),
                onPressed: _addItem,
                tooltip: 'Ajouter un objet',
              ),
          ],
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
          ...autresItems.map((item) => _buildInventaireCard(context, ref, item)),
        
        const SizedBox(height: 16),

        // Artefacts & Trésors
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
          ...artefacts.map((item) => _buildInventaireCard(context, ref, item)),
      ],
    );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Erreur: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _filterType == filterValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = filterValue;
        });
      },
      selectedColor: Colors.blue.withValues(alpha: 0.3),
      checkmarkColor: Colors.white,
    );
  }

  /// Ajouter un objet à l'inventaire (joueur - sauvegarde directe Firestore)
  Future<void> _addItem() async {
    final firestore = ref.read(firestoreServiceProvider);
    
    bool continueAdding = true;
    
    while (continueAdding) {
      if (!mounted) return;
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
      
      if (type == null || !mounted) return;
      
      // Étape 2: Sélectionner catégorie et charger items
      List<Map<String, dynamic>> allItems = [];
      String? selectedCategory;
      Map<String, dynamic>? selectedItem;
      
      // Gestion de la recherche globale
      if (type == 'recherche') {
        final armes = await firestore.getArmes();
        final armures = await firestore.getArmures();
        final equipements = await firestore.listCollection(collection: 'equipements');
        final artefacts = await firestore.listCollection(collection: 'artefacts');
        
        allItems = [
          ...armes.map((a) => {...a, '_type': 'arme'}),
          ...armures.map((a) => {...a, '_type': 'armure'}),
          ...equipements.map((e) => {...e, '_type': 'equipement'}),
          ...artefacts.map((a) => {...a, '_type': 'artefact'}),
        ];
        
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
          continue;
        }
        if (selectedItem == null || !mounted) return;
        
        final item = selectedItem;
        final realType = item['_type'] as String?;
        if (realType != null) {
          item.remove('_type');
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
            continue;
          }
          if (config == null || !mounted) return;
          
          await _saveNewItem(item, realType, config);
          continueAdding = false;
          continue;
        }
      }
      
      if (type == 'arme') {
        String? portee;
        
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
          
          if (portee == null || !mounted) return;
          
          allItems = await firestore.getArmes();
          allItems = allItems.where((a) => a['portee'] == portee).toList();
          
          final categories = allItems.map((a) => a['categorie'] as String? ?? '').where((c) => c.isNotEmpty).toSet().toList()..sort();
          
          if (categories.length > 1) {
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
              
              if (selectedCategory == '__BACK__') break;
              if (selectedCategory == null || !mounted) return;
              
              final filteredItems = allItems.where((a) => a['categorie'] == selectedCategory).toList();
              
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
                  selectedItem = null;
                  break;
                }
                if (selectedItem == null || !mounted) return;
                
                allItems = filteredItems;
                break;
              }
              
              if (selectedItem != null) break;
            }
            
            if (selectedCategory == '__BACK__') continue;
          } else {
            if (categories.isNotEmpty) {
              selectedCategory = categories.first;
              allItems = allItems.where((a) => a['categorie'] == selectedCategory).toList();
            }
          }
          
          if (selectedItem == null && categories.length <= 1) break;
          if (selectedItem != null) break;
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
        
        if (selectedCategory == '__BACK__') continue;
        if (selectedCategory == null || !mounted) return;
        
        allItems = await firestore.getArmures();
        allItems = allItems.where((a) => a['categorie'] == selectedCategory).toList();
      } else if (type == 'artefact') {
        allItems = await firestore.listCollection(collection: 'artefacts');
      } else {
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
        
        if (selectedCategory == '__BACK__') continue;
        if (selectedCategory == null || !mounted) return;
        
        allItems = allItems.where((e) => e['categorie'] == selectedCategory).toList();
      }
      
      if (!mounted) return;
      
      // Étape 3 et 4: Boucle sélection item + configuration
      while (true) {
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
            break;
          }
          if (selectedItem == null || !mounted) return;
        }
        
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
          selectedItem = null;
          continue;
        }
        if (itemConfig == null || !mounted) return;
        
        await _saveNewItem(selectedItem, type, itemConfig);
        return;
      }
      
      continue;
    }
  }

  /// Sauvegarde un nouvel item directement dans Firestore
  Future<void> _saveNewItem(Map<String, dynamic> item, String type, Map<String, dynamic> config) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final personnageAsync = await ref.read(personnageProvider(widget.personnageId).future);
      if (personnageAsync == null) return;
      
      final document = personnageAsync['document'] as Map<String, dynamic>? ?? {};
      final inventaire = List<Map<String, dynamic>>.from(document['inventaire'] ?? []);
      
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newItem = {
        'id': newId,
        'type': type,
        'nom_objet': item['nom'] as String,
        'description': config['description'] as String? ?? '',
        'quantite': config['quantite'] as int,
        'poids': item['poids'] ?? 0,
        'equipee': false,
        'est_sanctifie': config['est_sanctifie'] as bool? ?? false,
        'est_souille': config['est_souille'] as bool? ?? false,
        'arme_id': type == 'arme' ? item['id'] : null,
        'armure_id': type == 'armure' ? item['id'] : null,
        'equipement_id': type == 'equipement' ? item['id'] : null,
        'artefact_id': type == 'artefact' ? item['id'] : null,
        'qualites_armes': type == 'arme' ? (config['qualites_armes'] as List<int>? ?? []) : [],
        'qualites_armures': type == 'armure' ? (config['qualites_armures'] as List<int>? ?? []) : [],
        'personnage_id': int.tryParse(widget.personnageId) ?? 0,
      };
      
      inventaire.add(newItem);
      
      final updatedDocument = Map<String, dynamic>.from(document);
      updatedDocument['inventaire'] = inventaire;
      
      await firestoreService.updateDocument(
        collection: 'personnages',
        documentId: widget.personnageId,
        data: {'document': updatedDocument},
      );
      
      ref.invalidate(personnageProvider(widget.personnageId));
      
      if (mounted) {
        NotificationService.success('Objet ajouté à l\'inventaire');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error('Erreur lors de l\'ajout: $e');
      }
    }
  }

  /// Supprimer un item de l'inventaire (joueur - sauvegarde directe Firestore)
  Future<void> _deleteItem(BuildContext context, WidgetRef ref, Map<String, dynamic> item) async {
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

    if (confirm != true) return;

    try {
      final personnageAsync = await ref.read(personnageProvider(widget.personnageId).future);
      if (personnageAsync == null) return;

      final document = personnageAsync['document'] as Map<String, dynamic>? ?? {};
      final inventaire = List<Map<String, dynamic>>.from(document['inventaire'] ?? []);

      // Créer un identifiant unique basé sur plusieurs critères
      String createItemId(Map<String, dynamic> i) {
        final type = i['type'] ?? '';
        final id = i['${type}_id'] ?? '';
        final nom = i['nom_objet'] ?? '';
        final equipee = i['equipee'] ?? false;
        return '$type|$id|$nom|$equipee';
      }

      final targetId = createItemId(item);
      final itemIndex = inventaire.indexWhere((i) => createItemId(i) == targetId);

      if (itemIndex != -1) {
        inventaire.removeAt(itemIndex);

        final updatedDocument = Map<String, dynamic>.from(document);
        updatedDocument['inventaire'] = inventaire;

        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.updateDocument(
          collection: 'personnages',
          documentId: widget.personnageId,
          data: {'document': updatedDocument},
        );

        ref.invalidate(personnageProvider(widget.personnageId));

        if (context.mounted) {
          NotificationService.success('${item['nom_objet']} supprimé');
        }
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.error('Erreur lors de la suppression: $e');
      }
    }
  }

  Future<void> _editAllMoney(BuildContext context, WidgetRef ref, int currentThalers, int currentShillings, int currentOrtegs) async {
    final thalersController = TextEditingController(text: currentThalers.toString());
    final shillingsController = TextEditingController(text: currentShillings.toString());
    final ortegsController = TextEditingController(text: currentOrtegs.toString());
    
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'argent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: thalersController,
              decoration: InputDecoration(
                labelText: 'Thalers',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on, color: SymbaroumTheme.parchment),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: shillingsController,
              decoration: InputDecoration(
                labelText: 'Shillings',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on, color: SymbaroumTheme.parchment),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ortegsController,
              decoration: InputDecoration(
                labelText: 'Ortegs',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on, color: SymbaroumTheme.parchment),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const Text(
              '1 Thaler = 10 Shillings = 100 Ortegs',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final thalers = int.tryParse(thalersController.text);
              final shillings = int.tryParse(shillingsController.text);
              final ortegs = int.tryParse(ortegsController.text);
              
              if (thalers != null && thalers >= 0 &&
                  shillings != null && shillings >= 0 &&
                  ortegs != null && ortegs >= 0) {
                Navigator.pop(context, {
                  'thalers': thalers,
                  'shillings': shillings,
                  'ortegs': ortegs,
                });
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.updateDocument(
          collection: 'personnages',
          documentId: widget.personnageId,
          data: {
            'document.argent.thalers': result['thalers'],
            'document.argent.shillings': result['shillings'],
            'document.argent.ortegs': result['ortegs'],
          },
        );
        
        // Invalider le provider pour rafraîchir
        ref.invalidate(personnageProvider(widget.personnageId));
        
        if (context.mounted) {
          NotificationService.success('Argent modifié');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.error('Erreur lors de la modification: $e');
        }
      }
    }
  }

  Future<void> _editQuantite(BuildContext context, WidgetRef ref, Map<String, dynamic> item) async {
    final currentQuantite = _parseInt(item['quantite'], 1);
    final controller = TextEditingController(text: currentQuantite.toString());
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier la quantité de ${item['nom_objet']}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Quantité',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final personnageAsync = await ref.read(personnageProvider(widget.personnageId).future);
        if (personnageAsync == null) return;
        
        final document = personnageAsync['document'] as Map<String, dynamic>? ?? {};
        final inventaire = List<Map<String, dynamic>>.from(document['inventaire'] ?? []);
        
        // Créer un identifiant unique basé sur plusieurs critères
        String createItemId(Map<String, dynamic> i) {
          final type = i['type'] ?? '';
          final id = i['${type}_id'] ?? '';
          final nom = i['nom_objet'] ?? '';
          final equipee = i['equipee'] ?? false;
          return '$type|$id|$nom|$equipee';
        }
        
        final targetId = createItemId(item);
        
        // Trouver l'item par son identifiant unique
        final itemIndex = inventaire.indexWhere((i) => createItemId(i) == targetId);
        
        if (itemIndex != -1) {
          inventaire[itemIndex]['quantite'] = result;
          
          final updatedDocument = Map<String, dynamic>.from(document);
          updatedDocument['inventaire'] = inventaire;
          
          final firestoreService = ref.read(firestoreServiceProvider);
          await firestoreService.updateDocument(
            collection: 'personnages',
            documentId: widget.personnageId,
            data: {'document': updatedDocument},
          );
          
          ref.invalidate(personnageProvider(widget.personnageId));
          
          if (context.mounted) {
            NotificationService.success('Quantité modifiée');
          }
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.error('Erreur lors de la modification: $e');
        }
      }
    }
  }

  Widget _buildInventaireCard(BuildContext context, WidgetRef ref, Map<String, dynamic> item) {
    final nomObjet = item['nom_objet'] as String? ?? 'Objet inconnu';
    final equipee = item['equipee'] == true;
    final type = item['type'] as String? ?? 'equipement';
    
    // Icône selon le type
    IconData icon;
    Color iconColor;
    switch (type) {
      case 'arme':
        icon = Icons.gavel;
        iconColor = Colors.red;
        break;
      case 'armure':
        icon = Icons.shield;
        iconColor = Colors.blue;
        break;
      case 'artefact':
        icon = Icons.diamond;
        iconColor = Colors.purple;
        break;
      case 'munition':
        icon = Icons.change_history; // Icône pour flèches/munitions
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.inventory_2;
        iconColor = Colors.grey;
    }
    
    // Les armes/armures peuvent être équipées
    final canBeEquipped = type == 'arme' || type == 'armure';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.brown.shade900.withValues(alpha: 0.7),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.2),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(child: Text(nomObjet)),
            if (equipee)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  'Équipé',
                  style: TextStyle(fontSize: 11, color: Colors.green),
                ),
              ),
            // Bouton info pour afficher les détails
            IconButton(
              icon: const Icon(Icons.info_outline, size: 18),
              onPressed: () => _showItemDetails(context, ref, item),
              tooltip: 'Détails',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        trailing: (canBeEquipped && (widget.canModify || widget.canEditInventory))
            ? IconButton(
                icon: Icon(
                  equipee ? Icons.check_circle : Icons.circle_outlined,
                  size: 22,
                  color: equipee ? Colors.green : Colors.grey,
                ),
                onPressed: () => equipee ? _unequipItem(context, ref, item) : _equipItem(context, ref, item),
                tooltip: equipee ? 'Déséquiper' : 'Équiper',
              )
            : null,
      ),
    );
  }

  Future<void> _showItemDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> item) async {
    final type = item['type'] as String? ?? 'objet';
    final nom = item['nom_objet'] as String? ?? 'Objet';
    final description = item['description'] as String? ?? '';
    final quantite = _parseInt(item['quantite'], 1);
    
    // Récupérer les données complètes depuis Firestore
    final firestoreService = ref.read(firestoreServiceProvider);
    Map<String, dynamic>? itemData;
    
    if (type == 'arme' && item['arme_id'] != null) {
      itemData = await firestoreService.getDocumentWithFallback(collection: 'armes', id: item['arme_id']);
    } else if (type == 'armure' && item['armure_id'] != null) {
      itemData = await firestoreService.getDocumentWithFallback(collection: 'armures', id: item['armure_id']);
    } else if (type == 'equipement' && item['equipement_id'] != null) {
      itemData = await firestoreService.getDocumentWithFallback(collection: 'equipements', id: item['equipement_id']);
    } else if (type == 'artefact' && item['artefact_id'] != null) {
      itemData = await firestoreService.getDocumentWithFallback(collection: 'artefacts', id: item['artefact_id']);
    } else if (type == 'munition' && item['munition_id'] != null) {
      // Ajouter le support des munitions
      itemData = await firestoreService.getDocumentWithFallback(collection: 'munitions', id: item['munition_id']);
    }
    
    // Récupérer les qualités
    final qualitesArmes = List<int>.from(item['qualites_armes'] ?? []);
    final qualitesArmures = List<int>.from(item['qualites_armures'] ?? []);
    List<String> qualitesNoms = [];
    
    if (type == 'arme' && qualitesArmes.isNotEmpty) {
      qualitesNoms = await _fetchQualitesNames(ref, 'qualites_armes', qualitesArmes);
    } else if (type == 'armure' && qualitesArmures.isNotEmpty) {
      qualitesNoms = await _fetchQualitesNames(ref, 'qualites_armures', qualitesArmures);
    }
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nom),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Description
              if (description.isNotEmpty) ...[
                const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description),
                const SizedBox(height: 12),
              ],
              // Qualités
              if (qualitesNoms.isNotEmpty) ...[
                const Text('Qualités', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 12),
              ],
              
              // Divider avant les détails techniques
              if (itemData != null || quantite > 1) ...[
                const Divider(),
                const SizedBox(height: 8),
              ],
              
              // Quantité (pour tous les types)
              if (quantite > 1 || type == 'munition') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quantité', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$quantite', style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Détails techniques
              if (itemData != null) ...[
                if (type == 'arme') ...[
                  if (itemData['degats'] != null)
                    _buildDetailRow('Dégâts', itemData['degats'].toString()),
                  if (itemData['portee'] != null)
                    _buildDetailRow('Portée', itemData['portee'].toString()),
                  if (itemData['modif_defense'] != null && _parseInt(itemData['modif_defense'], 0) != 0)
                    _buildDetailRow('Modificateur défense', 
                      _parseInt(itemData['modif_defense'], 0) >= 0 
                        ? '+${itemData['modif_defense']}' 
                        : itemData['modif_defense'].toString()),
                  if (itemData['modif_protection'] != null && _parseInt(itemData['modif_protection'], 0) != 0)
                    _buildDetailRow('Modificateur protection', 
                      _parseInt(itemData['modif_protection'], 0) >= 0 
                        ? '+${itemData['modif_protection']}' 
                        : itemData['modif_protection'].toString()),
                  if (itemData['nom'] != null)
                    _buildDetailRow('Nom complet', itemData['nom'].toString()),
                  if (itemData['categorie'] != null)
                    _buildDetailRow('Catégorie', itemData['categorie'].toString()),
                  if (itemData['prix'] != null)
                    _buildDetailRow('Prix', '${itemData['prix']} Shillings'),
                ],
                if (type == 'armure') ...[
                  if (itemData['protection'] != null)
                    _buildDetailRow('Protection', itemData['protection'].toString()),
                  if (itemData['malus_defense'] != null)
                    _buildDetailRow('Malus défense', itemData['malus_defense'].toString()),
                ],
                if (type == 'munition') ...[
                  if (itemData['nom'] != null)
                    _buildDetailRow('Nom', itemData['nom'].toString()),
                  if (itemData['type_arme'] != null)
                    _buildDetailRow('Type d\'arme', itemData['type_arme'].toString()),
                  if (itemData['categorie'] != null)
                    _buildDetailRow('Catégorie', itemData['categorie'].toString()),
                  if (itemData['prix'] != null)
                    _buildDetailRow('Prix unitaire', '${itemData['prix']} Shillings'),
                ],
                if (type == 'equipement') ...[
                  if (itemData['nom'] != null)
                    _buildDetailRow('Nom', itemData['nom'].toString()),
                  if (itemData['categorie'] != null)
                    _buildDetailRow('Catégorie', itemData['categorie'].toString()),
                  if (itemData['prix'] != null)
                    _buildDetailRow('Prix', '${itemData['prix']} Shillings'),
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
              ],
            ],
          ),
        ),
        actions: [
          // Bouton suppression (si éditable)
          if (widget.canModify || widget.canEditInventory)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteItem(context, ref, item);
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          // Bouton édition quantité pour tous sauf artefacts (et seulement si éditable)
          if (type != 'artefact' && (widget.canModify || widget.canEditInventory))
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _editQuantite(context, ref, item);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Modifier quantité'),
            ),
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
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Future<List<String>> _fetchQualitesNames(WidgetRef ref, String collection, List<int> ids) async {
    final firestore = ref.read(firestoreServiceProvider);
    final names = <String>[];
    
    for (final id in ids) {
      try {
        final doc = await firestore.getDocumentWithFallback(collection: collection, id: id);
        if (doc != null) {
          names.add(doc['nom'] as String? ?? 'Qualité #$id');
        }
      } catch (e) {
        names.add('Qualité #$id');
      }
    }
    
    return names;
  }

  Future<void> _equipItem(BuildContext context, WidgetRef ref, Map<String, dynamic> item) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      // Lire les données fraîches depuis le provider
      final personnageAsync = await ref.read(personnageProvider(widget.personnageId).future);
      final document = personnageAsync?['document'] as Map<String, dynamic>? ?? {};
      final inventaire = List<Map<String, dynamic>>.from(document['inventaire'] ?? []);
      
      // Créer un identifiant unique basé sur plusieurs critères
      String createItemId(Map<String, dynamic> i) {
        final type = i['type'] ?? '';
        final id = i['${type}_id'] ?? '';
        final nom = i['nom_objet'] ?? '';
        final equipee = i['equipee'] ?? false;
        return '$type|$id|$nom|$equipee';
      }
      
      final targetId = createItemId(item);
      
      // Trouver l'index de l'item par son identifiant unique
      final index = inventaire.indexWhere((i) => createItemId(i) == targetId);
      if (index == -1) return;
      
      // Déterminer l'emplacement
      String? emplacement;
      if (item['type'] == 'arme') {
        // Trouver un emplacement libre (main_gauche ou main_droite)
        final mainGaucheOccupee = inventaire.any((i) => i['emplacement'] == 'main_gauche' && i['equipee'] == true);
        final mainDroiteOccupee = inventaire.any((i) => i['emplacement'] == 'main_droite' && i['equipee'] == true);
        
        if (!mainDroiteOccupee) {
          emplacement = 'main_droite';
        } else if (!mainGaucheOccupee) {
          emplacement = 'main_gauche';
        } else {
          if (context.mounted) {
            NotificationService.warning('Les deux mains sont déjà occupées');
          }
          return;
        }
      } else if (item['type'] == 'armure') {
        // Déséquiper l'armure actuelle si elle existe
        for (int i = 0; i < inventaire.length; i++) {
          if (inventaire[i]['type'] == 'armure' && inventaire[i]['equipee'] == true) {
            inventaire[i]['equipee'] = false;
            inventaire[i]['emplacement'] = null;
          }
        }
        emplacement = 'armure';
      }
      
      // Équiper l'item
      inventaire[index]['equipee'] = true;
      inventaire[index]['emplacement'] = emplacement;
      
      // Mettre à jour le document complet avec le nouvel inventaire
      document['inventaire'] = inventaire;
      
      await firestoreService.updateDocument(
        collection: 'personnages',
        documentId: widget.personnageId,
        data: {'document': document},
      );
      
      // Invalider le provider pour rafraîchir l'UI
      ref.invalidate(personnageProvider(widget.personnageId));
      
      if (context.mounted) {
        NotificationService.success('${item['nom_objet']} équipé');
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.error('Erreur lors de l\'équipement: $e');
      }
    }
  }

  Future<void> _unequipItem(BuildContext context, WidgetRef ref, Map<String, dynamic> item) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      // Lire les données fraîches depuis le provider
      final personnageAsync = await ref.read(personnageProvider(widget.personnageId).future);
      final document = personnageAsync?['document'] as Map<String, dynamic>? ?? {};
      final inventaire = List<Map<String, dynamic>>.from(document['inventaire'] ?? []);
      
      // Créer un identifiant unique basé sur plusieurs critères
      String createItemId(Map<String, dynamic> i) {
        final type = i['type'] ?? '';
        final id = i['${type}_id'] ?? '';
        final nom = i['nom_objet'] ?? '';
        final equipee = i['equipee'] ?? false;
        return '$type|$id|$nom|$equipee';
      }
      
      final targetId = createItemId(item);
      
      // Trouver l'index de l'item par son identifiant unique
      final index = inventaire.indexWhere((i) => createItemId(i) == targetId);
      if (index == -1) return;
      
      // Déséquiper l'item
      inventaire[index]['equipee'] = false;
      inventaire[index]['emplacement'] = null;
      
      // Mettre à jour le document complet avec le nouvel inventaire
      document['inventaire'] = inventaire;
      
      await firestoreService.updateDocument(
        collection: 'personnages',
        documentId: widget.personnageId,
        data: {'document': document},
      );
      
      // Invalider le provider pour rafraîchir l'UI
      ref.invalidate(personnageProvider(widget.personnageId));
      
      if (context.mounted) {
        NotificationService.success('${item['nom_objet']} déséquipé');
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.error('Erreur lors du déséquipement: $e');
      }
    }
  }
}

