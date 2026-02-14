import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../providers/firebase_providers.dart';
import '../dialogs/dialogs.dart';

/// Onglet des informations générales du personnage
class InfosTab extends ConsumerWidget {
  final String personnageId;
  final Map<String, dynamic> personnage;
  final Map<String, dynamic> document;
  final TextEditingController nomController;
  final TextEditingController ageController;
  final TextEditingController tailleController;
  final TextEditingController poidsController;
  final TextEditingController couleurOmbreController;
  final TextEditingController experienceController;
  final String? modifiedRaceId;
  final String? modifiedArchetypeId;
  final String? modifiedClasseId;
  final VoidCallback onModified;
  final Function(String?) onRaceChanged;
  final Function(String?) onArchetypeChanged;
  final Function(String?) onClasseChanged;
  final Function() onRefresh;
  final bool canModify;
  final Future<void> Function()? onEditAvatar;

  const InfosTab({
    super.key,
    required this.personnageId,
    required this.personnage,
    required this.document,
    required this.nomController,
    required this.ageController,
    required this.tailleController,
    required this.poidsController,
    required this.couleurOmbreController,
    required this.experienceController,
    this.modifiedRaceId,
    this.modifiedArchetypeId,
    this.modifiedClasseId,
    required this.onModified,
    required this.onRaceChanged,
    required this.onArchetypeChanged,
    required this.onClasseChanged,
    required this.onRefresh,
    this.canModify = false,
    this.onEditAvatar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estPJ = personnage['estPJ'] as bool? ?? true;
    final createur = personnage['createur'] as String? ?? '';
    final campagnesIds = List<String>.from(personnage['campagnes_ids'] ?? []);
    final raceId = document['race_id']?.toString() ?? '';
    final archetypeId = document['archetype_id']?.toString() ?? '';
    final classeId = document['classe_id']?.toString() ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar (lecture seule - édition désactivée pour éviter les appels Firebase)
        Center(
          child: Builder(builder: (_) {
            final avatarUrl = document['avatarUrl'] as String?;
            final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

            if (canModify) {
              return InkWell(
                borderRadius: BorderRadius.circular(56),
                onTap: () {
                  // Lancer le callback asynchrone sans attendre ici
                  onEditAvatar?.call();
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: estPJ ? Colors.blue : Colors.orange,
                      backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                      child: !hasAvatar
                          ? Text(
                              nomController.text.isNotEmpty ? nomController.text[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 48, color: Colors.white),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black45,
                        child: Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }

            return CircleAvatar(
              radius: 50,
              backgroundColor: estPJ ? Colors.blue : Colors.orange,
              backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
              child: !hasAvatar
                  ? Text(
                      nomController.text.isNotEmpty ? nomController.text[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 48, color: Colors.white),
                    )
                  : null,
            );
          }),
        ),
        const SizedBox(height: 24),

        // Nom
        TextFormField(
          controller: nomController,
          decoration: InputDecoration(
            labelText: 'Nom',
            labelStyle: TextStyle(color: SymbaroumTheme.gold),
            filled: true,
            fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: SymbaroumTheme.gold),
            ),
          ),
          style: TextStyle(color: SymbaroumTheme.parchment),
          onChanged: (value) => onModified(),
        ),
        const SizedBox(height: 16),

        // Type
        Card(
          color: Theme.of(context).cardColor.withValues(alpha: 0.25),
          child: ListTile(
            leading: Icon(
              estPJ ? Icons.person : Icons.smart_toy,
              color: estPJ ? Colors.blue : Colors.orange,
            ),
            title: Text(estPJ ? 'Personnage Joueur' : 'Personnage Non-Joueur'),
          ),
        ),
        const SizedBox(height: 16),

        // Race / Archetype / Classe
        const Text(
          'Identité',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildIdentiteCard(
          context,
          ref,
          'Race',
          modifiedRaceId ?? raceId,
          'races',
          Icons.face,
        ),
        const SizedBox(height: 8),
        _buildIdentiteCard(
          context,
          ref,
          'Archétype',
          modifiedArchetypeId ?? archetypeId,
          'archetypes',
          Icons.psychology,
        ),
        const SizedBox(height: 8),
        _buildIdentiteCard(
          context,
          ref,
          'Classe',
          modifiedClasseId ?? classeId,
          'classes',
          Icons.work,
        ),
        const SizedBox(height: 16),

        // Caractéristiques physiques
        const Text(
          'Caractéristiques physiques',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: ageController,
                decoration: InputDecoration(
                  labelText: 'Âge',
                  labelStyle: TextStyle(color: SymbaroumTheme.gold),
                  filled: true,
                  fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: SymbaroumTheme.gold),
                  ),
                  suffixText: 'ans',
                ),
                style: TextStyle(color: SymbaroumTheme.parchment),
                keyboardType: TextInputType.number,
                onChanged: (value) => onModified(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: tailleController,
                decoration: InputDecoration(
                  labelText: 'Taille',
                  labelStyle: TextStyle(color: SymbaroumTheme.gold),
                  filled: true,
                  fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: SymbaroumTheme.gold),
                  ),
                  suffixText: 'cm',
                ),
                style: TextStyle(color: SymbaroumTheme.parchment),
                keyboardType: TextInputType.number,
                onChanged: (value) => onModified(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: poidsController,
                decoration: InputDecoration(
                  labelText: 'Poids',
                  labelStyle: TextStyle(color: SymbaroumTheme.gold),
                  filled: true,
                  fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: SymbaroumTheme.gold),
                  ),
                  suffixText: 'kg',
                ),
                style: TextStyle(color: SymbaroumTheme.parchment),
                keyboardType: TextInputType.number,
                onChanged: (value) => onModified(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Couleur d'ombre
        TextFormField(
          controller: couleurOmbreController,
          decoration: InputDecoration(
            labelText: 'Couleur d\'ombre',
            labelStyle: TextStyle(color: SymbaroumTheme.gold),
            filled: true,
            fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: SymbaroumTheme.gold),
            ),
            helperText: 'Ex: Nuances de rouge et de noir',
          ),
          style: TextStyle(color: SymbaroumTheme.parchment),
          maxLines: 2,
          onChanged: (value) => onModified(),
        ),
        const SizedBox(height: 16),

        // Expérience (éditable par le MJ)
        TextFormField(
          controller: experienceController,
          decoration: InputDecoration(
            labelText: 'Expérience',
            labelStyle: TextStyle(color: SymbaroumTheme.gold),
            filled: true,
            fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: SymbaroumTheme.gold),
            ),
            suffixText: 'XP',
            helperText: 'Géré par le Maître de Jeu',
            prefixIcon: const Icon(Icons.star, color: Colors.amber),
          ),
          style: TextStyle(color: SymbaroumTheme.parchment),
          keyboardType: TextInputType.number,
          onChanged: (value) => onModified(),
        ),
        const SizedBox(height: 16),

        // Métadonnées
        const Text(
          'Informations',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).cardColor.withValues(alpha: 0.25),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Afficher le displayedName du créateur
                if (createur.isNotEmpty)
                  FutureBuilder<Map<String, dynamic>?>(
                    future: ref.read(firestoreServiceProvider).getDocument(
                      collection: 'users',
                      documentId: createur,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Row(
                          children: [
                            Text('Créateur: '),
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        );
                      }
                      
                      if (snapshot.hasData && snapshot.data != null) {
                        final displayedName = snapshot.data!['displayedName'] as String? ?? 'Inconnu';
                        return Text('Créateur: $displayedName');
                      }
                      
                      // En cas d'erreur, afficher "Inconnu" au lieu de l'UID
                      return const Text('Créateur: Inconnu');
                    },
                  )
                else
                  const Text('Créateur: Inconnu'),
                const SizedBox(height: 4),
                Text('Campagnes: ${campagnesIds.length}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentiteCard(
    BuildContext context,
    WidgetRef ref,
    String label,
    String id,
    String collection,
    IconData icon,
  ) {
    if (id.isEmpty) {
      return Card(
        color: Theme.of(context).cardColor.withValues(alpha: 0.25),
        child: ListTile(
          leading: Icon(icon, color: Colors.grey),
          title: Text(label),
          subtitle: const Text('Non défini'),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showSelectIdentiteDialog(context, ref, label, collection),
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(firestoreServiceProvider).getDocument(
        collection: collection,
        documentId: id,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            color: Theme.of(context).cardColor.withValues(alpha: 0.25),
            child: ListTile(
              leading: Icon(icon, color: Colors.grey),
              title: Text(label),
              subtitle: const Text('Chargement...'),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Card(
            color: Theme.of(context).cardColor.withValues(alpha: 0.25),
            child: ListTile(
              leading: Icon(icon, color: Colors.grey),
              title: Text(label),
              subtitle: Text('ID: $id'),
            ),
          );
        }

        final data = snapshot.data!;
        final nom = data['nom'] as String? ?? 'Inconnu';

        return Card(
          color: Theme.of(context).cardColor.withValues(alpha: 0.25),
          child: ListTile(
            leading: Icon(icon, color: Colors.grey),
            title: Text(label),
            subtitle: Text(
              nom,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showSelectIdentiteDialog(context, ref, label, collection),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSelectIdentiteDialog(
    BuildContext context,
    WidgetRef ref,
    String label,
    String collection,
  ) async {
    final firestore = ref.read(firestoreServiceProvider);

    // Utiliser les méthodes spécifiques si disponibles
    late List<Map<String, dynamic>> allItems;
    if (collection == 'races') {
      allItems = await firestore.getRaces();
    } else if (collection == 'archetypes') {
      allItems = await firestore.getArchetypes();
    } else if (collection == 'classes') {
      allItems = await firestore.getClasses();
      // Filtrer les classes par archétype si un archétype est sélectionné
      final currentArchetypeId = modifiedArchetypeId ?? document['archetype_id']?.toString();
      if (currentArchetypeId != null) {
        allItems = allItems.where((item) =>
          item['archetype_id']?.toString() == currentArchetypeId
        ).toList();
      }
    } else {
      allItems = await firestore.listCollection(collection: collection);
    }

    if (!context.mounted) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SelectIdentiteDialog(
        title: 'Sélectionner $label',
        items: allItems,
        showDescription: collection == 'classes', // Masquer description sauf pour classes
      ),
    );

    if (selected != null) {
      if (label == 'Race') {
        onRaceChanged(selected);
      } else if (label == 'Archétype') {
        onArchetypeChanged(selected);
      } else if (label == 'Classe') {
        onClasseChanged(selected);
      }
      onModified();
      onRefresh();
    }
  }
}
