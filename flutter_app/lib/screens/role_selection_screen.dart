import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/firebase_auth_service.dart';
import 'campagnes_list_screen.dart';
import 'firebase_login_screen.dart';
import 'account_settings_screen.dart';
import 'player_campagnes_screen.dart';

/// Écran de sélection du rôle (MJ ou Joueur)
class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. BACKGROUND IMAGE
          Image.asset(
            'assets/images/backgrounds/welcome_bg_free.png',
            fit: BoxFit.cover,
          ),
          // 3. UI CONTENT
          SafeArea(
            child: Column(
              children: [
                // Header avec logout
                _buildHeader(context, ref),
                // Content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTitle(),
                          const SizedBox(height: 64),
                          _buildRoleCards(context),
                        ],
                      ),
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

  // Background asset is handled globally via BackgroundSetter

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Bouton Paramètres
          IconButton(
            icon: Icon(Icons.settings, color: SymbaroumTheme.gold),
            tooltip: 'Paramètres du compte',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          // Bouton Déconnexion
          IconButton(
            icon: Icon(Icons.logout, color: SymbaroumTheme.gold),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await FirebaseAuthService.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const FirebaseLoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        // Ligne décorative
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDecorativeLine(),
            const SizedBox(width: 16),
            Icon(Icons.auto_awesome, color: SymbaroumTheme.gold.withValues(alpha: 0.8), size: 24),
            const SizedBox(width: 16),
            _buildDecorativeLine(),
          ],
        ),
        const SizedBox(height: 16),

        // Titre
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'CHOISISSEZ VOTRE RÔLE',
            style: GoogleFonts.cinzel(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: SymbaroumTheme.gold,
              letterSpacing: 4,
              shadows: [
                Shadow(color: Colors.black.withValues(alpha: 0.8), offset: const Offset(2, 2), blurRadius: 4),
                Shadow(color: SymbaroumTheme.gold.withValues(alpha: 0.3), offset: const Offset(0, 0), blurRadius: 10),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Ligne décorative
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDecorativeLine(),
            const SizedBox(width: 16),
            Icon(Icons.auto_awesome, color: SymbaroumTheme.gold.withValues(alpha: 0.8), size: 24),
            const SizedBox(width: 16),
            _buildDecorativeLine(),
          ],
        ),
      ],
    );
  }

  Widget _buildDecorativeLine() {
    return Container(
      width: 60,
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            SymbaroumTheme.gold.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCards(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        children: [
          _buildRoleCard(
            context: context,
            title: 'MAÎTRE DU JEU',
            icon: Icons.castle,
            description: 'Créez et gérez vos campagnes',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CampagnesListScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildRoleCard(
            context: context,
            title: 'JOUEUR',
            icon: Icons.group,
            description: 'Rejoignez une campagne',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlayerCampagnesScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: SymbaroumTheme.darkBrown.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SymbaroumTheme.gold.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SymbaroumTheme.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: SymbaroumTheme.gold.withValues(alpha: 0.5), width: 2),
              ),
              child: Icon(
                icon,
                size: 48,
                color: SymbaroumTheme.gold,
              ),
            ),
            const SizedBox(width: 24),

            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cinzel(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: SymbaroumTheme.gold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.cinzel(
                      fontSize: 14,
                      color: SymbaroumTheme.parchment.withValues(alpha: 0.8),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            
            // Flèche
            Icon(
              Icons.arrow_forward,
              color: SymbaroumTheme.gold.withValues(alpha: 0.7),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
