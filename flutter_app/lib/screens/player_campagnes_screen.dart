import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'qr_code_scan_screen.dart';
import 'player_personnage_select_screen.dart';

/// Écran listant les campagnes où l'utilisateur est JOUEUR
class PlayerCampagnesScreen extends ConsumerStatefulWidget {
  const PlayerCampagnesScreen({super.key});

  @override
  ConsumerState<PlayerCampagnesScreen> createState() => _PlayerCampagnesScreenState();
}

class _PlayerCampagnesScreenState extends ConsumerState<PlayerCampagnesScreen> {
  List<Map<String, dynamic>> _campagnesPubliques = [];
  List<Map<String, dynamic>> _campagnesPrivees = [];
  List<Map<String, dynamic>> _campagnesMJ = [];
  bool _isLoading = true;
  bool _mjSectionExpanded = false;
  bool _publicSectionExpanded = false;
  bool _privateSectionExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadCampagnes();
  }

  Future<void> _navigateToCampagne(String campagneId, String campagneNom) async {
    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerPersonnageSelectScreen(
          campagneId: campagneId,
          campagneNom: campagneNom,
        ),
      ),
    );
    
    // Si l'utilisateur a quitté la campagne, recharger la liste
    if (shouldRefresh == true && mounted) {
      await _loadCampagnes();
    }
  }

  Future<void> _loadCampagnes() async {
    setState(() => _isLoading = true);
    try {
      // Charger les deux listes en parallèle
      final results = await Future.wait([
        FirestoreService.instance.getCampagnesAsPlayer(),
        FirestoreService.instance.getCampagnes(), // Campagnes MJ
      ]);
      
      if (mounted) {
        final campagnesJoueur = results[0];
        final campagnesMJBrut = results[1];
        
        // Séparer les campagnes publiques et privées (joueur)
        final publiques = <Map<String, dynamic>>[];
        final privees = <Map<String, dynamic>>[];
        
        for (final campagne in campagnesJoueur) {
          final isPublic = campagne['isPublic'] as bool? ?? false;
          if (isPublic) {
            publiques.add(campagne);
          } else {
            privees.add(campagne);
          }
        }
        
        // Filtrer les campagnes MJ pour exclure les campagnes publiques
        // (elles sont déjà dans la section joueur)
        final campagnesMJ = campagnesMJBrut.where((campagne) {
          final isPublic = campagne['isPublic'] as bool? ?? false;
          return !isPublic; // Garder uniquement les campagnes privées où on est MJ
        }).toList();
        
        setState(() {
          _campagnesPubliques = publiques;
          _campagnesPrivees = privees;
          _campagnesMJ = campagnesMJ;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        NotificationService.error('Erreur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Mes Campagnes',
          style: GoogleFonts.cinzel(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: SymbaroumColors.primary,
                    ),
                  )
                : (_campagnesPubliques.isEmpty && 
                   _campagnesPrivees.isEmpty && 
                   _campagnesMJ.isEmpty)
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadCampagnes,
                        color: SymbaroumColors.primary,
                        child: _buildCampagnesList(),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRCodeScanScreen()),
          ).then((_) => _loadCampagnes());
        },
        backgroundColor: SymbaroumColors.primary,
        foregroundColor: SymbaroumColors.textDark,
        icon: Icon(Icons.qr_code_scanner, color: SymbaroumColors.textDark),
        label: Text(
          'REJOINDRE',
          style: GoogleFonts.cinzel(
            fontWeight: FontWeight.bold,
            color: SymbaroumColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SymbaroumColors.cardBackground.withValues(alpha: 0.3),
                border: Border.all(
                  color: SymbaroumColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.groups_outlined,
                size: 64,
                color: SymbaroumColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            
            // Titre
            Text(
              'AUCUNE CAMPAGNE',
              style: GoogleFonts.cinzel(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: SymbaroumColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Scannez un QR code pour rejoindre\nune campagne en tant que joueur',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            
            // Bouton
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRCodeScanScreen()),
                ).then((_) => _loadCampagnes());
              },
              icon: Icon(Icons.qr_code_scanner, color: SymbaroumColors.textDark),
              label: Text(
                'REJOINDRE UNE CAMPAGNE',
                style: GoogleFonts.cinzel(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: SymbaroumColors.textDark,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: SymbaroumColors.primary,
                foregroundColor: SymbaroumColors.textDark,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampagnesList() {
    return CustomScrollView(
      slivers: [
        // Section CAMPAGNES PRIVÉES (ouvert par défaut)
        if (_campagnesPrivees.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
                    color: SymbaroumColors.cardBackground.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SymbaroumColors.primary.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.castle,
                        color: SymbaroumColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'CAMPAGNES PRIVÉES',
                          style: GoogleFonts.cinzel(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: SymbaroumColors.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: SymbaroumColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_campagnesPrivees.length}',
                          style: GoogleFonts.cinzel(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: SymbaroumColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _privateSectionExpanded ? Icons.expand_less : Icons.expand_more,
                        color: SymbaroumColors.primary,
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
                    return _buildCampagneCard(_campagnesPrivees[index], isMJ: false);
                  },
                  childCount: _campagnesPrivees.length,
                ),
              ),
            ),
        ],
        
        // Section CAMPAGNES PUBLIQUES (fermé par défaut)
        if (_campagnesPubliques.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, _campagnesPrivees.isEmpty ? 24 : 16, 16, 8),
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
                    color: SymbaroumColors.cardBackground.withValues(alpha: 0.2),
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
                          '${_campagnesPubliques.length}',
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
                    return _buildCampagneCard(_campagnesPubliques[index], isMJ: false);
                  },
                  childCount: _campagnesPubliques.length,
                ),
              ),
            ),
        ],
        
        // Section MJ (rétractable)
        if (_campagnesMJ.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16, 
                (_campagnesPrivees.isEmpty && _campagnesPubliques.isEmpty) ? 24 : 16, 
                16, 
                8
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _mjSectionExpanded = !_mjSectionExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: SymbaroumColors.cardBackground.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.lightBlue.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Colors.lightBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'VUE MAÎTRE DU JEU',
                          style: GoogleFonts.cinzel(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlue,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_campagnesMJ.length}',
                          style: GoogleFonts.cinzel(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _mjSectionExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.lightBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Liste des campagnes MJ (si expanded)
          if (_mjSectionExpanded)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildCampagneCard(_campagnesMJ[index], isMJ: true);
                  },
                  childCount: _campagnesMJ.length,
                ),
              ),
            ),
        ],
        
        // Padding bottom pour le FAB
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  Widget _buildCampagneCard(Map<String, dynamic> campagne, {required bool isMJ}) {
    final nom = campagne['nom'] as String? ?? 'Sans nom';
    final description = campagne['description'] as String? ?? '';
    final campagneId = campagne['uid'] as String;
    final isPublic = campagne['isPublic'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: SymbaroumColors.cardBackground.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isMJ 
              ? Colors.lightBlue.withValues(alpha: 0.5)
              : isPublic
                  ? Colors.green.withValues(alpha: 0.5)
                  : SymbaroumColors.primary.withValues(alpha: 0.3),
          width: isMJ ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerPersonnageSelectScreen(
                campagneId: campagneId,
                campagneNom: nom,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône campagne
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMJ
                      ? Colors.lightBlue.withValues(alpha: 0.2)
                      : isPublic
                          ? Colors.green.withValues(alpha: 0.2)
                          : SymbaroumColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isMJ 
                      ? Icons.shield_outlined 
                      : (isPublic ? Icons.public : Icons.castle),
                  color: isMJ
                    ? Colors.lightBlue
                    : (isPublic ? Colors.green : SymbaroumColors.primary),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom + Badge MJ
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nom,
                            style: GoogleFonts.cinzel(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isMJ
                                ? Colors.lightBlue
                                : (isPublic ? Colors.green : SymbaroumColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Description
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: SymbaroumColors.textPrimary.withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Chevron
              Icon(
                Icons.chevron_right,
                color: isMJ
                  ? Colors.lightBlue.withValues(alpha: 0.5)
                  : isPublic
                      ? Colors.green.withValues(alpha: 0.5)
                      : SymbaroumColors.primary.withValues(alpha: 0.5),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}