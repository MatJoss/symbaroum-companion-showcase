import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet Infos - Affichage des informations générales (lecture seule pour joueur)
class PlayerInfosTab extends ConsumerWidget {
  final Map<String, dynamic> personnage;
  final Map<String, dynamic> document;

  const PlayerInfosTab({
    super.key,
    required this.personnage,
    required this.document,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final age = document['age'] as int?;
    final taille = document['taille'] as int?;
    final poids = document['poids'] as int?;
    final couleurOmbre = document['couleur_ombre'] as String? ?? '';
    final notes = document['notes'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Détails physiques
        const Text(
          'Détails physiques',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (age != null) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.cake),
              title: const Text('Âge'),
              subtitle: Text('$age ans'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (taille != null) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.height),
              title: const Text('Taille'),
              subtitle: Text('$taille cm'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (poids != null) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.monitor_weight),
              title: const Text('Poids'),
              subtitle: Text('$poids kg'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (couleurOmbre.isNotEmpty) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Couleur d\'ombre'),
              subtitle: Text(couleurOmbre),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Notes
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Notes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(notes),
            ),
          ),
        ],
      ],
    );
  }
}
