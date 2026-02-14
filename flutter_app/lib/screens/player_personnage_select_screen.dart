import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../providers/firebase_providers.dart';
import '../widgets/background_setter.dart';
import 'player_character_creation_screen.dart';
import 'player_character_detail_screen.dart';

/// Écran de sélection de personnage pour un joueur
/// Affiche les PJ disponibles (sans joueur actif) et les PJ déjà liés au joueur
class PlayerPersonnageSelectScreen extends ConsumerStatefulWidget {
  final String campagneId;
  final String campagneNom;

  const PlayerPersonnageSelectScreen({
    super.key,
    required this.campagneId,
    required this.campagneNom,
  });

  @override
  ConsumerState<PlayerPersonnageSelectScreen> createState() =>
      _PlayerPersonnageSelectScreenState();
}

class _PlayerPersonnageSelectScreenState
    extends ConsumerState<PlayerPersonnageSelectScreen> {
  final FirestoreService _firestore = FirestoreService.instance;
  final FirebaseAuthService _auth = FirebaseAuthService.instance;

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUserId;
    final campagneAsync = ref.watch(campagneProvider(widget.campagneId));
    bool isPublic = false;
    bool isMJ = false;
    
    campagneAsync.whenData((campagne) {
      if (campagne != null) {
        isPublic = campagne['isPublic'] as bool? ?? false;
        final createur = campagne['createur'] as String?;
        // Vérifier si l'utilisateur est le créateur/MJ de la campagne
        isMJ = createur == userId;
      }
    });

    if (userId == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Erreur: Non connecté',
            style: GoogleFonts.cinzel(color: Colors.red),
          ),
        ),
      );
    }

    // Affichage du background full-width via Stack dans le Scaffold
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showCampagneDetails(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.campagneNom,
                  style: GoogleFonts.cinzel(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.info_outline,
                size: 18,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Bouton pour quitter la campagne (seulement si privée ET que l'utilisateur n'est PAS le MJ)
          if (!isPublic && !isMJ)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => _showLeaveCampagneDialog(context),
              tooltip: 'Quitter la campagne',
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. BACKGROUND IMAGE
          Image.asset(
            'assets/images/backgrounds/personnage_bg_free.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // 2. OVERLAY
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.25),
                ],
              ),
            ),
          ),
          // 3. UI CONTENT
          SafeArea(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: isPublic
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'import',
                  onPressed: _importPersonnage,
                  backgroundColor: SymbaroumColors.primary.withValues(alpha: 0.85),
                  icon: const Icon(Icons.file_download, color: Colors.black),
                  label: Text(
                    'IMPORTER',
                    style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'create',
                  onPressed: _createNewPersonnage,
                  backgroundColor: SymbaroumColors.primary,
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: Text(
                    'CRÉER',
                    style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildContent() {
    final userId = _auth.currentUserId;
    if (userId == null) return const SizedBox();

    // Charger races et classes (comme côté MJ)
    final racesAsync = ref.watch(racesProvider);
    final classesAsync = ref.watch(classesProvider);

    return racesAsync.when(
      data: (races) => classesAsync.when(
        data: (classes) {
          // Créer des maps pour lookup rapide
          final racesMap = {for (var r in races) r['id'] as int: r['nom'] as String};
          final classesMap = {for (var c in classes) c['id'] as int: c['nom'] as String};

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('personnages')
                .where('campagnes_ids', arrayContains: widget.campagneId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur: ${snapshot.error}',
                    style: GoogleFonts.cinzel(color: Colors.red),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              
              // Séparer les personnages en deux catégories
              final mesPersonnages = <QueryDocumentSnapshot>[];
              final personnagesDispo = <QueryDocumentSnapshot>[];

              for (final doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final estPj = data['estPJ'] as bool? ?? false;
                
                // FILTRER : Afficher uniquement les PJ (estPJ == true)
                if (!estPj) {
                  continue;
                }
                
                final joueurActifId = data['joueur_actif_id'] as String?;

                if (joueurActifId == userId) {
                  // Mes personnages (que j'ai lockés)
                  mesPersonnages.add(doc);
                } else {
                  // Tous les autres personnages (disponibles OU lockés par d'autres)
                  personnagesDispo.add(doc);
                }
              }

              return CustomScrollView(
                slivers: [
                  // Titre de section "Mes personnages"
                  if (mesPersonnages.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Text(
                          'MES PERSONNAGES',
                          style: GoogleFonts.cinzel(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: SymbaroumColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final doc = mesPersonnages[index];
                            return _buildPersonnageCard(
                              doc,
                              racesMap: racesMap,
                              classesMap: classesMap,
                              isOwned: true,
                            );
                          },
                          childCount: mesPersonnages.length,
                        ),
                      ),
                    ),
                  ],

                  // Titre de section "Personnages disponibles"
                  if (personnagesDispo.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Text(
                          'PERSONNAGES DISPONIBLES',
                          style: GoogleFonts.cinzel(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: SymbaroumColors.textPrimary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final doc = personnagesDispo[index];
                            return _buildPersonnageCard(
                              doc,
                              racesMap: racesMap,
                              classesMap: classesMap,
                              isOwned: false,
                            );
                          },
                          childCount: personnagesDispo.length,
                        ),
                      ),
                    ),
                  ],

                  // Message si aucun personnage
                  if (mesPersonnages.isEmpty && personnagesDispo.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 64,
                              color: SymbaroumColors.textPrimary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun personnage disponible',
                              style: GoogleFonts.cinzel(
                                fontSize: 18,
                                color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Créez-en un nouveau !',
                              style: GoogleFonts.lato(
                                color: SymbaroumColors.textPrimary.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Bouton flottant pour créer un personnage
                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text(
            'Erreur chargement classes: $e',
            style: GoogleFonts.cinzel(color: Colors.red),
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Text(
          'Erreur chargement races: $e',
          style: GoogleFonts.cinzel(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildPersonnageCard(
    QueryDocumentSnapshot doc, {
    required Map<int, String> racesMap,
    required Map<int, String> classesMap,
    required bool isOwned,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Extraire les données depuis le champ 'document' (comme côté MJ)
    final document = data['document'] as Map<String, dynamic>? ?? {};
    final nom = document['nom'] as String? ?? 'Sans nom';
    final avatarUrl = document['avatarUrl'] as String?;  // camelCase comme côté MJ
    final niveau = document['niveau'] as int? ?? 1;
    
    // Race et classe (comme côté MJ)
    final raceId = document['race_id'] as int?;
    final classeId = document['classe_id'] as int?;
    final race = raceId != null ? (racesMap[raceId] ?? 'Race #$raceId') : '';
    final classe = classeId != null ? (classesMap[classeId] ?? 'Classe #$classeId') : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: SymbaroumColors.cardBackground.withValues(alpha: isOwned ? 0.3 : 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOwned 
              ? SymbaroumColors.primary.withValues(alpha: 0.5)
              : SymbaroumColors.textPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectPersonnage(doc, isOwned: isOwned),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar circulaire (style MJ)
              CircleAvatar(
                radius: 28,
                backgroundColor: isOwned ? SymbaroumColors.primary : SymbaroumColors.textPrimary.withValues(alpha: 0.3),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                        style: GoogleFonts.cinzel(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: GoogleFonts.cinzel(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOwned ? SymbaroumColors.primary : SymbaroumColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Race / Classe / Niveau (comme côté MJ)
                    if ([race, classe, niveau > 0 ? 'Niv. $niveau' : ''].where((s) => s.isNotEmpty).isNotEmpty)
                      Text(
                        [race, classe, niveau > 0 ? 'Niv. $niveau' : ''].where((s) => s.isNotEmpty).join(' - '),
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: SymbaroumColors.textPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                    // Badge "Mon personnage"
                    if (isOwned) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: SymbaroumColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'MON PERSONNAGE',
                            style: GoogleFonts.cinzel(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: SymbaroumColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Chevron (comme côté MJ)
              Icon(
                Icons.chevron_right,
                color: SymbaroumColors.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectPersonnage(QueryDocumentSnapshot doc, {required bool isOwned}) async {
    final userId = _auth.currentUserId;
    if (userId == null) return;

    try {
      // Ne pas assigner dans les campagnes publiques
      final campagne = await _firestore.getDocument(collection: 'campagnes', documentId: widget.campagneId);
      final isPublic = campagne?['isPublic'] as bool? ?? false;

      // Si le personnage n'est pas encore possédé, on l'assigne au joueur
      if (!isOwned && !isPublic) {
        await _firestore.updateDocument(
          collection: 'personnages',
          documentId: doc.id,
          data: {'joueur_actif_id': userId},
        );
        NotificationService.success('Personnage assigné !');
      } else if (isPublic) {
        NotificationService.info('Campagne publique: personnage non assigné');
      }

      // Navigation vers l'écran de jeu
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerCharacterDetailScreen(
              personnageId: doc.id,
            ),
          ),
        );
      }
    } catch (e) {
      NotificationService.error('Erreur: $e');
    }
  }

  Future<void> _importPersonnage() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;

    try {
      // Récupérer tous les personnages créés par l'utilisateur
      final allMyPersonnages = await _firestore.getMyPersonnages();

      // Filtrer : exclure ceux déjà dans cette campagne
      final importable = allMyPersonnages.where((p) {
        final campagnesIds = List<String>.from(p['campagnes_ids'] ?? []);
        return !campagnesIds.contains(widget.campagneId);
      }).toList();

      if (!mounted) return;

      if (importable.isEmpty) {
        NotificationService.info('Aucun personnage importable. Tous vos personnages sont déjà dans cette campagne.');
        return;
      }

      // Charger races et classes pour l'affichage
      final racesAsync = await ref.read(racesProvider.future);
      final classesAsync = await ref.read(classesProvider.future);
      final racesMap = {for (var r in racesAsync) r['id'] as int: r['nom'] as String};
      final classesMap = {for (var c in classesAsync) c['id'] as int: c['nom'] as String};

      if (!mounted) return;

      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: SymbaroumColors.cardBackground,
          title: Text(
            'Importer un personnage',
            style: GoogleFonts.cinzel(
              fontWeight: FontWeight.bold,
              color: SymbaroumColors.primary,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sélectionnez un de vos personnages existants à importer dans cette campagne.',
                  style: GoogleFonts.lato(
                    color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: importable.length,
                    itemBuilder: (context, index) {
                      final perso = importable[index];
                      final doc = perso['document'] as Map<String, dynamic>? ?? {};
                      final nom = doc['nom'] as String? ?? 'Sans nom';
                      final raceId = doc['race_id'] as int?;
                      final classeId = doc['classe_id'] as int?;
                      final niveau = doc['niveau'] as int? ?? 1;
                      final race = raceId != null ? (racesMap[raceId] ?? '') : '';
                      final classe = classeId != null ? (classesMap[classeId] ?? '') : '';
                      final subtitle = [race, classe, niveau > 0 ? 'Niv. $niveau' : ''].where((s) => s.isNotEmpty).join(' - ');
                      final campagnesIds = List<String>.from(perso['campagnes_ids'] ?? []);

                      return Card(
                        color: SymbaroumColors.cardBackground.withValues(alpha: 0.3),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: SymbaroumColors.primary.withValues(alpha: 0.3),
                            child: Text(
                              nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                              style: GoogleFonts.cinzel(
                                fontWeight: FontWeight.bold,
                                color: SymbaroumColors.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            nom,
                            style: GoogleFonts.cinzel(
                              fontWeight: FontWeight.bold,
                              color: SymbaroumColors.textPrimary,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (subtitle.isNotEmpty)
                                Text(
                                  subtitle,
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: SymbaroumColors.textPrimary.withValues(alpha: 0.6),
                                  ),
                                ),
                              Text(
                                '${campagnesIds.length} campagne${campagnesIds.length > 1 ? 's' : ''}',
                                style: GoogleFonts.lato(
                                  fontSize: 11,
                                  color: SymbaroumColors.textPrimary.withValues(alpha: 0.4),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: SymbaroumColors.primary.withValues(alpha: 0.5),
                          ),
                          onTap: () => Navigator.pop(context, perso),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ANNULER',
                style: GoogleFonts.cinzel(
                  color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      );

      if (selected == null || !mounted) return;

      // Confirmer l'import
      final personnageNom = (selected['document'] as Map<String, dynamic>?)?['nom'] ?? 'ce personnage';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: SymbaroumColors.cardBackground,
          title: Text(
            'Confirmer l\'import',
            style: GoogleFonts.cinzel(
              fontWeight: FontWeight.bold,
              color: SymbaroumColors.primary,
            ),
          ),
          content: Text(
            'Importer "$personnageNom" dans "${widget.campagneNom}" ?\n\nLe MJ de cette campagne pourra gérer ce personnage.',
            style: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'ANNULER',
                style: GoogleFonts.cinzel(
                  color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: SymbaroumColors.primary,
              ),
              child: Text(
                'IMPORTER',
                style: GoogleFonts.cinzel(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      // Effectuer l'import
      final personnageId = selected['uid'] as String;
      await _firestore.importPersonnageToCampagne(
        personnageId: personnageId,
        campagneId: widget.campagneId,
      );

      // Assigner le joueur actif
      await _firestore.updateDocument(
        collection: 'personnages',
        documentId: personnageId,
        data: {'joueur_actif_id': userId},
      );

      NotificationService.success('Personnage "$personnageNom" importé avec succès !');
    } catch (e) {
      NotificationService.error('Erreur lors de l\'import: $e');
    }
  }

  Future<void> _createNewPersonnage() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;

    // Navigation vers l'écran de création
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerCharacterCreationScreen(
            campagneId: widget.campagneId,
            campagneNom: widget.campagneNom,
          ),
        ),
      );
    }
  }

  void _showLeaveCampagneDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SymbaroumColors.cardBackground,
        title: Text(
          'Quitter la campagne',
          style: GoogleFonts.cinzel(
            fontWeight: FontWeight.bold,
            color: SymbaroumColors.primary,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir quitter "${widget.campagneNom}" ?\n\nVous pourrez la rejoindre à nouveau avec le code d\'invitation.',
          style: GoogleFonts.lato(
            color: SymbaroumColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ANNULER',
              style: GoogleFonts.cinzel(
                color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _leaveCampagne();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: Text(
              'QUITTER',
              style: GoogleFonts.cinzel(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveCampagne() async {
    try {
      await _firestore.leaveCampagne(widget.campagneId);
      NotificationService.success('Vous avez quitté la campagne');
      
      if (mounted) {
        // Retour à l'écran précédent
        Navigator.pop(context);
      }
    } catch (e) {
      NotificationService.error('Erreur: $e');
    }
  }

  void _showCampagneDetails(BuildContext context) async {
    try {
      final campagne = await _firestore.getDocument(
        collection: 'campagnes',
        documentId: widget.campagneId,
      );

      if (campagne == null) {
        NotificationService.error('Impossible de charger les détails de la campagne');
        return;
      }

      final description = campagne['description'] as String? ?? '';

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: SymbaroumColors.cardBackground,
          title: Text(
            widget.campagneNom,
            style: GoogleFonts.cinzel(
              fontWeight: FontWeight.bold,
              color: SymbaroumColors.primary,
              fontSize: 20,
            ),
          ),
          content: description.isNotEmpty
              ? SingleChildScrollView(
                  child: Text(
                    description,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: SymbaroumColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: Text(
                    'Aucune description disponible',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: SymbaroumColors.textPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'FERMER',
                style: GoogleFonts.cinzel(
                  color: SymbaroumColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      NotificationService.error('Erreur: $e');
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}