import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// ═══════════════════════════════════════════════════════════════════════════
/// STORAGE PATH SERVICE - CENTRALIZED PATH MANAGEMENT
/// ═══════════════════════════════════════════════════════════════════════════
///
/// STORAGE STRUCTURE INVARIANT:
///
/// Music/LumenLyric/
/// ├── Songs/        // ONLY .mp3 files (user-visible)
/// ├── .artwork/     // hidden artwork cache (.jpg files)
/// ├── .meta/        // hidden metadata files (.meta.json)
/// └── .cache/       // internal temp files
///
/// NON-NEGOTIABLE RULES:
/// 1. MP3 files ONLY go into /Songs/ folder
/// 2. Artwork (.jpg) files ONLY go into /.artwork/ folder
/// 3. Metadata (.meta.json) files ONLY go into /.meta/ folder
/// 4. Hidden folders (. prefix) are never shown to users
/// 5. The root /LumenLyric/ folder should be empty except for subfolders
/// ═══════════════════════════════════════════════════════════════════════════
class StoragePathService {
  static final StoragePathService instance = StoragePathService._internal();
  factory StoragePathService() => instance;
  StoragePathService._internal();

  bool _initialized = false;

  /// Base paths
  static const String _baseFolderName = 'LumenLyric';
  static const String _songsFolderName = 'Songs';
  static const String _artworkFolderName = '.artwork';
  static const String _metaFolderName = '.meta';
  static const String _cacheFolderName = '.cache';

  String? _basePath;
  String? _songsPath;
  String? _artworkPath;
  String? _metaPath;
  String? _cachePath;

  /// Initialize all storage paths and create directories
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Platform.isAndroid) {
        _basePath = '/storage/emulated/0/Music/$_baseFolderName';
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        _basePath = '${appDir.path}/$_baseFolderName';
      }

      _songsPath = '$_basePath/$_songsFolderName';
      _artworkPath = '$_basePath/$_artworkFolderName';
      _metaPath = '$_basePath/$_metaFolderName';
      _cachePath = '$_basePath/$_cacheFolderName';

      await _ensureDirectoriesExist();

      _initialized = true;
    } catch (e) {
      // Fallback to app directory
      final appDir = await getApplicationDocumentsDirectory();
      _basePath = '${appDir.path}/$_baseFolderName';
      _songsPath = '$_basePath/$_songsFolderName';
      _artworkPath = '$_basePath/$_artworkFolderName';
      _metaPath = '$_basePath/$_metaFolderName';
      _cachePath = '$_basePath/$_cacheFolderName';
      await _ensureDirectoriesExist();
      _initialized = true;
    }
  }

  Future<void> _ensureDirectoriesExist() async {
    final directories = [
      Directory(_basePath!),
      Directory(_songsPath!),
      Directory(_artworkPath!),
      Directory(_metaPath!),
      Directory(_cachePath!),
    ];

    for (final dir in directories) {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  /// Get base LumenLyric directory path
  Future<String> get basePath async {
    await initialize();
    return _basePath!;
  }

  /// Get Songs directory path (for MP3 files only)
  Future<String> get songsPath async {
    await initialize();
    return _songsPath!;
  }

  /// Get artwork directory path (hidden .artwork folder)
  Future<String> get artworkPath async {
    await initialize();
    return _artworkPath!;
  }

  /// Get metadata directory path (hidden .meta folder)
  Future<String> get metaPath async {
    await initialize();
    return _metaPath!;
  }

  /// Get cache directory path (hidden .cache folder)
  Future<String> get cachePath async {
    await initialize();
    return _cachePath!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILE PATH BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get full path for an MP3 file
  Future<String> getMp3Path(String filename) async {
    final songs = await songsPath;
    final safeName = _sanitizeFilename(filename);
    if (!safeName.toLowerCase().endsWith('.mp3')) {
      return '$songs/$safeName.mp3';
    }
    return '$songs/$safeName';
  }

  /// Get full path for artwork file (.jpg in .artwork folder)
  Future<String> getArtworkFilePath(String songFilename) async {
    final artwork = await artworkPath;
    final baseName = _getBaseFilename(songFilename);
    return '$artwork/$baseName.jpg';
  }

  /// Get full path for metadata JSON file (.meta.json in .meta folder)
  Future<String> getMetaFilePath(String songFilename) async {
    final meta = await metaPath;
    final baseName = _getBaseFilename(songFilename);
    return '$meta/$baseName.meta.json';
  }

  /// Get full path for a cache file
  Future<String> getCacheFilePath(String filename) async {
    final cache = await cachePath;
    return '$cache/$filename';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PATH RESOLUTION (for reading existing files)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Given an MP3 file path, get the corresponding artwork path
  /// Works for both new structure (/Songs/) and legacy (root folder)
  String getArtworkPathForMp3(String mp3FilePath) {
    final baseName = path.basenameWithoutExtension(mp3FilePath);

    // New structure: /Songs/filename.mp3 → /.artwork/filename.jpg
    if (_artworkPath != null) {
      return '$_artworkPath/$baseName.jpg';
    }

    // Fallback for uninitialized state
    final dir = path.dirname(mp3FilePath);
    final parentDir = path.dirname(dir);
    return '$parentDir/.artwork/$baseName.jpg';
  }

  /// Given an MP3 file path, get the corresponding metadata JSON path
  /// Works for both new structure (/Songs/) and legacy (root folder)
  String getMetaPathForMp3(String mp3FilePath) {
    final baseName = path.basenameWithoutExtension(mp3FilePath);

    // New structure: /Songs/filename.mp3 → /.meta/filename.meta.json
    if (_metaPath != null) {
      return '$_metaPath/$baseName.meta.json';
    }

    // Fallback for uninitialized state
    final dir = path.dirname(mp3FilePath);
    final parentDir = path.dirname(dir);
    return '$parentDir/.meta/$baseName.meta.json';
  }

  /// Check if a path is a LumenLyric file (in Songs folder or legacy root)
  bool isLumenLyricFile(String filePath) {
    return filePath.contains('LumenLyric') || filePath.contains('MyMusicApp');
  }

  /// Check if a path is in the new Songs folder structure
  bool isInSongsFolder(String filePath) {
    return filePath.contains('/Songs/') || filePath.contains('\\Songs\\');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY SUPPORT - Check for files in old locations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get legacy artwork path (same folder as MP3)
  String getLegacyArtworkPath(String mp3FilePath) {
    return mp3FilePath.replaceAll(
      RegExp(r'\.mp3$', caseSensitive: false),
      '.jpg',
    );
  }

  /// Get legacy metadata path (same folder as MP3)
  String getLegacyMetaPath(String mp3FilePath) {
    return mp3FilePath.replaceAll(
      RegExp(r'\.mp3$', caseSensitive: false),
      '.meta.json',
    );
  }

  /// Find artwork for an MP3 - checks new location first, then legacy
  Future<String?> findArtworkForMp3(String mp3FilePath) async {
    await initialize();

    // Check new location first
    final newPath = getArtworkPathForMp3(mp3FilePath);
    if (await File(newPath).exists()) {
      return newPath;
    }

    // Check legacy location
    final legacyPath = getLegacyArtworkPath(mp3FilePath);
    if (await File(legacyPath).exists()) {
      return legacyPath;
    }

    return null;
  }

  /// Find metadata JSON for an MP3 - checks new location first, then legacy
  Future<String?> findMetaForMp3(String mp3FilePath) async {
    await initialize();

    // Check new location first
    final newPath = getMetaPathForMp3(mp3FilePath);
    if (await File(newPath).exists()) {
      return newPath;
    }

    // Check legacy location (same folder as MP3)
    final legacyPath = getLegacyMetaPath(mp3FilePath);
    if (await File(legacyPath).exists()) {
      return legacyPath;
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MIGRATION - Move legacy files to new structure
  // ═══════════════════════════════════════════════════════════════════════════

  /// Migrate all legacy files from root LumenLyric folder to new structure
  /// This is idempotent - safe to run multiple times
  Future<MigrationResult> migrateLegacyFiles() async {
    await initialize();

    final result = MigrationResult();

    try {
      final baseDir = Directory(_basePath!);
      if (!await baseDir.exists()) {
        return result;
      }

      // List all files in root LumenLyric folder (not in subfolders)
      await for (final entity in baseDir.list(followLinks: false)) {
        if (entity is! File) continue;

        final filePath = entity.path;
        final fileName = path.basename(filePath);

        // Skip hidden files
        if (fileName.startsWith('.')) continue;

        try {
          if (fileName.toLowerCase().endsWith('.mp3')) {
            // Move MP3 to Songs folder
            final newPath = '$_songsPath/$fileName';
            if (!await File(newPath).exists()) {
              await entity.rename(newPath);
              result.movedMp3s++;
            } else {
              // File already exists in destination, delete the legacy copy
              await entity.delete();
              result.skippedDuplicates++;
            }
          } else if (fileName.toLowerCase().endsWith('.jpg') ||
              fileName.toLowerCase().endsWith('.jpeg') ||
              fileName.toLowerCase().endsWith('.png')) {
            // Move artwork to .artwork folder
            final newPath = '$_artworkPath/$fileName';
            if (!await File(newPath).exists()) {
              await entity.rename(newPath);
              result.movedArtwork++;
            } else {
              await entity.delete();
              result.skippedDuplicates++;
            }
          } else if (fileName.endsWith('.meta.json') ||
              fileName.endsWith('.json')) {
            // Move metadata to .meta folder
            final newPath = '$_metaPath/$fileName';
            if (!await File(newPath).exists()) {
              await entity.rename(newPath);
              result.movedMeta++;
            } else {
              await entity.delete();
              result.skippedDuplicates++;
            }
          }
        } catch (e) {
          debugPrint('⚠️ [MIGRATE] Failed to move $fileName: $e');
          result.errors++;
        }
      }

      debugPrint(
        '✅ [MIGRATE] Complete: ${result.movedMp3s} MP3s, '
        '${result.movedArtwork} artwork, ${result.movedMeta} meta files',
      );
    } catch (e) {
      debugPrint('❌ [MIGRATE] Migration failed: $e');
      result.errors++;
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  String _sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _getBaseFilename(String filename) {
    String name = path.basenameWithoutExtension(filename);
    // Remove any extension-like suffixes
    name = name.replaceAll(
      RegExp(r'\.(mp3|jpg|jpeg|png|json|meta)$', caseSensitive: false),
      '',
    );
    return _sanitizeFilename(name);
  }
}

/// Result of migration operation
class MigrationResult {
  int movedMp3s = 0;
  int movedArtwork = 0;
  int movedMeta = 0;
  int skippedDuplicates = 0;
  int errors = 0;

  bool get hasChanges => movedMp3s > 0 || movedArtwork > 0 || movedMeta > 0;
  bool get hasErrors => errors > 0;
}
