import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../config/theme.dart';
import '../utils/character_validator.dart';
import '../services/notification_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../providers/firebase_providers.dart';
import 'player_character_detail_screen.dart';

/// Écran de création de personnage simplifié pour joueur
/// Permet de définir : nom, infos de base, race, archétype, classe, caractéristiques, notes
class PlayerCharacterCreationScreen extends ConsumerStatefulWidget {
  final String campagneId;
  final String campagneNom;

  const PlayerCharacterCreationScreen({
    super.key,
    required this.campagneId,
    required this.campagneNom,
  });

  @override
  ConsumerState<PlayerCharacterCreationScreen> createState() =>
      _PlayerCharacterCreationScreenState();
}

class _PlayerCharacterCreationScreenState
    extends ConsumerState<PlayerCharacterCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestore = FirestoreService.instance;
  final FirebaseAuthService _auth = FirebaseAuthService.instance;

  // Controllers
  final _nomController = TextEditingController();
  final _ageController = TextEditingController(text: '25');
  final _tailleController = TextEditingController(text: '175');
  final _poidsController = TextEditingController(text: '70');
  final _notesController = TextEditingController();

  // Sélections
  int? _selectedRaceId;
  int? _selectedArchetypeId;
  int? _selectedClasseId;

  // Caractéristiques avec valeurs de départ
  final Map<String, int> _characteristics = {
    'force': CharacterValidator.startingValue,
    'agilite': CharacterValidator.startingValue,
    'precision': CharacterValidator.startingValue,
    'discretion': CharacterValidator.startingValue,
    'persuasion': CharacterValidator.startingValue,
    'astuce': CharacterValidator.startingValue,
    'vigilance': CharacterValidator.startingValue,
    'volonte': CharacterValidator.startingValue,
  };

  CharacteristicsValidation? _validation;
  bool _isCreating = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _validateCharacteristics();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _ageController.dispose();
    _tailleController.dispose();
    _poidsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _validateCharacteristics() {
    setState(() {
      _validation = CharacterValidator.validate(_characteristics);
    });
  }

  // Calculs automatiques des stats
  int get _enduranceMax => math.max(_characteristics['force']!, 10);
  int get _seuilCorruption => (_characteristics['volonte']! / 2).ceil();
  int get _resistanceDouleur => (_characteristics['force']! / 2).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Créer un Personnage',
          style: GoogleFonts.cinzel(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: SymbaroumColors.textPrimary,
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
          ),
          // 2. OVERLAY
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.10),
                  Colors.black.withOpacity(0.30),
                ],
              ),
            ),
          ),
          // 3. UI CONTENT
          SafeArea(
            child: Column(
              children: [
                // Indicateur de progression
                _buildProgressIndicator(),

                // Contenu du step actuel
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: _buildCurrentStep(),
                  ),
                ),

                // Boutons de navigation
                _buildNavigationButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepIndicator(0, 'Infos'),
          _buildStepConnector(0),
          _buildStepIndicator(1, 'Caractéristiques'),
          _buildStepConnector(1),
          _buildStepIndicator(2, 'Notes'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? SymbaroumColors.primary
                : isActive
                    ? SymbaroumColors.primary.withValues(alpha: 0.5)
                    : Colors.grey[700],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.black)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.cinzel(
                      color: isActive ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.lato(
            color: isActive ? SymbaroumColors.primary : SymbaroumColors.textPrimary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int step) {
    final isCompleted = _currentStep > step;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isCompleted ? SymbaroumColors.primary : Colors.grey[700],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildInfosStep();
      case 1:
        return _buildCaracteristiquesStep();
      case 2:
        return _buildNotesStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInfosStep() {
    final racesAsync = ref.watch(racesProvider);
    final archetypesAsync = ref.watch(archetypesProvider);
    final classesAsync = ref.watch(classesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMATIONS DE BASE',
            style: GoogleFonts.cinzel(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SymbaroumColors.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),

          // Nom
          TextFormField(
            controller: _nomController,
            decoration: InputDecoration(
              labelText: 'Nom du personnage *',
              labelStyle: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
              filled: true,
              fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nom';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Âge
          TextFormField(
            controller: _ageController,
            decoration: InputDecoration(
              labelText: 'Âge',
              labelStyle: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
              filled: true,
              fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Taille
          TextFormField(
            controller: _tailleController,
            decoration: InputDecoration(
              labelText: 'Taille (cm)',
              labelStyle: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
              filled: true,
              fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Poids
          TextFormField(
            controller: _poidsController,
            decoration: InputDecoration(
              labelText: 'Poids (kg)',
              labelStyle: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
              filled: true,
              fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          // Race
          racesAsync.when(
            data: (races) => DropdownButtonFormField<int>(
              initialValue: _selectedRaceId,
              decoration: InputDecoration(
                labelText: 'Race *',
                labelStyle: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
                filled: true,
                fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              dropdownColor: SymbaroumTheme.darkBrown,
              style: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
              items: races.map((race) {
                return DropdownMenuItem<int>(
                  value: race['id'] as int,
                  child: Text(race['nom'] as String),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedRaceId = value),
              validator: (value) => value == null ? 'Veuillez choisir une race' : null,
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text('Erreur: $e', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 16),

          // Archétype
          archetypesAsync.when(
            data: (archetypes) => DropdownButtonFormField<int>(
              initialValue: _selectedArchetypeId,
              decoration: InputDecoration(
                labelText: 'Archétype *',
                labelStyle: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
                filled: true,
                fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              dropdownColor: SymbaroumTheme.darkBrown,
              style: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
              items: archetypes.map((archetype) {
                return DropdownMenuItem<int>(
                  value: archetype['id'] as int,
                  child: Text(archetype['nom'] as String),
                );
              }).toList(),
              onChanged: (value) => setState(() {
                _selectedArchetypeId = value;
                _selectedClasseId = null; // reset la classe si archétype change
              }),
              validator: (value) => value == null ? 'Veuillez choisir un archétype' : null,
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text('Erreur: $e', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 16),

          // Classe
          classesAsync.when(
            data: (classes) {
              // Filtrer selon l'archétype sélectionné
              final filteredClasses = _selectedArchetypeId == null
                  ? <Map<String, dynamic>>[]
                  : classes.where((c) => c['archetype_id'] == _selectedArchetypeId).toList();
              return DropdownButtonFormField<int>(
                initialValue: _selectedClasseId,
                decoration: InputDecoration(
                  labelText: 'Classe *',
                  labelStyle: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
                  filled: true,
                  fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                dropdownColor: SymbaroumTheme.darkBrown,
                style: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
                items: filteredClasses.map((classe) {
                  return DropdownMenuItem<int>(
                    value: classe['id'] as int,
                    child: Text(classe['nom'] as String),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedClasseId = value),
                validator: (value) => value == null ? 'Veuillez choisir une classe' : null,
                disabledHint: Text('Choisissez un archétype d’abord', style: GoogleFonts.lato()),
                isExpanded: true,
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text('Erreur: $e', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCaracteristiquesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CARACTÉRISTIQUES',
            style: GoogleFonts.cinzel(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SymbaroumColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),

          // Indicateur de points
          _buildPointsIndicator(),
          const SizedBox(height: 24),

          // Message d'erreur si validation échoue
          if (_validation?.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[900]!.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[700]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _validation!.errorMessage!,
                      style: GoogleFonts.lato(color: Colors.red[300]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Liste des caractéristiques
          ...CharacterValidator.characteristicsOrder.map((key) {
            final value = _characteristics[key]!;
            return _buildCharacteristicSlider(key, value);
          }),

          const SizedBox(height: 24),

          // Stats calculées automatiquement
          _buildCalculatedStats(),
        ],
      ),
    );
  }

  Widget _buildCalculatedStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SymbaroumColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SymbaroumColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATS CALCULÉES',
            style: GoogleFonts.cinzel(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: SymbaroumColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow('Endurance max', '$_enduranceMax', 'max(Force, 10)'),
          const SizedBox(height: 8),
          _buildStatRow('Seuil de corruption', '$_seuilCorruption', '⌈Volonté / 2⌉'),
          const SizedBox(height: 8),
          _buildStatRow('Résistance douleur', '$_resistanceDouleur', '⌈Force / 2⌉'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, String formula) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.lato(
                color: SymbaroumColors.textPrimary,
                fontSize: 14,
              ),
            ),
            Text(
              formula,
              style: GoogleFonts.lato(
                color: SymbaroumColors.textPrimary.withValues(alpha: 0.5),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.cinzel(
            color: SymbaroumColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPointsIndicator() {
    final validation = _validation;
    if (validation == null) return const SizedBox.shrink();

    final remaining = validation.pointsRemaining;
    final color = remaining == 0
        ? Colors.green
        : remaining < 0
            ? Colors.red
            : SymbaroumColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(
            'POINTS RESTANTS',
            style: GoogleFonts.cinzel(
              fontSize: 14,
              color: SymbaroumTheme.parchment,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$remaining',
            style: GoogleFonts.cinzel(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${validation.pointsUsed} / ${validation.totalPoints} utilisés',
            style: GoogleFonts.lato(
              color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacteristicSlider(String key, int value) {
    final displayName = _getCharacteristicDisplayName(key);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SymbaroumTheme.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayName,
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SymbaroumTheme.parchment,
                ),
              ),
              Text(
                value.toString(),
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: SymbaroumTheme.parchment,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: SymbaroumTheme.gold,
              inactiveTrackColor: SymbaroumTheme.gold.withValues(alpha: 0.2),
              thumbColor: SymbaroumTheme.gold,
              overlayColor: SymbaroumTheme.gold.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: value.toDouble(),
              min: CharacterValidator.minValue.toDouble(),
              max: CharacterValidator.maxValue.toDouble(),
              divisions: CharacterValidator.maxValue - CharacterValidator.minValue,
              onChanged: (newValue) {
                setState(() {
                  _characteristics[key] = newValue.round();
                  _validateCharacteristics();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOTES',
            style: GoogleFonts.cinzel(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SymbaroumColors.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ajoutez des notes sur votre personnage (optionnel)',
            style: GoogleFonts.lato(
              color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Background, objectifs, traits de personnalité...',
              hintStyle: GoogleFonts.lato(
                color: SymbaroumColors.textPrimary.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
            maxLines: 10,
            minLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton Précédent
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isCreating ? null : () {
                  setState(() => _currentStep--);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: SymbaroumColors.textPrimary,
                  side: const BorderSide(color: SymbaroumColors.textPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'PRÉCÉDENT',
                  style: GoogleFonts.cinzel(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          // Bouton Suivant / Créer
          Expanded(
            child: FilledButton(
              onPressed: _isCreating ? null : _handleNextButton,
              style: FilledButton.styleFrom(
                backgroundColor: SymbaroumColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      _currentStep < 2 ? 'SUIVANT' : 'CRÉER',
                      style: GoogleFonts.cinzel(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextButton() {
    if (_currentStep < 2) {
      // Validation du step actuel
      if (_currentStep == 0 && !_formKey.currentState!.validate()) {
        return;
      }
      if (_currentStep == 1 && !(_validation?.isValid ?? false)) {
        NotificationService.warning('Veuillez répartir tous les points');
        return;
      }

      setState(() => _currentStep++);
    } else {
      // Création du personnage
      _createPersonnage();
    }
  }

  Future<void> _createPersonnage() async {
    if (!_formKey.currentState!.validate()) return;
    if (!(_validation?.isValid ?? false)) {
      NotificationService.error('Caractéristiques invalides');
      return;
    }

    final userId = _auth.currentUserId;
    if (userId == null) {
      NotificationService.error('Non connecté');
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Préparer les données
      final age = int.tryParse(_ageController.text) ?? 25;
      final taille = int.tryParse(_tailleController.text) ?? 175;
      final poids = int.tryParse(_poidsController.text) ?? 70;

      final now = Timestamp.now();

      final documentData = {
        'nom': _nomController.text.trim(),
        'age': age,
        'taille': taille,
        'poids': poids,
        'notes': _notesController.text.trim(),
        'avatarUrl': null,
        'race_id': _selectedRaceId,
        'archetype_id': _selectedArchetypeId,
        'classe_id': _selectedClasseId,
        'niveau': 1,
        'experience': 0,
        'caracteristiques': {
          ..._characteristics,
          'endurance_actuelle': _enduranceMax,
          'endurance_max': _enduranceMax,
          'corruption': 0,
          'corruption_permanente': 0,
          'seuil_corruption': _seuilCorruption,
          'resistance_douleur': _resistanceDouleur,
        },
        'argent': {
          'ortegs': 5,
          'shillings': 0,
          'thalers': 5,
        },
        'inventaire': [],
        'talents': [],
        'pouvoirs': [],
        'rituels': [],
        'traits': [],
        'atouts_fardeaux': [],
      };

      final personnageData = {
        'estPJ': true,
        'createur': userId,
        'campagnes_ids': [widget.campagneId],
        'joueur_actif_id': userId,
        'date_creation': now,
        'date_modification': now,
        'document': documentData,
      };

      final docRef = await _firestore.createDocument(
        collection: 'personnages',
        data: personnageData,
      );

      NotificationService.success('Personnage créé !');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerCharacterDetailScreen(
              personnageId: docRef,
            ),
          ),
        );
      }
    } catch (e) {
      NotificationService.error('Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  String _getCharacteristicDisplayName(String key) {
    const names = {
      'force': 'Force',
      'agilite': 'Agilité',
      'precision': 'Précision',
      'discretion': 'Discrétion',
      'persuasion': 'Persuasion',
      'astuce': 'Astuce',
      'vigilance': 'Vigilance',
      'volonte': 'Volonté',
    };
    return names[key] ?? key;
  }
}