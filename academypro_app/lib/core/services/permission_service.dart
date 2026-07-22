import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request all essential app permissions on app startup
  static Future<void> requestAppStartupPermissions(BuildContext context) async {
    try {
      // 1. Request Camera Permission (for QR Scanner & Workout Photo capture)
      final cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        await Permission.camera.request();
      }

      // 2. Request Media / Photos / Storage Permission (for Workout image uploads)
      if (await Permission.photos.isDenied) {
        await Permission.photos.request();
      } else if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }

      // 3. Request Notifications Permission (for practice reminders & announcements)
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) {
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('Startup permission request completed with note: $e');
    }
  }
}
