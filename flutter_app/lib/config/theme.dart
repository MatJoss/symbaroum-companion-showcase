/// Thème visuel Symbaroum
/// Couleurs inspirées de l'univers dark fantasy du JDR
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette de couleurs Symbaroum
/// Inspirée des tons sombres, forestiers et mystiques du jeu
class SymbaroumColors {
  // Couleurs principales
  /// Fond principal - Brun très foncé (forêt de Davokar)
  static const Color background = Color(0xFF1A1510);

  /// Fond secondaire - Brun foncé
  static const Color surface = Color(0xFF2D251C);

  /// Fond des cartes - Brun moyen avec transparence
  static const Color cardBackground = Color(0xFF3D3228);

  /// Accent principal - Or ancien (richesse d'Ambria)
  static const Color primary = Color(0xFFD4A84B);

  /// Accent secondaire - Or plus clair
  static const Color primaryLight = Color(0xFFE8C36B);

  /// Accent tertiaire - Or foncé
  static const Color primaryDark = Color(0xFFB8923A);

  /// Couleur d'action - Cuivre/Bronze
  static const Color secondary = Color(0xFFCD7F32);

  /// Couleur d'erreur - Rouge sang
  static const Color error = Color(0xFFC62828);

  /// Couleur de succès - Vert forêt
  static const Color success = Color(0xFF2E7D32);

  /// Couleur d'avertissement - Orange automnal
  static const Color warning = Color(0xFFE65100);

  // Textes
  /// Texte principal - Beige clair (parchemin)
  static const Color textPrimary = Color(0xFFF5E6D3);

  /// Texte secondaire - Beige atténué
  static const Color textSecondary = Color(0xFFBDAA94);

  /// Texte sur fond clair
  static const Color textDark = Color(0xFF2D1810);

  /// Texte désactivé
  static const Color textDisabled = Color(0xFF6D5D4D);

  // Éléments spéciaux
  /// Corruption - Violet sombre
  static const Color corruption = Color(0xFF6A1B9A);

  /// Magie - Bleu mystique
  static const Color magic = Color(0xFF1565C0);

  /// PV/Santé - Rouge vif
  static const Color health = Color(0xFFD32F2F);

  /// Endurance - Vert émeraude
  static const Color endurance = Color(0xFF388E3C);

  // Bordures et séparateurs
  /// Bordure standard
  static const Color border = Color(0xFF5D4D3D);

  /// Bordure dorée (éléments importants)
  static const Color borderGold = Color(0xFFD4A84B);

  /// Séparateur subtil
  static const Color divider = Color(0xFF4D3D2D);

  // Overlays
  /// Overlay sombre pour modals
  static const Color overlayDark = Color(0xCC000000);

  /// Overlay léger
  static const Color overlayLight = Color(0x33000000);
}

/// Thème complet de l'application
class SymbaroumTheme {
  // ==================== ALIAS DE COULEURS ====================
  // Ces getters permettent d'accéder aux couleurs via SymbaroumTheme.gold etc.
  
  /// Or - couleur primaire
  static Color get gold => SymbaroumColors.primary;
  
  /// Or clair
  static Color get lightGold => SymbaroumColors.primaryLight;
  
  /// Parchemin - texte principal
  static Color get parchment => SymbaroumColors.textPrimary;
  
  /// Brun foncé - fond
  static Color get darkBrown => SymbaroumColors.background;
  
  /// Vert forêt - succès
  static Color get forestGreen => SymbaroumColors.success;
  
  /// Rouge sang - erreur/dégâts
  static Color get bloodRed => SymbaroumColors.error;
  
  /// Fond de carte
  static Color get cardBg => SymbaroumColors.cardBackground;
  
  /// Surface
  static Color get surface => SymbaroumColors.surface;
  
  /// Bordure
  static Color get border => SymbaroumColors.border;
  
  /// Bordure dorée
  static Color get borderGold => SymbaroumColors.borderGold;
  
  /// Texte secondaire
  static Color get textSecondary => SymbaroumColors.textSecondary;
  
  /// Thème sombre complet
  static ThemeData get darkTheme => theme;

  /// Crée le ThemeData principal
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Couleurs
      colorScheme: const ColorScheme.dark(
        primary: SymbaroumColors.primary,
        onPrimary: SymbaroumColors.textDark,
        secondary: SymbaroumColors.secondary,
        onSecondary: SymbaroumColors.textPrimary,
        surface: SymbaroumColors.surface,
        onSurface: SymbaroumColors.textPrimary,
        error: SymbaroumColors.error,
        onError: SymbaroumColors.textPrimary,
      ),

      // Fond
      scaffoldBackgroundColor: SymbaroumColors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: SymbaroumColors.surface,
        foregroundColor: SymbaroumColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: SymbaroumColors.primary,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: SymbaroumColors.cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: SymbaroumColors.border,
            width: 1,
          ),
        ),
      ),

      // Boutons élevés
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SymbaroumColors.primary,
          foregroundColor: SymbaroumColors.textDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Boutons texte
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SymbaroumColors.primary,
          textStyle: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Boutons outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SymbaroumColors.primary,
          side: const BorderSide(color: SymbaroumColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Champs de texte
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SymbaroumColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SymbaroumColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SymbaroumColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SymbaroumColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SymbaroumColors.error),
        ),
        labelStyle: const TextStyle(color: SymbaroumColors.textSecondary),
        hintStyle: const TextStyle(color: SymbaroumColors.textDisabled),
      ),

      // Dialogues
      dialogTheme: DialogThemeData(
        backgroundColor: SymbaroumColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SymbaroumColors.borderGold, width: 2),
        ),
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: SymbaroumColors.primary,
        ),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SymbaroumColors.surface,
        selectedItemColor: SymbaroumColors.primary,
        unselectedItemColor: SymbaroumColors.textSecondary,
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: SymbaroumColors.primary,
        unselectedLabelColor: SymbaroumColors.textSecondary,
        indicatorColor: SymbaroumColors.primary,
        labelStyle: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: SymbaroumColors.divider,
        thickness: 1,
      ),

      // Snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SymbaroumColors.cardBackground,
        contentTextStyle: GoogleFonts.lato(
          color: SymbaroumColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Typography
      textTheme: _buildTextTheme(),
    );
  }

  /// Construit la hiérarchie de textes
  static TextTheme _buildTextTheme() {
    // Cinzel pour les titres (style médiéval élégant)
    // Lato pour le corps de texte (lisibilité optimale)
    return TextTheme(
      // Grands titres (écrans principaux)
      displayLarge: GoogleFonts.cinzel(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: SymbaroumColors.primary,
      ),
      displayMedium: GoogleFonts.cinzel(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: SymbaroumColors.primary,
      ),
      displaySmall: GoogleFonts.cinzel(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: SymbaroumColors.primary,
      ),

      // Titres de sections
      headlineLarge: GoogleFonts.cinzel(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: SymbaroumColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.cinzel(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: SymbaroumColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.cinzel(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: SymbaroumColors.textPrimary,
      ),

      // Titres de cartes/items
      titleLarge: GoogleFonts.lato(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: SymbaroumColors.textPrimary,
      ),
      titleMedium: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: SymbaroumColors.textPrimary,
      ),
      titleSmall: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: SymbaroumColors.textPrimary,
      ),

      // Corps de texte
      bodyLarge: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: SymbaroumColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: SymbaroumColors.textPrimary,
      ),
      bodySmall: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: SymbaroumColors.textSecondary,
      ),

      // Labels
      labelLarge: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: SymbaroumColors.textPrimary,
      ),
      labelMedium: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: SymbaroumColors.textSecondary,
      ),
      labelSmall: GoogleFonts.lato(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: SymbaroumColors.textSecondary,
      ),
    );
  }
}

/// Extensions pour faciliter l'accès aux couleurs
extension SymbaroumColorsExtension on BuildContext {
  /// Accès rapide aux couleurs Symbaroum
  SymbaroumColors get colors => SymbaroumColors();
}
