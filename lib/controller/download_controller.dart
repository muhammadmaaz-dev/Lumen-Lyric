import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async'; // Delay ke liye
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:musicapp/models/download_metadata_model.dart';
import 'package:musicapp/services/yt_download_service.dart';
import 'package:musicapp/services/background_download_service.dart';
import 'package:musicapp/services/metadata_database_service.dart'; // ✅ Permanent Metadata Storage
import 'package:musicapp/controller/audio_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart'; // ✅ Image Download
import 'package:flutter_audio_tagger/flutter_audio_tagger.dart'; // ✅ Tagging Tool
import 'package:flutter_audio_tagger/tag.dart'; // ✅ Tag Class
import 'package:path/path.dart' as path; // ✅ For file path operations

class DownloadController {
  static final DownloadController instance = DownloadController._internal();
  factory DownloadController() => instance;
  DownloadController._internal();

  final YtDownloadService _downloadService = YtDownloadService();
  final BackgroundDownloadService _backgroundService =
      BackgroundDownloadService.instance;
  final MetadataDatabaseService _metadataDb =
      MetadataDatabaseService.instance; // ✅ Permanent Storage
  final Uuid _uuid = const Uuid();

  // Observable state
  final ValueNotifier<List<DownloadTaskModel>> downloadQueue =
      ValueNotifier<List<DownloadTaskModel>>([]);

  final ValueNotifier<List<DownloadTaskModel>> recentDownloads =
      ValueNotifier<List<DownloadTaskModel>>([]);

  final ValueNotifier<bool> isProcessing = ValueNotifier<bool>(false);

  // Map to track flutter_downloader taskIds to our internal taskIds
  final Map<String, String> _downloaderTaskIdMap = {};

  // Version for metadata migration (increment when metadata structure changes)
  // Version 3: Also clears sidecar JSON files during cleanup
  static const int _metadataVersion = 3;

  Future<void> init() async {
    // ✅ Check if we need to clear corrupted metadata from previous versions
    await _checkAndClearCorruptedMetadata();

    // ✅ Initialize metadata database first (syncs from external after reinstall)
    await _metadataDb.initialize();
    await _metadataDb.syncFromExternalDatabase();

    await _loadRecentDownloads();
    await _loadDownloaderTaskMapping();

    // Initialize and bind background download service
    await _backgroundService.initialize();
    _backgroundService.registerCallback();
    _backgroundService.bindBackgroundIsolate();

    // Listen to download progress updates
    _backgroundService.onProgressUpdate = _handleBackgroundDownloadProgress;

    // Process any completed downloads from when app was closed
    await _processCompletedBackgroundDownloads();

    // Restore any in-progress downloads
    await _restoreDownloadTasks();
  }

  /// Clear corrupted metadata from previous app versions
  Future<void> _checkAndClearCorruptedMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt('metadata_version') ?? 0;

    if (storedVersion < _metadataVersion) {
      debugPrint(
        '🧹 Clearing corrupted metadata from version $storedVersion -> $_metadataVersion',
      );

      // Clear the corrupted metadata database
      await _metadataDb.initialize();
      await _metadataDb.clearAllMetadata();

      // Clear legacy SharedPreferences metadata
      await prefs.remove('recent_downloads');

      // Save new version
      await prefs.setInt('metadata_version', _metadataVersion);

      debugPrint('✅ Metadata cleanup complete');
    }
  }

  /// Handle progress updates from background downloads
  void _handleBackgroundDownloadProgress(
    String downloaderTaskId,
    int status,
    int progress,
  ) {
    // Find our internal task ID
    final internalTaskId = _downloaderTaskIdMap.entries
        .where((e) => e.value == downloaderTaskId)
        .map((e) => e.key)
        .firstOrNull;

    if (internalTaskId == null) return;

    // Map flutter_downloader status to our status
    DownloadStatus downloadStatus;
    switch (status) {
      case 1: // enqueued
        downloadStatus = DownloadStatus.pending;
        break;
      case 2: // running
        downloadStatus = DownloadStatus.downloading;
        break;
      case 3: // complete
        downloadStatus = DownloadStatus.completed;
        break;
      case 4: // failed
        downloadStatus = DownloadStatus.failed;
        break;
      case 5: // canceled
        downloadStatus = DownloadStatus.failed;
        break;
      case 6: // paused
        downloadStatus = DownloadStatus.pending;
        break;
      default:
        downloadStatus = DownloadStatus.pending;
    }

    _updateTask(
      internalTaskId,
      status: downloadStatus,
      progress: progress / 100.0,
    );

    // If completed, process the metadata
    if (status == 3) {
      _handleBackgroundDownloadComplete(internalTaskId);
    }
  }

  /// Handle background download completion
  Future<void> _handleBackgroundDownloadComplete(String taskId) async {
    final task = downloadQueue.value.firstWhere(
      (t) => t.id == taskId,
      orElse: () => DownloadTaskModel(
        id: '',
        youtubeUrl: '',
        status: DownloadStatus.failed,
      ),
    );

    if (task.id.isEmpty) return;

    // Get file path from background service
    final tasks = await _backgroundService.getAllTasks();
    final downloaderTaskId = _downloaderTaskIdMap[taskId];
    final downloaderTask = tasks?.firstWhere(
      (t) => t.taskId == downloaderTaskId,
    );

    if (downloaderTask != null && downloaderTask.taskId.isNotEmpty) {
      final filePath = '${downloaderTask.savedDir}/${downloaderTask.filename}';

      // Write metadata tags (YouTube URL stored in composer field as logical identity)
      await _writeTagsToFile(
        filePath,
        task.metadata,
        youtubeUrl: task.youtubeUrl,
      );

      // ✅ Save metadata permanently to SQLite database
      await _saveMetadataPermanently(
        filePath: filePath,
        metadata: task.metadata,
        localImagePath: task.localImagePath,
        youtubeUrl: task.youtubeUrl,
      );

      _updateTask(
        taskId,
        status: DownloadStatus.completed,
        filePath: filePath,
        progress: 1.0,
      );

      await _addToRecentDownloads(
        downloadQueue.value.firstWhere((t) => t.id == taskId),
      );

      // Scan media
      await AudioController.instance.scanNewMedia(filePath);
      await AudioController.instance.loadSongs();

      debugPrint("✅ Background Download Complete: $filePath");
    }
  }

  /// Process downloads that completed while app was closed
  Future<void> _processCompletedBackgroundDownloads() async {
    final completedQueue = await _backgroundService.getAndClearCompletedQueue();

    for (final item in completedQueue) {
      final metadata = item['metadata'] as Map<String, dynamic>?;
      final filePath = metadata?['filePath'] as String?;

      if (filePath != null && await File(filePath).exists()) {
        // Write tags to the downloaded file
        final downloadMetadata = metadata != null
            ? DownloadMetadataModel.fromJson(metadata)
            : null;

        if (downloadMetadata != null) {
          await _writeTagsToFile(
            filePath,
            downloadMetadata,
            youtubeUrl: metadata?['youtubeUrl'] as String?,
          );

          // ✅ Save metadata permanently to SQLite database
          await _saveMetadataPermanently(
            filePath: filePath,
            metadata: downloadMetadata,
            localImagePath: metadata?['localImagePath'] as String?,
            youtubeUrl: metadata?['youtubeUrl'] as String?,
          );
        }

        // Scan media
        await AudioController.instance.scanNewMedia(filePath);

        debugPrint("✅ Processed background download: $filePath");
      }
    }

    await AudioController.instance.loadSongs();
  }

  /// Restore download tasks from flutter_downloader
  Future<void> _restoreDownloadTasks() async {
    final tasks = await _backgroundService.getAllTasks();
    if (tasks == null) return;

    for (final task in tasks) {
      if (task.status == DownloadTaskStatus.running ||
          task.status == DownloadTaskStatus.enqueued ||
          task.status == DownloadTaskStatus.paused) {
        // Restore in-progress downloads to our queue
        final internalTaskId = _uuid.v4();
        _downloaderTaskIdMap[internalTaskId] = task.taskId;

        final downloadTask = DownloadTaskModel(
          id: internalTaskId,
          youtubeUrl: '', // We don't have this info anymore
          status: task.status == DownloadTaskStatus.running
              ? DownloadStatus.downloading
              : DownloadStatus.pending,
          progress: task.progress / 100.0,
          filePath: '${task.savedDir}/${task.filename}',
        );

        downloadQueue.value = [...downloadQueue.value, downloadTask];
      }
    }
  }

  bool isValidUrl(String url) {
    return _downloadService.isValidYoutubeUrl(url);
  }

  /// Add download to queue directly
  Future<void> addToQueue(String youtubeUrl) async {
    if (!isValidUrl(youtubeUrl)) {
      throw Exception('Invalid YouTube URL');
    }

    final taskId = _uuid.v4();
    final task = DownloadTaskModel(
      id: taskId,
      youtubeUrl: youtubeUrl,
      status: DownloadStatus.pending,
    );

    downloadQueue.value = [...downloadQueue.value, task];

    if (!isProcessing.value) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (isProcessing.value) return;
    isProcessing.value = true;

    while (downloadQueue.value.any((t) => t.status == DownloadStatus.pending)) {
      final taskIndex = downloadQueue.value.indexWhere(
        (t) => t.status == DownloadStatus.pending,
      );

      if (taskIndex == -1) break;

      final task = downloadQueue.value[taskIndex];

      try {
        debugPrint("📥 Starting download for: ${task.youtubeUrl}");

        // Use the reliable direct download method
        // This downloads within the app and shows real progress
        await _directDownload(task);
      } catch (e) {
        debugPrint("❌ Download failed: $e");
        _updateTask(
          task.id,
          status: DownloadStatus.failed,
          errorMessage: e.toString(),
        );
      }
    }

    isProcessing.value = false;
  }

  /// Direct download method - uses Dio for reliable in-app downloads with progress
  Future<void> _directDownload(DownloadTaskModel task) async {
    final result = await _downloadService.downloadAudio(
      task.youtubeUrl,
      onStageChange: (stage) {
        DownloadStatus status;
        switch (stage) {
          case DownloadStage.converting:
            status = DownloadStatus.converting;
            break;
          case DownloadStage.downloading:
            status = DownloadStatus.downloading;
            break;
          case DownloadStage.completed:
            status = DownloadStatus.completed;
            break;
          case DownloadStage.failed:
            status = DownloadStatus.failed;
            break;
          default:
            status = DownloadStatus.pending;
        }
        _updateTask(task.id, status: status);
      },
      onProgress: (progress) {
        _updateTask(task.id, progress: progress);
      },
    );

    if (result.success && result.filePath != null) {
      // Write ID3 tags with YouTube URL as logical identity
      await _writeTagsToFile(
        result.filePath!,
        result.metadata,
        youtubeUrl: task.youtubeUrl,
      );

      // ✅ Save metadata permanently to SQLite database
      await _saveMetadataPermanently(
        filePath: result.filePath!,
        metadata: result.metadata,
        localImagePath: result.localImagePath,
        youtubeUrl: task.youtubeUrl,
      );

      _updateTask(
        task.id,
        status: DownloadStatus.completed,
        filePath: result.filePath,
        metadata: result.metadata,
        localImagePath: result.localImagePath,
        progress: 1.0,
      );

      await _addToRecentDownloads(
        downloadQueue.value.firstWhere((t) => t.id == task.id),
      );

      debugPrint("✅ Download Complete: ${result.filePath}");

      await AudioController.instance.scanNewMedia(result.filePath!);
      await AudioController.instance.loadSongs();
    } else {
      throw Exception(result.errorMessage ?? 'Download failed');
    }
  }

  /// ✅ Save metadata permanently to SQLite database (survives reinstall)
  Future<void> _saveMetadataPermanently({
    required String filePath,
    DownloadMetadataModel? metadata,
    String? localImagePath,
    String? youtubeUrl,
  }) async {
    if (metadata == null) return;

    try {
      final fileName = path.basename(filePath);

      // Parse duration if available
      int? durationMs;
      if (metadata.duration != null) {
        try {
          // Duration might be in seconds or "MM:SS" format
          final durationStr = metadata.duration!;
          if (durationStr.contains(':')) {
            final parts = durationStr.split(':');
            if (parts.length == 2) {
              durationMs =
                  (int.parse(parts[0]) * 60 + int.parse(parts[1])) * 1000;
            } else if (parts.length == 3) {
              durationMs =
                  (int.parse(parts[0]) * 3600 +
                      int.parse(parts[1]) * 60 +
                      int.parse(parts[2])) *
                  1000;
            }
          } else {
            durationMs = int.tryParse(durationStr);
            if (durationMs != null && durationMs < 100000) {
              durationMs = durationMs * 1000; // Convert seconds to ms
            }
          }
        } catch (e) {
          debugPrint('⚠️ Could not parse duration: ${metadata.duration}');
        }
      }

      final persistentMeta = PersistentSongMetadata(
        filePath: filePath,
        fileName: fileName,
        title: metadata.title ?? fileName.replaceAll('.mp3', ''),
        artist: metadata.artist ?? 'Unknown Artist',
        album: metadata.album ?? 'LumenLyric',
        duration: durationMs,
        artworkPath: localImagePath,
        artworkUrl: metadata.thumbnailUrl,
        youtubeUrl: youtubeUrl,
        description: metadata.description,
      );

      await _metadataDb.saveMetadata(persistentMeta);
      debugPrint('✅ Metadata saved permanently for: ${persistentMeta.title}');
    } catch (e) {
      debugPrint('❌ Error saving permanent metadata: $e');
    }
  }

  /// Save task ID mapping for app restart
  Future<void> _saveDownloaderTaskMapping() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'downloader_task_map',
      jsonEncode(_downloaderTaskIdMap),
    );
  }

  /// Load task ID mapping on app start
  Future<void> _loadDownloaderTaskMapping() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('downloader_task_map');
    if (data != null) {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      _downloaderTaskIdMap.clear();
      decoded.forEach((key, value) {
        _downloaderTaskIdMap[key] = value.toString();
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WRITE ID3 TAGS TO MP3 FILE - THIS IS THE SINGLE SOURCE OF TRUTH
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // INVARIANT: Metadata is written ONCE at download time and NEVER modified.
  // The YouTube URL is stored in the 'composer' field as logical identity.
  //
  // FALLBACK: Since flutter_audio_tagger may fail silently, we also write
  // a sidecar .meta.json file that contains the same metadata.
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _writeTagsToFile(
    String filePath,
    DownloadMetadataModel? metadata, {
    String? youtubeUrl,
  }) async {
    if (metadata == null) return;

    try {
      final tagger = FlutterAudioTagger();
      Uint8List? artworkBytes;

      // ═══════════════════════════════════════════════════════════════════════
      // STEP 0: WRITE SIDECAR JSON METADATA (REINSTALL-SAFE BACKUP)
      // ═══════════════════════════════════════════════════════════════════════
      // This is the critical fix: write metadata to a .meta.json file that
      // survives app reinstall. ID3 tag writing may fail on some devices.
      try {
        final metaJsonPath = filePath.replaceAll(
          RegExp(r'\.mp3$', caseSensitive: false),
          '.meta.json',
        );
        final metaJson = {
          'title': metadata.title,
          'artist': metadata.artist,
          'album': metadata.album ?? 'LumenLyric',
          'youtubeUrl': youtubeUrl,
          'thumbnailUrl': metadata.thumbnailUrl,
          'duration': metadata.duration,
          'downloadedAt': DateTime.now().toIso8601String(),
        };
        await File(metaJsonPath).writeAsString(jsonEncode(metaJson));
        debugPrint('✅ [META] Sidecar metadata saved: $metaJsonPath');
      } catch (e) {
        debugPrint('⚠️ [META] Failed to save sidecar metadata: $e');
      }

      // ═══════════════════════════════════════════════════════════════════════
      // STEP 1: Download artwork bytes for embedding into ID3 APIC frame
      // ═══════════════════════════════════════════════════════════════════════
      if (metadata.thumbnailUrl != null && metadata.thumbnailUrl!.isNotEmpty) {
        try {
          final dio = Dio();
          final response = await dio.get(
            metadata.thumbnailUrl!,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.statusCode == 200) {
            artworkBytes = Uint8List.fromList(response.data);
            debugPrint(
              "✅ [ID3] Artwork downloaded: ${artworkBytes.length} bytes",
            );

            // ═══════════════════════════════════════════════════════════════════
            // STEP 1b: Also save artwork as sidecar .jpg file (backup for reading)
            // ═══════════════════════════════════════════════════════════════════
            try {
              final artworkPath = filePath.replaceAll(
                RegExp(r'\.mp3$', caseSensitive: false),
                '.jpg',
              );
              await File(artworkPath).writeAsBytes(artworkBytes);
              debugPrint("✅ [ID3] Artwork also saved as sidecar: $artworkPath");
            } catch (e) {
              debugPrint("⚠️ [ID3] Failed to save sidecar artwork: $e");
            }
          }
        } catch (e) {
          debugPrint("⚠️ Artwork download failed: $e");
        }
      }

      // ═══════════════════════════════════════════════════════════════════════
      // STEP 2: Create ID3v2 Tags object with ALL metadata
      // ═══════════════════════════════════════════════════════════════════════
      // IMPORTANT: 'composer' field stores the YouTube URL as LOGICAL IDENTITY
      // This allows us to identify the song's source even after file operations
      //
      // ID3 Frames being written:
      // - TIT2 → Title
      // - TPE1 → Artist
      // - TALB → Album
      // - TYER → Year
      // - TCOM → Composer (stores YouTube URL as logical identity)
      // - APIC → Embedded artwork (cover image bytes)
      // ═══════════════════════════════════════════════════════════════════════
      final tags = Tag(
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album ?? "LumenLyric",
        year: DateTime.now().year.toString(),
        composer: youtubeUrl, // ✅ LOGICAL IDENTITY - YouTube URL stored here
        artwork: artworkBytes, // ✅ EMBEDDED ARTWORK - stored in APIC frame
      );

      // ═══════════════════════════════════════════════════════════════════════
      // STEP 3: Write Tags to MP3 file (creates 'filename_edited.mp3')
      // ═══════════════════════════════════════════════════════════════════════
      debugPrint("📝 [ID3] Writing tags to: $filePath");
      debugPrint("📝 [ID3] Title: ${metadata.title}");
      debugPrint("📝 [ID3] Artist: ${metadata.artist}");
      debugPrint("📝 [ID3] Album: ${metadata.album ?? 'LumenLyric'}");
      if (youtubeUrl != null) {
        debugPrint("📝 [ID3] YouTube URL (composer): $youtubeUrl");
      }
      if (artworkBytes != null) {
        debugPrint("📝 [ID3] Artwork: ${artworkBytes.length} bytes embedded");
      }

      // Write tags to the file
      await tagger.editTags(tags, filePath);

      // Wait for file system to complete write
      await Future.delayed(const Duration(milliseconds: 800));

      // ─────────────────────────────────────────────────────────────────────────
      // FILE SWAP LOGIC - Replace original with tagged version
      // flutter_audio_tagger creates a new file with _edited suffix
      // ─────────────────────────────────────────────────────────────────────────
      String editedPath;

      if (filePath.toLowerCase().endsWith(".mp3")) {
        editedPath = "${filePath.substring(0, filePath.length - 4)}_edited.mp3";
      } else if (filePath.toLowerCase().endsWith(".m4a")) {
        editedPath = "${filePath.substring(0, filePath.length - 4)}_edited.m4a";
      } else {
        editedPath = "${filePath}_edited";
      }

      File originalFile = File(filePath);
      File editedFile = File(editedPath);

      debugPrint("🔍 [ID3] Checking for edited file at: $editedPath");
      debugPrint("🔍 [ID3] Edited file exists: ${await editedFile.exists()}");

      if (await editedFile.exists()) {
        try {
          debugPrint("🔄 Swapping files...");
          // First copy edited file to a temp location
          final tempPath = "${filePath}.temp";
          await editedFile.copy(tempPath);

          // Delete original
          if (await originalFile.exists()) {
            await originalFile.delete();
          }

          // Rename temp to original path
          await File(tempPath).rename(filePath);

          // Delete the edited file if it still exists
          if (await editedFile.exists()) {
            await editedFile.delete();
          }

          debugPrint("✅ [ID3] Tags saved permanently to: $filePath");

          // Verify the tags were written
          final verifyTags = await tagger.getAllTags(filePath);
          if (verifyTags != null) {
            debugPrint(
              "✅ [ID3] Verified - Title: ${verifyTags.title}, Artist: ${verifyTags.artist}",
            );
          } else {
            debugPrint("⚠️ [ID3] Warning: Could not verify tags after write");
          }
        } catch (e) {
          debugPrint("❌ Error swapping files: $e");
          // Try alternative: just copy the edited file over
          try {
            await editedFile.copy(filePath);
            await editedFile.delete();
            debugPrint("✅ [ID3] Tags saved via copy fallback");
          } catch (e2) {
            debugPrint("❌ Copy fallback also failed: $e2");
          }
        }
      } else {
        debugPrint(
          "⚠️ [ID3] Edited file not found at: $editedPath - trying direct write",
        );

        // Try writing tags again with a different approach
        // Some versions of the library might write directly to the file
        try {
          // Check if the original file now has tags
          final checkTags = await tagger.getAllTags(filePath);
          if (checkTags != null &&
              checkTags.title != null &&
              checkTags.title!.isNotEmpty) {
            debugPrint(
              "✅ [ID3] Tags written directly - Title: ${checkTags.title}",
            );
          } else {
            debugPrint("⚠️ [ID3] Tags not found in original file either");
          }
        } catch (e) {
          debugPrint("❌ Error checking tags: $e");
        }
      }
    } catch (e) {
      debugPrint("❌ Error writing ID3 Tags: $e");
    }
  }

  void _updateTask(
    String taskId, {
    DownloadMetadataModel? metadata,
    DownloadStatus? status,
    double? progress,
    String? filePath,
    String? localImagePath,
    String? errorMessage,
  }) {
    final tasks = List<DownloadTaskModel>.from(downloadQueue.value);
    final index = tasks.indexWhere((t) => t.id == taskId);

    if (index != -1) {
      tasks[index] = tasks[index].copyWith(
        metadata: metadata,
        status: status,
        progress: progress,
        filePath: filePath,
        localImagePath: localImagePath,
        errorMessage: errorMessage,
      );
      downloadQueue.value = tasks;
    }
  }

  Future<void> _addToRecentDownloads(DownloadTaskModel task) async {
    final recent = List<DownloadTaskModel>.from(recentDownloads.value);
    recent.insert(0, task);
    if (recent.length > 20) {
      recent.removeRange(20, recent.length);
    }
    recentDownloads.value = recent;
    await _saveRecentDownloads();
  }

  Future<void> _saveRecentDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final data = recentDownloads.value
        .map(
          (t) => {
            'id': t.id,
            'youtubeUrl': t.youtubeUrl,
            'filePath': t.filePath,
            'localImagePath': t.localImagePath,
            'createdAt': t.createdAt.toIso8601String(),
            'metadata': t.metadata?.toJson(),
          },
        )
        .toList();
    await prefs.setString('recent_downloads', jsonEncode(data));
  }

  Future<void> _loadRecentDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('recent_downloads');

    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      recentDownloads.value = decoded.map((item) {
        return DownloadTaskModel(
          id: item['id'],
          youtubeUrl: item['youtubeUrl'],
          filePath: item['filePath'],
          localImagePath: item['localImagePath'],
          status: DownloadStatus.completed,
          progress: 1.0,
          createdAt: DateTime.parse(item['createdAt']),
          metadata: item['metadata'] != null
              ? DownloadMetadataModel.fromJson(item['metadata'])
              : null,
        );
      }).toList();
    }
  }

  Future<void> clearRecentDownloads() async {
    recentDownloads.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_downloads');
  }
}
