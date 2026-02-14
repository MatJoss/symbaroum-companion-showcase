import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../config/theme.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'player_personnage_select_screen.dart';

/// Écran de scan QR code pour rejoindre une campagne (Joueur)
class QRCodeScanScreen extends ConsumerStatefulWidget {
  const QRCodeScanScreen({super.key});

  @override
  ConsumerState<QRCodeScanScreen> createState() => _QRCodeScanScreenState();
}

class _QRCodeScanScreenState extends ConsumerState<QRCodeScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final _manualCodeController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String code) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);

    try {
      // Extraire le token du QR code (format: symbaroum://join/{token})
      String token = code.trim().toUpperCase();
      if (code.startsWith('symbaroum://join/')) {
        token = code.substring('symbaroum://join/'.length).trim().toUpperCase();
      }

      // 🎯 Utiliser la nouvelle méthode joinCampagneByToken
      final firestoreService = FirestoreService.instance;
      final campagne = await firestoreService.joinCampagneByToken(token);

      if (campagne == null) {
        if (mounted) {
          NotificationService.error('Code d\'invitation invalide ou expiré');
        }
        setState(() => _isProcessing = false);
        return;
      }

      final campagneId = campagne['uid'] as String;
      final campagneNom = campagne['nom'] as String? ?? 'Sans nom';

      if (mounted) {
        // Naviguer vers l'écran de sélection de personnage pour cette campagne
        NotificationService.success('Campagne rejointe : $campagneNom');
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerPersonnageSelectScreen(
              campagneId: campagneId,
              campagneNom: campagneNom,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error('Erreur : ${e.toString().replaceAll('FirestoreException: ', '')}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Scanner le code',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Scanner camera
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQRCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Overlay avec cadre de scan
          _buildScanOverlay(),

          // Zone de saisie manuelle en bas
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildManualEntry(),
          ),

          // Loading indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: SymbaroumTheme.gold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cadre de scan
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: SymbaroumTheme.gold,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            // Instructions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SymbaroumTheme.darkBrown.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SymbaroumTheme.gold.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Alignez le QR code\ndans le cadre',
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  color: SymbaroumTheme.parchment,
                  letterSpacing: 1,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntry() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SymbaroumTheme.darkBrown.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.5), width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'OU SAISIR LE CODE',
              style: GoogleFonts.cinzel(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: SymbaroumTheme.gold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 16),

            // Champ de saisie
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualCodeController,
                    style: TextStyle(color: SymbaroumTheme.parchment),
                    decoration: InputDecoration(
                      hintText: 'Code d\'invitation',
                      hintStyle: TextStyle(color: SymbaroumTheme.parchment.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: SymbaroumTheme.gold, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Bouton valider
                ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          if (_manualCodeController.text.isNotEmpty) {
                            _handleQRCode(_manualCodeController.text);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SymbaroumTheme.gold,
                    foregroundColor: SymbaroumTheme.darkBrown,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Icon(Icons.check, size: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
