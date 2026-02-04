import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:musicapp/services/storage_permission_service.dart';
import 'package:musicapp/services/storage_path_service.dart';

/// Persistent metadata model for storing song metadata permanently
class PersistentSongMetadata {
  final int? id;
  final String filePath; // Unique identifier - the actual file path
  final String fileName; // File name without path
  final String title;
  final String artist;
  final String? album;
  final int? duration;
  final String? artworkPath; // Local path to artwork image
  final String? artworkUrl; // Original URL (for fallback)
  final String? youtubeUrl; // Original YouTube URL
  final String? description;
  final DateTime downloadedAt;
  final DateTime updatedAt;

  PersistentSongMetadata({
    this.id,
    required this.filePath,
    required this.fileName,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.artworkPath,
    this.artworkUrl,
    this.youtubeUrl,
    this.description,
    DateTime? downloadedAt,
    DateTime? updatedAt,
  }) : downloadedAt = downloadedAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'file_name': fileName,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'artwork_path': artworkPath,
      'artwork_url': artworkUrl,
      'youtube_url': youtubeUrl,
      'description': description,
      'downloaded_at': downloadedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PersistentSongMetadata.fromMap(Map<String, dynamic> map) {
    return PersistentSongMetadata(
      id: map['id'] as int?,
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String?,
      duration: map['duration'] as int?,
      artworkPath: map['artwork_path'] as String?,
      artworkUrl: map['artwork_url'] as String?,
      youtubeUrl: map['youtube_url'] as String?,
      description: map['description'] as String?,
      downloadedAt: DateTime.parse(map['downloaded_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  PersistentSongMetadata copyWith({
    int? id,
    String? filePath,
    String? fileName,
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? artworkPath,
    String? artworkUrl,
    String? youtubeUrl,
    String? description,
    DateTime? downloadedAt,
    DateTime? updatedAt,
  }) {
    return PersistentSongMetadata(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      artworkPath: artworkPath ?? this.artworkPath,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      description: description ?? this.description,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Service for managing persistent song metadata using SQLite
///
/// This service stores metadata in TWO locations for redundancy:
/// 1. App's internal database (fast access)
/// 2. External storage database (survives app reinstallation on Android)
///
/// This ensures metadata persists even when:
/// - App is reinstalled
/// - Internet is unavailable
/// - App data is cleared
class MetadataDatabaseService {
  static final MetadataDatabaseService instance =
      MetadataDatabaseService._internal();
  factory MetadataDatabaseService() => instance;
  MetadataDatabaseService._internal();

  static const String _databaseName = 'lumenlyric_metadata.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'song_metadata';

  Database? _internalDatabase;
  Database? _externalDatabase;
  bool _isInitialized = false;

  final StoragePermissionService _permissionService =
      StoragePermissionService.instance;

  /// Initialize both databases
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // ✅ Request storage permissions first (needed for external storage on Android 11+)
      await _permissionService.initialize();
      if (!_permissionService.hasFullStorageAccess) {
        debugPrint(
          '⚠️ Requesting storage permissions for metadata persistence...',
        );
        await _permissionService.requestStoragePermissions();
      }

      // 1. Initialize internal database (in app's data directory)
      await _initInternalDatabase();

      // 2. Initialize external database (in Music folder - survives reinstall)
      await _initExternalDatabase();

      _isInitialized = true;
      debugPrint('✅ MetadataDatabaseService initialized');
    } catch (e) {
      debugPrint('❌ MetadataDatabaseService initialization error: $e');
    }
  }

  Future<void> _initInternalDatabase() async {
    final dbPath = await getDatabasesPath();
    final internalPath = path.join(dbPath, _databaseName);

    _internalDatabase = await openDatabase(
      internalPath,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
    debugPrint('✅ Internal database opened: $internalPath');
  }

  Future<void> _initExternalDatabase() async {
    if (!Platform.isAndroid) {
      // On iOS/other platforms, use documents directory
      final dir = await getApplicationDocumentsDirectory();
      final externalPath = path.join(dir.path, 'LumenLyric', _databaseName);
      await Directory(path.dirname(externalPath)).create(recursive: true);

      _externalDatabase = await openDatabase(
        externalPath,
        version: _databaseVersion,
        onCreate: _createDatabase,
        onUpgrade: _onUpgrade,
      );
      debugPrint('✅ External database opened: $externalPath');
      return;
    }

    // On Android, try multiple locations for external storage
    // Priority 1: Music folder (survives reinstall if app has storage permission)
    // Priority 2: External files directory (app-specific external storage)
    // Priority 3: Documents directory (internal, fallback)

    bool hasStoragePermission = false;

    // Check if we have storage permissions
    if (await Permission.storage.isGranted ||
        await Permission.manageExternalStorage.isGranted) {
      hasStoragePermission = true;
    }

    if (hasStoragePermission) {
      try {
        final musicDir = Directory(
          '/storage/emulated/0/Music/LumenLyric/.metadata',
        );
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }

        final externalPath = path.join(musicDir.path, _databaseName);
        _externalDatabase = await openDatabase(
          externalPath,
          version: _databaseVersion,
          onCreate: _createDatabase,
          onUpgrade: _onUpgrade,
        );
        debugPrint('✅ External database opened (Music folder): $externalPath');
        return;
      } catch (e) {
        debugPrint('⚠️ Could not create external database in Music folder: $e');
      }
    }

    // Try external files directory (Android's getExternalFilesDir equivalent)
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // Go up to the Android folder level and create in a shared location
        // /storage/emulated/0/Android/data/com.example.musicapp/files
        // We'll put it in a parent-accessible location
        final extPath = path.join(externalDir.path, 'metadata', _databaseName);
        await Directory(path.dirname(extPath)).create(recursive: true);

        _externalDatabase = await openDatabase(
          extPath,
          version: _databaseVersion,
          onCreate: _createDatabase,
          onUpgrade: _onUpgrade,
        );
        debugPrint('✅ External database opened (External Files): $extPath');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Could not create external database in external files: $e');
    }

    // Fallback to documents directory
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fallbackPath = path.join(dir.path, 'LumenLyric', _databaseName);
      await Directory(path.dirname(fallbackPath)).create(recursive: true);

      _externalDatabase = await openDatabase(
        fallbackPath,
        version: _databaseVersion,
        onCreate: _createDatabase,
        onUpgrade: _onUpgrade,
      );
      debugPrint('✅ Fallback external database opened: $fallbackPath');
    } catch (e) {
      debugPrint('❌ Could not create any external database: $e');
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT NOT NULL UNIQUE,
        file_name TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT,
        duration INTEGER,
        artwork_path TEXT,
        artwork_url TEXT,
        youtube_url TEXT,
        description TEXT,
        downloaded_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create index on file_path for fast lookups
    await db.execute('CREATE INDEX idx_file_path ON $_tableName(file_path)');

    // Create index on file_name for matching songs by name
    await db.execute('CREATE INDEX idx_file_name ON $_tableName(file_name)');

    debugPrint('✅ Database table created');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here in future versions
    debugPrint('📦 Database upgrade from v$oldVersion to v$newVersion');
  }

  /// Save or update metadata in both databases
  Future<void> saveMetadata(PersistentSongMetadata metadata) async {
    await initialize();

    final map = metadata.toMap();
    map.remove('id'); // Remove id for insert (auto-generated)
    map['updated_at'] = DateTime.now().toIso8601String();

    // Save to internal database
    if (_internalDatabase != null) {
      await _upsertMetadata(_internalDatabase!, map);
    }

    // Save to external database (backup)
    if (_externalDatabase != null) {
      await _upsertMetadata(_externalDatabase!, map);
    }

    // ✅ Also save to JSON backup file (survives reinstall)
    await _saveToJsonBackup(metadata);

    // ✅ Also save as sidecar JSON file next to the song (most reliable for reinstall)
    await _saveSidecarJson(metadata);

    debugPrint('✅ Metadata saved for: ${metadata.title}');
  }

  /// ✅ Save metadata as a sidecar JSON file in the hidden .meta/ folder
  /// This is the most reliable method for surviving reinstallation
  /// STORAGE STRUCTURE: Metadata goes into /.meta/ hidden folder
  Future<void> _saveSidecarJson(PersistentSongMetadata metadata) async {
    try {
      // Use StoragePathService to get the correct .meta/ folder path
      final storagePaths = StoragePathService.instance;
      await storagePaths.initialize();
      final sidecarPath = storagePaths.getMetaPathForMp3(metadata.filePath);

      final sidecarFile = File(sidecarPath);
      final jsonContent = const JsonEncoder.withIndent(
        '  ',
      ).convert(metadata.toMap());

      await sidecarFile.writeAsString(jsonContent);
      debugPrint('📎 Sidecar JSON saved to .meta/: $sidecarPath');
    } catch (e) {
      debugPrint('⚠️ Could not save sidecar JSON: $e');
    }
  }

  Future<void> _upsertMetadata(Database db, Map<String, dynamic> map) async {
    try {
      await db.insert(
        _tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('⚠️ Error saving metadata: $e');
    }
  }

  /// Get metadata by exact file path
  Future<PersistentSongMetadata?> getMetadataByPath(String filePath) async {
    await initialize();

    // First try internal database
    if (_internalDatabase != null) {
      final result = await _queryByPath(_internalDatabase!, filePath);
      if (result != null) return result;
    }

    // Fallback to external database
    if (_externalDatabase != null) {
      final result = await _queryByPath(_externalDatabase!, filePath);
      if (result != null) {
        // Sync to internal database
        if (_internalDatabase != null) {
          await _upsertMetadata(_internalDatabase!, result.toMap());
        }
        return result;
      }
    }

    // ✅ Final fallback: check for sidecar JSON file
    final sidecarResult = await _loadFromSidecarJson(filePath);
    if (sidecarResult != null) {
      // Save to databases for future quick lookups
      if (_internalDatabase != null) {
        await _upsertMetadata(_internalDatabase!, sidecarResult.toMap());
      }
      return sidecarResult;
    }

    return null;
  }

  /// ✅ Load metadata from sidecar JSON file (checks new .meta/ folder and legacy location)
  Future<PersistentSongMetadata?> _loadFromSidecarJson(
    String songFilePath,
  ) async {
    try {
      // Use StoragePathService to find the metadata file (checks new and legacy locations)
      final storagePaths = StoragePathService.instance;
      final sidecarPath = await storagePaths.findMetaForMp3(songFilePath);

      if (sidecarPath == null) {
        return null;
      }

      final sidecarFile = File(sidecarPath);

      if (!await sidecarFile.exists()) {
        return null;
      }

      final content = await sidecarFile.readAsString();
      final map = Map<String, dynamic>.from(jsonDecode(content));

      debugPrint('📎 Loaded metadata from sidecar: $sidecarPath');
      return PersistentSongMetadata.fromMap(map);
    } catch (e) {
      debugPrint('⚠️ Error loading sidecar JSON: $e');
      return null;
    }
  }

  Future<PersistentSongMetadata?> _queryByPath(
    Database db,
    String filePath,
  ) async {
    try {
      final results = await db.query(
        _tableName,
        where: 'file_path = ?',
        whereArgs: [filePath],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return PersistentSongMetadata.fromMap(results.first);
      }
    } catch (e) {
      debugPrint('⚠️ Error querying metadata: $e');
    }
    return null;
  }

  /// Get metadata by file name (useful when path might differ after reinstall)
  Future<PersistentSongMetadata?> getMetadataByFileName(String fileName) async {
    await initialize();

    // First try internal database
    if (_internalDatabase != null) {
      final result = await _queryByFileName(_internalDatabase!, fileName);
      if (result != null) return result;
    }

    // Fallback to external database
    if (_externalDatabase != null) {
      final result = await _queryByFileName(_externalDatabase!, fileName);
      if (result != null) {
        // Sync to internal database
        if (_internalDatabase != null) {
          await _upsertMetadata(_internalDatabase!, result.toMap());
        }
        return result;
      }
    }

    return null;
  }

  Future<PersistentSongMetadata?> _queryByFileName(
    Database db,
    String fileName,
  ) async {
    try {
      final results = await db.query(
        _tableName,
        where: 'file_name = ?',
        whereArgs: [fileName],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return PersistentSongMetadata.fromMap(results.first);
      }
    } catch (e) {
      debugPrint('⚠️ Error querying metadata by filename: $e');
    }
    return null;
  }

  /// Get all stored metadata
  Future<List<PersistentSongMetadata>> getAllMetadata() async {
    await initialize();

    // Prefer external database (has data after reinstall)
    if (_externalDatabase != null) {
      try {
        final results = await _externalDatabase!.query(
          _tableName,
          orderBy: 'downloaded_at DESC',
        );
        return results.map((m) => PersistentSongMetadata.fromMap(m)).toList();
      } catch (e) {
        debugPrint('⚠️ Error getting all metadata from external: $e');
      }
    }

    // Fallback to internal database
    if (_internalDatabase != null) {
      try {
        final results = await _internalDatabase!.query(
          _tableName,
          orderBy: 'downloaded_at DESC',
        );
        return results.map((m) => PersistentSongMetadata.fromMap(m)).toList();
      } catch (e) {
        debugPrint('⚠️ Error getting all metadata from internal: $e');
      }
    }

    return [];
  }

  /// Get metadata map for quick lookups (file path -> metadata)
  ///
  /// ARCHITECTURE FIX: Only uses full file path as key.
  /// NEVER use fileName as a lookup key - this caused metadata collision
  /// after reinstall where all songs got the first song's metadata.
  Future<Map<String, PersistentSongMetadata>> getMetadataMap() async {
    final allMetadata = await getAllMetadata();
    final map = <String, PersistentSongMetadata>{};

    for (final meta in allMetadata) {
      // ONLY use full file path as key - no fileName fallback!
      // fileName lookup was causing metadata collision bug
      map[meta.filePath] = meta;
    }

    return map;
  }

  /// Delete metadata by file path
  Future<void> deleteMetadata(String filePath) async {
    await initialize();

    if (_internalDatabase != null) {
      await _internalDatabase!.delete(
        _tableName,
        where: 'file_path = ?',
        whereArgs: [filePath],
      );
    }

    if (_externalDatabase != null) {
      await _externalDatabase!.delete(
        _tableName,
        where: 'file_path = ?',
        whereArgs: [filePath],
      );
    }

    debugPrint('🗑️ Metadata deleted for: $filePath');
  }

  /// Sync external database to internal (useful after app reinstall)
  Future<void> syncFromExternalDatabase() async {
    await initialize();

    if (_externalDatabase == null || _internalDatabase == null) return;

    try {
      final externalData = await _externalDatabase!.query(_tableName);
      int syncedCount = 0;

      for (final row in externalData) {
        final filePath = row['file_path'] as String?;
        if (filePath == null) continue;

        // Only sync if the MP3 file still exists
        if (!await File(filePath).exists()) {
          debugPrint('⏭️ Skipping (file missing): $filePath');
          continue;
        }

        // ✅ FIX: Verify and update artwork_path to match actual file location
        final mutableRow = Map<String, dynamic>.from(row);
        final expectedArtworkPath = filePath.replaceAll('.mp3', '.jpg');
        if (await File(expectedArtworkPath).exists()) {
          mutableRow['artwork_path'] = expectedArtworkPath;
        } else {
          mutableRow['artwork_path'] = null;
        }

        await _internalDatabase!.insert(
          _tableName,
          mutableRow,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        syncedCount++;
      }

      debugPrint('✅ Synced $syncedCount records from external database');
    } catch (e) {
      debugPrint('⚠️ Error syncing databases: $e');
    }

    // ✅ Also restore from JSON backup file (survives reinstall)
    await _restoreFromJsonBackup();

    // ✅ Also restore from sidecar JSON files (most reliable for reinstall)
    await _restoreFromSidecarJsonFiles();
  }

  /// ✅ Restore metadata from sidecar JSON files next to songs
  Future<void> _restoreFromSidecarJsonFiles() async {
    try {
      debugPrint('🔄 Looking for sidecar JSON files...');

      final musicDir = Directory('/storage/emulated/0/Music/LumenLyric');
      if (!await musicDir.exists()) {
        debugPrint('📁 Music directory does not exist: ${musicDir.path}');
        return;
      }

      int restoredCount = 0;

      await for (final entity in musicDir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            // Check if corresponding MP3 file exists
            final mp3Path = entity.path.replaceAll('.json', '.mp3');
            if (!await File(mp3Path).exists()) {
              continue; // Skip orphaned JSON files
            }

            final content = await entity.readAsString();
            final map = Map<String, dynamic>.from(jsonDecode(content));

            // Update file path in case it changed
            map['file_path'] = mp3Path;
            map['file_name'] = path.basename(mp3Path);

            // ✅ FIX: Update artwork_path to match the current song location
            // The artwork should be a JPG file with the same name as the MP3
            final expectedArtworkPath = mp3Path.replaceAll('.mp3', '.jpg');
            if (await File(expectedArtworkPath).exists()) {
              map['artwork_path'] = expectedArtworkPath;
              debugPrint('🖼️ Found artwork at: $expectedArtworkPath');
            } else {
              // Clear artwork_path if file doesn't exist
              map['artwork_path'] = null;
              debugPrint('⚠️ Artwork not found at: $expectedArtworkPath');
            }

            if (_internalDatabase != null) {
              await _upsertMetadata(_internalDatabase!, map);
              restoredCount++;
              debugPrint(
                '📎 Restored from sidecar: ${map['title']} (${map['file_name']})',
              );
            }
          } catch (e) {
            debugPrint('⚠️ Could not parse sidecar ${entity.path}: $e');
          }
        }
      }

      if (restoredCount > 0) {
        debugPrint('🎉 Restored $restoredCount songs from sidecar JSON files');
      } else {
        debugPrint('📄 No sidecar JSON files found');
      }
    } catch (e) {
      debugPrint('⚠️ Error restoring from sidecar files: $e');
    }
  }

  /// ✅ Save metadata to JSON backup file (survives reinstall)
  Future<void> _saveToJsonBackup(PersistentSongMetadata metadata) async {
    try {
      debugPrint('📝 Attempting to save JSON backup for: ${metadata.title}');

      final backupFile = await _getJsonBackupFile();
      if (backupFile == null) {
        debugPrint('❌ Could not get backup file path');
        return;
      }

      debugPrint('📁 Backup file path: ${backupFile.path}');

      Map<String, dynamic> backupData = {};

      // Load existing data
      if (await backupFile.exists()) {
        try {
          final content = await backupFile.readAsString();
          backupData = Map<String, dynamic>.from(jsonDecode(content));
          debugPrint(
            '📖 Loaded existing backup with ${backupData.length} entries',
          );
        } catch (e) {
          debugPrint('⚠️ Could not parse existing backup: $e');
          // Start fresh
          backupData = {};
        }
      } else {
        debugPrint('📄 Creating new backup file');
      }

      // Add/update this metadata
      backupData[metadata.filePath] = metadata.toMap();

      // Save back
      final jsonContent = const JsonEncoder.withIndent(
        '  ',
      ).convert(backupData);
      await backupFile.writeAsString(jsonContent);

      // Verify the write
      if (await backupFile.exists()) {
        final fileSize = await backupFile.length();
        debugPrint(
          '✅ JSON backup saved: ${backupFile.path} (${fileSize} bytes, ${backupData.length} songs)',
        );
      } else {
        debugPrint('❌ Backup file does not exist after write!');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Could not save to JSON backup: $e');
      debugPrint('📜 Stack trace: $stackTrace');
    }
  }

  /// ✅ Restore metadata from JSON backup file
  Future<void> _restoreFromJsonBackup() async {
    try {
      debugPrint('🔄 Checking for JSON backup to restore...');

      final backupFile = await _getJsonBackupFile();
      if (backupFile == null) {
        debugPrint('❌ Could not get backup file path for restore');
        return;
      }

      debugPrint('📁 Looking for backup at: ${backupFile.path}');

      if (!await backupFile.exists()) {
        debugPrint('📄 No JSON backup file found at: ${backupFile.path}');
        return;
      }

      final fileSize = await backupFile.length();
      debugPrint('📖 Found backup file (${fileSize} bytes), reading...');

      final content = await backupFile.readAsString();
      final Map<String, dynamic> backupData = Map<String, dynamic>.from(
        jsonDecode(content),
      );

      debugPrint('📦 Backup contains ${backupData.length} song entries');

      int restoredCount = 0;
      int skippedCount = 0;

      for (final entry in backupData.entries) {
        try {
          final map = Map<String, dynamic>.from(entry.value);
          final filePath = map['file_path'] as String?;

          if (filePath == null) continue;

          // Only restore if file still exists
          if (await File(filePath).exists()) {
            // ✅ FIX: Update artwork_path to match the current song location
            final expectedArtworkPath = filePath.replaceAll('.mp3', '.jpg');
            if (await File(expectedArtworkPath).exists()) {
              map['artwork_path'] = expectedArtworkPath;
            } else {
              map['artwork_path'] = null;
            }

            if (_internalDatabase != null) {
              await _upsertMetadata(_internalDatabase!, map);
              restoredCount++;
              debugPrint('✅ Restored: ${map['title']}');
            }
          } else {
            skippedCount++;
            debugPrint('⏭️ Skipped (file missing): $filePath');
          }
        } catch (e) {
          debugPrint('⚠️ Could not restore entry ${entry.key}: $e');
        }
      }

      debugPrint(
        '🎉 Restore complete: $restoredCount restored, $skippedCount skipped (files missing)',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Could not restore from JSON backup: $e');
      debugPrint('📜 Stack trace: $stackTrace');
    }
  }

  /// ✅ Get JSON backup file path (stored alongside music files)
  Future<File?> _getJsonBackupFile() async {
    if (!Platform.isAndroid) {
      // On iOS/other platforms, use documents directory
      try {
        final dir = await getApplicationDocumentsDirectory();
        final backupDir = Directory('${dir.path}/LumenLyric');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        return File('${backupDir.path}/.metadata_backup.json');
      } catch (e) {
        debugPrint('❌ Could not get backup file path (non-Android): $e');
        return null;
      }
    }

    // On Android, try multiple locations
    // Priority 1: Music folder (survives reinstall)
    try {
      final musicDir = Directory('/storage/emulated/0/Music/LumenLyric');

      // Check if directory exists or can be created
      if (!await musicDir.exists()) {
        debugPrint('📁 Creating LumenLyric directory...');
        await musicDir.create(recursive: true);
      }

      if (await musicDir.exists()) {
        debugPrint('✅ LumenLyric directory exists: ${musicDir.path}');
        return File('${musicDir.path}/.metadata_backup.json');
      }
    } catch (e) {
      debugPrint('⚠️ Could not access Music folder: $e');
    }

    // Priority 2: External storage directory
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final backupDir = Directory('${extDir.path}/metadata');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        debugPrint('📁 Using external storage for backup: ${backupDir.path}');
        return File('${backupDir.path}/.metadata_backup.json');
      }
    } catch (e) {
      debugPrint('⚠️ Could not access external storage: $e');
    }

    // Priority 3: App documents directory (fallback)
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/LumenLyric');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      debugPrint('📁 Using app documents for backup: ${backupDir.path}');
      return File('${backupDir.path}/.metadata_backup.json');
    } catch (e) {
      debugPrint('❌ Could not get any backup file path: $e');
      return null;
    }
  }

  /// Clean up metadata for files that no longer exist
  Future<void> cleanupOrphanedMetadata() async {
    await initialize();

    final allMetadata = await getAllMetadata();
    int cleaned = 0;

    for (final meta in allMetadata) {
      final file = File(meta.filePath);
      if (!await file.exists()) {
        await deleteMetadata(meta.filePath);
        cleaned++;
      }
    }

    if (cleaned > 0) {
      debugPrint('🧹 Cleaned up $cleaned orphaned metadata records');
    }
  }

  /// Check if metadata exists for a file
  Future<bool> hasMetadata(String filePath) async {
    final metadata = await getMetadataByPath(filePath);
    return metadata != null;
  }

  /// Clear ALL metadata (useful for fixing corrupted data)
  Future<void> clearAllMetadata() async {
    await initialize();

    try {
      if (_internalDatabase != null) {
        await _internalDatabase!.delete(_tableName);
        debugPrint('🗑️ Cleared internal database');
      }

      if (_externalDatabase != null) {
        await _externalDatabase!.delete(_tableName);
        debugPrint('🗑️ Cleared external database');
      }

      // Also clear JSON backup
      final backupFile = await _getJsonBackupFile();
      if (backupFile != null && await backupFile.exists()) {
        await backupFile.delete();
        debugPrint('🗑️ Deleted JSON backup file');
      }

      // Also clear all sidecar JSON files
      await _clearSidecarJsonFiles();

      debugPrint('✅ All metadata cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing metadata: $e');
    }
  }

  /// Delete all sidecar JSON files in LumenLyric folder
  Future<void> _clearSidecarJsonFiles() async {
    try {
      final lumenLyricDir = Directory('/storage/emulated/0/Music/LumenLyric');
      if (!await lumenLyricDir.exists()) {
        return;
      }

      int deletedCount = 0;
      await for (final entity in lumenLyricDir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            await entity.delete();
            deletedCount++;
          } catch (e) {
            debugPrint('⚠️ Could not delete sidecar file: ${entity.path}');
          }
        }
      }

      if (deletedCount > 0) {
        debugPrint('🗑️ Deleted $deletedCount sidecar JSON files');
      }
    } catch (e) {
      debugPrint('❌ Error clearing sidecar JSON files: $e');
    }
  }

  /// Close databases
  Future<void> close() async {
    await _internalDatabase?.close();
    await _externalDatabase?.close();
    _isInitialized = false;
    debugPrint('📴 MetadataDatabaseService closed');
  }
}
