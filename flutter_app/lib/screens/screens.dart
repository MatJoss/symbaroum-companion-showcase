/// Barrel file pour tous les écrans
library;

// ===== ÉCRANS FIREBASE (FONCTIONNELS) =====
export 'firebase_login_screen.dart';
export 'role_selection_screen.dart';
export 'campagnes_list_screen.dart';
export 'campagne_detail_screen.dart';
export 'personnage_detail_screen.dart';
export 'qr_code_display_screen.dart';
export 'qr_code_scan_screen.dart';
export 'account_settings_screen.dart';

// ===== ÉCRANS JOUEUR =====
export 'player_personnage_select_screen.dart';
export 'player_character_creation_screen.dart';
export 'player_character_detail_screen.dart';

// ===== ÉCRANS LEGACY (archivés dans _legacy_archive/) =====
// welcome_screen.dart → Remplacé par firebase_login_screen.dart
// campagne_manage_screen.dart → Fusionné dans campagne_detail_screen.dart
