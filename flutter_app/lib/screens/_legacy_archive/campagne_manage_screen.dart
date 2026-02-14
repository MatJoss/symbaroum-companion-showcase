import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/widgets.dart';

/// Écran MJ - Gestion de la campagne et des personnages
class CampagneManageScreen extends ConsumerStatefulWidget {
  const CampagneManageScreen({super.key});

  @override
  ConsumerState<CampagneManageScreen> createState() => _CampagneManageScreenState();
}

class _CampagneManageScreenState extends ConsumerState<CampagneManageScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Personnage> _personnages = [];
  // TODO: implement lock tracking if needed
  List<Map<String, dynamic>> _connectedPlayers = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPersonnages();
    _loadConnectedPlayers();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  /// Charge la liste des personnages de la campagne
  Future<void> _loadPersonnages() async {
    final campagne = ref.read(currentCampagneProvider);
    if (campagne == null) {
      setState(() {
        _error = 'Aucune campagne sélectionnée';
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Use Firestore to load personnages for this campaign (legacy ApiService removed)
      final firestore = ref.read(firestoreServiceProvider);
      final docs = await firestore.queryCollectionArrayContains(
        collection: 'personnages',
        field: 'campagnes_ids',
        value: campagne['id'].toString(),
      );

      final personnages = docs.map((d) => Personnage.fromJson(d)).toList();

      setState(() {
        _personnages = personnages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }
  
  /// Charge la liste des joueurs connectés (TODO: implémenter avec SSE/WebSocket)
  Future<void> _loadConnectedPlayers() async {
    // Pour l'instant, on simule des données
    // TODO: Implémenter la récupération réelle via SSE
    setState(() {
      _connectedPlayers = [];
    });
  }
  
  /// Crée un nouveau personnage
  Future<void> _createPersonnage() async {
    final campagne = ref.read(currentCampagneProvider);
    if (campagne == null) return;
    
    final nameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => ParchmentDialog(
        title: 'Nouveau Personnage',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nom du personnage:',
              style: GoogleFonts.lora(
                color: SymbaroumTheme.parchment.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              style: GoogleFonts.lora(color: SymbaroumTheme.parchment),
              decoration: InputDecoration(
                hintText: 'Ex: Alaric le Brave',
                hintStyle: GoogleFonts.lora(
                  color: SymbaroumTheme.parchment.withValues(alpha: 0.4),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: SymbaroumTheme.gold.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: SymbaroumTheme.gold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.cinzel(color: SymbaroumTheme.parchment),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context, nameController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SymbaroumTheme.gold,
            ),
            child: Text(
              'Créer',
              style: GoogleFonts.cinzel(color: SymbaroumTheme.darkBrown),
            ),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);
      
        try {
        final firestore = ref.read(firestoreServiceProvider);
        await firestore.createPersonnage(campagneId: campagne['id'].toString(), nom: result);

        await _loadPersonnages();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Personnage "$result" créé avec succès!',
                style: GoogleFonts.lora(color: SymbaroumTheme.parchment),
              ),
              backgroundColor: SymbaroumTheme.forestGreen,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _error = 'Erreur lors de la création: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  /// Supprime un personnage après confirmation
  Future<void> _deletePersonnage(Personnage personnage) async {
    final confirmed = await showSymbaroumConfirm(
      context,
      title: 'Supprimer le personnage?',
      message: 'Cette action est irréversible.',
    );
    
    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        // TODO: Implémenter deletePersonnage dans l'API service
        // final apiService = ref.read(apiServiceProvider);
        // await apiService.deletePersonnage(personnage.id);
        
        // Pour l'instant, on ne fait rien et on affiche un message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Suppression à implémenter',
                style: GoogleFonts.lora(color: SymbaroumTheme.parchment),
              ),
              backgroundColor: SymbaroumTheme.bloodRed,
            ),
          );
        }
        
        setState(() => _isLoading = false);
      } catch (e) {
        setState(() {
          _error = 'Erreur lors de la suppression: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  /// Applique un repos à tous les PJ de la campagne
  /// Réinitialise la corruption temporaire à 0 et l'endurance à son maximum
  Future<void> _appliquerRepos() async {
    final campagne = ref.read(currentCampagneProvider);
    if (campagne == null) return;
    
    final confirmed = await showSymbaroumConfirm(
      context,
      title: 'Appliquer un repos?',
      message: 'Tous les PJ de la campagne retrouveront leur endurance maximale et perdront leur corruption temporaire.',
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Not implemented: appliquerRepos was part of the legacy ApiService
      NotificationService.info('Appliquer un repos n\'est pas implémenté dans la version Firestore.');
      // Recharger la liste des personnages
      await _loadPersonnages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'application du repos: $e',
              style: GoogleFonts.lora(color: SymbaroumTheme.parchment),
            ),
            backgroundColor: SymbaroumTheme.bloodRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      setState(() {
        _error = 'Erreur lors de l\'application du repos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final campagne = ref.watch(currentCampagneProvider);
    final Campagne? selectedCampagne = campagne != null ? Campagne.fromJson(campagne) : null;
    
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SymbaroumTheme.darkBrown,
                  const Color(0xFF1A0F0A),
                ],
              ),
            ),
            child: Image.asset(
              'assets/images/backgrounds/campagne_list_bg_free.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
          
          // Overlay léger
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          
          // Contenu
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(selectedCampagne),
                
                // Tabs
                _buildTabBar(),
                
                // Contenu des tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPersonnagesTab(),
                      _buildPlayersTab(),
                      _buildChatTab(),
                      _buildQRTab(selectedCampagne),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // FAB pour créer un personnage (seulement sur l'onglet personnages)
      floatingActionButton: _tabController.index == 0
        ? FloatingActionButton.extended(
            onPressed: _createPersonnage,
            backgroundColor: SymbaroumTheme.gold,
            icon: Icon(Icons.person_add, color: SymbaroumTheme.darkBrown),
            label: Text(
              'Nouveau',
              style: GoogleFonts.cinzel(
                color: SymbaroumTheme.darkBrown,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : null,
    );
  }
  
  Widget _buildHeader(Campagne? campagne) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Bouton retour
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: SymbaroumTheme.parchment,
          ),
          
          const SizedBox(width: 8),
          
          // Titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion MJ',
                  style: GoogleFonts.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: SymbaroumTheme.gold,
                  ),
                ),
                if (campagne != null)
                  Text(
                    campagne.nom,
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      color: SymbaroumTheme.parchment.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          
          // Bouton refresh
          IconButton(
            onPressed: _loadPersonnages,
            icon: const Icon(Icons.refresh),
            color: SymbaroumTheme.gold,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: SymbaroumTheme.gold.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: SymbaroumTheme.gold,
        unselectedLabelColor: SymbaroumTheme.parchment.withOpacity(0.6),
        indicatorColor: SymbaroumTheme.gold,
        labelStyle: GoogleFonts.cinzel(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.cinzel(
          fontSize: 12,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.people, size: 20), text: 'Personnages'),
          Tab(icon: Icon(Icons.person, size: 20), text: 'Joueurs'),
          Tab(icon: Icon(Icons.chat, size: 20), text: 'Chat'),
          Tab(icon: Icon(Icons.qr_code, size: 20), text: 'QR Code'),
        ],
      ),
    );
  }
  
  Widget _buildPersonnagesTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(SymbaroumTheme.gold),
        ),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: SymbaroumTheme.bloodRed.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.lora(
                color: SymbaroumTheme.parchment,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPersonnages,
              style: ElevatedButton.styleFrom(
                backgroundColor: SymbaroumTheme.gold,
              ),
              child: Text(
                'Réessayer',
                style: GoogleFonts.cinzel(color: SymbaroumTheme.darkBrown),
              ),
            ),
          ],
        ),
      );
    }
    
    if (_personnages.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 32),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: SymbaroumTheme.parchment.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun personnage dans cette campagne',
                  style: GoogleFonts.lora(
                    color: SymbaroumTheme.parchment.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez un premier personnage avec le bouton +',
                  style: GoogleFonts.lora(
                    color: SymbaroumTheme.parchment.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // Titre section personnages
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.people, color: SymbaroumTheme.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'PERSONNAGES JOUEURS',
                style: GoogleFonts.cinzel(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: SymbaroumTheme.gold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: SymbaroumTheme.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_personnages.length}',
                  style: GoogleFonts.cinzel(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: SymbaroumTheme.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Liste des personnages
        ...List.generate(_personnages.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPersonnageCard(_personnages[index]),
          );
        }),
      ],
    );
  }
  
  Widget _buildPersonnageCard(Personnage personnage) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: SymbaroumTheme.darkBrown.withOpacity(0.8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: SymbaroumTheme.gold.withOpacity(0.2),
          child: Icon(
            Icons.person,
            color: SymbaroumTheme.gold,
          ),
        ),
        title: Text(
          personnage.nom,
          style: GoogleFonts.cinzel(
            color: SymbaroumTheme.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: personnage.race != null
          ? Text(
              personnage.race?.nom ?? '',
              style: GoogleFonts.lora(
                color: SymbaroumTheme.parchment.withOpacity(0.7),
              ),
            )
          : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: SymbaroumTheme.gold),
              onPressed: () {
                // Editing a personnage from this screen is not yet implemented.
                NotificationService.info('Édition de personnage non disponible ici.');
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: SymbaroumTheme.bloodRed),
              onPressed: () => _deletePersonnage(personnage),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlayersTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(SymbaroumTheme.gold),
        ),
      );
    }
    
    // Compter les joueurs actifs (connectés ET avec un personnage PJ)
    final nbActivePlayersWithPJ = _connectedPlayers.where((p) {
      final personnageId = p['personnage_id'] as int?;
      if (personnageId == null) return false;
      // Vérifier que c'est un PJ
      try {
        final perso = _personnages.firstWhere((pers) => pers.id == personnageId);
        return perso.estPj;
      } catch (e) {
        return false;
      }
    }).length;
    
    return Column(
      children: [
        // Bouton REPOS (uniquement si il y a des joueurs actifs avec PJ)
        if (nbActivePlayersWithPJ > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _appliquerRepos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SymbaroumTheme.forestGreen,
                  foregroundColor: SymbaroumTheme.parchment,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.hotel),
                label: Text(
                  'REPOS ($nbActivePlayersWithPJ joueur${nbActivePlayersWithPJ > 1 ? 's' : ''})',
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        
        // Liste des joueurs connectés
        Expanded(
          child: _connectedPlayers.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: SymbaroumTheme.parchment.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun joueur connecté',
                      style: GoogleFonts.lora(
                        color: SymbaroumTheme.parchment.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les joueurs apparaîtront ici quand ils scannent le QR Code',
                      style: GoogleFonts.lora(
                        color: SymbaroumTheme.parchment.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _connectedPlayers.length,
                itemBuilder: (context, index) {
                  final player = _connectedPlayers[index];
                  return _buildPlayerCard(player);
                },
              ),
        ),
      ],
    );
  }
  
  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final personnageId = player['personnage_id'] as int?;
    final isPlaying = personnageId != null;
    final personnage = isPlaying
        ? _personnages.firstWhere((p) => p.id == personnageId,
            orElse: () => _personnages.first)
        : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: SymbaroumTheme.darkBrown.withOpacity(0.8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: SymbaroumTheme.gold.withOpacity(0.2),
              child: Icon(
                isPlaying ? Icons.person : Icons.person_outline,
                color: SymbaroumTheme.gold,
              ),
            ),
            if (isPlaying)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: SymbaroumTheme.forestGreen,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SymbaroumTheme.darkBrown,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          isPlaying && personnage != null
              ? personnage.nom
              : 'Joueur non assigné',
          style: GoogleFonts.cinzel(
            color: SymbaroumTheme.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: isPlaying && personnage != null
            ? Row(
                children: [
                  Icon(
                    Icons.lock,
                    size: 14,
                    color: SymbaroumTheme.gold.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Fiche verrouillée',
                    style: GoogleFonts.lora(
                      color: SymbaroumTheme.parchment.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Text(
                'En attente de sélection',
                style: GoogleFonts.lora(
                  color: SymbaroumTheme.parchment.withOpacity(0.5),
                ),
              ),
      ),
    );
  }
  
  Widget _buildChatTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: SymbaroumTheme.parchment.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chat MJ',
                    style: GoogleFonts.cinzel(
                      color: SymbaroumTheme.gold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fonctionnalité à venir',
                    style: GoogleFonts.lora(
                      color: SymbaroumTheme.parchment.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SymbaroumTheme.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: SymbaroumTheme.gold.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Prochaines fonctionnalités :',
                          style: GoogleFonts.cinzel(
                            color: SymbaroumTheme.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Messages broadcast à tous les joueurs\n'
                          '• Messages privés individuels\n'
                          '• Notifications en temps réel\n'
                          '• Historique des conversations',
                          style: GoogleFonts.lora(
                            color: SymbaroumTheme.parchment.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQRTab(Campagne? campagne) {
    if (campagne == null) {
      return Center(
        child: Text(
          'Aucune campagne sélectionnée',
          style: GoogleFonts.lora(
            color: SymbaroumTheme.parchment,
            fontSize: 16,
          ),
        ),
      );
    }
    
    return FutureBuilder<String?>(
      future: StorageService.instance.getToken(campagne.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(SymbaroumTheme.gold),
            ),
          );
        }
        
        final mjToken = snapshot.data;
        
        // Générer le contenu QR avec toutes les infos nécessaires incluant le token MJ
        final qrData = {
          'server': {
            'host': AppConfig.serverHost,
            'port': AppConfig.serverPort,
            'https': AppConfig.useHttps,
          },
          'campagne': {
            'id': campagne.id,
            'nom': campagne.nom,
          },
          'mj_token': mjToken,  // Ajout du token MJ pour accès direct
          'version': '2.0',
        };
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'QR Code de la Campagne',
                style: GoogleFonts.cinzel(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: SymbaroumTheme.gold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                campagne.nom,
                style: GoogleFonts.lora(
                  fontSize: 18,
                  color: SymbaroumTheme.parchment,
                ),
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: jsonEncode(qrData),
                  version: QrVersions.auto,
                  size: 250,
                ),
              ),
              
              const SizedBox(height: 32),
              Text(
                'Les joueurs peuvent scanner ce QR Code\npour rejoindre la campagne',
                style: GoogleFonts.lora(
                  fontSize: 14,
                  color: SymbaroumTheme.parchment.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _shareQRCode(campagne, mjToken),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SymbaroumTheme.gold,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: Icon(
                      Icons.share,
                      color: SymbaroumTheme.darkBrown,
                    ),
                    label: Text(
                      'Partager',
                      style: GoogleFonts.cinzel(
                        color: SymbaroumTheme.darkBrown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _copyQRData(qrData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SymbaroumTheme.gold.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: Icon(
                      Icons.copy,
                      color: SymbaroumTheme.gold,
                    ),
                    label: Text(
                      'Copier',
                      style: GoogleFonts.cinzel(
                        color: SymbaroumTheme.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Partage le QR Code
  Future<void> _shareQRCode(Campagne campagne, String? mjToken) async {
    final qrData = {
      'server': {
        'host': AppConfig.serverHost,
        'port': AppConfig.serverPort,
        'https': AppConfig.useHttps,
      },
      'campagne': {
        'id': campagne.id,
        'nom': campagne.nom,
      },
      'mj_token': mjToken,
      'version': '2.0',
    };
    
    final text = 'Rejoignez la campagne "${campagne.nom}" !\n\n'
        'Serveur: ${AppConfig.useHttps ? "https" : "http"}://${AppConfig.serverHost}:${AppConfig.serverPort}\n'
        'Données QR Code:\n${jsonEncode(qrData)}';
    
    await Share.share(
      text,
      subject: 'Invitation Campagne Symbaroum',
    );
  }
  
  /// Copie les données du QR Code dans le presse-papiers
  Future<void> _copyQRData(Map<String, dynamic> qrData) async {
    await Clipboard.setData(
      ClipboardData(text: jsonEncode(qrData)),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Données copiées dans le presse-papiers',
            style: GoogleFonts.lora(color: SymbaroumTheme.parchment),
          ),
          backgroundColor: SymbaroumTheme.forestGreen,
        ),
      );
    }
  }
}
