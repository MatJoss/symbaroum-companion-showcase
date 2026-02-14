/// Modèle Personnage complet
library;

import 'package:flutter/foundation.dart';

import 'caracteristiques.dart';
import 'game_data.dart';
import 'inventaire.dart';
import 'argent.dart';
import 'talent.dart';
import 'pouvoir.dart';
import 'trait.dart';
import 'atout_fardeau.dart';
import 'json_helpers.dart';

/// Modèle Personnage
class Personnage {
  final int id;
  final String nom;
  final int? raceId;
  final int? archetypeId;
  final int? classeId;
  final bool estPj;
  final String? joueurConnecte;
  final int niveau;
  final String? avatarUrl;
  final String? avatarThumbnailUrl;
  final String? notes;
  final int? age;
  final double? poids;
  final double? taille;
  final String? couleurOmbre;

  // Relations
  final Race? race;
  final Archetype? archetype;
  final Classe? classe;
  final Caracteristiques? caracteristiques;
  final List<InventaireItem> inventaire;
  final Argent? argent;
  final List<PersonnageTalent> talents;
  final List<PersonnageTrait> traits;
  final List<PersonnagePouvoir> pouvoirs;
  final List<PersonnageRituel> rituels;
  final List<PersonnageAtoutFardeau> atoutsFardeaux;

  const Personnage({
    required this.id,
    required this.nom,
    this.raceId,
    this.archetypeId,
    this.classeId,
    this.estPj = true,
    this.joueurConnecte,
    this.niveau = 1,
    this.avatarUrl,
    this.avatarThumbnailUrl,
    this.notes,
    this.age,
    this.poids,
    this.taille,
    this.couleurOmbre,
    this.race,
    this.archetype,
    this.classe,
    this.caracteristiques,
    this.inventaire = const [],
    this.argent,
    this.talents = const [],
    this.traits = const [],
    this.pouvoirs = const [],
    this.rituels = const [],
    this.atoutsFardeaux = const [],
  });

  /// Crée un Personnage depuis un JSON
  factory Personnage.fromJson(Map<String, dynamic> json) {
    try {
      return Personnage(
        id: parseInt(json['id'], 0),
        nom: json['nom'] as String,
        raceId: parseIntOrNull(json['race_id']),
        archetypeId: parseIntOrNull(json['archetype_id']),
        classeId: parseIntOrNull(json['classe_id']),
        estPj: json['est_pj'] as bool? ?? true,
        joueurConnecte: json['joueur_connecte'] as String?,
        niveau: parseInt(json['niveau'], 1),
        avatarUrl: json['avatar_url'] as String?,
        avatarThumbnailUrl: json['avatar_thumbnail_url'] as String?,
        notes: json['notes'] as String?,
        age: parseIntOrNull(json['age']),
        poids: parseDoubleOrNull(json['poids']),
        taille: parseDoubleOrNull(json['taille']),
        couleurOmbre: json['couleur_ombre'] as String?,
        race: json['race'] != null ? Race.fromJson(json['race']) : null,
        archetype: json['archetype'] != null
            ? Archetype.fromJson(json['archetype'])
            : null,
        classe: json['classe'] != null ? Classe.fromJson(json['classe']) : null,
        caracteristiques: json['caracteristiques'] != null
            ? Caracteristiques.fromJson(json['caracteristiques'])
            : null,
        inventaire: (json['inventaire'] as List<dynamic>?)
                ?.map((e) => InventaireItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        argent: json['argent'] != null ? Argent.fromJson(json['argent']) : null,
        talents: (json['talents'] as List<dynamic>?)
                ?.map(
                    (e) => PersonnageTalent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        traits: (json['traits'] as List<dynamic>?)
                ?.map((e) => PersonnageTrait.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        pouvoirs: (json['pouvoirs'] as List<dynamic>?)
                ?.map(
                    (e) => PersonnagePouvoir.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        rituels: (json['rituels'] as List<dynamic>?)
                ?.map((e) => PersonnageRituel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        atoutsFardeaux: (json['atouts_fardeaux'] as List<dynamic>?)
                ?.map((e) =>
                    PersonnageAtoutFardeau.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ERREUR dans Personnage.fromJson pour ${json['nom']}');
      debugPrint('JSON complet: $json');
      debugPrint('Exception: $e');
      debugPrint('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'race_id': raceId,
      'archetype_id': archetypeId,
      'classe_id': classeId,
      'est_pj': estPj,
      'joueur_connecte': joueurConnecte,
      'niveau': niveau,
      'avatar_url': avatarUrl,
      'avatar_thumbnail_url': avatarThumbnailUrl,
      'notes': notes,
      'age': age,
      'poids': poids,
      'taille': taille,
      'couleur_ombre': couleurOmbre,
    };
  }

  /// Copie avec modifications
  Personnage copyWith({
    int? id,
    String? nom,
    int? raceId,
    int? archetypeId,
    int? classeId,
    bool? estPj,
    String? joueurConnecte,
    int? niveau,
    String? avatarUrl,
    String? avatarThumbnailUrl,
    String? notes,
    int? age,
    double? poids,
    double? taille,
    String? couleurOmbre,
    Race? race,
    Archetype? archetype,
    Classe? classe,
    Caracteristiques? caracteristiques,
    List<InventaireItem>? inventaire,
    Argent? argent,
    List<PersonnageTalent>? talents,
    List<PersonnageTrait>? traits,
    List<PersonnagePouvoir>? pouvoirs,
    List<PersonnageRituel>? rituels,
    List<PersonnageAtoutFardeau>? atoutsFardeaux,
  }) {
    return Personnage(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      raceId: raceId ?? this.raceId,
      archetypeId: archetypeId ?? this.archetypeId,
      classeId: classeId ?? this.classeId,
      estPj: estPj ?? this.estPj,
      joueurConnecte: joueurConnecte ?? this.joueurConnecte,
      niveau: niveau ?? this.niveau,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarThumbnailUrl: avatarThumbnailUrl ?? this.avatarThumbnailUrl,
      notes: notes ?? this.notes,
      age: age ?? this.age,
      poids: poids ?? this.poids,
      taille: taille ?? this.taille,
      couleurOmbre: couleurOmbre ?? this.couleurOmbre,
      race: race ?? this.race,
      archetype: archetype ?? this.archetype,
      classe: classe ?? this.classe,
      caracteristiques: caracteristiques ?? this.caracteristiques,
      inventaire: inventaire ?? this.inventaire,
      argent: argent ?? this.argent,
      talents: talents ?? this.talents,
      traits: traits ?? this.traits,
      pouvoirs: pouvoirs ?? this.pouvoirs,
      rituels: rituels ?? this.rituels,
      atoutsFardeaux: atoutsFardeaux ?? this.atoutsFardeaux,
    );
  }

  // ===================== GETTERS PRATIQUES =====================

  /// Endurance actuelle (alias pour pvActuels)
  int get enduranceActuelle => caracteristiques?.enduranceActuelle ?? 0;
  
  /// Alias - PV actuels (= endurance actuelle)
  int get pvActuels => enduranceActuelle;

  /// Endurance max (alias pour pvMax)
  int get enduranceMax => caracteristiques?.enduranceMax ?? 0;
  
  /// Alias - PV max (= endurance max)
  int get pvMax => enduranceMax;

  /// Corruption actuelle
  int get corruption => caracteristiques?.corruption ?? 0;

  /// Corruption permanente
  int get corruptionPermanente => caracteristiques?.corruptionPermanente ?? 0;

  /// Seuil de corruption
  int get seuilCorruption => caracteristiques?.seuilCorruption ?? 0;

  /// Expérience
  int get experience => caracteristiques?.experience ?? 0;
  
  /// Défense (basée sur Agilité rapide, modifiable par équipement)
  int get defense {
    final base = 10 - (caracteristiques?.agilite ?? 10);
    // TODO: Ajouter bonus/malus d'armure et bouclier
    return base;
  }
  
  /// Protection (de l'armure équipée) - retourne le texte du dé (ex: "1D6")
  String get protection {
    final armure = armureEquipee;
    if (armure == null) return '-';
    return armure.armure?.protection ?? '-';
  }

  /// Nom de la race
  String get raceNom => race?.nom ?? 'Inconnue';

  /// Nom de l'archétype
  String get archetypeNom => archetype?.nom ?? 'Inconnu';

  /// Nom de la classe
  String get classeNom => classe?.nom ?? 'Inconnue';

  /// Items équipés
  List<InventaireItem> get itemsEquipes =>
      inventaire.where((i) => i.equipee).toList();

  /// Arme main droite (première arme équipée qui n'est pas un bouclier)
  InventaireItem? get armeMainDroite {
    return itemsEquipes.cast<InventaireItem?>().firstWhere(
          (i) => i!.estArme && !i.estBouclier,
          orElse: () => null,
        );
  }

  /// Bouclier ou arme main gauche
  InventaireItem? get armeMainGauche {
    // Cherche d'abord un bouclier
    final bouclier = itemsEquipes.cast<InventaireItem?>().firstWhere(
          (i) => i!.estBouclier,
          orElse: () => null,
        );
    if (bouclier != null) return bouclier;

    // Sinon cherche une deuxième arme (après la main droite)
    final armes = itemsEquipes.where((i) => i.estArme && !i.estBouclier).toList();
    if (armes.length > 1) return armes[1];
    return null;
  }

  /// Armure équipée
  InventaireItem? get armureEquipee {
    return itemsEquipes.cast<InventaireItem?>().firstWhere(
          (i) => i!.estArmure,
          orElse: () => null,
        );
  }

  /// Poids total de l'inventaire
  double get poidsTotal {
    return inventaire.fold(0.0, (sum, item) => sum + (item.poids * item.quantite));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Personnage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Personnage(id: $id, nom: $nom)';
}
