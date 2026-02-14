import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/firebase_providers.dart';
import '../../../services/notification_service.dart';

/// Onglet Notes - Affichage des notes (éditable pour joueur)
class PlayerNotesTab extends ConsumerWidget {
  final String personnageId;
  final Map<String, dynamic> personnage;
  final Map<String, dynamic> document;
  final bool canModify;

  const PlayerNotesTab({
    super.key,
    required this.personnageId,
    required this.personnage,
    required this.document,
    this.canModify = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = document['notes'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bouton d'édition (si autorisé)
        if (canModify)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _editNotes(context, ref, notes),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Modifier les notes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (canModify) const SizedBox(height: 16),
        
        if (notes.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Aucune note',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          Card(
            color: const Color(0xFF2C1810),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                notes,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _editNotes(BuildContext context, WidgetRef ref, String currentNotes) async {
    final controller = TextEditingController(text: currentNotes);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier les notes'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 15,
            minLines: 10,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    
    if (result != null && result != currentNotes) {
      try {
        final firestoreService = ref.read(firestoreServiceProvider);
        
        // Mettre à jour le document avec les nouvelles notes
        final updatedDocument = Map<String, dynamic>.from(document);
        updatedDocument['notes'] = result;
        
        await firestoreService.updateDocument(
          collection: 'personnages',
          documentId: personnageId,
          data: {'document': updatedDocument},
        );
        
        // Invalider le provider pour rafraîchir l'UI
        ref.invalidate(personnageProvider(personnageId));
        
        if (context.mounted) {
          NotificationService.success('Notes mises à jour');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.error('Erreur lors de la mise à jour: $e');
        }
      }
    }
  }
}
