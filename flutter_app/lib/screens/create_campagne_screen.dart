import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../providers/firebase_providers.dart';
import '../services/firebase_auth_service.dart';
import '../services/notification_service.dart';

/// Écran de création de campagne (MJ)
class CreateCampagneScreen extends ConsumerStatefulWidget {
  const CreateCampagneScreen({super.key});

  @override
  ConsumerState<CreateCampagneScreen> createState() => _CreateCampagneScreenState();
}

class _CreateCampagneScreenState extends ConsumerState<CreateCampagneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isPublic = false; // Nouvelle option

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCampagne() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Générer un token d'invitation unique
      final invitationToken = _generateInvitationToken();
      
      final campagneId = await ref.read(authProvider.notifier).createCampagne(
            _nomController.text,
            _descriptionController.text.isEmpty ? null : _descriptionController.text,
            isPublic: _isPublic,
            invitationToken: invitationToken,
          );

      if (campagneId != null && mounted) {
        NotificationService.success('Campagne créée avec succès !');
        
        // Rafraîchir la liste des campagnes
        ref.invalidate(campagnesMJProvider);
        
        Navigator.pop(context, campagneId);
      } else if (mounted) {
        throw Exception('Échec de la création');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error('Erreur : ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Génère un token d'invitation unique (12 caractères alphanumériques)
  String _generateInvitationToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Sans I, O, 0, 1 pour éviter confusion
    final random = Random.secure();
    return List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService.instance;
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Campagne'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Info utilisateur avec displayedName
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: authService.getUserData(),
                    builder: (context, snapshot) {
                      final displayedName = snapshot.data?['displayedName'] as String?;
                      final email = user?.email ?? 'Non connecté';
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Maître du Jeu',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayedName ?? email,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (displayedName != null && displayedName != email)
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Nom de la campagne
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la campagne *',
                  hintText: 'Ex: Les Ombres de Davokar',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  hintText: 'Décrivez votre campagne...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Option publique
              Card(
                child: SwitchListTile(
                  title: const Text('Campagne publique'),
                  subtitle: const Text(
                    'Permet à tous les joueurs de voir et rejoindre cette campagne',
                  ),
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() => _isPublic = value);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Bouton créer
              ElevatedButton(
                onPressed: _isLoading ? null : _createCampagne,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Créer la campagne'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
