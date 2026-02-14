import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/theme.dart';
import '../services/notification_service.dart';

/// Écran d'affichage du QR code pour rejoindre une campagne (MJ)
class QRCodeDisplayScreen extends ConsumerWidget {
  final String campagneId;
  final String campagneNom;
  final String invitationToken;

  const QRCodeDisplayScreen({
    super.key,
    required this.campagneId,
    required this.campagneNom,
    required this.invitationToken,
  });

  String get _invitationUrl => 'symbaroum://join/$invitationToken';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Code d\'invitation',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
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
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
          // 3. UI CONTENT
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Titre
                    _buildTitle(),
                    const SizedBox(height: 48),
                    // QR Code Card
                    _buildQRCard(context),
                    const SizedBox(height: 32),
                    // Instructions
                    _buildInstructions(),
                  ],
                ),
              ),
            ),
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
            Icon(Icons.qr_code_2, color: SymbaroumTheme.gold.withValues(alpha: 0.8), size: 32),
            const SizedBox(width: 16),
            _buildDecorativeLine(),
          ],
        ),
        const SizedBox(height: 16),

        // Nom de la campagne
        Text(
          campagneNom.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: SymbaroumTheme.gold,
            letterSpacing: 3,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.8), offset: const Offset(2, 2), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Text(
          'CODE D\'INVITATION',
          style: GoogleFonts.cinzel(
            fontSize: 14,
            color: SymbaroumTheme.parchment.withValues(alpha: 0.7),
            letterSpacing: 4,
          ),
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

  Widget _buildQRCard(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: SymbaroumTheme.darkBrown.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SymbaroumTheme.gold.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: _invitationUrl,
              version: QrVersions.auto,
              size: 250,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
          ),
          const SizedBox(height: 24),

          // Token (pour copie manuelle)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SymbaroumTheme.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    invitationToken,
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      color: SymbaroumTheme.parchment,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, color: SymbaroumTheme.gold, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: invitationToken));
                    NotificationService.success('Code copié !');
                  },
                  tooltip: 'Copier le code',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SymbaroumTheme.darkBrown.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SymbaroumTheme.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: SymbaroumTheme.gold, size: 32),
          const SizedBox(height: 12),
          Text(
            'COMMENT REJOINDRE',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: SymbaroumTheme.gold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Les joueurs doivent :\n\n'
            '1. Ouvrir l\'application en mode Joueur\n'
            '2. Scanner ce QR code\n'
            '3. Ou saisir manuellement le code d\'invitation',
            style: GoogleFonts.cinzel(
              fontSize: 13,
              color: SymbaroumTheme.parchment.withValues(alpha: 0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
