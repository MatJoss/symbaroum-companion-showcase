import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/firebase_providers.dart';
import '../services/notification_service.dart';

/// Écran d'édition de campagne (MJ uniquement)
class EditCampagneScreen extends ConsumerStatefulWidget {
  final String campagneId;

  const EditCampagneScreen({
    super.key,
    required this.campagneId,
  });

  @override
  ConsumerState<EditCampagneScreen> createState() => _EditCampagneScreenState();
}

class _EditCampagneScreenState extends ConsumerState<EditCampagneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isPublic = false;
  bool _joueursEditInventaire = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCampagne() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestore = ref.read(firestoreServiceProvider);
      
      await firestore.updateDocument(
        collection: 'campagnes',
        documentId: widget.campagneId,
        data: {
          'nom': _nomController.text.trim(),
          'description': _descriptionController.text.trim(),
          'isPublic': _isPublic,
          'joueursEditInventaire': _joueursEditInventaire,
          'date_modification': DateTime.now().toIso8601String(),
        },
      );

      // Invalider le cache
      ref.invalidate(campagnesMJProvider);
      ref.invalidate(campagneProvider(widget.campagneId));

      if (mounted) {
        NotificationService.success('Campagne mise à jour avec succès');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error('Erreur lors de la mise à jour: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    // Vérifier les permissions avant de continuer
    final authService = ref.read(firebaseAuthServiceProvider);
    final currentUserId = authService.currentUser?.uid;
    
    // Récupérer les informations de la campagne pour vérifier le créateur
    final firestore = ref.read(firestoreServiceProvider);
    final campagne = await firestore.getDocument(
      collection: 'campagnes',
      documentId: widget.campagneId,
    );

    if (!mounted) return;

    if (campagne == null) {
      NotificationService.error('Campagne introuvable');
      return;
    }

    final nom = campagne['nom'] as String? ?? 'Sans nom';
    final isPublic = campagne['isPublic'] as bool? ?? false;
    final createur = campagne['createur'] as String? ?? campagne['uid'] as String?;

    // Vérifier si l'utilisateur peut supprimer
    if (isPublic && createur != null && createur != currentUserId) {
      NotificationService.error('Campagne publique : seul le créateur peut la supprimer');
      return;
    }
    
    // Récupérer tous les personnages liés à cette campagne
    final personnages = await firestore.queryCollectionArrayContains(
      collection: 'personnages',
      field: 'campagnes_ids',
      value: widget.campagneId,
    );

    if (!mounted) return;

    // Identifier les personnages qui seront supprimés (liés uniquement à cette campagne)
    final personnagesToDelete = personnages.where((p) {
      final campagnesIds = List<String>.from(p['campagnes_ids'] ?? []);
      return campagnesIds.length == 1 && campagnesIds.first == widget.campagneId;
    }).toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Expanded(child: Text('Supprimer la campagne')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voulez-vous vraiment supprimer la campagne "$nom" ?',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cette action est irréversible.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (personnagesToDelete.isNotEmpty) ...[
                  const Text(
                    '⚠️ Les personnages suivants seront DÉFINITIVEMENT SUPPRIMÉS car ils ne sont liés qu\'à cette campagne :',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    softWrap: true,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: personnagesToDelete.map((p) {
                          final doc = p['document'] as Map<String, dynamic>? ?? {};
                          final nomPerso = doc['nom'] as String? ?? 'Sans nom';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    nomPerso,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                if (personnages.length > personnagesToDelete.length) ...[
                  const SizedBox(height: 12),
                  Text(
                    'ℹ️ ${personnages.length - personnagesToDelete.length} personnage(s) resteront disponibles dans d\'autres campagnes.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    softWrap: true,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteCampagne();
    }
  }

  Future<void> _deleteCampagne() async {
    setState(() => _isLoading = true);

    try {
      final firestore = ref.read(firestoreServiceProvider);

      // 1. Récupérer tous les personnages liés à cette campagne
      final personnages = await firestore.queryCollectionArrayContains(
        collection: 'personnages',
        field: 'campagnes_ids',
        value: widget.campagneId,
      );

      // 2. Traiter chaque personnage
      for (final personnage in personnages) {
        final personnageId = personnage['id'] as String;
        final campagnesIds = List<String>.from(personnage['campagnes_ids'] ?? []);

        if (campagnesIds.length == 1) {
          // Personnage lié uniquement à cette campagne → supprimer
          await firestore.deleteDocument(
            collection: 'personnages',
            documentId: personnageId,
          );
        } else {
          // Personnage lié à d'autres campagnes → retirer juste cette campagne
          campagnesIds.remove(widget.campagneId);
          await firestore.updateDocument(
            collection: 'personnages',
            documentId: personnageId,
            data: {'campagnes_ids': campagnesIds},
          );
        }
      }

      // 3. Supprimer la campagne
      await firestore.deleteDocument(
        collection: 'campagnes',
        documentId: widget.campagneId,
      );

      // 4. Invalider les caches
      ref.invalidate(campagnesMJProvider);
      ref.invalidate(campagneProvider(widget.campagneId));

      if (mounted) {
        NotificationService.success('Campagne supprimée avec succès');
        Navigator.pop(context, true);
        Navigator.pop(context); // Retour à la liste des campagnes
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error('Erreur lors de la suppression: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final campagneAsync = ref.watch(campagneProvider(widget.campagneId));

    return campagneAsync.when(
      data: (campagne) {
        if (campagne == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Campagne introuvable')),
            body: const Center(child: Text('Cette campagne n\'existe pas')),
          );
        }

        // Initialiser les champs une seule fois
        if (!_isInitialized) {
          _nomController.text = campagne['nom'] as String? ?? '';
          _descriptionController.text = campagne['description'] as String? ?? '';
          _isPublic = campagne['isPublic'] as bool? ?? false;
          _joueursEditInventaire = campagne['joueursEditInventaire'] as bool? ?? false;
          _isInitialized = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Éditer la campagne'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _isLoading ? null : _confirmDelete,
                tooltip: 'Supprimer la campagne',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Info campagne
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations générales',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Créée le ${_formatDate(campagne['date_creation'])}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nom de la campagne
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la campagne *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le nom est obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // Option publique
                  Card(
                    child: SwitchListTile(
                      title: const Text('Campagne publique'),
                      subtitle: const Text(
                        'Visible par tous les joueurs (lecture seule pour la démo)',
                      ),
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() => _isPublic = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option joueurs éditent inventaire
                  Card(
                    child: SwitchListTile(
                      title: const Text('Permettre modification d\'inventaire'),
                      subtitle: const Text(
                        'Les joueurs peuvent ajouter des objets à leur inventaire',
                      ),
                      value: _joueursEditInventaire,
                      onChanged: (value) {
                        setState(() => _joueursEditInventaire = value);
                      },
                      secondary: const Icon(Icons.inventory_2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton sauvegarder
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveCampagne,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Enregistrer les modifications'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Éditer la campagne')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(child: Text('Erreur: $error')),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Date inconnue';
    try {
      DateTime dt;
      if (date is String) {
        dt = DateTime.parse(date);
      } else if (date is Timestamp) {
        dt = date.toDate();
      } else {
        return 'Date inconnue';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return 'Date inconnue';
    }
  }
}
