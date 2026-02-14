import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/firebase_providers.dart';
import '../../../config/theme.dart';

/// Widget pour afficher une carte de talent
class TalentCard extends ConsumerWidget {
  final Map<String, dynamic> talent;
  final VoidCallback onShowDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TalentCard({
    super.key,
    required this.talent,
    required this.onShowDetails,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talentId = talent['talent_id'] as int?;
    final niveau = talent['niveau'] as int? ?? 0;

    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(firestoreServiceProvider).getDocumentWithFallback(
        collection: 'talents',
        id: talentId,
      ),
      builder: (context, snapshot) {
        final talentData = snapshot.data;
        final nom = talentData?['nom'] as String? ?? 'Talent #$talentId';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                ['N', 'A', 'M'][niveau - 1],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(nom, style: TextStyle(color: SymbaroumTheme.parchment)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  onPressed: onShowDetails,
                  tooltip: 'Détails',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget pour afficher une carte de pouvoir mystique
class PouvoirCard extends ConsumerWidget {
  final Map<String, dynamic> pouvoir;
  final VoidCallback onShowDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PouvoirCard({
    super.key,
    required this.pouvoir,
    required this.onShowDetails,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pouvoirId = pouvoir['pouvoir_id'] as int?;
    final niveau = pouvoir['niveau'] as int? ?? 0;

    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(firestoreServiceProvider).getDocumentWithFallback(
        collection: 'pouvoirs_mystiques',
        id: pouvoirId,
      ),
      builder: (context, snapshot) {
        final pouvoirData = snapshot.data;
        final nom = pouvoirData?['nom'] as String? ?? 'Pouvoir #$pouvoirId';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple,
              child: Text(
                ['N', 'A', 'M'][niveau - 1],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(nom, style: TextStyle(color: SymbaroumTheme.parchment)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20, color: Colors.purple),
                  onPressed: onShowDetails,
                  tooltip: 'Détails',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget pour afficher une carte de trait
class TraitCard extends ConsumerWidget {
  final Map<String, dynamic> trait;
  final VoidCallback onShowDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TraitCard({
    super.key,
    required this.trait,
    required this.onShowDetails,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traitId = trait['trait_id'] as int?;
    final niveau = trait['niveau'] as int? ?? 0;

    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(firestoreServiceProvider).getDocumentWithFallback(
        collection: 'traits',
        id: traitId,
      ),
      builder: (context, snapshot) {
        final traitData = snapshot.data;
        final nom = traitData?['nom'] as String? ?? 'Trait #$traitId';
        final niveauType = traitData?['niveau_type'] as String? ?? 'normal';
        final isMonstrueux = niveauType == 'monstrueux';
        
        // Déterminer l'affichage du niveau
        String niveauDisplay;
        if (isMonstrueux) {
          niveauDisplay = ['I', 'II', 'III'][niveau - 1];
        } else {
          niveauDisplay = ['N', 'A', 'M'][niveau - 1];
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange,
              child: Text(niveauDisplay, style: const TextStyle(color: Colors.white)),
            ),
            title: Text(nom, style: TextStyle(color: SymbaroumTheme.parchment)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20, color: Colors.orange),
                  onPressed: onShowDetails,
                  tooltip: 'Détails',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget pour afficher une carte de rituel
class RituelCard extends ConsumerWidget {
  final Map<String, dynamic> rituel;
  final VoidCallback onShowDetails;
  final VoidCallback onDelete;

  const RituelCard({
    super.key,
    required this.rituel,
    required this.onShowDetails,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rituelId = rituel['rituel_id'] as int?;

    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(firestoreServiceProvider).getDocumentWithFallback(
        collection: 'rituels',
        id: rituelId,
      ),
      builder: (context, snapshot) {
        final rituelData = snapshot.data;
        final nom = rituelData?['nom'] as String? ?? 'Rituel #$rituelId';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.menu_book, color: Colors.white, size: 20),
            ),
            title: Text(nom, style: TextStyle(color: SymbaroumTheme.parchment)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20, color: Colors.deepPurple),
                  onPressed: onShowDetails,
                  tooltip: 'Détails',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget pour afficher une carte d'atout ou fardeau
class AtoutFardeauCard extends ConsumerWidget {
  final Map<String, dynamic> atout;
  final VoidCallback onShowDetails;
  final VoidCallback onDelete;

  const AtoutFardeauCard({
    super.key,
    required this.atout,
    required this.onShowDetails,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atoutId = atout['atout_fardeau_id'] as int?;
    final niveau = atout['niveau'] as int? ?? 1;

    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(firestoreServiceProvider).getDocumentWithFallback(
        collection: 'atouts_fardeaux',
        id: atoutId,
      ),
      builder: (context, snapshot) {
        final atoutData = snapshot.data;
        final nom = atoutData?['nom'] as String? ?? 'Atout/Fardeau #$atoutId';
        final type = atoutData?['type'] as String? ?? 'atout';
        final isAtout = type.toLowerCase() == 'atout';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isAtout ? Colors.green : Colors.red.shade700,
              child: Icon(
                isAtout ? Icons.stars : Icons.warning,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(nom, style: TextStyle(color: SymbaroumTheme.parchment))),
                if (niveau > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Niv. $niveau',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: isAtout ? Colors.green : Colors.red.shade700,
                  ),
                  onPressed: onShowDetails,
                  tooltip: 'Détails',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
