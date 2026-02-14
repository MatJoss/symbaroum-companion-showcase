/// Dialog pour sélectionner une capacité (talent/trait/pouvoir/rituel/atout/fardeau)
library;

import 'package:flutter/material.dart';

/// Type de capacité à sélectionner
enum CapaciteType {
  talent,
  trait,
  pouvoir,
  rituel,
  atoutFardeau,
}

/// Dialog générique de sélection de capacité avec recherche
class CapaciteSelectionDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) getItemName;
  final String? Function(T)? getItemDescription;
  final bool hasLevel; // Si la capacité a un niveau (Novice/Adepte/Maître)
  final int initialLevel; // Niveau initial (1, 2, 3)
  final bool Function(T)? filterMonstrueux; // Pour les traits monstrueux

  const CapaciteSelectionDialog({
    super.key,
    required this.title,
    required this.items,
    required this.getItemName,
    this.getItemDescription,
    this.hasLevel = false,
    this.initialLevel = 1,
    this.filterMonstrueux,
  });

  @override
  State<CapaciteSelectionDialog<T>> createState() => _CapaciteSelectionDialogState<T>();
}

class _CapaciteSelectionDialogState<T> extends State<CapaciteSelectionDialog<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];
  int _selectedLevel = 1;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialLevel;
    _filteredItems = List.from(widget.items);
    _filterItems(); // Initial filter
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final rawQuery = _searchController.text.trim();
    final normalizedQuery = _normalizeString(rawQuery.toLowerCase());

    // Use a local snapshot of items to avoid concurrent mutations
    final itemsSnapshot = List<T>.from(widget.items);

    setState(() {
      if (normalizedQuery.isEmpty) {
        _filteredItems = itemsSnapshot;
      } else {
        _filteredItems = itemsSnapshot.where((item) {
          final name = widget.getItemName(item);
          final description = widget.getItemDescription?.call(item);
          final normalizedName = _normalizeString((name ?? '').toLowerCase());
          final normalizedDescription = _normalizeString((description ?? '').toLowerCase());
          return normalizedName.contains(normalizedQuery) || normalizedDescription.contains(normalizedQuery);
        }).toList();
      }

      // Tri alphabétique par nom
      _filteredItems.sort((a, b) =>
        widget.getItemName(a).toLowerCase().compareTo(widget.getItemName(b).toLowerCase())
      );
    });
  }

  /// Normalise une chaîne en retirant les accents
  String _normalizeString(String str) {
    // Expand mapping to include ligatures and common special chars
    const withAccents = 'àáâãäåèéêëìíîïòóôõöùúûüýÿñçœæÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝŸÑÇŒÆ';
    const withoutAccents = 'aaaaaaeeeeiiiioooouuuuyyncoeaeAAAAAEEEEIIIIOOOOOUUUUYYNCOEAE';

    String result = str;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }

    // Normalize various apostrophes and dashes that may have crept in
    result = result.replaceAll("’", "'");
    result = result.replaceAll("‚", "'");
    result = result.replaceAll("–", "-");
    result = result.replaceAll("—", "-");
    result = result.replaceAll("\u200B", ""); // zero-width
    return result;
  }

  String _getLevelLabel(int level) {
    return ['', 'Novice', 'Adepte', 'Maître'][level.clamp(0, 3)];
  }

  String _getMonstrueuxLabel(int level) {
    return ['', 'I', 'II', 'III'][level.clamp(0, 3)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMonstrueux = widget.filterMonstrueux != null;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barre de recherche
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return TextField(
                  controller: _searchController,
                  onChanged: (v) => _filterItems(),
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterItems();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Sélecteur de niveau (si applicable)
            if (widget.hasLevel) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Text(
                        'Niveau : ',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SegmentedButton<int>(
                          segments: [
                            ButtonSegment<int>(
                              value: 1,
                              label: Text(isMonstrueux ? _getMonstrueuxLabel(1) : _getLevelLabel(1)),
                            ),
                            ButtonSegment<int>(
                              value: 2,
                              label: Text(isMonstrueux ? _getMonstrueuxLabel(2) : _getLevelLabel(2)),
                            ),
                            ButtonSegment<int>(
                              value: 3,
                              label: Text(isMonstrueux ? _getMonstrueuxLabel(3) : _getLevelLabel(3)),
                            ),
                          ],
                          selected: {_selectedLevel},
                          onSelectionChanged: (Set<int> selected) {
                            setState(() {
                              _selectedLevel = selected.first;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Liste des items
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun résultat',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final name = widget.getItemName(item);
                        final description = widget.getItemDescription?.call(item);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              name,
                              style: theme.textTheme.titleMedium,
                            ),
                            subtitle: description != null
                                ? Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () {
                              Navigator.pop(context, {
                                'item': item,
                                'level': widget.hasLevel ? _selectedLevel : 1,
                              });
                            },
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                        );
                      },
                    ),
            ),

            // Footer avec nombre de résultats
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${_filteredItems.length} résultat(s)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
