import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/firebase_providers.dart';

/// Onglet Caractéristiques - Affichage des caractéristiques et équipements (éditable pour joueur)
class PlayerCaracteristiquesTab extends ConsumerWidget {
  final String personnageId;
  final Map<String, dynamic> personnage;
  final Map<String, dynamic> document;

  const PlayerCaracteristiquesTab({
    super.key,
    required this.personnageId,
    required this.personnage,
    required this.document,
  });

  // Helper pour parser int/string depuis Firestore
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Surveiller le provider pour avoir l'inventaire frais
    final personnageAsync = ref.watch(personnageProvider(personnageId));
    
    return personnageAsync.when(
      data: (freshData) {
        // FreshData contient: document (infos statiques) + inventaire (à la racine, dynamique)
        final document = freshData?['document'] as Map<String, dynamic>? ?? {};
        final caracteristiques = document['caracteristiques'] as Map<String, dynamic>? ?? {};
        // Inventaire correct est dans document, pas à la racine (la racine n'est pas toujours à jour)
        final inventaire = List<Map<String, dynamic>>.from(document['inventaire'] ?? []);
        final talents = List<Map<String, dynamic>>.from(document['talents'] ?? []);
        final traits = List<Map<String, dynamic>>.from(document['traits'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Caractéristiques principales (sans titre)
        _buildCharacteristicsGrid(caracteristiques),
        
        const SizedBox(height: 24),
        
        // Statistiques (sans titre)
        _buildStatistiques(context, ref, caracteristiques),
        
        const SizedBox(height: 24),
        
        // Équipement (sans titre)
        _buildEquipement(context, ref, inventaire),
        
        const SizedBox(height: 24),
        
        // Défense et Protection (sans titre) - avec FutureBuilder pour les talents/traits
        FutureBuilder<Map<String, dynamic>>(
          future: _calculateDefenseAndProtectionAsync(ref, inventaire, talents, traits, caracteristiques),
          builder: (context, snapshot) {
            final data = snapshot.data ?? {
              'defense': _parseInt(caracteristiques['agilite'], 10),
              'defenseModifiers': <Map<String, String>>[],
              'protectionDisplay': '...',
              'protectionSources': <Map<String, String>>[],
              'protectionDiceList': <String>[],
              'protectionFixe': 0,
            };
            return _buildDefense(context, data);
          },
        ),
      ],
    );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Erreur: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildCharacteristicsGrid(Map<String, dynamic> caracteristiques) {
    // Ordre alphabétique des 8 caractéristiques principales
    final characteristics = [
      'agilite',
      'astuce',
      'discretion',
      'force',
      'persuasion',
      'precision',
      'vigilance',
      'volonte',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: characteristics.length,
      itemBuilder: (context, index) {
        final key = characteristics[index];
        final value = _parseInt(caracteristiques[key], 10);
        return _buildCharacteristicCard(_getDisplayName(key), value);
      },
    );
  }

  Widget _buildCharacteristicCard(String label, int value) {
    return Card(
      color: Colors.brown.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistiques(BuildContext context, WidgetRef ref, Map<String, dynamic> caracteristiques) {
    final enduranceActuelle = _parseInt(caracteristiques['endurance_actuelle'], 10);
    final enduranceMax = _parseInt(caracteristiques['endurance_max'], 10);
    final resistanceDouleur = _parseInt(caracteristiques['resistance_douleur'], 5);
    final corruption = _parseInt(caracteristiques['corruption'], 0);
    final corruptionPermanente = _parseInt(caracteristiques['corruption_permanente'], 0);
    final seuilCorruption = _parseInt(caracteristiques['seuil_corruption'], 5);

    return Column(
      children: [
        // Ligne 1: Endurance | Résistance à la douleur
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _editEndurance(context, ref, enduranceActuelle, enduranceMax),
                child: Card(
                  color: Colors.red.shade900.withValues(alpha: 0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Endurance',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit, size: 16, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$enduranceActuelle / $enduranceMax',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                color: Colors.orange.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.healing, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Résist. douleur',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$resistanceDouleur',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Ligne 2: Corruption Temporaire | Corruption Permanente
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _editCorruptionTemporaire(context, ref, corruption),
                child: Card(
                  color: Colors.purple.shade900.withValues(alpha: 0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.whatshot, color: Colors.purple, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Corr. Temp.',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Icon(Icons.edit, size: 16, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$corruption',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _editCorruptionPermanente(context, ref, corruptionPermanente),
                child: Card(
                  color: Colors.deepPurple.shade900.withValues(alpha: 0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.dangerous, color: Colors.deepPurple, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Corr. Perm.',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Icon(Icons.edit, size: 16, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$corruptionPermanente / $seuilCorruption',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEquipement(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> inventaire) {
    // Filtrer les équipements équipés
    final equipes = inventaire.where((item) => item['equipee'] == true).toList();
    
    // Séparer par emplacement
    final mainGauche = equipes.where((item) => item['emplacement'] == 'main_gauche').firstOrNull;
    final armure = equipes.where((item) => item['emplacement'] == 'armure').firstOrNull;
    final mainDroite = equipes.where((item) => item['emplacement'] == 'main_droite').firstOrNull;

    return Row(
      children: [
        Expanded(
          child: _buildEquipmentSlot(context, ref, 'Main Gauche', Icons.back_hand, mainGauche, flip: true),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEquipmentSlot(context, ref, 'Armure', Icons.shield, armure),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEquipmentSlot(context, ref, 'Main Droite', Icons.back_hand, mainDroite),
        ),
      ],
    );
  }

  Widget _buildEquipmentSlot(BuildContext context, WidgetRef ref, String label, IconData icon, Map<String, dynamic>? item, {bool flip = false}) {
    return GestureDetector(
      onTap: item != null ? () => _showItemDetails(context, ref, item) : null,
      child: Card(
        color: item != null ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              flip
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.14159),
                      child: Icon(
                        icon,
                        size: 32,
                        color: item != null ? Colors.green : Colors.grey,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 32,
                      color: item != null ? Colors.green : Colors.grey,
                    ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                item != null ? (item['nom_objet'] as String? ?? 'Sans nom') : 'Vide',
                style: TextStyle(
                  fontSize: 11,
                  color: item != null ? Colors.white : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefense(BuildContext context, Map<String, dynamic> data) {
    final defense = data['defense'] as int;
    final defenseModifiers = data['defenseModifiers'] as List<Map<String, String>>;
    final protectionDisplay = data['protectionDisplay'] as String;
    final protectionSources = data['protectionSources'] as List<Map<String, String>>;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showDefenseDetails(context, defense, defenseModifiers),
            child: Card(
              color: Colors.blue.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: const [
                        Icon(Icons.shield, color: Colors.blue, size: 24),
                        Text(
                          'Défense',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$defense',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _showProtectionDetails(context, protectionDisplay, protectionSources),
            child: Card(
              color: Colors.grey.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: const [
                        Icon(Icons.security, color: Colors.grey, size: 24),
                        Text(
                          'Protection',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      protectionDisplay,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Calculer la protection totale avec format XdY+Z (async pour récupérer les talents)
  Future<Map<String, dynamic>> _calculateDefenseAndProtectionAsync(
    WidgetRef ref,
    List<Map<String, dynamic>> inventaire,
    List<Map<String, dynamic>> talents,
    List<Map<String, dynamic>> traits,
    Map<String, dynamic> caracteristiques,
  ) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    
    // Calcul de la Défense
    int defenseBase = _parseInt(caracteristiques['agilite'], 10);
    int defenseModif = 0;
    final defenseModifiers = <Map<String, String>>[];
    
    // Modificateurs de défense depuis les traits
    for (final traitRef in traits) {
      final traitId = traitRef['trait_id'];
      final niveau = _parseInt(traitRef['niveau'], 1);
      
      if (traitId != null) {
        try {
          final traitDoc = await firestoreService.getDocumentWithFallback(
            collection: 'traits',
            id: traitId,
          );
          
          if (traitDoc != null) {
            final nom = traitDoc['nom'] as String? ?? 'Trait';
            final niveauType = traitDoc['niveau_type'] as String? ?? '';
            final isMonstrueux = niveauType.toLowerCase() == 'monstrueux';
            
            int modif = 0;
            if (isMonstrueux) {
              // Pour les traits monstrueux, les modifs sont directement à la racine
              final modifKey = 'modif_defense_${['i', 'ii', 'iii'][niveau - 1]}';
              modif = _parseInt(traitDoc[modifKey], 0);
            } else {
              // Pour les traits normaux, les modifs sont dans des objets imbriqués
              final niveauKey = _getNiveauKey(niveau);
              final niveauData = traitDoc[niveauKey] as Map<String, dynamic>?;
              if (niveauData != null && niveauData['modificateur_defense'] != null) {
                modif = _parseInt(niveauData['modificateur_defense'], 0);
              }
            }
            
            if (modif != 0) {
              defenseModif += modif;
              final niveauLabel = isMonstrueux ? ['I', 'II', 'III'][niveau - 1] : ['N', 'A', 'M'][niveau - 1];
              defenseModifiers.add({
                'source': '$nom ($niveauLabel)',
                'valeur': modif >= 0 ? '+$modif' : '$modif',
              });
            }
          }
        } catch (e) {
          // Error retrieving trait
        }
      }
    }
    
    // Modificateurs de défense depuis les talents
    for (final talentRef in talents) {
      final talentId = talentRef['talent_id'];
      final niveau = _parseInt(talentRef['niveau'], 1);
      
      // debugPrint('🔍 Checking talent: id=$talentId, niveau=$niveau');
      
      if (talentId != null) {
        try {
          final talentDoc = await firestoreService.getDocumentWithFallback(
            collection: 'talents',
            id: talentId,
          );
          
          if (talentDoc != null) {
            final nom = talentDoc['nom'] as String? ?? 'Talent';
            
            // Pour les talents, les modifs sont directement à la racine avec _novice/_adepte/_maitre
            final modifKey = 'modif_defense_${_getNiveauKey(niveau)}';
            final modif = _parseInt(talentDoc[modifKey], 0);
            
            if (modif != 0) {
              defenseModif += modif;
              defenseModifiers.add({
                'source': '$nom (${_getNiveauLabel(niveau)})',
                'valeur': modif >= 0 ? '+$modif' : '$modif',
              });
            }
          }
        } catch (e) {
          // Error retrieving talent
        }
      }
    }
    
    // Modificateurs de défense depuis les boucliers équipés
    final armes = inventaire.where((item) => item['type'] == 'arme' && item['equipee'] == true);
    for (final arme in armes) {
      if (arme['arme_id'] != null) {
        try {
          final armeData = await firestoreService.getDocumentWithFallback(
            collection: 'armes',
            id: arme['arme_id'],
          );
          
          if (armeData != null) {
            final modifDefense = _parseInt(armeData['modif_defense'], 0);
            if (modifDefense != 0) {
              final nom = arme['nom_objet'] as String? ?? 'Arme';
              defenseModif += modifDefense;
              defenseModifiers.add({
                'source': nom,
                'valeur': modifDefense >= 0 ? '+$modifDefense' : '$modifDefense',
              });
            }
          }
        } catch (e) {
          // Error retrieving weapon
        }
      }
    }
    
    // Malus de défense depuis les armures équipées
    final armuresEquipees = inventaire.where((item) => item['type'] == 'armure' && item['equipee'] == true);
    for (final armure in armuresEquipees) {
      if (armure['armure_id'] != null) {
        try {
          final armureData = await firestoreService.getDocumentWithFallback(
            collection: 'armures',
            id: armure['armure_id'],
          );
          
          if (armureData != null) {
            final malusDefense = _parseInt(armureData['malus_defense'], 0);
            if (malusDefense != 0) {
              final nom = armure['nom_objet'] as String? ?? 'Armure';
              defenseModif += malusDefense;
              defenseModifiers.add({
                'source': nom,
                'valeur': malusDefense >= 0 ? '+$malusDefense' : '$malusDefense',
              });
            }
          }
        } catch (e) {
          // Error retrieving armor
        }
      }
    }
    
    final defenseTotal = defenseBase + defenseModif;
    
    // Calcul de la Protection (code existant)
    int protectionFixe = 0;
    final diceList = <String>[];
    final sources = <Map<String, String>>[];
    
    // Protection des armures équipées
    final armures = inventaire.where((item) => item['type'] == 'armure' && item['equipee'] == true);
    // debugPrint('🛡️ Armures équipées: ${armures.length}');
    
    for (final armure in armures) {
      // debugPrint('🔍 Checking armure: ${armure['nom_objet']}, id=${armure['armure_id']}');
      // Fetcher les données complètes de l'armure depuis Firestore
      if (armure['armure_id'] != null) {
        try {
          final armureData = await firestoreService.getDocumentWithFallback(
            collection: 'armures',
            id: armure['armure_id'],
          );
          
          // debugPrint('✅ Armure data: $armureData');
          
          if (armureData != null) {
            final prot = armureData['protection'];
            final nom = armure['nom_objet'] as String? ?? 'Armure';
            
            // debugPrint('🔢 Protection value: $prot (type: ${prot.runtimeType})');
            
            if (prot is int) {
              protectionFixe += prot;
              sources.add({'source': nom, 'valeur': '+$prot'});
            } else if (prot is String) {
              // Normaliser en minuscules pour gérer "1D4" et "1d4"
              final protNormalized = prot.toLowerCase();
              
              // Format "1d4" ou "1d6+2"
              if (protNormalized.contains('d')) {
                final parsed = _parseDiceNotation(protNormalized);
                if (parsed['dice'] != null) {
                  diceList.add(parsed['dice'] as String);
                }
                if (parsed['bonus'] != null) {
                  protectionFixe += parsed['bonus'] as int;
                }
                sources.add({'source': nom, 'valeur': protNormalized});
              } else {
                final val = int.tryParse(protNormalized) ?? 0;
                protectionFixe += val;
                sources.add({'source': nom, 'valeur': '+$val'});
              }
            }
          }
        } catch (e) {
          // Error retrieving armor
        }
      }
    }
    
    // Protection des boucliers (armes équipées avec modif_protection)
    final armesEquipees = inventaire.where((item) => item['type'] == 'arme' && item['equipee'] == true);
    for (final arme in armesEquipees) {
      if (arme['arme_id'] != null) {
        try {
          final armeData = await firestoreService.getDocumentWithFallback(
            collection: 'armes',
            id: arme['arme_id'],
          );
          
          if (armeData != null) {
            final modifProtection = _parseInt(armeData['modif_protection'], 0);
            if (modifProtection > 0) {
              protectionFixe += modifProtection;
              final nom = arme['nom_objet'] as String? ?? 'Arme';
              sources.add({'source': nom, 'valeur': '+$modifProtection'});
            }
          }
        } catch (e) {
          debugPrint('Erreur lors de la récupération de l\'arme ${arme['arme_id']}: $e');
        }
      }
    }
    
    // Protection des traits (notamment Armure naturelle pour les monstrueux)
    // debugPrint('🐾 Checking ${traits.length} traits for protection modifiers');
    for (final traitRef in traits) {
      final traitId = traitRef['trait_id'];
      final niveau = _parseInt(traitRef['niveau'], 1);
      
      if (traitId != null) {
        try {
          final traitDoc = await firestoreService.getDocumentWithFallback(
            collection: 'traits',
            id: traitId,
          );
          
          if (traitDoc != null) {
            final nom = traitDoc['nom'] as String? ?? 'Trait';
            final niveauType = traitDoc['niveau_type'] as String? ?? '';
            final isMonstrueux = niveauType.toLowerCase() == 'monstrueux';
            
            int protectionModif = 0;
            if (isMonstrueux) {
              // Pour les traits monstrueux, les modifs sont directement à la racine
              final modifKey = 'modif_protection_${['i', 'ii', 'iii'][niveau - 1]}';
              protectionModif = _parseInt(traitDoc[modifKey], 0);
              // debugPrint('🔑 Monstrueux - $nom - modifKey=$modifKey, protectionModif=$protectionModif');
            } else {
              // Pour les traits normaux, les modifs sont dans des objets imbriqués
              final niveauKey = _getNiveauKey(niveau);
              final niveauData = traitDoc[niveauKey] as Map<String, dynamic>?;
              if (niveauData != null && niveauData['modificateur_protection'] != null) {
                protectionModif = _parseInt(niveauData['modificateur_protection'], 0);
              }
            }
            
            if (protectionModif != 0) {
              protectionFixe += protectionModif;
              final niveauLabel = isMonstrueux ? ['I', 'II', 'III'][niveau - 1] : ['N', 'A', 'M'][niveau - 1];
              sources.add({
                'source': '$nom ($niveauLabel)',
                'valeur': '+$protectionModif',
              });
              // debugPrint('✨ Protection modifier: +$protectionModif from $nom');
            }
          }
        } catch (e) {
          debugPrint('Erreur lors de la récupération du trait $traitId: $e');
        }
      }
    }
    
    // Protection des talents en fonction du niveau
    // debugPrint('🎯 Checking ${talents.length} talents for protection modifiers');
    for (final talentRef in talents) {
      final talentId = talentRef['talent_id'];
      final niveau = _parseInt(talentRef['niveau'], 1);
      
      // debugPrint('🔍 Checking talent for protection: id=$talentId, niveau=$niveau');
      
      if (talentId != null) {
        try {
          final talentDoc = await firestoreService.getDocumentWithFallback(
            collection: 'talents',
            id: talentId,
          );
          
          if (talentDoc != null) {
            final nom = talentDoc['nom'] as String? ?? 'Talent';
            
            // Pour les talents, les modifs sont directement à la racine avec _novice/_adepte/_maitre
            final modifKey = 'modif_protection_${_getNiveauKey(niveau)}';
            final protection = talentDoc[modifKey];
            
            // debugPrint('🔑 Talent protection - modifKey=$modifKey, protection=$protection');
            
            if (protection != null) {
              
              if (protection is int) {
                protectionFixe += protection;
                sources.add({'source': '$nom (Niv. $niveau)', 'valeur': '+$protection'});
              } else if (protection is String && protection.contains('d')) {
                final parsed = _parseDiceNotation(protection);
                if (parsed['dice'] != null) {
                  diceList.add(parsed['dice'] as String);
                }
                if (parsed['bonus'] != null && (parsed['bonus'] as int) != 0) {
                  protectionFixe += parsed['bonus'] as int;
                }
                sources.add({'source': '$nom (Niv. $niveau)', 'valeur': protection});
              }
            }
          }
        } catch (e) {
          debugPrint('Erreur lors de la récupération du talent $talentId: $e');
        }
      }
    }
    
    // Format d'affichage
    String display = _formatProtectionDisplay(diceList, protectionFixe);
    
    return {
      'defense': defenseTotal,
      'defenseModifiers': defenseModifiers,
      'protectionDisplay': display,
      'protectionSources': sources,
      'protectionDiceList': diceList,
      'protectionFixe': protectionFixe,
    };
  }

  // Parse notation de dés "1d6+2" -> {dice: "1d6", bonus: 2}
  Map<String, dynamic> _parseDiceNotation(String notation) {
    if (notation.contains('+')) {
      final parts = notation.split('+');
      return {
        'dice': parts[0].trim(),
        'bonus': int.tryParse(parts[1].trim()) ?? 0,
      };
    } else if (notation.contains('-')) {
      final parts = notation.split('-');
      return {
        'dice': parts[0].trim(),
        'bonus': -(int.tryParse(parts[1].trim()) ?? 0),
      };
    } else {
      return {'dice': notation.trim(), 'bonus': 0};
    }
  }

  // Formater l'affichage de la protection
  String _formatProtectionDisplay(List<String> diceList, int bonus) {
    if (diceList.isEmpty && bonus == 0) {
      return '0';
    }
    
    final parts = <String>[];
    
    // Grouper les dés identiques (ex: 1d6 + 1d6 = 2d6)
    final diceGroups = <String, int>{};
    for (final dice in diceList) {
      final match = RegExp(r'(\d+)d(\d+)').firstMatch(dice);
      if (match != null) {
        final count = int.parse(match.group(1)!);
        final faces = match.group(2)!;
        final key = 'd$faces';
        diceGroups[key] = (diceGroups[key] ?? 0) + count;
      }
    }
    
    // Ajouter les dés groupés
    for (final entry in diceGroups.entries) {
      parts.add('${entry.value}${entry.key}');
    }
    
    // Construire la formule finale
    if (parts.isEmpty) {
      return bonus.toString();
    }
    
    String result = parts.join('+');
    if (bonus > 0) {
      result += '+$bonus';
    } else if (bonus < 0) {
      result += '$bonus';
    }
    
    return result;
  }

  // Convertir niveau en clé Firestore
  String _getNiveauKey(int niveau) {
    switch (niveau) {
      case 1:
        return 'novice';
      case 2:
        return 'adepte';
      case 3:
        return 'maitre';
      default:
        return 'novice';
    }
  }

  String _getNiveauLabel(int niveau) {
    switch (niveau) {
      case 1:
        return 'N';
      case 2:
        return 'A';
      case 3:
        return 'M';
      default:
        return 'Niv. $niveau';
    }
  }

  String _getDisplayName(String key) {
    const names = {
      'agilite': 'Agilité',
      'astuce': 'Astuce',
      'discretion': 'Discrétion',
      'force': 'Force',
      'persuasion': 'Persuasion',
      'precision': 'Précision',
      'vigilance': 'Vigilance',
      'volonte': 'Volonté',
    };
    return names[key] ?? key;
  }

  // Édition Endurance
  Future<void> _editEndurance(BuildContext context, WidgetRef ref, int actuelle, int max) async {
    final controller = TextEditingController(text: actuelle.toString());
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'Endurance actuelle'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Endurance (max: $max)',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) {
                Navigator.pop(context, value.clamp(0, max));
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null) {
      // TODO: Mettre à jour Firestore
    }
  }

  // Édition Corruption Temporaire
  Future<void> _editCorruptionTemporaire(BuildContext context, WidgetRef ref, int current) async {
    final controller = TextEditingController(text: current.toString());
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la Corruption Temporaire'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Corruption Temporaire',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null) {
      // TODO: Mettre à jour Firestore
    }
  }

  // Édition Corruption Permanente
  Future<void> _editCorruptionPermanente(BuildContext context, WidgetRef ref, int current) async {
    final controller = TextEditingController(text: current.toString());
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la Corruption Permanente'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Corruption Permanente',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null) {
      // TODO: Mettre à jour Firestore
    }
  }

  // Afficher détails item
  Future<void> _showItemDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> item) async {
    final type = item['type'] as String? ?? 'objet';
    final nom = item['nom_objet'] as String? ?? 'Objet';
    final description = item['description'] as String? ?? '';
    
    // Récupérer les données complètes depuis Firestore
    final firestoreService = ref.read(firestoreServiceProvider);
    Map<String, dynamic>? itemData;
    
    if (type == 'arme' && item['arme_id'] != null) {
      itemData = await firestoreService.getDocumentWithFallback(collection: 'armes', id: item['arme_id']);
    } else if (type == 'armure' && item['armure_id'] != null) {
      itemData = await firestoreService.getDocumentWithFallback(collection: 'armures', id: item['armure_id']);
    }
    
    // Récupérer les qualités
    List<String> qualitesNoms = [];
    if (type == 'arme' && item['qualites_armes'] != null) {
      final qualitesArmes = List<int>.from(item['qualites_armes']);
      for (int id in qualitesArmes) {
        final qualite = await firestoreService.getDocumentWithFallback(collection: 'qualites_armes', id: id);
        if (qualite != null && qualite['nom'] != null) {
          qualitesNoms.add(qualite['nom']);
        }
      }
    } else if (type == 'armure' && item['qualites_armures'] != null) {
      final qualitesArmures = List<int>.from(item['qualites_armures']);
      for (int id in qualitesArmures) {
        final qualite = await firestoreService.getDocumentWithFallback(collection: 'qualites_armures', id: id);
        if (qualite != null && qualite['nom'] != null) {
          qualitesNoms.add(qualite['nom']);
        }
      }
    }
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nom),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              if (description.isNotEmpty) ...[
                Text(description, style: TextStyle(color: Colors.grey[300])),
                const SizedBox(height: 12),
              ],
              
              // Qualités
              if (qualitesNoms.isNotEmpty) ...[
                const Text('Qualités', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: qualitesNoms.map((q) => Chip(
                    label: Text(q, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    backgroundColor: type == 'arme' ? Colors.red.shade700 : Colors.blue.shade700,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],
              
              // Divider avant les détails techniques
              if (itemData != null) ...[
                const Divider(),
                const SizedBox(height: 8),
              ],
              
              // Détails techniques
              if (itemData != null) ...[
                if (type == 'arme') ...[
                  if (itemData['degats'] != null)
                    _buildDetailRow('Dégâts', itemData['degats'].toString()),
                  if (itemData['portee'] != null)
                    _buildDetailRow('Portée', itemData['portee'].toString()),
                  if (itemData['modif_defense'] != null && _parseInt(itemData['modif_defense'], 0) != 0)
                    _buildDetailRow('Modificateur défense', 
                      _parseInt(itemData['modif_defense'], 0) >= 0 
                        ? '+${itemData['modif_defense']}' 
                        : itemData['modif_defense'].toString()),
                  if (itemData['modif_protection'] != null && _parseInt(itemData['modif_protection'], 0) != 0)
                    _buildDetailRow('Modificateur protection', 
                      _parseInt(itemData['modif_protection'], 0) >= 0 
                        ? '+${itemData['modif_protection']}' 
                        : itemData['modif_protection'].toString()),
                  if (itemData['nom'] != null)
                    _buildDetailRow('Nom complet', itemData['nom'].toString()),
                  if (itemData['categorie'] != null)
                    _buildDetailRow('Catégorie', itemData['categorie'].toString()),
                  if (itemData['prix'] != null)
                    _buildDetailRow('Prix', '${itemData['prix']} Shillings'),
                ],
                if (type == 'armure') ...[
                  if (itemData['protection'] != null)
                    _buildDetailRow('Protection', itemData['protection'].toString()),
                  if (itemData['malus_defense'] != null)
                    _buildDetailRow('Malus défense', itemData['malus_defense'].toString()),
                  if (itemData['nom'] != null)
                    _buildDetailRow('Nom complet', itemData['nom'].toString()),
                  if (itemData['categorie'] != null)
                    _buildDetailRow('Catégorie', itemData['categorie'].toString()),
                  if (itemData['prix'] != null)
                    _buildDetailRow('Prix', '${itemData['prix']} Shillings'),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _unequipItem(context, ref, item);
            },
            child: const Text('Déséquiper'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Future<void> _unequipItem(BuildContext context, WidgetRef ref, Map<String, dynamic> item) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      // Lire les données fraîches depuis le provider
      final personnageAsync = await ref.read(personnageProvider(personnageId).future);
      final inventaire = List<Map<String, dynamic>>.from(personnageAsync?['inventaire'] ?? []);
      
      // Trouver l'index de l'item par son ID unique
      final index = inventaire.indexWhere((i) => i['id'] == item['id']);
      if (index == -1) return;
      
      // Déséquiper l'item
      inventaire[index]['equipee'] = false;
      inventaire[index]['emplacement'] = null;
      
      await firestoreService.updateDocument(
        collection: 'personnages',
        documentId: personnageId,
        data: {'inventaire': inventaire},
      );
      
      // Invalider le provider pour rafraîchir l'UI
      ref.invalidate(personnageProvider(personnageId));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item['nom_objet']} déséquipé'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du déséquipement: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Afficher détails défense
  void _showDefenseDetails(BuildContext context, int defense, List<Map<String, String>> modifiers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calcul de la Défense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('La Défense est basée sur votre Agilité + modificateurs.'),
            const SizedBox(height: 12),
            ...modifiers.map((mod) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(mod['source']!),
                  Text(mod['valeur']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$defense', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
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

  // Afficher détails protection
  void _showProtectionDetails(BuildContext context, String display, List<Map<String, String>> sources) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Protection'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Formule totale en gros
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    display,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Détail des sources :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (sources.isEmpty)
                const Text(
                  'Aucune protection équipée',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...sources.map((source) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          source['source']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        source['valeur']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                )),
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
}
