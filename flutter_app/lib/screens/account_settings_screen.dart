import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../config/theme.dart';
import 'firebase_login_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Écran de gestion du compte utilisateur
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _displayedNameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _canChangeDisplayedName = true;
  DateTime? _nextChangeDate;
  bool _emailVerified = false;
  
  // Durée minimale entre deux changements de nom (30 jours)
  static const _nameChangeCooldown = Duration(days: 30);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayedNameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authService = FirebaseAuthService.instance;
    
    try {
      final userData = await authService.getUserData();
      if (userData != null && mounted) {
        _displayedNameController.text = userData['displayedName'] as String? ?? '';

        // Email verification status: prefer Firebase Auth value, fallback to Firestore flag
        final user = authService.currentUser;
        bool verified = false;
        if (user != null) {
          verified = user.emailVerified;
        }
        verified = verified || (userData['verifiedMail'] == true);
        setState(() {
          _emailVerified = verified;
        });
        
        // Vérifier le dernier changement de nom
        final lastChange = userData['lastDisplayedNameChange'];
        if (lastChange != null) {
          DateTime lastChangeDate;
          if (lastChange is Timestamp) {
            lastChangeDate = lastChange.toDate();
          } else if (lastChange is String) {
            lastChangeDate = DateTime.parse(lastChange);
          } else {
            lastChangeDate = DateTime.now().subtract(const Duration(days: 31));
          }
          
          final nextChange = lastChangeDate.add(_nameChangeCooldown);
          final now = DateTime.now();
          
          setState(() {
            _canChangeDisplayedName = now.isAfter(nextChange);
            _nextChangeDate = nextChange;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error('Erreur de chargement: $e');
      }
    }
  }

  Future<void> _updateDisplayedName() async {
    if (_displayedNameController.text.trim().isEmpty) {
      NotificationService.error('Le nom ne peut pas être vide');
      return;
    }

    if (!_canChangeDisplayedName) {
      NotificationService.error('Vous pourrez changer votre nom le ${_formatDate(_nextChangeDate!)}');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestoreService = FirestoreService.instance;

      // Utiliser la nouvelle méthode du service
      await firestoreService.updateDisplayedName(
        _displayedNameController.text.trim(),
      );

      if (mounted) {
        NotificationService.success('Nom mis à jour avec succès');
        // Recharger les données pour mettre à jour le cooldown
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error('Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    print('🟢🟢🟢 FONCTION APPELÉE 🟢🟢🟢'); // TOUT EN HAUT
    final authService = FirebaseAuthService.instance;
    final email = authService.currentUserEmail;

    if (email == null) {
      NotificationService.error('Email non disponible');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔵 DÉBUT envoi email à: $email');
      print('🔵 Timestamp: ${DateTime.now()}');
      
      final stopwatch = Stopwatch()..start();
      await authService.sendPasswordResetEmail(email);
      stopwatch.stop();
      print('✅ Email envoyé en ${stopwatch.elapsedMilliseconds}ms');
      print('✅ Timestamp: ${DateTime.now()}');

      if (mounted) {
        NotificationService.success('Email de réinitialisation envoyé à $email');
      }
    } catch (e) {
      print('❌ ERREUR: $e');
      print('❌ Type: ${e.runtimeType}');
      if (mounted) {
        NotificationService.error('Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SymbaroumTheme.darkBrown,
        title: Text(
          'SUPPRIMER LE COMPTE',
          style: GoogleFonts.cinzel(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Cette action est irréversible.\n\nÊtes-vous absolument sûr ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      
      // ✅ BONNE FAÇON d'appeler une Cloud Function
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('deleteUserAccount');
      final result = await callable.call();
      
      print('✅ Compte supprimé: ${result.data}');

      if (mounted) {
        NotificationService.success('Compte supprimé');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const FirebaseLoginScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error('Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    print('🟢🟢🟢 _resendVerificationEmail() APPELÉE 🟢🟢🟢');
    setState(() => _isLoading = true);
    
    try {
      print('🔵 Appel sendVerificationEmail - DÉBUT');
      print('🔵 Timestamp: ${DateTime.now()}');
      
      final authService = FirebaseAuthService.instance;
      
      final stopwatch = Stopwatch()..start();
      await authService.sendVerificationEmail();
      stopwatch.stop();
      
      print('✅ Email envoyé en ${stopwatch.elapsedMilliseconds}ms');
      print('✅ Timestamp: ${DateTime.now()}');
      
      NotificationService.success('Email de vérification renvoyé (${stopwatch.elapsedMilliseconds}ms)');
      
      // Re-check status
      final verified = await authService.checkAndSyncEmailVerification();
      if (mounted) setState(() => _emailVerified = verified);
    } catch (e) {
      print('❌ ERREUR: $e');
      print('❌ Type: ${e.runtimeType}');
      if (mounted) NotificationService.error('Erreur: $e');
    } finally {
      print('🔵 Finally _resendVerificationEmail()');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService.instance;
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Paramètres du compte',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
        ),
        backgroundColor: SymbaroumTheme.darkBrown,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Informations utilisateur
          Card(
            color: SymbaroumTheme.darkBrown.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INFORMATIONS',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: SymbaroumTheme.gold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Email', user?.email ?? 'Non disponible'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Email vérifié: ', style: TextStyle(color: SymbaroumTheme.parchment)),
                      Text(_emailVerified ? 'Oui' : 'Non', style: TextStyle(color: _emailVerified ? Colors.green : Colors.orange)),
                      const SizedBox(width: 16),
                      if (!_emailVerified && (user?.providerData.any((p) => p.providerId == 'password') ?? false))
                        ElevatedButton(
                          onPressed: _isLoading ? null : _resendVerificationEmail,
                          child: const Text('Renvoyer le mail de vérification'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('UID', user?.uid ?? 'Non disponible'),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Fournisseur',
                    user?.providerData.firstOrNull?.providerId ?? 'Non disponible',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Changement de nom affiché
          Card(
            color: SymbaroumTheme.darkBrown.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOM AFFICHÉ',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: SymbaroumTheme.gold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _displayedNameController,
                    enabled: _canChangeDisplayedName && !_isLoading,
                    style: TextStyle(color: SymbaroumTheme.parchment),
                    decoration: InputDecoration(
                      labelText: 'Nom affiché',
                      labelStyle: TextStyle(color: SymbaroumTheme.gold.withValues(alpha: 0.7)),
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
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  if (!_canChangeDisplayedName && _nextChangeDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ Prochain changement possible le ${_formatDate(_nextChangeDate!)}',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_canChangeDisplayedName && !_isLoading) ? _updateDisplayedName : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SymbaroumTheme.gold,
                        foregroundColor: SymbaroumTheme.darkBrown,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('METTRE À JOUR LE NOM'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Réinitialisation mot de passe
          if (user?.providerData.any((p) => p.providerId == 'password') ?? false) ...[
            Card(
              color: SymbaroumTheme.darkBrown.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MOT DE PASSE',
                      style: GoogleFonts.cinzel(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: SymbaroumTheme.gold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Un email de réinitialisation sera envoyé à ${user?.email}',
                      style: TextStyle(color: SymbaroumTheme.parchment.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _sendPasswordResetEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.email),
                        label: const Text('RÉINITIALISER LE MOT DE PASSE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Zone dangereuse - Suppression compte
          Card(
            color: Colors.red.shade900.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ZONE DANGEREUSE',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'La suppression de votre compte est irréversible. Toutes vos données seront définitivement perdues.',
                    style: TextStyle(color: SymbaroumTheme.parchment.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('SUPPRIMER MON COMPTE'),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: GoogleFonts.cinzel(
              color: SymbaroumTheme.gold.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(color: SymbaroumTheme.parchment),
          ),
        ),
      ],
    );
  }
}
