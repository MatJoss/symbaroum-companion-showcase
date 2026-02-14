import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../config/routes.dart';
import '../widgets/background_setter.dart';

/// Écran d'accueil - Choix du mode MJ ou Joueur
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    
    return BackgroundSetter(
      asset: 'assets/images/backgrounds/welcome_bg_free.png',
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient overlay (background image is handled by BackgroundSetter)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),

            // Contenu principal
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Logo / Titre
                    _buildTitle(context),

                    const Spacer(flex: 1),

                    // Sous-titre
                    _buildSubtitle(context),

                    const SizedBox(height: 48),

                    // Boutons de choix
                    _buildModeButtons(context, size),

                    const Spacer(flex: 2),

                    // Version
                    _buildVersionInfo(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Background is set via BackgroundSetter globally
  
  /// Titre principal avec style médiéval
  Widget _buildTitle(BuildContext context) {
    return Column(
      children: [
        // Décoration au-dessus
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDecorativeLine(),
            const SizedBox(width: 16),
            Icon(
              Icons.auto_awesome,
              color: SymbaroumTheme.gold.withValues(alpha: 0.8),
              size: 24,
            ),
            const SizedBox(width: 16),
            _buildDecorativeLine(),
          ],
        ),
        const SizedBox(height: 16),
        
        // Titre SYMBAROUM
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'SYMBAROUM',
            style: GoogleFonts.cinzel(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: SymbaroumTheme.gold,
              letterSpacing: 6,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
                Shadow(
                  color: SymbaroumTheme.gold.withValues(alpha: 0.3),
                  offset: const Offset(0, 0),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
        
        // Sous-titre COMPANION
        Text(
          'COMPANION',
          style: GoogleFonts.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: SymbaroumTheme.parchment.withValues(alpha: 0.9),
            letterSpacing: 12,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Décoration en dessous
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDecorativeLine(),
            const SizedBox(width: 16),
            Icon(
              Icons.auto_awesome,
              color: SymbaroumTheme.gold.withValues(alpha: 0.8),
              size: 24,
            ),
            const SizedBox(width: 16),
            _buildDecorativeLine(),
          ],
        ),
      ],
    );
  }
  
  /// Ligne décorative dorée
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
  
  /// Sous-titre explicatif
  Widget _buildSubtitle(BuildContext context) {
    return Text(
      'Gérez vos campagnes et personnages\ndans le monde de Symbaroum',
      textAlign: TextAlign.center,
      style: GoogleFonts.lora(
        fontSize: 14,
        color: SymbaroumTheme.parchment.withValues(alpha: 0.7),
        height: 1.5,
        fontStyle: FontStyle.italic,
      ),
    );
  }
  
  /// Boutons de sélection du mode
  Widget _buildModeButtons(BuildContext context, Size size) {
    return Column(
      children: [
        // Bouton Maître du Jeu
        _ModeButton(
          icon: Icons.menu_book,
          title: 'Maître du Jeu',
          subtitle: 'Créer et gérer des campagnes',
          onTap: () => _goToMJMode(context),
        ),
        
        const SizedBox(height: 16),
        
        // Bouton Joueur
        _ModeButton(
          icon: Icons.person,
          title: 'Joueur',
          subtitle: 'Rejoindre une campagne',
          onTap: () => _goToPlayerMode(context),
        ),
      ],
    );
  }
  
  /// Navigation vers le mode MJ
  void _goToMJMode(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.qrDisplay);
  }
  
  /// Navigation vers le mode Joueur
  void _goToPlayerMode(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.qrScan);
  }
  
  /// Information de version
  Widget _buildVersionInfo() {
    return Text(
      'v2.0.0 - Flutter Edition',
      style: GoogleFonts.lora(
        fontSize: 12,
        color: SymbaroumTheme.parchment.withValues(alpha: 0.4),
      ),
    );
  }
}

/// Bouton de sélection de mode stylisé
class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  
  const _ModeButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: SymbaroumTheme.gold.withValues(alpha: 0.2),
        highlightColor: SymbaroumTheme.gold.withValues(alpha: 0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: SymbaroumTheme.gold.withValues(alpha: 0.4),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SymbaroumTheme.darkBrown.withValues(alpha: 0.8),
                SymbaroumTheme.darkBrown.withValues(alpha: 0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icône
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SymbaroumTheme.gold.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  gradient: RadialGradient(
                    colors: [
                      SymbaroumTheme.gold.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  color: SymbaroumTheme.gold,
                  size: 26,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Textes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cinzel(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: SymbaroumTheme.parchment,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        color: SymbaroumTheme.parchment.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Flèche
              Icon(
                Icons.arrow_forward_ios,
                color: SymbaroumTheme.gold.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
