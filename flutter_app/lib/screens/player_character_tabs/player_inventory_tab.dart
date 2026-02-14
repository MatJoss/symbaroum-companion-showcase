import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../providers/firebase_providers.dart';

/// Onglet Inventaire - Gestion des objets (équiper, utiliser, modifier quantités)
class PlayerInventoryTab extends ConsumerStatefulWidget {
  final String personnageId;
  final Map<String, dynamic> data;

  const PlayerInventoryTab({
    super.key,
    required this.personnageId,
    required this.data,
  });

  @override
  ConsumerState<PlayerInventoryTab> createState() => _PlayerInventoryTabState();
}

class _PlayerInventoryTabState extends ConsumerState<PlayerInventoryTab> {
  final FirestoreService _firestore = FirestoreService.instance;
  String _filterType = 'tous';

  // Helper pour parser int/string depuis Firestore
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final inventaire = widget.data['inventaire'] as List<dynamic>? ?? [];
    final argent = widget.data['argent'] as Map<String, dynamic>? ?? {};
    
    // Filtrer l'inventaire
    final filteredInventaire = inventaire.where((item) {
      if (_filterType == 'tous') return true;
      final itemMap = item as Map<String, dynamic>;
      return itemMap['type'] == _filterType;
    }).toList();

    return Column(
      children: [
        // Bourse
        _buildMoneyDisplay(argent),

        // Filtres
        _buildFilters(),

        // Liste d'inventaire
        Expanded(
          child: filteredInventaire.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredInventaire.length,
                  itemBuilder: (context, index) {
                    final item = filteredInventaire[index] as Map<String, dynamic>;
                    return _buildInventoryItem(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMoneyDisplay(Map<String, dynamic> argent) {
    // Support des deux formats: pluriel (thalers) et singulier (thaler)
    final thalers = _parseInt(argent['thalers'] ?? argent['thaler']);
    final shillings = _parseInt(argent['shillings'] ?? argent['shilling']);
    final ortegs = _parseInt(argent['ortegs'] ?? argent['orteg']);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SymbaroumColors.cardBackground.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMoneyColumn('THALERS', thalers, SymbaroumColors.textPrimary),
          _buildMoneyColumn('SHILLINGS', shillings, SymbaroumColors.textPrimary),
          _buildMoneyColumn('ORTEGS', ortegs, SymbaroumColors.textPrimary),
        ],
      ),
    );
  }

  Widget _buildMoneyColumn(String label, int value, Color color) {
    return InkWell(
      onTap: () => _editMoney(label.toLowerCase(), value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Icon(Icons.monetization_on, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.cinzel(
                color: SymbaroumColors.textPrimary.withValues(alpha: 0.9),
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: GoogleFonts.cinzel(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tous', 'tous'),
            const SizedBox(width: 8),
            _buildFilterChip('Armes', 'arme'),
            const SizedBox(width: 8),
            _buildFilterChip('Armures', 'armure'),
            const SizedBox(width: 8),
            _buildFilterChip('Équipement', 'equipement'),
            const SizedBox(width: 8),
            _buildFilterChip('Artefacts', 'artefact'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _filterType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterType = type);
      },
      selectedColor: SymbaroumColors.primary,
      backgroundColor: SymbaroumColors.cardBackground,
      labelStyle: GoogleFonts.cinzel(
        color: isSelected ? Colors.black : SymbaroumColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: SymbaroumColors.textPrimary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Inventaire vide',
            style: GoogleFonts.cinzel(
              color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItem(Map<String, dynamic> item) {
    // Utiliser nom_objet (personnalisé) en priorité
    final nom = item['nom_objet'] as String? ?? item['nom'] as String? ?? 'Sans nom';
    final type = item['type'] as String? ?? '';
    final quantite = _parseInt(item['quantite']) == 0 ? 1 : _parseInt(item['quantite']);
    final equipee = item['equipee'] as bool? ?? false;
    final description = item['description'] as String? ?? '';
    
    // IDs pour résolution
    final armeId = item['arme_id'];
    final armureId = item['armure_id'];
    final equipementId = item['equipement_id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: equipee
          ? SymbaroumColors.cardBackground.withValues(alpha: 0.9)
          : SymbaroumColors.cardBackground.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: equipee ? SymbaroumColors.primary : SymbaroumColors.textPrimary.withValues(alpha: 0.2),
          width: equipee ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: SymbaroumColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: equipee ? SymbaroumColors.primary : SymbaroumColors.textPrimary.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            _getItemIcon(type),
            color: equipee ? SymbaroumColors.primary : SymbaroumColors.textPrimary,
          ),
        ),
        title: Text(
          nom,
          style: GoogleFonts.cinzel(
            color: equipee ? SymbaroumColors.primary : SymbaroumColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              _getTypeLabel(type),
              style: GoogleFonts.lato(
                color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            if (quantite > 1) ...[
              const SizedBox(width: 8),
              Text(
                '× $quantite',
                style: GoogleFonts.lato(
                  color: SymbaroumColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        trailing: equipee
            ? const Icon(Icons.check_circle, color: SymbaroumColors.primary)
            : null,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Détails de l'objet (résolu depuis Firestore)
                _buildItemDetails(type, armeId, armureId, equipementId),

                // Description personnalisée
                if (description.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    'Description:',
                    style: GoogleFonts.cinzel(
                      color: SymbaroumColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.lato(
                      color: SymbaroumColors.textPrimary.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Actions
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Équiper/Déséquiper (si arme ou armure)
                    if (type == 'arme' || type == 'armure')
                      ElevatedButton.icon(
                        onPressed: () => _toggleEquip(item),
                        icon: Icon(equipee ? Icons.close : Icons.shield, size: 16),
                        label: Text(equipee ? 'DÉSÉQUIPER' : 'ÉQUIPER'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: equipee ? Colors.red[700] : SymbaroumColors.primary,
                          foregroundColor: Colors.black,
                          textStyle: GoogleFonts.cinzel(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // Modifier quantité
                    if (quantite > 0 && type != 'arme' && type != 'armure')
                      OutlinedButton.icon(
                        onPressed: () => _editQuantity(item),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('QUANTITÉ'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SymbaroumColors.textPrimary,
                          side: const BorderSide(color: SymbaroumColors.textPrimary),
                          textStyle: GoogleFonts.cinzel(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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

  IconData _getItemIcon(String type) {
    switch (type) {
      case 'arme':
        return Icons.hardware;
      case 'armure':
        return Icons.shield;
      case 'equipement':
        return Icons.backpack;
      case 'artefact':
        return Icons.auto_awesome;
      default:
        return Icons.inventory;
    }
  }

  String _getTypeLabel(String type) {
    const labels = {
      'arme': 'Arme',
      'armure': 'Armure',
      'equipement': 'Équipement',
      'artefact': 'Artefact',
    };
    return labels[type] ?? type;
  }

  Widget _buildItemDetails(String type, dynamic armeId, dynamic armureId, dynamic equipementId) {
    // Déterminer la collection et l'ID (convertir en String car IDs sont des int)
    String? collection;
    String? itemId;
    
    if (type == 'arme' && armeId != null) {
      collection = 'armes';
      itemId = armeId.toString();
    } else if (type == 'armure' && armureId != null) {
      collection = 'armures';
      itemId = armureId.toString();
    } else if (type == 'equipement' && equipementId != null) {
      collection = 'equipements';
      itemId = equipementId.toString();
    }

    if (collection == null || itemId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(firestoreServiceProvider).getDocumentWithFallback(
        collection: collection,
        id: itemId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == 'arme') ...[
              _buildDetailRow('Dégâts', data['degats']?.toString() ?? 'N/A'),
              _buildDetailRow('Portée', data['portee']?.toString() ?? 'N/A'),
              if (data['prix'] != null)
                _buildDetailRow('Prix', '${data['prix']} ortegs'),
            ],
            if (type == 'armure') ...[
              _buildDetailRow('Protection', data['protection']?.toString() ?? 'N/A'),
              _buildDetailRow('Malus défense', data['malus_defense']?.toString() ?? '0'),
              if (data['prix'] != null)
                _buildDetailRow('Prix', '${data['prix']} ortegs'),
            ],
            if (type == 'equipement') ...[
              if (data['prix'] != null)
                _buildDetailRow('Prix', '${data['prix']} ortegs'),
              if (data['description'] != null && data['description'].toString().isNotEmpty)
                _buildDetailRow('Description', data['description'].toString()),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.lato(
                color: SymbaroumColors.textPrimary.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                color: SymbaroumColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleEquip(Map<String, dynamic> item) async {
    try {
      final inventaire = List<Map<String, dynamic>>.from(
        widget.data['inventaire'] as List<dynamic>? ?? [],
      );

      // Trouver l'item par nom_objet et type
      final nomObjet = item['nom_objet'] as String? ?? item['nom'] as String?;
      final type = item['type'] as String?;
      
      final index = inventaire.indexWhere((i) =>
          i['nom_objet'] == nomObjet && i['type'] == type);

      if (index != -1) {
        final currentEquipee = inventaire[index]['equipee'] as bool? ?? false;
        inventaire[index]['equipee'] = !currentEquipee;

        await _firestore.updateDocument(
          collection: 'personnages',
          documentId: widget.personnageId,
          data: {'document.inventaire': inventaire},
        );

        NotificationService.success(
          currentEquipee ? 'Équipement retiré' : 'Équipement porté',
        );
      }
    } catch (e) {
      NotificationService.error('Erreur: $e');
    }
  }

  Future<void> _editQuantity(Map<String, dynamic> item) async {
    final quantite = _parseInt(item['quantite']);
    final controller = TextEditingController(
      text: '${quantite == 0 ? 1 : quantite}',
    );

    final newQuantity = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SymbaroumColors.cardBackground,
        title: Text(
          'Modifier la quantité',
          style: GoogleFonts.cinzel(color: SymbaroumColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Quantité',
            labelStyle: GoogleFonts.lato(color: SymbaroumColors.textPrimary.withValues(alpha: 0.7)),
            filled: true,
            fillColor: SymbaroumColors.background,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ANNULER',
              style: GoogleFonts.cinzel(color: SymbaroumColors.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SymbaroumColors.primary,
              foregroundColor: Colors.black,
            ),
            child: Text(
              'VALIDER',
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (newQuantity != null && newQuantity >= 0) {
      try {
        final inventaire = List<Map<String, dynamic>>.from(
          widget.data['inventaire'] as List<dynamic>? ?? [],
        );

        final nomObjet = item['nom_objet'] as String? ?? item['nom'] as String?;
        final type = item['type'] as String?;
        
        final index = inventaire.indexWhere((i) =>
            i['nom_objet'] == nomObjet && i['type'] == type);

        if (index != -1) {
          if (newQuantity == 0) {
            // Supprimer l'objet
            inventaire.removeAt(index);
            NotificationService.success('Objet supprimé');
          } else {
            inventaire[index]['quantite'] = newQuantity;
            NotificationService.success('Quantité modifiée');
          }

          await _firestore.updateDocument(
            collection: 'personnages',
            documentId: widget.personnageId,
            data: {'document.inventaire': inventaire},
          );
        }
      } catch (e) {
        NotificationService.error('Erreur: $e');
      }
    }
  }

  Future<void> _editMoney(String currency, int currentValue) async {
    final controller = TextEditingController(text: '$currentValue');

    final newValue = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SymbaroumColors.cardBackground,
        title: Text(
          'Modifier ${currency.toUpperCase()}',
          style: GoogleFonts.cinzel(color: SymbaroumColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.lato(color: SymbaroumColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Montant',
            labelStyle: GoogleFonts.lato(color: SymbaroumColors.textPrimary.withValues(alpha: 0.7)),
            filled: true,
            fillColor: SymbaroumColors.background,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ANNULER',
              style: GoogleFonts.cinzel(color: SymbaroumColors.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SymbaroumColors.primary,
              foregroundColor: Colors.black,
            ),
            child: Text(
              'VALIDER',
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (newValue != null && newValue >= 0) {
      try {
        final argent = Map<String, dynamic>.from(
          widget.data['argent'] as Map<String, dynamic>? ?? {},
        );
        
        argent[currency] = newValue;

        await _firestore.updateDocument(
          collection: 'personnages',
          documentId: widget.personnageId,
          data: {'document.argent': argent},
        );

        NotificationService.success('Argent modifié');
      } catch (e) {
        NotificationService.error('Erreur: $e');
      }
    }
  }
}