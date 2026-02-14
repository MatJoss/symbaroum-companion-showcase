import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/firebase_providers.dart';
import '../config/theme.dart';
//import '../widgets/background_setter.dart';
import 'firebase_login_screen.dart';
import 'role_selection_screen.dart';
import 'campagne_detail_screen.dart';
import 'create_campagne_screen.dart';

/// Écran de liste des campagnes (MJ)
class CampagnesListScreen extends ConsumerStatefulWidget {
  const CampagnesListScreen({super.key});

  @override
  ConsumerState<CampagnesListScreen> createState() => _CampagnesListScreenState();
}

class _CampagnesListScreenState extends ConsumerState<CampagnesListScreen> {
  bool _publicSectionExpanded = false;
  bool _privateSectionExpanded = true;

  @override
  Widget build(BuildContext context) {
    final campagnesAsync = ref.watch(campagnesMJProvider);

    return PopScope(
      canPop: false, // Empêche le pop par défaut du bouton retour Android
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Navigue vers RoleSelectionScreen au lieu de pop
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          );
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              );
            },
          ),
          title: Text(
            'Mes Campagnes',
            style: GoogleFonts.cinzel(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  // Remplacer complètement la stack de navigation par l'écran de login
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const FirebaseLoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. BACKGROUND IMAGE
            Image.asset(
              'assets/images/backgrounds/campagne_list_bg_free.png',
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
              child: campagnesAsync.when(
                data: (campagnes) {
                  if (campagnes.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Séparer les campagnes publiques et privées
                  final campagnesPubliques = <Map<String, dynamic>>[];
                  final campagnesPrivees = <Map<String, dynamic>>[];

                  for (final campagne in campagnes) {
                    final isPublic = campagne['isPublic'] as bool? ?? false;
                    if (isPublic) {
                      campagnesPubliques.add(campagne);
                    } else {
                      campagnesPrivees.add(campagne);
                    }
                  }

                  return CustomScrollView(
                    slivers: [
                      // Section CAMPAGNES PUBLIQUES (fermé par défaut)
                      if (campagnesPubliques.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _publicSectionExpanded = !_publicSectionExpanded;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                decoration: BoxDecoration(
                                  color: SymbaroumTheme.darkBrown.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.public,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'CAMPAGNES PUBLIQUES',
                                        style: GoogleFonts.cinzel(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${campagnesPubliques.length}',
                                        style: GoogleFonts.cinzel(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      _publicSectionExpanded ? Icons.expand_less : Icons.expand_more,
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        if (_publicSectionExpanded)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _buildCampagneCard(campagnesPubliques[index]);
                                },
                                childCount: campagnesPubliques.length,
                              ),
                            ),
                          ),
                      ],

                      // Section CAMPAGNES PRIVÉES (ouvert par défaut)
                      if (campagnesPrivees.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              campagnesPubliques.isEmpty ? 24 : 16,
                              16,
                              8,
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _privateSectionExpanded = !_privateSectionExpanded;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                decoration: BoxDecoration(
                                  color: SymbaroumTheme.darkBrown.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: SymbaroumTheme.gold.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.castle,
                                      color: SymbaroumTheme.gold,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'MES CAMPAGNES PRIVÉES',
                                        style: GoogleFonts.cinzel(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: SymbaroumTheme.gold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: SymbaroumTheme.gold.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${campagnesPrivees.length}',
                                        style: GoogleFonts.cinzel(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: SymbaroumTheme.gold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      _privateSectionExpanded ? Icons.expand_less : Icons.expand_more,
                                      color: SymbaroumTheme.gold,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        if (_privateSectionExpanded)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _buildCampagneCard(campagnesPrivees[index]);
                                },
                                childCount: campagnesPrivees.length,
                              ),
                            ),
                          ),
                      ],

                      // Padding bottom pour le FAB
                      const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                    ],
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(color: SymbaroumTheme.gold),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: SymbaroumTheme.gold.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur: $error',
                        style: TextStyle(color: SymbaroumTheme.parchment),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(campagnesMJProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SymbaroumTheme.gold,
                          foregroundColor: SymbaroumTheme.darkBrown,
                        ),
                        child: Text(
                          'Réessayer',
                          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: campagnesAsync.hasValue
            ? FloatingActionButton(
                onPressed: () => _navigateToCreate(context),
                backgroundColor: SymbaroumTheme.gold,
                foregroundColor: SymbaroumTheme.darkBrown,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign, size: 64, color: SymbaroumTheme.gold.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Aucune campagne',
            style: GoogleFonts.cinzel(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: SymbaroumTheme.parchment,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première campagne',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              color: SymbaroumTheme.parchment.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreate(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: SymbaroumTheme.gold,
              foregroundColor: SymbaroumTheme.darkBrown,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: const Icon(Icons.add),
            label: Text(
              'Créer une campagne',
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampagneCard(Map<String, dynamic> campagne) {
    final campagneId = campagne['uid'] ?? campagne['id'];
    final nom = campagne['nom'] ?? 'Sans nom';
    final description = campagne['description'];
    final isPublic = campagne['isPublic'] as bool? ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: SymbaroumTheme.darkBrown.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPublic
            ? Colors.green.withValues(alpha: 0.5)
            : SymbaroumColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () {
          if (campagneId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CampagneDetailScreen(
                  campagneId: campagneId,
                  campagneNom: nom,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isPublic
                  ? Colors.green.withValues(alpha: 0.2)
                  : SymbaroumTheme.gold.withValues(alpha: 0.2),
                child: Icon(
                  isPublic ? Icons.public : Icons.castle,
                  color: isPublic ? Colors.green : SymbaroumTheme.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nom,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isPublic ? Colors.green : SymbaroumTheme.gold),
                          ),
                        ),
                        if (isPublic)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.public, size: 12, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'Publique',
                                  style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (description != null && description.isNotEmpty)
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    else
                      const Text(
                        'Aucune description',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: isPublic ? Colors.green.withValues(alpha: 0.5) : SymbaroumTheme.gold.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCampagneScreen(),
      ),
    );
  }
}