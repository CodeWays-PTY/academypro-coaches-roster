import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request photo upload permissions lazily ONLY when user clicks photo upload
  static Future<bool> requestPhotoPermissionOnDemand() async {
    try {
      if (await Permission.photos.isGranted || await Permission.storage.isGranted) {
        return true;
      }
      final status = await Permission.photos.request();
      if (status.isGranted) return true;

      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } catch (e) {
      debugPrint('On-demand photo permission note: $e');
      return true;
    }
  }

  /// Request camera permission lazily ONLY when user opens QR scanner or takes a photo
  static Future<bool> requestCameraPermissionOnDemand() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) return true;
      final requested = await Permission.camera.request();
      return requested.isGranted;
    } catch (e) {
      debugPrint('On-demand camera permission note: $e');
      return true;
    }
  }
}
