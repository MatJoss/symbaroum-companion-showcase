/// Service de stockage persistant
/// Gère les tokens JWT et les préférences utilisateur
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

final _logger = Logger(printer: SimplePrinter());

/// Service de stockage sécurisé pour les tokens et données sensibles
class StorageService {
  static StorageService? _instance;
  late final FlutterSecureStorage _secureStorage;
  late final SharedPreferences _prefs;
  bool _initialized = false;

  StorageService._();

  /// Singleton
  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  /// Initialise le service (doit être appelé au démarrage)
  Future<void> init() async {
    if (_initialized) return;

    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(),
    );
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    _logger.i('StorageService initialisé');
  }

  // ===================== TOKENS JWT =====================

  /// Clé pour le token d'une campagne
  String _tokenKey(int campagneId) => 'jwt_token_$campagneId';

  /// Clé pour le rôle d'une campagne
  String _roleKey(int campagneId) => 'jwt_role_$campagneId';

  /// Clé pour l'expiration d'un token
  String _expirationKey(int campagneId) => 'jwt_expiration_$campagneId';

  /// Sauvegarde un token JWT pour une campagne
  Future<void> saveToken({
    required int campagneId,
    required String token,
    required String role,
    int expiresInHours = 24,
  }) async {
    final expiration = DateTime.now()
        .add(Duration(hours: expiresInHours))
        .millisecondsSinceEpoch;

    await _secureStorage.write(key: _tokenKey(campagneId), value: token);
    await _prefs.setString(_roleKey(campagneId), role);
    await _prefs.setInt(_expirationKey(campagneId), expiration);

    _logger.d('Token sauvegardé pour campagne $campagneId (role: $role)');
  }

  /// Récupère le token JWT pour une campagne
  Future<String?> getToken(int campagneId) async {
    // Vérifie l'expiration
    final expiration = _prefs.getInt(_expirationKey(campagneId));
    if (expiration != null &&
        DateTime.now().millisecondsSinceEpoch > expiration) {
      _logger.w('Token expiré pour campagne $campagneId');
      await deleteToken(campagneId);
      return null;
    }

    return await _secureStorage.read(key: _tokenKey(campagneId));
  }

  /// Récupère le rôle pour une campagne
  String? getRole(int campagneId) {
    return _prefs.getString(_roleKey(campagneId));
  }

  /// Vérifie si l'utilisateur est MJ pour une campagne
  bool isMj(int campagneId) {
    return getRole(campagneId) == 'mj';
  }

  /// Supprime le token d'une campagne
  Future<void> deleteToken(int campagneId) async {
    await _secureStorage.delete(key: _tokenKey(campagneId));
    await _prefs.remove(_roleKey(campagneId));
    await _prefs.remove(_expirationKey(campagneId));
    _logger.d('Token supprimé pour campagne $campagneId');
  }
  
  /// Récupère le token MJ pour une campagne (alias pour getToken si rôle=mj)
  Future<String?> getMjToken(int campagneId) async {
    if (isMj(campagneId)) {
      return getToken(campagneId);
    }
    return null;
  }
  
  /// Sauvegarde un token MJ pour une campagne
  Future<void> saveMjToken(int campagneId, String token) async {
    await saveToken(
      campagneId: campagneId,
      token: token,
      role: 'mj',
    );
  }

  /// Supprime tous les tokens
  Future<void> clearAllTokens() async {
    await _secureStorage.deleteAll();
    final keys = _prefs.getKeys().where((k) =>
        k.startsWith('jwt_role_') || k.startsWith('jwt_expiration_'));
    for (final key in keys) {
      await _prefs.remove(key);
    }
    _logger.i('Tous les tokens supprimés');
  }

  // ===================== PRÉFÉRENCES =====================

  /// Clé du device ID
  static const String _deviceIdKey = 'device_id';

  /// Récupère ou génère un device ID unique
  Future<String> getDeviceId() async {
    var deviceId = _prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      // Génère un UUID simple
      deviceId = _generateUuid();
      await _prefs.setString(_deviceIdKey, deviceId);
      _logger.i('Nouveau device ID généré: $deviceId');
    }
    return deviceId;
  }

  /// Génère un UUID v4 simple
  String _generateUuid() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
      RegExp(r'[xy]'),
      (match) {
        final r = (now + (DateTime.now().microsecond * 16)) % 16 | 0;
        final v = match.group(0) == 'x' ? r : (r & 0x3 | 0x8);
        return v.toRadixString(16);
      },
    );
  }

  // ===================== PRÉFÉRENCES SIMPLES =====================

  /// Dernière campagne sélectionnée
  int? get lastCampagneId => _prefs.getInt('last_campagne_id');
  Future<void> setLastCampagneId(int id) =>
      _prefs.setInt('last_campagne_id', id);

  /// Dernier personnage sélectionné
  int? get lastPersonnageId => _prefs.getInt('last_personnage_id');
  Future<void> setLastPersonnageId(int id) =>
      _prefs.setInt('last_personnage_id', id);
}
