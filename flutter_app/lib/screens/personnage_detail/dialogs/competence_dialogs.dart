import 'package:flutter/material.dart';

/// Dialogue pour sélectionner une identité (race, archetype, classe, rituel).
class SelectIdentiteDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final bool showDescription;
  
  const SelectIdentiteDialog({
    super.key,
    required this.title,
    required this.items,
    this.showDescription = false,
  });
  
  @override
  State<SelectIdentiteDialog> createState() => _SelectIdentiteDialogState();
}

class _SelectIdentiteDialogState extends State<SelectIdentiteDialog> {
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
                  final nom = item['nom'] as String? ?? 'Inconnu';
                  final description = item['description'] as String? ?? '';
                  // L'ID métier est dans le champ 'id' (int), on le convertit en string
                  final id = (item['id'])?.toString() ?? item['uid'] as String;
                  
                  return ListTile(
                    title: Text(nom),
                    subtitle: widget.showDescription && description.isNotEmpty 
                      ? Text(
                          description.length > 100 
                            ? '${description.substring(0, 100)}...' 
                            : description,
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                    onTap: () => Navigator.of(context).pop(id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

/// Dialogue pour sélectionner un talent/pouvoir/trait/atout avec niveau.
class SelectTalentPouvoirDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String type; // 'talent', 'pouvoir', 'trait', 'atout'
  
  const SelectTalentPouvoirDialog({
    super.key,
    required this.title,
    required this.items,
    required this.type,
  });
  
  @override
  State<SelectTalentPouvoirDialog> createState() => _SelectTalentPouvoirDialogState();
}

class _SelectTalentPouvoirDialogState extends State<SelectTalentPouvoirDialog> {
  String _searchQuery = '';
  int _selectedNiveau = 1;
  
  List<Map<String, dynamic>> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    return widget.items.where((item) {
      final nom = (item['nom'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return nom.contains(query);
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 550,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rechercher',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Niveau : '),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedNiveau,
                  items: [1, 2, 3].map((niveau) {
                    return DropdownMenuItem(
                      value: niveau,
                      child: Text(niveau == 1 ? 'Novice' : niveau == 2 ? 'Adepte' : 'Maître'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedNiveau = value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  final nom = item['nom'] as String? ?? 'Inconnu';
                  final id = (item['id'])?.toString() ?? item['uid'] as String;
                  
                  return ListTile(
                    title: Text(nom),
                    onTap: () => Navigator.of(context).pop({
                      'id': int.tryParse(id) ?? id,
                      'niveau': _selectedNiveau,
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

/// Dialogue pour éditer le niveau d'une compétence.
class EditNiveauDialog extends StatefulWidget {
  final String title;
  final int currentNiveau;
  final bool isMonstrueux;
  
  const EditNiveauDialog({
    super.key,
    required this.title,
    required this.currentNiveau,
    this.isMonstrueux = false,
  });
  
  @override
  State<EditNiveauDialog> createState() => _EditNiveauDialogState();
}

class _EditNiveauDialogState extends State<EditNiveauDialog> {
  late int _selectedNiveau;
  
  @override
  void initState() {
    super.initState();
    _selectedNiveau = widget.currentNiveau;
  }
  
  @override
  Widget build(BuildContext context) {
    final niveau1Label = widget.isMonstrueux ? 'I' : 'Novice';
    final niveau2Label = widget.isMonstrueux ? 'II' : 'Adepte';
    final niveau3Label = widget.isMonstrueux ? 'III' : 'Maître';
    
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<int>(
            title: Text(niveau1Label),
            value: 1,
            groupValue: _selectedNiveau,
            onChanged: (value) {
              if (value != null) setState(() => _selectedNiveau = value);
            },
          ),
          RadioListTile<int>(
            title: Text(niveau2Label),
            value: 2,
            groupValue: _selectedNiveau,
            onChanged: (value) {
              if (value != null) setState(() => _selectedNiveau = value);
            },
          ),
          RadioListTile<int>(
            title: Text(niveau3Label),
            value: 3,
            groupValue: _selectedNiveau,
            onChanged: (value) {
              if (value != null) setState(() => _selectedNiveau = value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedNiveau),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
