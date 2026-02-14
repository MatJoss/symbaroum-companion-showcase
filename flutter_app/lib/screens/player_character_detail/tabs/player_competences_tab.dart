import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/firebase_providers.dart';
import '../../../config/theme.dart';

/// Onglet Compétences - Affichage des talents, pouvoirs, traits, rituels (lecture seule pour joueur)
class PlayerCompetencesTab extends ConsumerWidget {
  final Map<String, dynamic> personnage;
  final Map<String, dynamic> document;

  const PlayerCompetencesTab({
    super.key,
    required this.personnage,
    required this.document,
  });

  // Helper pour parser int/string depuis Firestore
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talents = List<Map<String, dynamic>>.from(document['talents'] ?? []);
    final pouvoirs = List<Map<String, dynamic>>.from(document['pouvoirs'] ?? []);
    final traits = List<Map<String, dynamic>>.from(document['traits'] ?? []);
    final rituels = List<Map<String, dynamic>>.from(document['rituels'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Talents
        _buildSection(
          context,
          ref,
          'TALENTS',
          Icons.star,
          Colors.blue,
          talents,
          'talents',
          'talent_id',
        ),
        const SizedBox(height: 16),
        
        // Pouvoirs Mystiques
        _buildSection(
          context,
          ref,
          'POUVOIRS MYSTIQUES',
          Icons.auto_awesome,
          Colors.purple,
          pouvoirs,
          'pouvoirs',
          'pouvoir_id',
        ),
        const SizedBox(height: 16),
        
        // Traits
        _buildSection(
          context,
          ref,
          'TRAITS',
          Icons.psychology,
          Colors.orange,
          traits,
          'traits',
          'trait_id',
        ),
        const SizedBox(height: 16),
        
        // Rituels
        _buildSection(
          context,
          ref,
          'RITUELS',
          Icons.self_improvement,
          Colors.green,
          rituels,
          'rituels',
          'rituel_id',
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    IconData icon,
    Color color,
    List<Map<String, dynamic>> items,
    String collection,
    String idField,
  ) {
    return Card(
      color: const Color(0xFF2C1810),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: SymbaroumTheme.parchment,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            const SizedBox.shrink()
          else
            FutureBuilder<List<Widget>>(
              future: _buildSortedCompetencesList(context, ref, items, collection, idField, color),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Column(children: snapshot.data ?? []);
              },
            ),
        ],
      ),
    );
  }

  Future<List<Widget>> _buildSortedCompetencesList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> items,
    String collection,
    String idField,
    Color color,
  ) async {
    // Fetcher les noms pour trier
    final firestoreService = ref.read(firestoreServiceProvider);
    final itemsWithNames = <Map<String, dynamic>>[];
    
    for (final item in items) {
      final id = item[idField];
      if (id != null) {
        try {
          final doc = await firestoreService.getDocumentWithFallback(
            collection: collection,
            id: id,
          );
          if (doc != null) {
            final itemWithName = Map<String, dynamic>.from(item);
            itemWithName['_nom'] = doc['nom'] as String? ?? '';
            itemsWithNames.add(itemWithName);
          }
        } catch (e) {
          // En cas d'erreur, ajouter quand même l'item sans nom
          itemsWithNames.add(item);
        }
      }
    }
    
    // Trier par nom
    itemsWithNames.sort((a, b) {
      final nomA = a['_nom'] as String? ?? '';
      final nomB = b['_nom'] as String? ?? '';
      return nomA.toLowerCase().compareTo(nomB.toLowerCase());
    });
    
    // Construire les widgets
    return itemsWithNames.map((item) => _buildCompetenceItem(
      context,
      ref,
      item,
      collection,
      idField,
      color,
    )).toList();
  }

  Widget _buildCompetenceItem(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
    String collection,
    String idField,
    Color color,
  ) {
    final itemId = item[idField]?.toString();
    final niveau = _parseInt(item['niveau'], 1);
    
    if (itemId == null) {
      return const ListTile(
        title: Text('Compétence inconnue'),
      );
    }

    // Résoudre l'ID pour obtenir les détails
    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(firestoreServiceProvider).getDocumentWithFallback(
        collection: collection,
        id: itemId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Chargement...'),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const ListTile(
            title: Text('Erreur de chargement'),
          );
        }

        final data = snapshot.data!;
        final nom = data['nom'] as String? ?? 'Sans nom';
        final descriptionGenerale = data['description_generale'] as String? ?? '';
        final niveauType = data['niveau_type'] as String? ?? '';
        final isMonstrueux = niveauType.toLowerCase() == 'monstrueux';
        
        // Descriptions selon le type
        final descriptionNovice = isMonstrueux ? (data['description_i'] as String? ?? '') : (data['description_novice'] as String? ?? '');
        final descriptionAdepte = isMonstrueux ? (data['description_ii'] as String? ?? '') : (data['description_adepte'] as String? ?? '');
        final descriptionMaitre = isMonstrueux ? (data['description_iii'] as String? ?? '') : (data['description_maitre'] as String? ?? '');
        
        // Badge selon le type
        final niveauLabel = isMonstrueux ? ['I', 'II', 'III'][niveau - 1] : ['N', 'A', 'M'][niveau - 1];
        
        return ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Text(
              niveauLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ),
          title: Text(nom),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (descriptionGenerale.isNotEmpty) ...[
                    const Text(
                      'Description générale',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(descriptionGenerale),
                    const SizedBox(height: 12),
                  ],
                  if (niveau >= 1 && descriptionNovice.isNotEmpty) ...[
                    Text(
                      isMonstrueux ? 'Niveau I' : 'Niveau Novice',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(descriptionNovice),
                    const SizedBox(height: 12),
                  ],
                  if (niveau >= 2 && descriptionAdepte.isNotEmpty) ...[
                    Text(
                      isMonstrueux ? 'Niveau II' : 'Niveau Adepte',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(descriptionAdepte),
                    const SizedBox(height: 12),
                  ],
                  if (niveau >= 3 && descriptionMaitre.isNotEmpty) ...[
                    Text(
                      isMonstrueux ? 'Niveau III' : 'Niveau Maître',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(descriptionMaitre),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
