import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/firebase_providers.dart';

/// Dialog pour sélectionner une catégorie d'objet
class SelectCategoryDialog extends StatelessWidget {
  final String title;
  final List<String> categories;
  final bool showBackButton;
  
  const SelectCategoryDialog({
    super.key,
    required this.title,
    required this.categories,
    this.showBackButton = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              title: Text(category),
              onTap: () => Navigator.of(context).pop(category),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(showBackButton ? '__BACK__' : null),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

/// Dialog pour sélectionner un item spécifique (arme/armure/équipement)
class SelectItemDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String type;
  final bool showBackButton;
  
  const SelectItemDialog({
    super.key,
    required this.title,
    required this.items,
    required this.type,
    this.showBackButton = false,
  });
  
  @override
  State<SelectItemDialog> createState() => _SelectItemDialogState();
}

class _SelectItemDialogState extends State<SelectItemDialog> {
  String _searchQuery = '';
  
  List<Map<String, dynamic>> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    
    return widget.items.where((item) {
      final nom = (item['nom'] as String? ?? '').toLowerCase();
      final description = (item['description'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return nom.contains(query) || description.contains(query);
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rechercher',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  final nom = item['nom'] as String? ?? 'Sans nom';
                  final description = item['description'] as String? ?? '';
                  
                  // Info spécifique selon le type
                  String info = '';
                  if (widget.type == 'arme') {
                    final degats = item['degats'] as String? ?? '';
                    final prix = item['prix'];
                    info = degats.isNotEmpty ? '$degats - ${prix ?? 0} ortegs' : '${prix ?? 0} ortegs';
                  } else if (widget.type == 'armure') {
                    final protection = item['protection'] as String? ?? '';
                    final prix = item['prix'];
                    info = protection.isNotEmpty ? 'Protection $protection - ${prix ?? 0} ortegs' : '${prix ?? 0} ortegs';
                  } else if (widget.type == 'equipement' || widget.type == 'artefact') {
                    final prix = item['prix'];
                    final unite = item['unite_mesure'] ?? 'ortegs';
                    info = '${prix ?? 0} $unite';
                  }
                  
                  return ListTile(
                    title: Text(nom),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (info.isNotEmpty) Text(info, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        if (description.isNotEmpty) Text(description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    onTap: () => Navigator.of(context).pop(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(widget.showBackButton ? {'__BACK__': true} : null),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

/// Dialog pour configurer un item (quantité, qualités, sanctifié/souillé)
class ConfigureItemDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final String type;
  final bool isEdit;
  final bool showBackButton;
  
  const ConfigureItemDialog({
    super.key,
    required this.item,
    required this.type,
    this.isEdit = false,
    this.showBackButton = false,
  });
  
  @override
  ConsumerState<ConfigureItemDialog> createState() => _ConfigureItemDialogState();
}

class _ConfigureItemDialogState extends ConsumerState<ConfigureItemDialog> {
  late TextEditingController _descriptionController;
  late TextEditingController _quantiteController;
  bool _estSanctifie = false;
  bool _estSouille = false;
  List<int> _selectedQualitesArmes = [];
  List<int> _selectedQualitesArmures = [];
  
  @override
  void initState() {
    super.initState();
    
    if (widget.isEdit) {
      _descriptionController = TextEditingController(text: widget.item['description'] as String? ?? '');
      _quantiteController = TextEditingController(text: (widget.item['quantite'] ?? 1).toString());
      _estSanctifie = widget.item['est_sanctifie'] as bool? ?? false;
      _estSouille = widget.item['est_souille'] as bool? ?? false;
      _selectedQualitesArmes = List<int>.from(widget.item['qualites_armes'] ?? []);
      _selectedQualitesArmures = List<int>.from(widget.item['qualites_armures'] ?? []);
    } else {
      _descriptionController = TextEditingController(text: widget.item['description'] as String? ?? '');
      _quantiteController = TextEditingController(text: '1');
    }
  }
  
  @override
  void dispose() {
    _descriptionController.dispose();
    _quantiteController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Modifier l\'objet' : 'Configurer l\'objet'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item['nom'] as String? ?? 'Objet', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantiteController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            if (widget.type == 'arme' || widget.type == 'armure') ...[
              CheckboxListTile(
                title: const Text('Sanctifié'),
                value: _estSanctifie,
                onChanged: (value) => setState(() => _estSanctifie = value ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Souillé'),
                value: _estSouille,
                onChanged: (value) => setState(() => _estSouille = value ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
            if (widget.type == 'arme') ...[
              const SizedBox(height: 8),
              const Text('Qualités d\'arme:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildQualitesSelector('qualites_armes', _selectedQualitesArmes, (selected) {
                setState(() => _selectedQualitesArmes = selected);
              }),
            ],
            if (widget.type == 'armure') ...[
              const SizedBox(height: 8),
              const Text('Qualités d\'armure:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildQualitesSelector('qualites_armures', _selectedQualitesArmures, (selected) {
                setState(() => _selectedQualitesArmures = selected);
              }),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(widget.showBackButton ? {'__BACK__': true} : null),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop({
              'description': _descriptionController.text,
              'quantite': int.tryParse(_quantiteController.text) ?? 1,
              'est_sanctifie': _estSanctifie,
              'est_souille': _estSouille,
              'qualites_armes': _selectedQualitesArmes,
              'qualites_armures': _selectedQualitesArmures,
            });
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
  
  Widget _buildQualitesSelector(String collection, List<int> selectedIds, Function(List<int>) onChanged) {
    // Récupérer les qualités disponibles pour cet objet spécifique
    // Le champ 'qualites' contient un JSON string avec les NOMS des qualités, ex: ["Dissimulé", "Pratique"]
    final itemQualites = widget.item['qualites'];
    List<String> availableQualiteNames = [];
    
    if (itemQualites is List) {
      // Si c'est déjà une liste
      availableQualiteNames = itemQualites.map((q) => q.toString()).toList();
    } else if (itemQualites is String && itemQualites.isNotEmpty) {
      // Si c'est un JSON string
      try {
        final decoded = jsonDecode(itemQualites);
        if (decoded is List) {
          availableQualiteNames = decoded.map((q) => q.toString()).toList();
        }
      } catch (e) {
        // Ignore si parsing échoue
      }
    }
    
    // Si aucune qualité disponible, afficher un message
    if (availableQualiteNames.isEmpty) {
      return const Text('Aucune qualité disponible pour cet objet', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
    }
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(firestoreServiceProvider).listCollection(collection: collection),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        
        // Filtrer uniquement les qualités disponibles pour cet objet (par nom)
        final allQualites = snapshot.data!;
        final qualites = allQualites.where((q) {
          final nom = q['nom'] as String? ?? '';
          return availableQualiteNames.contains(nom);
        }).toList();
        
        if (qualites.isEmpty) {
          return const Text('Aucune qualité disponible pour cet objet', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
        }
        
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: qualites.map((qualite) {
            final id = qualite['id'] as int;
            final nom = qualite['nom'] as String? ?? 'Qualité #$id';
            final isSelected = selectedIds.contains(id);
            
            return FilterChip(
              label: Text(nom),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = List<int>.from(selectedIds);
                if (selected) {
                  newSelection.add(id);
                } else {
                  newSelection.remove(id);
                }
                onChanged(newSelection);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
