import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/notification_service.dart';
import '../../../providers/firebase_providers.dart';
import '../widgets/widgets.dart';
import '../dialogs/dialogs.dart';

/// Tab pour la gestion des compétences d'un personnage.
/// 
/// Gère:
/// - Talents (Novice/Adepte/Maître)
/// - Pouvoirs Mystiques (Novice/Adepte/Maître)
/// - Traits (normal ou monstrueux I/II/III)
/// - Atouts & Fardeaux
/// - Rituels
class CompetencesTab extends ConsumerStatefulWidget {
  final String personnageId;
  final Map<String, dynamic> document;
  final List<Map<String, dynamic>>? modifiedTalents;
  final List<Map<String, dynamic>>? modifiedPouvoirs;
  final List<Map<String, dynamic>>? modifiedTraits;
  final List<Map<String, dynamic>>? modifiedAtoutsFardeaux;
  final List<Map<String, dynamic>>? modifiedRituels;
  final Function(List<Map<String, dynamic>>?) onTalentsChanged;
  final Function(List<Map<String, dynamic>>?) onPouvoirsChanged;
  final Function(List<Map<String, dynamic>>?) onTraitsChanged;
  final Function(List<Map<String, dynamic>>?) onAtoutsFardeauxChanged;
  final Function(List<Map<String, dynamic>>?) onRituelsChanged;
  final VoidCallback onModified;

  const CompetencesTab({
    super.key,
    required this.personnageId,
    required this.document,
    this.modifiedTalents,
    this.modifiedPouvoirs,
    this.modifiedTraits,
    this.modifiedAtoutsFardeaux,
    this.modifiedRituels,
    required this.onTalentsChanged,
    required this.onPouvoirsChanged,
    required this.onTraitsChanged,
    required this.onAtoutsFardeauxChanged,
    required this.onRituelsChanged,
    required this.onModified,
  });

  @override
  ConsumerState<CompetencesTab> createState() => _CompetencesTabState();
}

class _CompetencesTabState extends ConsumerState<CompetencesTab> {
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final talents = widget.modifiedTalents ?? 
      List<Map<String, dynamic>>.from(widget.document['talents'] ?? []);
    final pouvoirs = widget.modifiedPouvoirs ?? 
      List<Map<String, dynamic>>.from(widget.document['pouvoirs'] ?? []);
    final traits = widget.modifiedTraits ?? 
      List<Map<String, dynamic>>.from(widget.document['traits'] ?? []);
    final rituels = widget.modifiedRituels ?? 
      List<Map<String, dynamic>>.from(widget.document['rituels'] ?? []);
    final atoutsFardeaux = widget.modifiedAtoutsFardeaux ?? 
      List<Map<String, dynamic>>.from(widget.document['atouts_fardeaux'] ?? []);

    return ListView(
      key: ValueKey(_refreshKey),
      padding: const EdgeInsets.all(16),
      children: [
        // Talents
        CompetenceSection(
          title: 'Talents',
          icon: Icons.star,
          color: Colors.blue,
          items: talents,
          builder: (talent) => _buildTalentCard(talent),
          onAdd: _addTalent,
        ),
        const SizedBox(height: 16),
        
        // Pouvoirs Mystiques
        CompetenceSection(
          title: 'Pouvoirs Mystiques',
          icon: Icons.auto_awesome,
          color: Colors.purple,
          items: pouvoirs,
          builder: (pouvoir) => _buildPouvoirCard(pouvoir),
          onAdd: _addPouvoir,
        ),
        const SizedBox(height: 16),
        
        // Traits
        CompetenceSection(
          title: 'Traits',
          icon: Icons.psychology,
          color: Colors.orange,
          items: traits,
          builder: (trait) => _buildTraitCard(trait),
          onAdd: _addTrait,
        ),
        const SizedBox(height: 16),
        
        // Atouts & Fardeaux
        CompetenceSection(
          title: 'Atouts & Fardeaux',
          icon: Icons.balance,
          color: Colors.teal,
          items: atoutsFardeaux,
          builder: (atout) => _buildAtoutFardeauCard(atout),
          onAdd: _addAtoutFardeau,
        ),
        const SizedBox(height: 16),
        
        // Rituels
        CompetenceSection(
          title: 'Rituels',
          icon: Icons.menu_book,
          color: Colors.deepPurple,
          items: rituels,
          builder: (rituel) => _buildRituelCard(rituel),
          onAdd: _addRituel,
        ),
      ],
    );
  }

  // ============================================================================
  // CARD BUILDERS
  // ============================================================================

  Widget _buildTalentCard(Map<String, dynamic> talent) {
    final niveau = talent['niveau'] as int? ?? 0;
    return TalentCard(
      talent: talent,
      onShowDetails: () async {
        final data = await ref.read(firestoreServiceProvider).getDocumentWithFallback(
          collection: 'talents',
          id: talent['talent_id'],
        );
        if (mounted) _showTalentDetails(data, niveau);
      },
      onEdit: () => _editTalent(talent),
      onDelete: () => _deleteTalent(talent),
    );
  }

  Widget _buildPouvoirCard(Map<String, dynamic> pouvoir) {
    final niveau = pouvoir['niveau'] as int? ?? 0;
    return PouvoirCard(
      pouvoir: pouvoir,
      onShowDetails: () async {
        final data = await ref.read(firestoreServiceProvider).getDocumentWithFallback(
          collection: 'pouvoirs_mystiques',
          id: pouvoir['pouvoir_id'],
        );
        if (mounted) _showPouvoirDetails(data, niveau);
      },
      onEdit: () => _editPouvoir(pouvoir),
      onDelete: () => _deletePouvoir(pouvoir),
    );
  }

  Widget _buildTraitCard(Map<String, dynamic> trait) {
    final niveau = trait['niveau'] as int? ?? 0;
    return TraitCard(
      trait: trait,
      onShowDetails: () async {
        final data = await ref.read(firestoreServiceProvider).getDocumentWithFallback(
          collection: 'traits',
          id: trait['trait_id'],
        );
        if (mounted) _showTraitDetails(data, niveau);
      },
      onEdit: () => _editTrait(trait),
      onDelete: () => _deleteTrait(trait),
    );
  }

  Widget _buildRituelCard(Map<String, dynamic> rituel) {
    return RituelCard(
      rituel: rituel,
      onShowDetails: () async {
        final data = await ref.read(firestoreServiceProvider).getDocumentWithFallback(
          collection: 'rituels',
          id: rituel['rituel_id'],
        );
        if (mounted) _showRituelDetails(data);
      },
      onDelete: () => _deleteRituel(rituel),
    );
  }

  Widget _buildAtoutFardeauCard(Map<String, dynamic> atout) {
    return AtoutFardeauCard(
      atout: atout,
      onShowDetails: () async {
        final data = await ref.read(firestoreServiceProvider).getDocumentWithFallback(
          collection: 'atouts_fardeaux',
          id: atout['atout_fardeau_id'],
        );
        final niveau = atout['niveau'] as int? ?? 1;
        if (mounted) _showAtoutFardeauDetails(data, niveau);
      },
      onDelete: () => _deleteAtoutFardeau(atout),
    );
  }

  // ============================================================================
  // DETAIL DIALOGS
  // ============================================================================

  void _showTalentDetails(Map<String, dynamic>? talentData, int niveau) {
    if (talentData == null) return;
    
    final nom = talentData['nom'] as String? ?? 'Talent';
    final descriptionGenerale = talentData['description_generale'] as String? ?? '';
    final materiel = talentData['materiel'] as String? ?? '';
    final descNovice = talentData['description_novice'] as String? ?? '';
    final descAdepte = talentData['description_adepte'] as String? ?? '';
    final descMaitre = talentData['description_maitre'] as String? ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nom),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (descriptionGenerale.isNotEmpty) ...[
                const Text('Description générale', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(descriptionGenerale),
                const SizedBox(height: 12),
              ],
              if (materiel.isNotEmpty) ...[
                const Text('Matériel', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(materiel),
                const SizedBox(height: 12),
              ],
              if (descNovice.isNotEmpty || descAdepte.isNotEmpty || descMaitre.isNotEmpty) ...[
                const Text('Niveaux', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
              ],
              if (descNovice.isNotEmpty) ...[
                const Text('Novice:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(descNovice, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
              ],
              if (descAdepte.isNotEmpty) ...[
                const Text('Adepte:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(descAdepte, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
              ],
              if (descMaitre.isNotEmpty) ...[
                const Text('Maître:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(descMaitre, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showPouvoirDetails(Map<String, dynamic>? pouvoirData, int niveau) {
    if (pouvoirData == null) return;
    
    final nom = pouvoirData['nom'] as String? ?? 'Pouvoir';
    final materiel = pouvoirData['materiel'] as String? ?? '';
    final tradition = pouvoirData['tradition'] as String? ?? '';
    final descNovice = pouvoirData['description_novice'] as String? ?? '';
    final descAdepte = pouvoirData['description_adepte'] as String? ?? '';
    final descMaitre = pouvoirData['description_maitre'] as String? ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nom),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tradition.isNotEmpty) ...[
                const Text('Tradition', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(tradition),
                const SizedBox(height: 12),
              ],
              if (materiel.isNotEmpty) ...[
                const Text('Matériel', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(materiel),
                const SizedBox(height: 12),
              ],
              if (descNovice.isNotEmpty || descAdepte.isNotEmpty || descMaitre.isNotEmpty) ...[
                const Text('Niveaux', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (descNovice.isNotEmpty)
                  const Text('Novice:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (descNovice.isNotEmpty)
                  Text(descNovice, style: const TextStyle(fontSize: 12)),
                if (descNovice.isNotEmpty)
                  const SizedBox(height: 8),
                if (descAdepte.isNotEmpty)
                  const Text('Adepte:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (descAdepte.isNotEmpty)
                  Text(descAdepte, style: const TextStyle(fontSize: 12)),
                if (descAdepte.isNotEmpty)
                  const SizedBox(height: 8),
                if (descMaitre.isNotEmpty)
                  const Text('Maître:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (descMaitre.isNotEmpty)
                  Text(descMaitre, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showTraitDetails(Map<String, dynamic>? traitData, int niveau) {
    if (traitData == null) return;
    
    final nom = traitData['nom'] as String? ?? 'Trait';
    final descriptionGenerale = traitData['description_generale'] as String? ?? '';
    final niveauType = traitData['niveau_type'] as String? ?? '';
    final isMonstrueux = niveauType.toLowerCase() == 'monstrueux';
    
    final descNovice = traitData['description_novice'] as String? ?? '';
    final descAdepte = traitData['description_adepte'] as String? ?? '';
    final descMaitre = traitData['description_maitre'] as String? ?? '';
    final descI = traitData['description_i'] as String? ?? '';
    final descII = traitData['description_ii'] as String? ?? '';
    final descIII = traitData['description_iii'] as String? ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nom),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (descriptionGenerale.isNotEmpty) ...[
                const Text('Description générale', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(descriptionGenerale),
                const SizedBox(height: 12),
              ],
              if (isMonstrueux) ...[
                if (descI.isNotEmpty || descII.isNotEmpty || descIII.isNotEmpty)
                  const Text('Niveaux', style: TextStyle(fontWeight: FontWeight.bold)),
                if (descI.isNotEmpty || descII.isNotEmpty || descIII.isNotEmpty)
                  const SizedBox(height: 4),
                if (descI.isNotEmpty)
                  const Text('I:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (descI.isNotEmpty)
                  Text(descI, style: const TextStyle(fontSize: 12)),
                if (descI.isNotEmpty)
                  const SizedBox(height: 8),
                if (descII.isNotEmpty)
                  const Text('II:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (descII.isNotEmpty)
                  Text(descII, style: const TextStyle(fontSize: 12)),
                if (descII.isNotEmpty)
                  const SizedBox(height: 8),
                if (descIII.isNotEmpty)
                  const Text('III:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (descIII.isNotEmpty)
                  Text(descIII, style: const TextStyle(fontSize: 12)),
              ] else ...[
                if (descNovice.isNotEmpty || descAdepte.isNotEmpty || descMaitre.isNotEmpty)
                  const Text('Niveaux', style: TextStyle(fontWeight: FontWeight.bold)),
                if (descNovice.isNotEmpty || descAdepte.isNotEmpty || descMaitre.isNotEmpty)
                  const SizedBox(height: 4),
                if (descNovice.isNotEmpty)
                  const Text('Novice:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (descNovice.isNotEmpty)
                  Text(descNovice, style: const TextStyle(fontSize: 12)),
                if (descNovice.isNotEmpty)
                  const SizedBox(height: 8),
                if (descAdepte.isNotEmpty)
                  const Text('Adepte:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (descAdepte.isNotEmpty)
                  Text(descAdepte, style: const TextStyle(fontSize: 12)),
                if (descAdepte.isNotEmpty)
                  const SizedBox(height: 8),
                if (descMaitre.isNotEmpty)
                  const Text('Maître:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (descMaitre.isNotEmpty)
                  Text(descMaitre, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showAtoutFardeauDetails(Map<String, dynamic>? atoutData, int niveau) {
    if (atoutData == null) return;
    
    final nom = atoutData['nom'] as String? ?? 'Atout/Fardeau';
    final description = atoutData['description'] as String? ?? '';
    final effet = atoutData['effet'] as String? ?? '';
    final repetableValue = atoutData['repetable'];
    final repetable = repetableValue is bool ? repetableValue : (repetableValue == 1 || repetableValue == true);
    final type = atoutData['type'] as String? ?? 'atout';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              type.toLowerCase() == 'atout' ? Icons.add_circle : Icons.remove_circle,
              color: type.toLowerCase() == 'atout' ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(nom)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (description.isNotEmpty) ...[
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description),
                const SizedBox(height: 12),
              ],
              if (effet.isNotEmpty) ...[
                const Text('Effet', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(effet),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  const Text('Répétable: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(repetable ? 'Oui' : 'Non'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showRituelDetails(Map<String, dynamic>? rituelData) {
    if (rituelData == null) return;
    
    final nom = rituelData['nom'] as String? ?? 'Rituel';
    final description = rituelData['description'] as String? ?? '';
    final materiel = rituelData['materiel'] as String? ?? '';
    final tradition = rituelData['tradition'] as String? ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nom),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (description.isNotEmpty) ...[
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description),
                const SizedBox(height: 12),
              ],
              if (tradition.isNotEmpty) ...[
                const Text('Tradition', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(tradition),
                const SizedBox(height: 12),
              ],
              if (materiel.isNotEmpty) ...[
                const Text('Matériel', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(materiel),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // CRUD METHODS - Talents
  // ============================================================================

  Future<void> _addTalent() async {
    final firestore = ref.read(firestoreServiceProvider);
    final allTalents = await firestore.getTalents();
    
    if (!mounted) return;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SelectTalentPouvoirDialog(
        title: 'Ajouter un talent',
        items: allTalents,
        type: 'talent',
      ),
    );
    
    if (result != null) {
      final currentTalents = widget.modifiedTalents ?? 
        List<Map<String, dynamic>>.from(widget.document['talents'] ?? []);
      
      currentTalents.add({
        'talent_id': result['id'],
        'niveau': result['niveau'],
      });
      
      widget.onTalentsChanged(currentTalents);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Talent ajouté (pensez à sauvegarder)');
      }
    }
  }
  
  Future<void> _editTalent(Map<String, dynamic> talent) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => EditNiveauDialog(
        title: 'Modifier le niveau du talent',
        currentNiveau: talent['niveau'] as int,
      ),
    );
    
    if (result != null) {
      final currentTalents = widget.modifiedTalents ?? 
        List<Map<String, dynamic>>.from(widget.document['talents'] ?? []);
      
      final index = currentTalents.indexWhere((t) => t['talent_id'] == talent['talent_id']);
      if (index != -1) {
        currentTalents[index]['niveau'] = result;
        
        widget.onTalentsChanged(currentTalents);
        widget.onModified();
        
        setState(() {
          _refreshKey++;
        });
        
        if (mounted) {
          NotificationService.info('Talent modifié (pensez à sauvegarder)');
        }
      }
    }
  }
  
  Future<void> _deleteTalent(Map<String, dynamic> talent) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce talent ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final currentTalents = widget.modifiedTalents ?? 
        List<Map<String, dynamic>>.from(widget.document['talents'] ?? []);
      currentTalents.removeWhere((t) => t['talent_id'] == talent['talent_id']);
      
      widget.onTalentsChanged(currentTalents);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Talent supprimé (pensez à sauvegarder)');
      }
    }
  }

  // ============================================================================
  // CRUD METHODS - Pouvoirs
  // ============================================================================

  Future<void> _addPouvoir() async {
    final firestore = ref.read(firestoreServiceProvider);
    final allPouvoirs = await firestore.getPouvoirsMystiques();
    
    if (!mounted) return;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SelectTalentPouvoirDialog(
        title: 'Ajouter un pouvoir',
        items: allPouvoirs,
        type: 'pouvoir',
      ),
    );
    
    if (result != null) {
      final currentPouvoirs = widget.modifiedPouvoirs ?? 
        List<Map<String, dynamic>>.from(widget.document['pouvoirs'] ?? []);
      
      currentPouvoirs.add({
        'pouvoir_id': result['id'],
        'niveau': result['niveau'],
      });
      
      widget.onPouvoirsChanged(currentPouvoirs);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Pouvoir ajouté (pensez à sauvegarder)');
      }
    }
  }
  
  Future<void> _editPouvoir(Map<String, dynamic> pouvoir) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => EditNiveauDialog(
        title: 'Modifier le niveau du pouvoir',
        currentNiveau: pouvoir['niveau'] as int,
      ),
    );
    
    if (result != null) {
      final currentPouvoirs = widget.modifiedPouvoirs ?? 
        List<Map<String, dynamic>>.from(widget.document['pouvoirs'] ?? []);
      
      final index = currentPouvoirs.indexWhere((p) => p['pouvoir_id'] == pouvoir['pouvoir_id']);
      if (index != -1) {
        currentPouvoirs[index]['niveau'] = result;
        
        widget.onPouvoirsChanged(currentPouvoirs);
        widget.onModified();
        
        setState(() {
          _refreshKey++;
        });
        
        if (mounted) {
          NotificationService.info('Pouvoir modifié (pensez à sauvegarder)');
        }
      }
    }
  }
  
  Future<void> _deletePouvoir(Map<String, dynamic> pouvoir) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce pouvoir ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final currentPouvoirs = widget.modifiedPouvoirs ?? 
        List<Map<String, dynamic>>.from(widget.document['pouvoirs'] ?? []);
      currentPouvoirs.removeWhere((p) => p['pouvoir_id'] == pouvoir['pouvoir_id']);
      
      widget.onPouvoirsChanged(currentPouvoirs);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Pouvoir supprimé (pensez à sauvegarder)');
      }
    }
  }

  // ============================================================================
  // CRUD METHODS - Traits
  // ============================================================================

  Future<void> _addTrait() async {
    final firestore = ref.read(firestoreServiceProvider);
    final allTraits = await firestore.getTraits();
    
    if (!mounted) return;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SelectTalentPouvoirDialog(
        title: 'Ajouter un trait',
        items: allTraits,
        type: 'trait',
      ),
    );
    
    if (result != null) {
      final currentTraits = widget.modifiedTraits ?? 
        List<Map<String, dynamic>>.from(widget.document['traits'] ?? []);
      
      currentTraits.add({
        'trait_id': result['id'],
        'niveau': result['niveau'],
      });
      
      widget.onTraitsChanged(currentTraits);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Trait ajouté (pensez à sauvegarder)');
      }
    }
  }
  
  Future<void> _editTrait(Map<String, dynamic> trait) async {
    // Récupérer le niveau_type du trait
    final firestore = ref.read(firestoreServiceProvider);
    final allTraits = await firestore.getTraits();
    final traitData = allTraits.firstWhere(
      (t) => t['id'] == trait['trait_id'],
      orElse: () => <String, dynamic>{},
    );
    final isMonstrueux = traitData['niveau_type'] == 'monstrueux';
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => EditNiveauDialog(
        title: 'Modifier le niveau du trait',
        currentNiveau: trait['niveau'] as int,
        isMonstrueux: isMonstrueux,
      ),
    );
    
    if (result != null) {
      final currentTraits = widget.modifiedTraits ?? 
        List<Map<String, dynamic>>.from(widget.document['traits'] ?? []);
      
      final index = currentTraits.indexWhere((t) => t['trait_id'] == trait['trait_id']);
      if (index != -1) {
        currentTraits[index]['niveau'] = result;
        
        widget.onTraitsChanged(currentTraits);
        widget.onModified();
        
        setState(() {
          _refreshKey++;
        });
        
        if (mounted) {
          NotificationService.info('Trait modifié (pensez à sauvegarder)');
        }
      }
    }
  }
  
  Future<void> _deleteTrait(Map<String, dynamic> trait) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce trait ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final currentTraits = widget.modifiedTraits ?? 
        List<Map<String, dynamic>>.from(widget.document['traits'] ?? []);
      currentTraits.removeWhere((t) => t['trait_id'] == trait['trait_id']);
      
      widget.onTraitsChanged(currentTraits);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Trait supprimé (pensez à sauvegarder)');
      }
    }
  }

  // ============================================================================
  // CRUD METHODS - Atouts/Fardeaux
  // ============================================================================

  Future<void> _addAtoutFardeau() async {
    final firestore = ref.read(firestoreServiceProvider);
    final allAtouts = await firestore.getAtoutsFardeaux();
    
    if (!mounted) return;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SelectTalentPouvoirDialog(
        title: 'Ajouter un atout/fardeau',
        items: allAtouts,
        type: 'atout',
      ),
    );
    
    if (result != null) {
      final currentAtoutsFardeaux = widget.modifiedAtoutsFardeaux ?? 
        List<Map<String, dynamic>>.from(widget.document['atouts_fardeaux'] ?? []);
      
      currentAtoutsFardeaux.add({
        'atout_fardeau_id': result['id'],
        'niveau': result['niveau'],
      });
      
      widget.onAtoutsFardeauxChanged(currentAtoutsFardeaux);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Atout/Fardeau ajouté (pensez à sauvegarder)');
      }
    }
  }
  
  Future<void> _deleteAtoutFardeau(Map<String, dynamic> atout) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cet atout/fardeau ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final currentAtoutsFardeaux = widget.modifiedAtoutsFardeaux ?? 
        List<Map<String, dynamic>>.from(widget.document['atouts_fardeaux'] ?? []);
      currentAtoutsFardeaux.removeWhere((a) => a['atout_fardeau_id'] == atout['atout_fardeau_id']);
      
      widget.onAtoutsFardeauxChanged(currentAtoutsFardeaux);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Atout/Fardeau supprimé (pensez à sauvegarder)');
      }
    }
  }

  // ============================================================================
  // CRUD METHODS - Rituels
  // ============================================================================

  Future<void> _addRituel() async {
    final firestore = ref.read(firestoreServiceProvider);
    final allRituels = await firestore.getRituels();
    
    if (!mounted) return;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SelectIdentiteDialog(
        title: 'Ajouter un rituel',
        items: allRituels,
        showDescription: false,
      ),
    );
    
    if (result != null) {
      final currentRituels = widget.modifiedRituels ?? 
        List<Map<String, dynamic>>.from(widget.document['rituels'] ?? []);
      
      currentRituels.add({
        'rituel_id': int.tryParse(result) ?? result,
      });
      
      widget.onRituelsChanged(currentRituels);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Rituel ajouté (pensez à sauvegarder)');
      }
    }
  }
  
  Future<void> _deleteRituel(Map<String, dynamic> rituel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce rituel ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final currentRituels = widget.modifiedRituels ?? 
        List<Map<String, dynamic>>.from(widget.document['rituels'] ?? []);
      currentRituels.removeWhere((r) => r['rituel_id'] == rituel['rituel_id']);
      
      widget.onRituelsChanged(currentRituels);
      widget.onModified();
      
      setState(() {
        _refreshKey++;
      });
      
      if (mounted) {
        NotificationService.info('Rituel supprimé (pensez à sauvegarder)');
      }
    }
  }
}
