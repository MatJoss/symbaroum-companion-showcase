import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/firebase_providers.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';
import '../config/theme.dart';
import '../widgets/reference_book_widget.dart';
import '../widgets/equipment_reference_widget.dart';
import 'personnage_detail_screen.dart';
import 'qr_code_display_screen.dart';
import 'edit_campagne_screen.dart';

/// Écran de détail d'une campagne avec gestion des personnages
class CampagneDetailScreen extends ConsumerWidget {
  final String campagneId;
  final String campagneNom;

  const CampagneDetailScreen({
    super.key,
    required this.campagneId,
    required this.campagneNom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campagneAsync = ref.watch(campagneProvider(campagneId));
    final personnagesAsync = ref.watch(personnagesCampagneProvider(campagneId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          campagneNom,
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditCampagneScreen(campagneId: campagneId),
                ),
              );
              
              if (result == true) {
                // Rafraîchir les données si modifications
                ref.invalidate(campagneProvider(campagneId));
              }
            },
            tooltip: 'Éditer la campagne',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            onPressed: () async {
              var invitationToken = campagneAsync.value?['invitationToken'] as String?;
              
              // Générer et sauvegarder un token si absent ou vide
              if (invitationToken == null || invitationToken.isEmpty) {
                const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
                final random = Random.secure();
                invitationToken = List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
                
                try {
                  // Mettre à jour le token dans Firestore
                  await FirestoreService.instance.updateDocument(
                    collection: 'campagnes',
                    documentId: campagneId,
                    data: {'invitationToken': invitationToken},
                  );
                  
                  // Invalider le cache pour recharger avec le nouveau token
                  ref.invalidate(campagneProvider(campagneId));
                  
                  NotificationService.success('Code d\'invitation généré');
                } catch (e) {
                  NotificationService.error('Erreur lors de la génération du code');
                  return;
                }
              }
              
              if (!context.mounted) return;
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRCodeDisplayScreen(
                    campagneId: campagneId,
                    campagneNom: campagneNom,
                    invitationToken: invitationToken!,
                  ),
                ),
              );
            },
            tooltip: 'Code d\'invitation',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. BACKGROUND IMAGE
          Image.asset(
            'assets/images/backgrounds/qr_display_bg_free.png',
            fit: BoxFit.cover,
          ),
          // 2. OVERLAY
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
          // 3. UI CONTENT
          SafeArea(
            child: campagneAsync.when(
              data: (campagne) {
                if (campagne == null) {
                  return const Center(child: Text('Campagne introuvable'));
                }

                return Column(
                  children: [
                    // En-tête avec infos campagne
                    _buildCampagneHeader(campagne),

                    const Divider(),

                    // Liste des personnages
                    Expanded(
                      child: personnagesAsync.when(
                        data: (personnages) => _buildPersonnagesList(context, ref, personnages),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text('Erreur: $error'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => ref.invalidate(personnagesCampagneProvider(campagneId)),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
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
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'import',
            onPressed: () => _importPersonnageToCampagne(context, ref, campagneId),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.file_download),
            label: Text('Importer', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: () => _navigateToCreatePersonnage(context, ref),
            backgroundColor: SymbaroumTheme.gold,
            foregroundColor: SymbaroumTheme.darkBrown,
            icon: const Icon(Icons.person_add),
            label: Text('Nouveau', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCampagneHeader(Map<String, dynamic> campagne) {
    final description = campagne['description'] as String? ?? '';
    final isPublic = campagne['isPublic'] as bool? ?? false;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SymbaroumTheme.darkBrown.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SymbaroumTheme.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.castle, size: 32, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campagne['nom'] ?? 'Sans nom',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isPublic)
                      Row(
                        children: const [
                          Icon(Icons.public, size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Campagne publique',
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SymbaroumTheme.darkBrown.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                description,
                style: TextStyle(color: SymbaroumTheme.parchment.withValues(alpha: 0.9)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonnagesList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> personnages,
  ) {
    if (personnages.isEmpty) {
      return ListView(
        children: [
          // Livre de référence - toujours accessible
          const ReferenceBookWidget(),
          // Catalogue d'équipement
          const EquipmentReferenceWidget(),
          const SizedBox(height: 32),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun personnage',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Créez votre premier personnage',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Charger les races et classes une seule fois
    final racesAsync = ref.watch(racesProvider);
    final classesAsync = ref.watch(classesProvider);

    return racesAsync.when(
      data: (races) => classesAsync.when(
        data: (classes) {
          // Créer des maps pour lookup rapide
          final racesMap = {for (var r in races) r['id'] as int: r['nom'] as String};
          final classesMap = {for (var c in classes) c['id'] as int: c['nom'] as String};

          return _buildPersonnagesListContent(context, ref, personnages, racesMap, classesMap);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => _buildPersonnagesListContent(context, ref, personnages, {}, {}),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => _buildPersonnagesListContent(context, ref, personnages, {}, {}),
    );
  }

  Widget _buildPersonnagesListContent(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> personnages,
    Map<int, String> racesMap,
    Map<int, String> classesMap,
  ) {

    // Séparer PJ et PNJ (estPJ dans additionalData ou est_pj dans document)
    final pjs = personnages.where((p) {
      final estPJ = p['estPJ'] as bool?;
      if (estPJ != null) return estPJ;
      final document = p['document'] as Map<String, dynamic>?;
      return document?['est_pj'] == true;
    }).toList();
    
    final pnjs = personnages.where((p) {
      final estPJ = p['estPJ'] as bool?;
      if (estPJ != null) return !estPJ;
      final document = p['document'] as Map<String, dynamic>?;
      return document?['est_pj'] != true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(personnagesCampagneProvider(campagneId));
        // Attendre que le provider se recharge
        await ref.read(personnagesCampagneProvider(campagneId).future);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Livre de référence MJ
          const ReferenceBookWidget(),
          // Catalogue d'équipement MJ
          const EquipmentReferenceWidget(),
          const SizedBox(height: 16),
          if (pjs.isNotEmpty) ...[
            Text(
              'PERSONNAGES JOUEURS',
              style: GoogleFonts.cinzel(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: SymbaroumTheme.gold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
          ...pjs.map((p) => _buildPersonnageCard(context, ref, p, true, racesMap, classesMap)),
          const SizedBox(height: 16),
        ],
        if (pnjs.isNotEmpty) ...[
          Text(
            'PERSONNAGES NON-JOUEURS',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: SymbaroumTheme.gold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          ...pnjs.map((p) => _buildPersonnageCard(context, ref, p, false, racesMap, classesMap)),
        ],
        ],
      ),
    );
  }

  Widget _buildPersonnageCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> personnage,
    bool isPJ,
    Map<int, String> racesMap,
    Map<int, String> classesMap,
  ) {
    // Extraire les données depuis le champ 'document'
    final document = personnage['document'] as Map<String, dynamic>? ?? {};
    final nom = document['nom'] as String? ?? 'Sans nom';
    final avatarUrl = document['avatarUrl'] as String?;
    
    // Récupérer race et classe depuis les IDs
    final raceId = document['race_id'] as int?;
    final classeId = document['classe_id'] as int?;
    final niveau = document['niveau'] as int? ?? 0;
    
    final race = raceId != null ? (racesMap[raceId] ?? 'Race #$raceId') : '';
    final classe = classeId != null ? (classesMap[classeId] ?? 'Classe #$classeId') : '';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: SymbaroumTheme.darkBrown.withValues(alpha: 0.2),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonnageDetailScreen(
                personnageId: personnage['uid'] as String,
                campagneId: campagneId,
              ),
            ),
          );
          // Rafraîchir la liste après retour du détail
          ref.invalidate(personnagesCampagneProvider(campagneId));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isPJ ? Colors.blue : Colors.orange,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if ([race, classe, niveau > 0 ? 'Niv. $niveau' : ''].where((s) => s.isNotEmpty).isNotEmpty)
                      Text(
                        [race, classe, niveau > 0 ? 'Niv. $niveau' : ''].where((s) => s.isNotEmpty).join(' - '),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: SymbaroumTheme.gold.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreatePersonnage(BuildContext context, WidgetRef ref) async {
    // Dialogue simple pour le nom et type
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreatePersonnageDialog(),
    );
    
    if (result == null) return;
    
    try {
      final firestore = ref.read(firestoreServiceProvider);
      
      // Créer le personnage avec valeurs par défaut
      final personnageId = await firestore.createPersonnage(
        campagneId: campagneId,
        nom: result['nom'] as String,
        additionalData: {
          'estPJ': result['estPJ'] as bool,
          'race_id': 1,
          'classe_id': 1,
          'archetype_id': 1,
          'niveau': 1,
          'age': 25,
          'taille': 170,
          'poids': 70,
          'couleur_ombre': '',
          'notes': '',
          'argent': {
            'thalers': 5,
            'shillings': 0,
            'ortegs': 0,
          },
          'caracteristiques': {
            'force': 10,
            'agilite': 10,
            'precision': 10,
            'vigilance': 10,
            'discretion': 10,
            'astuce': 10,
            'persuasion': 10,
            'volonte': 10,
            'endurance_actuelle': 10,
            'endurance_max': 10,
            'resistance_douleur': 5,
            'seuil_corruption': 5,
            'corruption': 0,
            'corruption_permanente': 0,
            'experience': 0,
          },
          'talents': [],
          'pouvoirs': [],
          'traits': [],
          'atouts_fardeaux': [],
          'rituels': [],
          'inventaire': [],
        },
      );
      
      if (context.mounted) {
        // Ouvrir directement l'écran d'édition
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PersonnageDetailScreen(
              personnageId: personnageId,
              campagneId: campagneId,
            ),
          ),
        ).then((_) {
          ref.invalidate(personnagesCampagneProvider(campagneId));
        });
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.error('Erreur: $e');
      }
    }
  }
}

/// Dialogue de création rapide de personnage
class _CreatePersonnageDialog extends StatefulWidget {
  @override
  State<_CreatePersonnageDialog> createState() => _CreatePersonnageDialogState();
}

class _CreatePersonnageDialogState extends State<_CreatePersonnageDialog> {
  final _nomController = TextEditingController();
  bool _estPJ = true;
  
  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SymbaroumTheme.darkBrown,
      title: Text(
        'NOUVEAU PERSONNAGE',
        style: GoogleFonts.cinzel(
          color: SymbaroumTheme.gold,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomController,
              autofocus: true,
              style: GoogleFonts.crimsonText(
                color: SymbaroumTheme.parchment,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: 'Nom du personnage',
                labelStyle: GoogleFonts.cinzel(
                  color: SymbaroumTheme.gold.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.person, color: SymbaroumTheme.gold),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: SymbaroumTheme.gold),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: SymbaroumTheme.gold, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: SymbaroumTheme.gold.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: Text(
                      'Personnage Joueur (PJ)',
                      style: GoogleFonts.crimsonText(
                        color: SymbaroumTheme.parchment,
                        fontSize: 14,
                      ),
                    ),
                    value: true,
                    groupValue: _estPJ,
                    onChanged: (value) => setState(() => _estPJ = value!),
                    activeColor: SymbaroumTheme.gold,
                  ),
                  RadioListTile<bool>(
                    title: Text(
                      'Personnage Non-Joueur (PNJ)',
                      style: GoogleFonts.crimsonText(
                        color: SymbaroumTheme.parchment,
                        fontSize: 14,
                      ),
                    ),
                    value: false,
                    groupValue: _estPJ,
                    onChanged: (value) => setState(() => _estPJ = value!),
                    activeColor: SymbaroumTheme.gold,
                  ),
                ],
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
              color: SymbaroumTheme.parchment.withValues(alpha: 0.7),
              letterSpacing: 1,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nomController.text.trim().isEmpty) {
              NotificationService.error('Le nom est requis');
              return;
            }
            Navigator.pop(context, {
              'nom': _nomController.text.trim(),
              'estPJ': _estPJ,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: SymbaroumTheme.gold,
            foregroundColor: SymbaroumTheme.darkBrown,
          ),
          child: Text(
            'CRÉER',
            style: GoogleFonts.cinzel(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// Importer un personnage existant dans une campagne
Future<void> _importPersonnageToCampagne(BuildContext context, WidgetRef ref, String campagneId) async {
    try {
      final firestore = ref.read(firestoreServiceProvider);
      final authService = ref.read(firebaseAuthServiceProvider);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) {
        NotificationService.error('Utilisateur non connecté');
        return;
      }
      
      // Récupérer tous les personnages de l'utilisateur (via toutes ses campagnes)
      final userDoc = await firestore.getDocument(
        collection: 'users',
        documentId: userId,
      );
      
      if (userDoc == null) {
        NotificationService.error('Utilisateur introuvable');
        return;
      }
      
      // Récupérer les IDs de toutes les campagnes où l'utilisateur est MJ
      final roles = userDoc['roles'] as Map<String, dynamic>? ?? {};
      final campagnesRoles = roles['campagnes'] as Map<String, dynamic>? ?? {};
      final allCampagnesIds = campagnesRoles.keys.toList();
      
      if (allCampagnesIds.isEmpty) {
        NotificationService.error('Vous n\'avez aucune campagne');
        return;
      }
      
      // Récupérer tous les personnages de ces campagnes (sans filtre)
      final allPersonnages = <Map<String, dynamic>>[];
      final seenPersonnageIds = <String>{};
      
      for (final otherCampagneId in allCampagnesIds) {
        final personnages = await firestore.queryCollectionArrayContains(
          collection: 'personnages',
          field: 'campagnes_ids',
          value: otherCampagneId,
        );
        
        for (final personnage in personnages) {
          final personnageId = personnage['uid'] as String?;
          // Ajouter uniquement si pas déjà vu (éviter doublons)
          if (personnageId != null && !seenPersonnageIds.contains(personnageId)) {
            seenPersonnageIds.add(personnageId);
            allPersonnages.add(personnage);
          }
        }
      }
      
      // Filtrer: ne garder que ceux qui NE sont PAS dans la campagne cible
      final availablePersonnages = allPersonnages.where((personnage) {
        final campagnesIds = List<String>.from(personnage['campagnes_ids'] ?? []);
        return !campagnesIds.contains(campagneId); // campagneId = campagne cible où on veut importer
      }).toList();
      
      if (availablePersonnages.isEmpty) {
        if (context.mounted) {
          NotificationService.info('Aucun personnage disponible pour l\'importation');
        }
        return;
      }
      
      // Afficher un dialogue pour choisir le personnage
      final selectedPersonnageId = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Importer un personnage'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availablePersonnages.length,
              itemBuilder: (context, index) {
                final personnage = availablePersonnages[index];
                final document = personnage['document'] as Map<String, dynamic>? ?? {};
                final nom = document['nom'] as String? ?? 'Sans nom';
                final avatarUrl = document['avatarUrl'] as String?;
                final estPJ = personnage['estPJ'] as bool? ?? true;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: estPJ ? Colors.blue : Colors.orange,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Text(nom.isNotEmpty ? nom[0].toUpperCase() : '?')
                        : null,
                  ),
                  title: Text(nom),
                  subtitle: Text(estPJ ? 'Personnage Joueur' : 'PNJ'),
                  onTap: () => Navigator.pop(context, personnage['uid'] as String),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );
      
      if (selectedPersonnageId == null) return;
      
      // Récupérer le personnage complet
      final personnage = await firestore.getDocument(
        collection: 'personnages',
        documentId: selectedPersonnageId,
      );
      
      if (personnage == null) {
        NotificationService.error('Personnage introuvable');
        return;
      }
      
      // Ajouter cette campagne à la liste des campagnes du personnage
      final campagnesIds = List<String>.from(personnage['campagnes_ids'] ?? []);
      if (!campagnesIds.contains(campagneId)) {
        campagnesIds.add(campagneId);
        
        await firestore.updateDocument(
          collection: 'personnages',
          documentId: selectedPersonnageId,
          data: {'campagnes_ids': campagnesIds},
        );
        
        // Invalider les caches
        ref.invalidate(personnagesCampagneProvider(campagneId));
        ref.invalidate(personnageProvider(selectedPersonnageId));
        
        if (context.mounted) {
          final document = personnage['document'] as Map<String, dynamic>? ?? {};
          final nom = document['nom'] as String? ?? 'Sans nom';
          NotificationService.success('$nom importé dans la campagne');
        }
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.error('Erreur lors de l\'importation: $e');
      }
    }
  }
