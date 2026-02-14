/// Service Firebase Storage
/// Gère l'upload, le téléchargement et la suppression des avatars
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import '../config/firebase_config.dart';

final _logger = Logger(printer: SimplePrinter());

/// Exception Storage
class StorageException implements Exception {
  final String message;
  final dynamic originalError;

  StorageException(this.message, [this.originalError]);

  @override
  String toString() => 'StorageException: $message';
}

/// Service Firebase Storage
class FirebaseStorageService {
  static FirebaseStorageService? _instance;
  final FirebaseStorage _storage;

  FirebaseStorageService._({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance {
    _logger.i('FirebaseStorageService initialisé');
  }

  /// Singleton
  static FirebaseStorageService get instance {
    _instance ??= FirebaseStorageService._();
    return _instance!;
  }

  // ===================== AVATARS =====================

  /// Uploader un avatar pour un personnage
  Future<String> uploadAvatar({
    required String personnageId,
    required File file,
  }) async {
    try {
      final fileSize = await file.length();
      _logger.d('UPLOAD avatar pour personnage: $personnageId (file: ${file.path}, size: $fileSize bytes)');

      final path = '${FirebaseConfig.avatarsPath}/$personnageId/avatar.jpg';
      final ref = _storage.ref(path);

      // Upload
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'personnageId': personnageId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      _logger.d('Starting upload task for $personnageId (file)');
      // Attendre la fin de l'upload
      final snapshot = await uploadTask;
      _logger.d('Upload task complete. State: ${snapshot.state} bytesTransferred: ${snapshot.bytesTransferred}');

      // Récupérer l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();

      _logger.i('✅ Avatar uploadé: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      _logger.e('❌ Erreur Firebase Storage: ${e.code} - ${e.message}');
      throw StorageException('Erreur lors de l\'upload de l\'avatar (${e.code})', e);
    } catch (e) {
      _logger.e('❌ Erreur upload avatar: $e');
      throw StorageException('Erreur lors de l\'upload de l\'avatar', e);
    }
  }

  /// Uploader un avatar depuis bytes
  Future<String> uploadAvatarFromBytes({
    required String personnageId,
    required Uint8List bytes,
  }) async {
    try {
      _logger.d('UPLOAD avatar (bytes) pour personnage: $personnageId (size: ${bytes.length} bytes)');

      final path = '${FirebaseConfig.avatarsPath}/$personnageId/avatar.jpg';
      final ref = _storage.ref(path);

      // Upload
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'personnageId': personnageId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      _logger.d('Starting upload task for $personnageId (bytes)');
      // Attendre la fin de l'upload
      final snapshot = await uploadTask;
      _logger.d('Upload task complete. State: ${snapshot.state} bytesTransferred: ${snapshot.bytesTransferred}');

      // Récupérer l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();

      _logger.i('✅ Avatar uploadé: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      _logger.e('❌ Erreur Firebase Storage: ${e.code} - ${e.message}');
      throw StorageException('Erreur lors de l\'upload de l\'avatar (${e.code})', e);
    } catch (e) {
      _logger.e('❌ Erreur upload avatar: $e');
      throw StorageException('Erreur lors de l\'upload de l\'avatar', e);
    }
  }

  /// Récupérer l'URL de l'avatar d'un personnage
  Future<String?> getAvatarUrl(String personnageId) async {
    try {
      final path = '${FirebaseConfig.avatarsPath}/$personnageId/avatar.jpg';
      final ref = _storage.ref(path);

      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        _logger.d('⚠️ Avatar non trouvé pour personnage: $personnageId');
        return null;
      }

      _logger.e('❌ Erreur Firebase Storage: ${e.code} - ${e.message}');
      throw StorageException('Erreur lors de la récupération de l\'avatar',
e);
    } catch (e) {
      _logger.e('❌ Erreur récupération avatar URL: $e');
      throw StorageException('Erreur lors de la récupération de l\'avatar',
e);
    }
  }

  /// Télécharger un avatar
  Future<Uint8List?> downloadAvatar(String personnageId) async {
    try {
      _logger.d('DOWNLOAD avatar pour personnage: $personnageId');

      final path = '${FirebaseConfig.avatarsPath}/$personnageId/avatar.jpg';
      final ref = _storage.ref(path);

      final bytes = await ref.getData();

      if (bytes == null) {
        _logger.w('⚠️ Avatar vide pour personnage: $personnageId');
        return null;
      }

      _logger.i('✅ Avatar téléchargé (${bytes.length} bytes)');
      return bytes;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        _logger.d('⚠️ Avatar non trouvé pour personnage: $personnageId');
        return null;
      }

      _logger.e('❌ Erreur Firebase Storage: ${e.code} - ${e.message}');
      throw StorageException('Erreur lors du téléchargement de l\'avatar', e);
    } catch (e) {
      _logger.e('❌ Erreur download avatar: $e');
      throw StorageException('Erreur lors du téléchargement de l\'avatar', e);
    }
  }

  /// Supprimer un avatar
  Future<void> deleteAvatar(String personnageId) async {
    try {
      _logger.d('DELETE avatar pour personnage: $personnageId');

      final path = '${FirebaseConfig.avatarsPath}/$personnageId/avatar.jpg';
      final ref = _storage.ref(path);

      await ref.delete();

      _logger.i('✅ Avatar supprimé');
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        _logger.d('⚠️ Avatar déjà supprimé pour personnage: $personnageId');
        return;
      }

      _logger.e('❌ Erreur Firebase Storage: ${e.code} - ${e.message}');
      throw StorageException('Erreur lors de la suppression de l\'avatar', e);
    } catch (e) {
      _logger.e('❌ Erreur delete avatar: $e');
      throw StorageException('Erreur lors de la suppression de l\'avatar', e);
    }
  }

  /// Vérifier si un avatar existe
  Future<bool> avatarExists(String personnageId) async {
    try {
      final url = await getAvatarUrl(personnageId);
      return url != null;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer les métadonnées d'un avatar
  Future<FullMetadata?> getAvatarMetadata(String personnageId) async {
    try {
      final path = '${FirebaseConfig.avatarsPath}/$personnageId/avatar.jpg';
      final ref = _storage.ref(path);

      final metadata = await ref.getMetadata();
      return metadata;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        _logger.d('⚠️ Avatar non trouvé pour personnage: $personnageId');
        return null;
      }

      _logger.e('❌ Erreur Firebase Storage: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      _logger.e('❌ Erreur récupération métadonnées: $e');
      return null;
    }
  }

  // ===================== OPÉRATIONS GÉNÉRIQUES =====================

  /// Uploader un fichier générique
  Future<String> uploadFile({
    required String path,
    required File file,
    String? contentType,
    Map<String, String>? customMetadata,
  }) async {
    try {
      _logger.d('UPLOAD file: $path');

      final ref = _storage.ref(path);

      final metadata = contentType != null || customMetadata != null
          ? SettableMetadata(
              contentType: contentType,
              customMetadata: customMetadata,
            )
          : null;

      final uploadTask = metadata != null
          ? ref.putFile(file, metadata)
          : ref.putFile(file);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      _logger.i('✅ Fichier uploadé: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('❌ Erreur upload file: $e');
      throw StorageException('Erreur lors de l\'upload du fichier', e);
    }
  }

  /// Supprimer un fichier générique
  Future<void> deleteFile(String path) async {
    try {
      _logger.d('DELETE file: $path');

      final ref = _storage.ref(path);
      await ref.delete();

      _logger.i('✅ Fichier supprimé');
    } catch (e) {
      _logger.e('❌ Erreur delete file: $e');
      throw StorageException('Erreur lors de la suppression du fichier', e);
    }
  }

  /// Lister les fichiers dans un répertoire
  Future<List<String>> listFiles(String path) async {
    try {
      _logger.d('LIST files: $path');

      final ref = _storage.ref(path);
      final result = await ref.listAll();

      final urls = <String>[];
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      _logger.i('✅ ${urls.length} fichier(s) trouvé(s)');
      return urls;
    } catch (e) {
      _logger.e('❌ Erreur list files: $e');
      throw StorageException('Erreur lors du listage des fichiers', e);
    }
  }
}
