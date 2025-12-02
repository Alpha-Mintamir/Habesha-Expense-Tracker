import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request SMS permissions (RECEIVE_SMS and READ_SMS)
  /// Returns true if all permissions are granted
  /// Note: Permission.sms covers both RECEIVE_SMS and READ_SMS on Android
  static Future<bool> requestSmsPermissions() async {
    final smsPermission = await Permission.sms.request();
    return smsPermission.isGranted;
  }

  /// Check if SMS permissions are granted
  static Future<bool> hasSmsPermissions() async {
    final smsPermission = await Permission.sms.status;
    return smsPermission.isGranted;
  }

  /// Check if permissions are permanently denied (user needs to go to settings)
  static Future<bool> arePermissionsPermanentlyDenied() async {
    final smsPermission = await Permission.sms.status;
    return smsPermission.isPermanentlyDenied;
  }

  /// Open app settings so user can grant permissions manually
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}

