import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<void> requestInitialPermissions() async {
    final permissions = [
      Permission.microphone,
      Permission.camera,
      Permission.storage,
      Permission.notification,
    ];

    for (final permission in permissions) {
      final status = await permission.status;
      if (status.isDenied) {
        await permission.request();
      }
    }
  }

  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  static Future<bool> hasStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }
}