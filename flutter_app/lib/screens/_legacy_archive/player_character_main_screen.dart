import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../services/firestore_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/notification_service.dart';

/// LEGACY - À décommissionner : Écran principal du personnage pour le joueur (style MMORPG)
/// Cet écran n'est plus utilisé pour la navigation après création de personnage.
/// Utiliser PlayerCharacterDetailScreen à la place.
@deprecated
class PlayerCharacterMainScreen extends ConsumerStatefulWidget {
  final String personnageId;
  final String campagneId;

  const PlayerCharacterMainScreen({
    super.key,
    required this.personnageId,
    required this.campagneId,
  });

  @override
  ConsumerState<PlayerCharacterMainScreen> createState() =>
      _PlayerCharacterMainScreenState();
}

class _PlayerCharacterMainScreenState
    extends ConsumerState<PlayerCharacterMainScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestore = FirestoreService.instance;
  final FirebaseStorageService _storage = FirebaseStorageService.instance;
  final ImagePicker _imagePicker = ImagePicker();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Change avatar - Player can change their character's avatar
  Future<void> _changeAvatar() async {
    try {
      // Show source selection dialog
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: SymbaroumColors.cardBackground,
          title: Text(
            'Changer l\'avatar',
            style: GoogleFonts.cinzel(color: SymbaroumColors.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: Text(
                  'Appareil photo',
                  style: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: Text(
                  'Galerie',
                  style: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Upload to Firebase Storage
      final bytes = await pickedFile.readAsBytes();
      final downloadUrl = await _storage.uploadAvatarFromBytes(
        personnageId: widget.personnageId,
        bytes: bytes,
      );

      // Update Firestore (dans document.avatarUrl comme côté MJ)
      await _firestore.updateDocument(
        collection: 'personnages',
        documentId: widget.personnageId,
        data: {'document.avatarUrl': downloadUrl},
      );

      if (!mounted) return;
      NotificationService.success('Avatar modifié avec succès');
    } catch (e) {
      if (!mounted) return;
      NotificationService.error('Erreur lors du changement d\'avatar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // LEGACY - Cet écran n'est plus utilisé. À terme, supprimer ce widget.
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                'Écran legacy non utilisé',
                style: GoogleFonts.cinzel(fontSize: 22, color: Colors.orange, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Cet écran (PlayerCharacterMainScreen) est obsolète et n\'est plus utilisé dans le flux de création ou de consultation de personnage. Utilisez PlayerCharacterDetailScreen.',
                style: GoogleFonts.lato(fontSize: 15, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    String nom,
    int niveau,
    String? avatarUrl,
    int enduranceActuelle,
    int enduranceMax,
    Map<String, dynamic>? race,
    Map<String, dynamic>? classe,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SymbaroumColors.cardBackground.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton retour
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: SymbaroumColors.textPrimary,
          ),
          const SizedBox(width: 8),

          // Avatar (tappable to change, sans indicateur photo)
          GestureDetector(
            onTap: _changeAvatar,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SymbaroumColors.primary,
                  width: 3,
                ),
                image: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Icon(
                      Icons.person,
                      size: 32,
                      color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom
                Text(
                  nom,
                  style: GoogleFonts.cinzel(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: SymbaroumColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                
                // Niveau
                Text(
                  'Niveau $niveau',
                  style: GoogleFonts.lato(
                    color: SymbaroumColors.textPrimary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Race / Classe
                Row(
                  children: [
                    if (race != null) ...[
                      Icon(Icons.group, size: 12, color: SymbaroumColors.textPrimary.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        race['nom'] as String? ?? 'Race',
                        style: GoogleFonts.lato(
                          color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (race != null && classe != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: SymbaroumColors.textPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    if (classe != null) ...[
                      Icon(Icons.school, size: 12, color: SymbaroumColors.textPrimary.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          classe['nom'] as String? ?? 'Classe',
                          style: GoogleFonts.lato(
                            color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                
                // Barre d'endurance
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 16,
                      color: Colors.red[400],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: enduranceMax > 0
                            ? (enduranceActuelle / enduranceMax).clamp(0.0, 1.0)
                            : 0.0,
                        backgroundColor: Colors.red[900]!.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.red[400]!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$enduranceActuelle/$enduranceMax',
                      style: GoogleFonts.lato(
                        color: SymbaroumColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: SymbaroumColors.cardBackground.withValues(alpha: 0.5),
      child: TabBar(
        controller: _tabController,
        indicatorColor: SymbaroumColors.primary,
        labelColor: SymbaroumColors.primary,
        unselectedLabelColor: SymbaroumColors.textPrimary.withValues(alpha: 0.6),
        labelStyle: GoogleFonts.cinzel(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        tabs: const [
          Tab(text: 'VUE', icon: Icon(Icons.person, size: 20)),
          Tab(text: 'ÉQUIP.', icon: Icon(Icons.shield, size: 20)),
          Tab(text: 'INVENT.', icon: Icon(Icons.inventory, size: 20)),
          Tab(text: 'CAPAC.', icon: Icon(Icons.auto_awesome, size: 20)),
        ],
      ),
    );
  }
}
