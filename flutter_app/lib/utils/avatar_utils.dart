import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../providers/firebase_providers.dart';
import '../services/firebase_storage_service.dart';
import '../services/notification_service.dart';

/// Utilitaire pour gérer l'upload et le cropping d'avatar
class AvatarUtils {
  /// Éditer l'avatar d'un personnage avec sélection de source et cropping
  static Future<void> editAvatar(
    BuildContext context,
    WidgetRef ref,
    String personnageId,
  ) async {
    try {
      debugPrint('AvatarUtils.editAvatar called for $personnageId');
      final ImagePicker picker = ImagePicker();
      
      // Choisir la source
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choisir une source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Appareil photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Sélectionner l'image
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (image == null) return;

      // Crop l'image
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        maxWidth: 512,
        maxHeight: 512,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recadrer l\'avatar',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
          IOSUiSettings(
            title: 'Recadrer l\'avatar',
            aspectRatioLockEnabled: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
        ],
      );

      if (croppedFile == null) return; // Utilisateur a annulé

      debugPrint('Avatar cropped: ${croppedFile.path}');

      // Afficher un loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Upload vers Firebase Storage
      final imageBytes = await croppedFile.readAsBytes();
      final storageService = FirebaseStorageService.instance;
      final avatarUrl = await storageService.uploadAvatarFromBytes(
        bytes: imageBytes,
        personnageId: personnageId,
      );
      debugPrint('Avatar upload returned url: $avatarUrl');

      // Mettre à jour Firestore
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateDocument(
        collection: 'personnages',
        documentId: personnageId,
        data: {
          'document.avatarUrl': avatarUrl,
        },
      );

      // Invalider le cache
      ref.invalidate(personnageProvider(personnageId));

      if (context.mounted) {
        Navigator.pop(context); // Fermer le loading
        NotificationService.success('Avatar mis à jour avec succès');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Fermer le loading si erreur
        NotificationService.error('Erreur lors de l\'upload: $e');
      }
    }
  }
}
