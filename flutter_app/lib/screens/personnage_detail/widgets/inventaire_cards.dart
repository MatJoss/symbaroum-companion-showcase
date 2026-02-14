import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';

/// Widget pour afficher une carte d'inventaire (arme, armure, équipement, artefact)
class InventaireCard extends ConsumerWidget {
  final Map<String, dynamic> item;
  final bool isEquipped;
  final VoidCallback onEquip;
  final VoidCallback onUnequip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShowDetails;

  const InventaireCard({
    super.key,
    required this.item,
    required this.isEquipped,
    required this.onEquip,
    required this.onUnequip,
    required this.onEdit,
    required this.onDelete,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = item['type'] as String? ?? 'objet';
    final nom = item['nom_objet'] as String? ?? 'Objet sans nom';
    final quantite = item['quantite'] as int? ?? 1;
    
    // Seuls les armes et armures peuvent être équipés
    final canBeEquipped = type == 'arme' || type == 'armure';

    IconData icon;
    Color color;
    
    switch (type) {
      case 'arme':
        icon = Icons.gavel;
        color = Colors.red;
        break;
      case 'armure':
        icon = Icons.shield;
        color = Colors.blue;
        break;
      case 'artefact':
        icon = Icons.auto_awesome;
        color = Colors.purple;
        break;
      default:
        icon = Icons.inventory_2;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Expanded(child: Text(nom, style: TextStyle(color: SymbaroumTheme.parchment))),
            if (quantite > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('x$quantite', style: const TextStyle(fontSize: 12)),
              ),
            // Infobulle pour les détails
            IconButton(
              icon: const Icon(Icons.info_outline, size: 18),
              onPressed: onShowDetails,
              tooltip: 'Détails',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canBeEquipped)
              IconButton(
                icon: Icon(
                  isEquipped ? Icons.check_circle : Icons.circle_outlined,
                  size: 22,
                  color: isEquipped ? Colors.green : Colors.grey,
                ),
                onPressed: isEquipped ? onUnequip : onEquip,
                tooltip: isEquipped ? 'Déséquiper' : 'Équiper',
              ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }
}
