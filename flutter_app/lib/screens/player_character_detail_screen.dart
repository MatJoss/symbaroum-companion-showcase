import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/firebase_providers.dart';
import 'package:logger/logger.dart';
import '../services/notification_service.dart';
import '../utils/avatar_utils.dart';
import 'player_character_detail/tabs/tabs.dart';
import '../widgets/background_setter.dart';

final _logger = Logger(printer: SimplePrinter());

/// Écran de consultation du personnage pour le joueur (lecture seule)
class PlayerCharacterDetailScreen extends ConsumerStatefulWidget {
  final String personnageId;

  const PlayerCharacterDetailScreen({
    super.key,
    required this.personnageId,
  });

  @override
  ConsumerState<PlayerCharacterDetailScreen> createState() => _PlayerCharacterDetailScreenState();
}

class _PlayerCharacterDetailScreenState extends ConsumerState<PlayerCharacterDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1); // Démarrer sur Caractéristiques
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final personnageAsync = ref.watch(personnageProvider(widget.personnageId));

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
        final avatarUrl = document['avatarUrl'] as String?;
        final niveau = document['niveau'] as int? ?? 1;
        final raceId = document['race_id']?.toString();
        final classeId = document['classe_id']?.toString();

        // Vérifier les permissions d'édition (campagnes publiques)
        final authService = ref.watch(firebaseAuthServiceProvider);
        final currentUserId = authService.currentUser?.uid;
        final campagnesIds = List<String>.from(personnage['campagnes_ids'] ?? []);
        
        bool canModify = true;
        bool canEditInventory = false;
        
        // Vérifier chaque campagne
        for (final campagneId in campagnesIds) {
          final campagneAsync = ref.watch(campagneProvider(campagneId));
          campagneAsync.whenData((campagne) {
            if (campagne != null) {
              final isPublic = campagne['isPublic'] as bool? ?? false;
              final createur = campagne['createur'] as String? ?? campagne['uid'] as String?;
              // Bloquer si campagne publique et utilisateur n'est pas le créateur
              if (isPublic && createur != null && createur != currentUserId) {
                canModify = false;
              }
              // Vérifier si la campagne autorise les joueurs à éditer l'inventaire
              final joueursEditInventaire = campagne['joueursEditInventaire'] as bool? ?? false;
              if (joueursEditInventaire) {
                canEditInventory = true;
              }
            }
          });
        }

        // En plus, si un joueur actif est défini et que ce n'est pas l'utilisateur courant, bloquer la modification
        final joueurActifId = personnage['joueur_actif_id'] as String?;
        if (joueurActifId != null && joueurActifId.isNotEmpty && joueurActifId != currentUserId) {
          canModify = false;
        }

        // Charger races et classes
        final racesAsync = ref.watch(racesProvider);
        final classesAsync = ref.watch(classesProvider);

        return Scaffold(
          body: BackgroundSetter(
            asset: 'assets/images/backgrounds/personnage_bg_free.png',
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(personnageProvider(widget.personnageId));
                await ref.read(personnageProvider(widget.personnageId).future);
                setState(() {});
              },
              child: SafeArea(
                child: racesAsync.when(
                  data: (races) => classesAsync.when(
                    data: (classes) {
                      return Column(
                        children: [
                          _buildHeader(context, personnage, document, nom, avatarUrl, niveau, raceId, classeId, racesAsync, classesAsync, canModify),
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white70,
                            tabs: const [
                              Tab(icon: Icon(Icons.auto_awesome), text: 'Compétences'),
                              Tab(icon: Icon(Icons.trending_up), text: 'Caractéristiques'),
                              Tab(icon: Icon(Icons.shopping_bag), text: 'Inventaire'),
                              Tab(icon: Icon(Icons.notes), text: 'Notes'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                PlayerCompetencesTab(personnage: personnage, document: document),
                                PlayerCaracteristiquesTab(personnageId: widget.personnageId, personnage: personnage, document: document),
                                PlayerInventaireTab(personnageId: widget.personnageId, personnage: personnage, document: document, canModify: canModify, canEditInventory: canEditInventory),
                                PlayerNotesTab(personnageId: widget.personnageId, personnage: personnage, document: document, canModify: canModify),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Erreur: $e')),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Erreur: $e')),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Map<String, dynamic> personnage,
    Map<String, dynamic> document,
    String nom,
    String? avatarUrl,
    int niveau,
    String? raceId,
    String? classeId,
    AsyncValue<List<Map<String, dynamic>>> racesAsync,
    AsyncValue<List<Map<String, dynamic>>> classesAsync,
    bool canModify,
  ) {
    // Debug info to help diagnose tap/hit testing issues
    _logger.d('Header build - canModify: $canModify, avatarUrl: ${avatarUrl ?? '<null>'} for ${widget.personnageId}');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      // No decoration: remove gradient overlay to show background image fully
      child: Row(
        children: [
          // Avatar (éditable si autorisé)
          if (canModify)
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                splashColor: Colors.yellow.withValues(alpha: 0.25),
                onTapDown: (_) => _logger.d('Avatar onTapDown for ${widget.personnageId}'),
                onTap: () {
                  _logger.d('Avatar tap detected for personnage ${widget.personnageId}');
                  _editAvatar(context, personnage);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // increase hit area more
                  child: Container(
                    decoration: kDebugMode
                        ? BoxDecoration(
                            border: Border.all(color: Colors.yellow.withValues(alpha: 0.7), width: 1),
                            borderRadius: BorderRadius.circular(40),
                          )
                        : null,
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.transparent,
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(
                              nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 32, color: Colors.white),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            )
          else
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.transparent,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(
                      nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    )
                  : null,
            ),
          const SizedBox(width: 16),
          
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom (éditable si autorisé)
                Row(
                  children: [
                    Expanded(
                      child: canModify
                          ? GestureDetector(
                              onTap: () => _editNom(context, personnage, nom),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      nom,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit, size: 16, color: Colors.white.withValues(alpha: 0.6)),
                                ],
                              ),
                            )
                          : Text(
                              nom,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Forcer le rafraîchissement des données
                        ref.invalidate(personnageProvider(widget.personnageId));
                        NotificationService.success('Données rafraîchies');
                      },
                      icon: const Icon(Icons.refresh),
                      color: Colors.white.withValues(alpha: 0.6),
                      iconSize: 20,
                      tooltip: 'Rafraîchir',
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.white.withValues(alpha: 0.6),
                      iconSize: 20,
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Race / Classe / Niveau (cliquable pour afficher détails physiques)
                GestureDetector(
                  onTap: () => _showDetailsPhysiques(context, document),
                  child: racesAsync.when(
                    data: (races) {
                      return classesAsync.when(
                        data: (classes) {
                          final race = raceId != null
                              ? races.firstWhere((r) => r['id']?.toString() == raceId,
                                  orElse: () => {})
                              : {};
                          final classe = classeId != null
                              ? classes.firstWhere((c) => c['id']?.toString() == classeId,
                                  orElse: () => {})
                              : {};
                          
                          final raceName = race['nom'] as String? ?? '?';
                          final className = classe['nom'] as String? ?? '?';
                          
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '$raceName • $className • Niveau $niveau',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withValues(alpha: 0.7),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.info_outline,
                                        size: 14,
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        loading: () => Text(
                          '? • ? • Niveau $niveau',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        error: (_, __) => Text(
                          '? • ? • Niveau $niveau',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                    loading: () => Text(
                      '? • ? • Niveau $niveau',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    error: (_, __) => Text(
                      '? • ? • Niveau $niveau',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Éditer le nom du personnage
  Future<void> _editNom(BuildContext context, Map<String, dynamic> personnage, String currentNom) async {
    final controller = TextEditingController(text: currentNom);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le nom'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentNom) {
      try {
        final firestore = ref.read(firestoreServiceProvider);
        await firestore.updateDocument(
          collection: 'personnages',
          documentId: widget.personnageId,
          data: {'document.nom': result},
        );
        ref.invalidate(personnageProvider(widget.personnageId));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  /// Éditer l'avatar du personnage
  Future<void> _editAvatar(BuildContext context, Map<String, dynamic> personnage) async {
    await AvatarUtils.editAvatar(context, ref, widget.personnageId);
  }

  /// Afficher les détails physiques du personnage
  void _showDetailsPhysiques(BuildContext context, Map<String, dynamic> document) {
    final age = document['age'] as int?;
    final taille = document['taille'] as int?;
    final poids = document['poids'] as int?;
    final couleurOmbre = document['couleur_ombre'] as String? ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails physiques'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (age != null)
                ListTile(
                  leading: const Icon(Icons.cake),
                  title: const Text('Âge'),
                  subtitle: Text('$age ans'),
                  contentPadding: EdgeInsets.zero,
                ),
              if (taille != null)
                ListTile(
                  leading: const Icon(Icons.height),
                  title: const Text('Taille'),
                  subtitle: Text('$taille cm'),
                  contentPadding: EdgeInsets.zero,
                ),
              if (poids != null)
                ListTile(
                  leading: const Icon(Icons.monitor_weight),
                  title: const Text('Poids'),
                  subtitle: Text('$poids kg'),
                  contentPadding: EdgeInsets.zero,
                ),
              if (couleurOmbre.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Couleur d\'ombre'),
                  subtitle: Text(couleurOmbre),
                  contentPadding: EdgeInsets.zero,
                ),
              if (age == null && taille == null && poids == null && couleurOmbre.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Aucune information disponible',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
