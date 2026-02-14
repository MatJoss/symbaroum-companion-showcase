import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/models.dart';

/// Affiche une popup avec la description complète d'un talent, incluant les niveaux cumulatifs
void showTalentDescriptionDialog(BuildContext context, Talent talent, int niveauActuel) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: SymbaroumTheme.darkBrown,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: SymbaroumTheme.gold, width: 2),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    talent.nom,
                    style: GoogleFonts.cinzel(
                      color: SymbaroumTheme.gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: SymbaroumTheme.parchment),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const Divider(color: Color(0xFFD4A84B), thickness: 2),
            const SizedBox(height: 12),
            
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description générale
                    if (talent.cleanDescriptionGenerale != null) ...[
                      _buildSectionTitle('Description générale'),
                      const SizedBox(height: 8),
                      _buildDescriptionText(talent.cleanDescriptionGenerale!),
                      const SizedBox(height: 16),
                    ],
                    
                    // Novice
                    if (talent.cleanDescriptionNovice != null) ...[
                      _buildNiveauHeader('Novice', niveauActuel >= 1),
                      const SizedBox(height: 8),
                      _buildDescriptionText(talent.cleanDescriptionNovice!),
                      const SizedBox(height: 12),
                    ],
                    
                    // Adepte
                    if (talent.cleanDescriptionAdepte != null) ...[
                      _buildNiveauHeader('Adepte', niveauActuel >= 2),
                      const SizedBox(height: 8),
                      _buildDescriptionText(talent.cleanDescriptionAdepte!),
                      const SizedBox(height: 12),
                    ],
                    
                    // Maître
                    if (talent.cleanDescriptionMaitre != null) ...[
                      _buildNiveauHeader('Maître', niveauActuel >= 3),
                      const SizedBox(height: 8),
                      _buildDescriptionText(talent.cleanDescriptionMaitre!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Affiche une popup avec la description complète d'un trait, incluant les niveaux cumulatifs
void showTraitDescriptionDialog(BuildContext context, Trait trait, int niveauActuel) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: SymbaroumTheme.darkBrown,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: SymbaroumTheme.gold, width: 2),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    trait.nom,
                    style: GoogleFonts.cinzel(
                      color: SymbaroumTheme.gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: SymbaroumTheme.parchment),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const Divider(color: Color(0xFFD4A84B), thickness: 2),
            const SizedBox(height: 12),
            
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description générale
                    if (trait.cleanDescriptionGenerale != null) ...[
                      _buildSectionTitle('Description générale'),
                      const SizedBox(height: 8),
                      _buildDescriptionText(trait.cleanDescriptionGenerale!),
                      const SizedBox(height: 16),
                    ],
                    
                    // Pour les traits Novice/Adepte/Maître
                    if (trait.niveauType == 'novice_adepte_maitre') ...[
                      if (trait.cleanDescriptionNovice != null) ...[
                        _buildNiveauHeader('Novice', niveauActuel >= 1),
                        const SizedBox(height: 8),
                        _buildDescriptionText(trait.cleanDescriptionNovice!),
                        const SizedBox(height: 12),
                      ],
                      if (trait.cleanDescriptionAdepte != null) ...[
                        _buildNiveauHeader('Adepte', niveauActuel >= 2),
                        const SizedBox(height: 8),
                        _buildDescriptionText(trait.cleanDescriptionAdepte!),
                        const SizedBox(height: 12),
                      ],
                      if (trait.cleanDescriptionMaitre != null) ...[
                        _buildNiveauHeader('Maître', niveauActuel >= 3),
                        const SizedBox(height: 8),
                        _buildDescriptionText(trait.cleanDescriptionMaitre!),
                      ],
                    ],
                    
                    // Pour les traits Monstrueux (I, II, III)
                    if (trait.isMonstrueux) ...[
                      if (trait.cleanDescriptionI != null) ...[
                        _buildNiveauHeader('I', niveauActuel >= 1),
                        const SizedBox(height: 8),
                        _buildDescriptionText(trait.cleanDescriptionI!),
                        const SizedBox(height: 12),
                      ],
                      if (trait.cleanDescriptionII != null) ...[
                        _buildNiveauHeader('II', niveauActuel >= 2),
                        const SizedBox(height: 8),
                        _buildDescriptionText(trait.cleanDescriptionII!),
                        const SizedBox(height: 12),
                      ],
                      if (trait.cleanDescriptionIII != null) ...[
                        _buildNiveauHeader('III', niveauActuel >= 3),
                        const SizedBox(height: 8),
                        _buildDescriptionText(trait.cleanDescriptionIII!),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Affiche une popup avec la description complète d'un pouvoir mystique, incluant les niveaux cumulatifs
void showPouvoirDescriptionDialog(BuildContext context, PouvoirMystique pouvoir, int niveauActuel) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: SymbaroumTheme.darkBrown,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: SymbaroumTheme.gold, width: 2),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pouvoir.nom,
                        style: GoogleFonts.cinzel(
                          color: SymbaroumTheme.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tradition: ${pouvoir.tradition}',
                        style: GoogleFonts.lora(
                          color: SymbaroumTheme.parchment.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (pouvoir.materiel != null && pouvoir.materiel!.isNotEmpty)
                        Text(
                          'Matériel: ${pouvoir.materiel}',
                          style: GoogleFonts.lora(
                            color: SymbaroumTheme.parchment.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: SymbaroumTheme.parchment),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const Divider(color: Color(0xFFD4A84B), thickness: 2),
            const SizedBox(height: 12),
            
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Novice
                    _buildNiveauHeader('Novice', niveauActuel >= 1),
                    const SizedBox(height: 8),
                    _buildDescriptionText(pouvoir.cleanDescriptionNovice),
                    const SizedBox(height: 12),
                    
                    // Adepte
                    if (pouvoir.cleanDescriptionAdepte != null) ...[
                      _buildNiveauHeader('Adepte', niveauActuel >= 2),
                      const SizedBox(height: 8),
                      _buildDescriptionText(pouvoir.cleanDescriptionAdepte!),
                      const SizedBox(height: 12),
                    ],
                    
                    // Maître
                    if (pouvoir.cleanDescriptionMaitre != null) ...[
                      _buildNiveauHeader('Maître', niveauActuel >= 3),
                      const SizedBox(height: 8),
                      _buildDescriptionText(pouvoir.cleanDescriptionMaitre!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Affiche une popup avec la description complète d'un rituel mystique
void showRituelDescriptionDialog(BuildContext context, RituelMystique rituel) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: SymbaroumTheme.darkBrown,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: SymbaroumTheme.gold, width: 2),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rituel.nom,
                        style: GoogleFonts.cinzel(
                          color: SymbaroumTheme.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tradition: ${rituel.tradition}',
                        style: GoogleFonts.lora(
                          color: SymbaroumTheme.parchment.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (rituel.materiel != null && rituel.materiel!.isNotEmpty)
                        Text(
                          'Matériel: ${rituel.materiel}',
                          style: GoogleFonts.lora(
                            color: SymbaroumTheme.parchment.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: SymbaroumTheme.parchment),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const Divider(color: Color(0xFFD4A84B), thickness: 2),
            const SizedBox(height: 12),
            
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                child: _buildDescriptionText(rituel.cleanDescription),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Affiche une popup avec la description d'un atout ou fardeau
void showAtoutFardeauDescriptionDialog(BuildContext context, AtoutFardeau atoutFardeau) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: SymbaroumTheme.darkBrown,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: SymbaroumTheme.gold, width: 2),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        atoutFardeau.nom,
                        style: GoogleFonts.cinzel(
                          color: SymbaroumTheme.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        atoutFardeau.isAtout ? 'Atout' : 'Fardeau',
                        style: GoogleFonts.lora(
                          color: atoutFardeau.isAtout 
                              ? SymbaroumTheme.forestGreen 
                              : SymbaroumTheme.bloodRed,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: SymbaroumTheme.parchment),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const Divider(color: Color(0xFFD4A84B), thickness: 2),
            const SizedBox(height: 12),
            
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                child: _buildDescriptionText(atoutFardeau.cleanDescription),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ==================== WIDGETS INTERNES ====================

Widget _buildSectionTitle(String title) {
  return Text(
    title,
    style: GoogleFonts.cinzel(
      color: SymbaroumTheme.gold,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget _buildNiveauHeader(String niveau, bool isUnlocked) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isUnlocked 
          ? SymbaroumTheme.gold.withValues(alpha: 0.2)
          : SymbaroumTheme.surface.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: isUnlocked 
            ? SymbaroumTheme.gold 
            : SymbaroumTheme.parchment.withValues(alpha: 0.3),
        width: 1.5,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUnlocked ? Icons.check_circle : Icons.lock_outline,
          color: isUnlocked 
              ? SymbaroumTheme.gold 
              : SymbaroumTheme.parchment.withValues(alpha: 0.5),
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          niveau,
          style: GoogleFonts.cinzel(
            color: isUnlocked 
                ? SymbaroumTheme.gold 
                : SymbaroumTheme.parchment.withValues(alpha: 0.7),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget _buildDescriptionText(String text) {
  return Text(
    text,
    style: GoogleFonts.lora(
      color: SymbaroumTheme.parchment.withValues(alpha: 0.9),
      fontSize: 14,
      height: 1.5,
    ),
  );
}
