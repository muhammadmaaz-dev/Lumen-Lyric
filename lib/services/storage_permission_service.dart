import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle storage permissions for metadata persistence
///
/// On Android 11+ (API 30+), apps need MANAGE_EXTERNAL_STORAGE permission
/// to write files that survive app reinstallation.
class StoragePermissionService {
  static final StoragePermissionService instance =
      StoragePermissionService._internal();
  factory StoragePermissionService() => instance;
  StoragePermissionService._internal();

  bool _hasRequestedPermission = false;
  bool _hasFullStorageAccess = false;

  /// Check if we have permission to access external storage
  bool get hasFullStorageAccess => _hasFullStorageAccess;

  /// Initialize and check current permission status
  Future<void> initialize() async {
    if (!Platform.isAndroid) {
      _hasFullStorageAccess = true;
      return;
    }

    // Check current permission status
    await _checkPermissions();
  }

  /// Check all relevant storage permissions
  Future<void> _checkPermissions() async {
    if (!Platform.isAndroid) {
      _hasFullStorageAccess = true;
      return;
    }

    // Check storage permission
    final storageStatus = await Permission.storage.status;
    final manageStorageStatus = await Permission.manageExternalStorage.status;

    _hasFullStorageAccess =
        storageStatus.isGranted || manageStorageStatus.isGranted;

    debugPrint('📁 Storage Permission: ${storageStatus.name}');
    debugPrint('📁 Manage External Storage: ${manageStorageStatus.name}');
    debugPrint('📁 Has Full Access: $_hasFullStorageAccess');
  }

  /// Request storage permissions
  /// Returns true if permission was granted
  Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    _hasRequestedPermission = true;

    // First try regular storage permission
    var storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      storageStatus = await Permission.storage.request();
    }

    if (storageStatus.isGranted) {
      _hasFullStorageAccess = true;
      debugPrint('✅ Storage permission granted');
      return true;
    }

    // On Android 11+, need MANAGE_EXTERNAL_STORAGE for full access
    var manageStatus = await Permission.manageExternalStorage.status;
    if (!manageStatus.isGranted) {
      manageStatus = await Permission.manageExternalStorage.request();
    }

    _hasFullStorageAccess = manageStatus.isGranted;

    if (_hasFullStorageAccess) {
      debugPrint('✅ Manage external storage permission granted');
    } else {
      debugPrint('⚠️ Storage permissions not fully granted');
    }

    return _hasFullStorageAccess;
  }

  /// Request permissions with a user-friendly dialog
  Future<bool> requestWithDialog(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    // Check if already granted
    await _checkPermissions();
    if (_hasFullStorageAccess) return true;

    // Show explanation dialog
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
          'LumenLyric needs storage access to save your music metadata permanently. '
          'This allows your song information (titles, artists, album art) to persist '
          'even if you reinstall the app.\n\n'
          'Please grant "All Files Access" permission on the next screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );

    if (shouldRequest != true) return false;

    return await requestStoragePermissions();
  }

  /// Check and request permissions if needed (silent version)
  Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid) return true;

    await _checkPermissions();
    if (_hasFullStorageAccess) return true;

    // Only request automatically once per session
    if (!_hasRequestedPermission) {
      return await requestStoragePermissions();
    }

    return _hasFullStorageAccess;
  }

  /// Open app settings if permission was permanently denied
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
