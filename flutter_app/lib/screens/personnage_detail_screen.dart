import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../providers/firebase_providers.dart';
import '../services/notification_service.dart';
import '../utils/avatar_utils.dart';
import '../services/firebase_storage_service.dart';
import 'personnage_detail/tabs/tabs.dart';

final _logger = Logger(printer: SimplePrinter());

/// Écran de détail/édition d'un personnage
class PersonnageDetailScreen extends ConsumerStatefulWidget {
  final String personnageId;
  final String campagneId;

  const PersonnageDetailScreen({
    super.key,
    required this.personnageId,
    required this.campagneId,
  });

  @override
  ConsumerState<PersonnageDetailScreen> createState() => _PersonnageDetailScreenState();
}

class _PersonnageDetailScreenState extends ConsumerState<PersonnageDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _refreshKey = 0;
  bool _isModified = false;
  
  // Controllers pour les champs éditables
  final _nomController = TextEditingController();
  final _ageController = TextEditingController();
  final _tailleController = TextEditingController();
  final _poidsController = TextEditingController();
  final _notesController = TextEditingController();
  final _couleurOmbreController = TextEditingController();
  final _experienceController = TextEditingController();
  
  // Données modifiées (pour les dropdowns et sélections)
  String? _modifiedRaceId;
  String? _modifiedArchetypeId;
  String? _modifiedClasseId;
  Map<String, int>? _modifiedCaracteristiques;
  List<Map<String, dynamic>>? _modifiedTalents;
  List<Map<String, dynamic>>? _modifiedPouvoirs;
  List<Map<String, dynamic>>? _modifiedTraits;
  List<Map<String, dynamic>>? _modifiedAtoutsFardeaux;
  List<Map<String, dynamic>>? _modifiedRituels;
  Map<String, int>? _modifiedArgent;
  List<Map<String, dynamic>>? _modifiedInventaire;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomController.dispose();
    _ageController.dispose();
    _tailleController.dispose();
    _poidsController.dispose();
    _notesController.dispose();
    _couleurOmbreController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final personnageAsync = ref.watch(personnageProvider(widget.personnageId));
    final campagneAsync = ref.watch(campagneProvider(widget.campagneId));
    final authService = ref.watch(firebaseAuthServiceProvider);
    final currentUserId = authService.currentUser?.uid;

    return personnageAsync.when(
      data: (personnage) {
        if (personnage == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Personnage introuvable')),
            body: const Center(child: Text('Ce personnage n\'existe pas')),
          );
        }

        final document = personnage['document'] as Map<String, dynamic>? ?? {};
        final nom = document['nom'] as String? ?? 'Sans nom';
        final isLocked = personnage['joueur_connecte'] != null;
        
        // Vérifier les permissions pour modification/suppression
        bool canModify = true;
        String? restrictionMessage;

        // Synchronous read from the async value ensures correct permissions during build
        final campagne = campagneAsync.asData?.value;
        if (campagne != null) {
          final isPublic = campagne['isPublic'] as bool? ?? false;
          final createur = campagne['createur'] as String? ?? campagne['uid'] as String?;

          _logger.d('Permission check - isPublic: $isPublic, createur: $createur, currentUser: $currentUserId');

          if (isPublic && createur != null && createur != currentUserId) {
            canModify = false;
            restrictionMessage = 'Campagne publique : seul le créateur peut modifier les personnages';
          }
        }
        
        // Initialiser les controllers une seule fois au premier affichage
        if (!_controllersInitialized) {
          final age = document['age'] as int? ?? 0;
          final taille = document['taille'] as int? ?? 0;
          final poids = document['poids'] as int? ?? 0;
          final couleurOmbre = document['couleur_ombre'] as String? ?? '';
          final experience = document['experience'] as int? ?? 0;
          final notes = document['notes'] as String? ?? '';
          
          _nomController.text = nom;
          _ageController.text = age > 0 ? age.toString() : '';
          _tailleController.text = taille > 0 ? taille.toString() : '';
          _poidsController.text = poids > 0 ? poids.toString() : '';
          _couleurOmbreController.text = couleurOmbre;
          _experienceController.text = experience.toString();
          _notesController.text = notes;
          _controllersInitialized = true;
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(personnageProvider(widget.personnageId));
            await ref.read(personnageProvider(widget.personnageId).future);
            setState(() {
              _refreshKey++;
            });
          },
          child: Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/backgrounds/personnage_bg_free.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: _buildScaffoldContent(personnage, document, nom, isLocked, canModify, restrictionMessage),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Chargement...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaffoldContent(
    Map<String, dynamic> personnage,
    Map<String, dynamic> document,
    String nom,
    bool isLocked,
    bool canModify,
    String? restrictionMessage,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Text(nom),
            if (_isModified) ...[
              const SizedBox(width: 8),
              const Icon(Icons.circle, size: 8, color: Colors.orange),
            ],
            if (!canModify) ...[
              const SizedBox(width: 8),
              const Tooltip(
                message: 'Modification restreinte',
                child: Icon(Icons.lock_outline, size: 16, color: Colors.amber),
              ),
            ],
          ],
        ),
        actions: [
                if (isLocked)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.lock, color: Colors.amber),
                  ),
                if (!canModify && restrictionMessage != null)
                  Tooltip(
                    message: restrictionMessage,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.info_outline, color: Colors.blue),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.save, color: _isModified && canModify ? Colors.orange : null),
                  onPressed: (_isModified && canModify) ? () => _savePersonnage(personnage) : null,
                  tooltip: canModify ? 'Sauvegarder' : 'Modification non autorisée',
                ),
                // Bouton suppression (uniquement si autorisé)
                if (canModify)
                  PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDeletePersonnage(personnage);
                    } else if (value == 'import') {
                      _importPersonnageToOtherCampagne(personnage);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                          Icon(Icons.file_copy, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Importer dans une campagne'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(icon: Icon(Icons.person), text: 'Infos'),
                  Tab(icon: Icon(Icons.trending_up), text: 'Caractéristiques'),
                  Tab(icon: Icon(Icons.auto_awesome), text: 'Compétences'),
                  Tab(icon: Icon(Icons.shopping_bag), text: 'Inventaire'),
                  Tab(icon: Icon(Icons.notes), text: 'Notes'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              key: ValueKey(_refreshKey),
              children: [
                InfosTab(
                  personnageId: widget.personnageId,
                  personnage: personnage,
                  document: document,
                  nomController: _nomController,
                  ageController: _ageController,
                  tailleController: _tailleController,
                  poidsController: _poidsController,
                  couleurOmbreController: _couleurOmbreController,
                  experienceController: _experienceController,
                  modifiedRaceId: _modifiedRaceId,
                  modifiedArchetypeId: _modifiedArchetypeId,
                  modifiedClasseId: _modifiedClasseId,
                  onModified: () => setState(() => _isModified = true),
                  onRaceChanged: (value) => setState(() {
                    _modifiedRaceId = value;
                    _isModified = true;
                  }),
                  onArchetypeChanged: (value) async {
                    setState(() {
                      _modifiedArchetypeId = value;
                      _modifiedClasseId = null; // Reset temporairement
                      _isModified = true;
                    });
                    
                    // Charger les classes de ce nouvel archétype et sélectionner la première
                    if (value != null) {
                      try {
                        final firestore = ref.read(firestoreServiceProvider);
                        final classes = await firestore.listCollection(collection: 'classes');
                        final classesOfArchetype = classes.where((c) => c['archetype_id']?.toString() == value).toList();
                        
                        if (classesOfArchetype.isNotEmpty) {
                          setState(() {
                            _modifiedClasseId = classesOfArchetype.first['id']?.toString();
                          });
                        }
                      } catch (e) {
                        _logger.e('Erreur lors du chargement des classes: $e');
                      }
                    }
                  },
                  canModify: canModify,
                  onEditAvatar: canModify
                      ? () async {
                          try {
                            await AvatarUtils.editAvatar(context, ref, widget.personnageId);
                            ref.invalidate(personnageProvider(widget.personnageId));
                          } catch (e) {
                            NotificationService.error('Erreur: $e');
                          }
                        }
                      : null,
                  onClasseChanged: (value) => setState(() {
                    _modifiedClasseId = value;
                    _isModified = true;
                  }),
                  onRefresh: () => setState(() => _refreshKey++),
                ),
                CaracteristiquesTab(
                  caracteristiques: _modifiedCaracteristiques ?? Map<String, int>.from(
                    (document['caracteristiques'] as Map<String, dynamic>? ?? {}).map(
                      (key, value) => MapEntry(key, value as int? ?? 0),
                    ),
                  ),
                  onCaracteristiquesChanged: (newCarac) {
                    setState(() {
                      _modifiedCaracteristiques = newCarac;
                    });
                  },
                  onModified: () => setState(() => _isModified = true),
                ),
                _buildTalentsTab(document),
                _buildInventaireTab(document),
                NotesTab(
                  notesController: _notesController,
                  onModified: () => setState(() => _isModified = true),
                ),
              ],
            ),
        );
  }

  Widget _buildTalentsTab(Map<String, dynamic> document) {
    return CompetencesTab(
      personnageId: widget.personnageId,
      document: document,
      modifiedTalents: _modifiedTalents,
      modifiedPouvoirs: _modifiedPouvoirs,
      modifiedTraits: _modifiedTraits,
      modifiedAtoutsFardeaux: _modifiedAtoutsFardeaux,
      modifiedRituels: _modifiedRituels,
      onTalentsChanged: (talents) => _modifiedTalents = talents,
      onPouvoirsChanged: (pouvoirs) => _modifiedPouvoirs = pouvoirs,
      onTraitsChanged: (traits) => _modifiedTraits = traits,
      onAtoutsFardeauxChanged: (atouts) => _modifiedAtoutsFardeaux = atouts,
      onRituelsChanged: (rituels) => _modifiedRituels = rituels,
      onModified: () => setState(() {
        _isModified = true;
        _refreshKey++;
      }),
    );
  }

  Widget _buildInventaireTab(Map<String, dynamic> document) {
    return InventaireTab(
      personnageId: widget.personnageId,
      document: document,
      modifiedInventaire: _modifiedInventaire,
      modifiedArgent: _modifiedArgent,
      onInventaireChanged: (inventaire) => _modifiedInventaire = inventaire,
      onArgentChanged: (argent) => _modifiedArgent = argent?.map((k, v) => MapEntry(k, v as int)),
      onModified: () => setState(() {
        _isModified = true;
        _refreshKey++;
      }),
    );
  }

  Future<void> _savePersonnage(Map<String, dynamic> personnage) async {
    try {
      final firestore = ref.read(firestoreServiceProvider);
      final document = personnage['document'] as Map<String, dynamic>? ?? {};
      
      // Construire le document mis à jour
      final updatedDocument = Map<String, dynamic>.from(document);
      
      // Mettre à jour les champs simples
      updatedDocument['nom'] = _nomController.text.trim().isEmpty ? 'Sans nom' : _nomController.text.trim();
      updatedDocument['age'] = int.tryParse(_ageController.text.trim()) ?? 0;
      updatedDocument['taille'] = int.tryParse(_tailleController.text.trim()) ?? 0;
      updatedDocument['poids'] = int.tryParse(_poidsController.text.trim()) ?? 0;
      updatedDocument['notes'] = _notesController.text;
      updatedDocument['couleur_ombre'] = _couleurOmbreController.text.trim();
      updatedDocument['experience'] = int.tryParse(_experienceController.text.trim()) ?? 0;
      
      // Mettre à jour race/archetype/classe si modifiés (convertir en int)
      if (_modifiedRaceId != null) {
        updatedDocument['race_id'] = int.tryParse(_modifiedRaceId!) ?? 0;
      }
      if (_modifiedArchetypeId != null) {
        updatedDocument['archetype_id'] = int.tryParse(_modifiedArchetypeId!) ?? 0;
      }
      if (_modifiedClasseId != null) {
        updatedDocument['classe_id'] = int.tryParse(_modifiedClasseId!) ?? 0;
      }
      
      // Mettre à jour les caractéristiques si modifiées
      if (_modifiedCaracteristiques != null) {
        updatedDocument['caracteristiques'] = _modifiedCaracteristiques;
      }
      
      // Mettre à jour talents/pouvoirs/traits/rituels/atouts_fardeaux si modifiés
      if (_modifiedTalents != null) {
        updatedDocument['talents'] = _modifiedTalents;
      }
      if (_modifiedPouvoirs != null) {
        updatedDocument['pouvoirs'] = _modifiedPouvoirs;
      }
      if (_modifiedTraits != null) {
        updatedDocument['traits'] = _modifiedTraits;
      }
      if (_modifiedRituels != null) {
        updatedDocument['rituels'] = _modifiedRituels;
      }
      if (_modifiedAtoutsFardeaux != null) {
        updatedDocument['atouts_fardeaux'] = _modifiedAtoutsFardeaux;
      }
      if (_modifiedArgent != null) {
        updatedDocument['argent'] = _modifiedArgent;
      }
      if (_modifiedInventaire != null) {
        updatedDocument['inventaire'] = _modifiedInventaire;
      }
      
      // Sauvegarder dans Firestore
      await firestore.updateDocument(
        collection: 'personnages',
        documentId: widget.personnageId,
        data: {
          'document': updatedDocument,
          'date_modification': DateTime.now().toIso8601String(),
        },
      );
      
      // Invalider le cache du provider pour forcer le rechargement
      ref.invalidate(personnageProvider(widget.personnageId));
      
      setState(() {
        _isModified = false;
        _controllersInitialized = false; // Permettre réinitialisation après rechargement
      });
      
      if (mounted) {
        NotificationService.success('Personnage sauvegardé avec succès');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error('Erreur lors de la sauvegarde: $e');
      }
    }
  }

  Future<void> _confirmDeletePersonnage(Map<String, dynamic> personnage) async {
    final document = personnage['document'] as Map<String, dynamic>? ?? {};
    final nom = document['nom'] as String? ?? 'Sans nom';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le personnage'),
        content: Text(
          'Voulez-vous vraiment supprimer "$nom" de cette campagne ?\n\n'
          'Si ce personnage n\'est lié à aucune autre campagne, '
          'il sera définitivement supprimé de la base de données.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deletePersonnage();
    }
  }

  Future<void> _deletePersonnage() async {
    try {
      final firestore = ref.read(firestoreServiceProvider);
      
      // Récupérer le personnage complet
      final personnageData = await firestore.getDocument(
        collection: 'personnages',
        documentId: widget.personnageId,
      );
      
      if (personnageData == null) {
        throw Exception('Personnage introuvable');
      }
      
      // Récupérer la liste des campagnes
      final campagnesIds = personnageData['campagnes_ids'] as List<dynamic>? ?? [];
      
      // Retirer la campagne actuelle
      final updatedCampagnes = campagnesIds.where((id) => id != widget.campagneId).toList();
      
      if (updatedCampagnes.isEmpty) {
        // Plus aucune campagne : supprimer le personnage de Firestore
        await firestore.deleteDocument(
          collection: 'personnages',
          documentId: widget.personnageId,
        );
        
        // Supprimer l'avatar associé de Firebase Storage
        try {
          final storageService = FirebaseStorageService.instance;
          await storageService.deleteAvatar(widget.personnageId);
        } catch (e) {
          // Ignorer si l'avatar n'existe pas
          _logger.w('⚠️ Avatar non supprimé (peut-être inexistant): $e');
        }
        
        if (mounted) {
          NotificationService.success('Personnage supprimé définitivement');
        }
      } else {
        // Il reste des campagnes : mettre à jour la liste
        await firestore.updateDocument(
          collection: 'personnages',
          documentId: widget.personnageId,
          data: {'campagnes_ids': updatedCampagnes},
        );
        
        if (mounted) {
          NotificationService.success('Personnage retiré de la campagne');
        }
      }
      
      // Invalider les providers et retourner à l'écran précédent
      ref.invalidate(personnagesCampagneProvider(widget.campagneId));
      ref.invalidate(personnageProvider(widget.personnageId));
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error('Erreur lors de la suppression: $e');
      }
    }
  }

  /// Importer le personnage dans une autre campagne
  Future<void> _importPersonnageToOtherCampagne(Map<String, dynamic> personnage) async {
    try {
      final firestore = ref.read(firestoreServiceProvider);
      final authService = ref.read(firebaseAuthServiceProvider);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) {
        NotificationService.error('Utilisateur non connecté');
        return;
      }

      // Vérifier si le personnage provient d'une campagne publique
      final personnageCampagnes = List<String>.from(personnage['campagnes_ids'] ?? []);
      for (final campagneId in personnageCampagnes) {
        final campagne = await firestore.getDocument(
          collection: 'campagnes',
          documentId: campagneId,
        );
        
        if (campagne != null) {
          final isPublic = campagne['isPublic'] as bool? ?? false;
          final createur = campagne['createur'] as String? ?? campagne['uid'] as String?;
          
          // Bloquer si campagne publique et utilisateur n'est pas le créateur
          if (isPublic && createur != null && createur != userId) {
            NotificationService.error(
              'Impossible d\'importer un personnage d\'une campagne publique dont vous n\'êtes pas le créateur'
            );
            return;
          }
        }
      }
      
      // Récupérer les campagnes du MJ (pas celles où il est PJ)
      final userDoc = await firestore.getDocument(
        collection: 'users',
        documentId: userId,
      );
      
      if (userDoc == null) {
        NotificationService.error('Utilisateur introuvable');
        return;
      }
      
      // Récupérer les campagnes où l'utilisateur est MJ
      final roles = userDoc['roles'] as Map<String, dynamic>? ?? {};
      final campagnesRoles = roles['campagnes'] as Map<String, dynamic>? ?? {};
      final campagnesMJIds = campagnesRoles.entries
          .where((entry) => entry.value == 'MJ')
          .map((entry) => entry.key)
          .toList();
      
      if (campagnesMJIds.isEmpty) {
        NotificationService.error('Vous n\'êtes MJ d\'aucune campagne');
        return;
      }
      
      // Filtrer les campagnes où le personnage n'est pas encore (réutiliser personnageCampagnes)
      final availableCampagnes = <Map<String, dynamic>>[];
      for (final campagneId in campagnesMJIds) {
        if (!personnageCampagnes.contains(campagneId)) {
          final campagne = await firestore.getDocument(
            collection: 'campagnes',
            documentId: campagneId,
          );
          if (campagne != null) {
            final isPublicTarget = campagne['isPublic'] as bool? ?? false;
            if (!isPublicTarget) {
              availableCampagnes.add({
                'id': campagneId,
                'nom': campagne['nom'] as String? ?? 'Campagne sans nom',
              });
            }
          }
        }
      }
      
      if (availableCampagnes.isEmpty) {
        if (mounted) {
          NotificationService.info('Aucune campagne privée disponible pour l\'import');
        }
        return;
      }
      
      // Afficher un dialogue pour choisir la campagne
      final selectedCampagneId = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Importer dans une campagne'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableCampagnes.map((campagne) {
              return ListTile(
                leading: const Icon(Icons.castle),
                title: Text(campagne['nom'] as String),
                onTap: () => Navigator.pop(context, campagne['id'] as String),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );
      
      if (selectedCampagneId == null) return;
      
      // Ajouter la campagne à la liste des campagnes du personnage
      final updatedCampagnes = [...personnageCampagnes, selectedCampagneId];
      await firestore.updateDocument(
        collection: 'personnages',
        documentId: widget.personnageId,
        data: {'campagnes_ids': updatedCampagnes},
      );
      
      // Invalider les caches
      ref.invalidate(personnagesCampagneProvider(selectedCampagneId));
      ref.invalidate(personnageProvider(widget.personnageId));
      
      if (mounted) {
        final selectedCampagne = availableCampagnes.firstWhere(
          (c) => c['id'] == selectedCampagneId,
        );
        NotificationService.success(
          'Personnage importé dans "${selectedCampagne['nom']}"',
        );
      }
    } catch (e) {
      _logger.e('Erreur lors de l\'importation: $e');
      if (mounted) {
        NotificationService.error('Erreur lors de l\'importation: $e');
      }
    }
  }
}








