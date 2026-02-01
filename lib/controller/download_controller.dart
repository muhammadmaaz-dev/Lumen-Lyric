import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async'; // Delay ke liye
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:musicapp/models/download_metadata_model.dart';
import 'package:musicapp/services/yt_download_service.dart';
import 'package:musicapp/services/background_download_service.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart'; // ✅ Image Download
import 'package:flutter_audio_tagger/flutter_audio_tagger.dart'; // ✅ Tagging Tool
import 'package:flutter_audio_tagger/tag.dart'; // ✅ Tag Class

class DownloadController {
  static final DownloadController instance = DownloadController._internal();
  factory DownloadController() => instance;
  DownloadController._internal();

  final YtDownloadService _downloadService = YtDownloadService();
  final BackgroundDownloadService _backgroundService =
      BackgroundDownloadService.instance;
  final Uuid _uuid = const Uuid();

  // Observable state
  final ValueNotifier<List<DownloadTaskModel>> downloadQueue =
      ValueNotifier<List<DownloadTaskModel>>([]);

  final ValueNotifier<List<DownloadTaskModel>> recentDownloads =
      ValueNotifier<List<DownloadTaskModel>>([]);

  final ValueNotifier<bool> isProcessing = ValueNotifier<bool>(false);

  // Map to track flutter_downloader taskIds to our internal taskIds
  final Map<String, String> _downloaderTaskIdMap = {};

  Future<void> init() async {
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

      // Write metadata tags
      await _writeTagsToFile(filePath, task.metadata);

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
        if (metadata != null) {
          final downloadMetadata = DownloadMetadataModel.fromJson(metadata);
          await _writeTagsToFile(filePath, downloadMetadata);
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
      await _writeTagsToFile(result.filePath!, result.metadata);

      _updateTask(
        task.id,
        status: DownloadStatus.completed,
        filePath: result.filePath,
        metadata: result.metadata,
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

  // ✅ Helper Function: Tags Write + File Swap Logic (Permanent Fix)
  Future<void> _writeTagsToFile(
    String filePath,
    DownloadMetadataModel? metadata,
  ) async {
    if (metadata == null) return;

    try {
      final tagger = FlutterAudioTagger();
      Uint8List? artworkBytes;

      // 1. Artwork Download (Agar image URL hai)
      if (metadata.thumbnailUrl != null && metadata.thumbnailUrl!.isNotEmpty) {
        try {
          final dio = Dio();
          final response = await dio.get(
            metadata.thumbnailUrl!,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.statusCode == 200) {
            artworkBytes = Uint8List.fromList(response.data);
          }
        } catch (e) {
          debugPrint("⚠️ Artwork download failed: $e");
        }
      }

      // 2. Tags Object Create
      final tags = Tag(
        title: metadata.title,
        artist: metadata.artist,
        album: "LumenLyric",
        year: DateTime.now().year.toString(),
        artwork: artworkBytes, // Image Embed hogi
      );

      // 3. Write Tags (Yeh 'filename_edited.mp3' banata hai)
      debugPrint("📝 Writing tags to: $filePath");
      await tagger.editTags(tags, filePath);

      // Thora wait karein taa ke file system write complete kar le
      await Future.delayed(const Duration(milliseconds: 500));

      // ---------------------------------------------------------
      // ✅ FILE SWAP LOGIC (Bina external package ke)
      // ---------------------------------------------------------
      String editedPath;

      // Determine Edited File Name based on extension
      if (filePath.toLowerCase().endsWith(".mp3")) {
        editedPath = filePath.substring(0, filePath.length - 4) + "_edited.mp3";
      } else if (filePath.toLowerCase().endsWith(".m4a")) {
        editedPath = filePath.substring(0, filePath.length - 4) + "_edited.m4a";
      } else {
        editedPath = filePath + "_edited";
      }

      File originalFile = File(filePath);
      File editedFile = File(editedPath);

      // Agar Edited file ban gayi hai, to Original se swap karein
      if (await editedFile.exists()) {
        try {
          debugPrint("🔄 Swapping files...");

          // 1. Original (bina tags wali) delete karein
          if (await originalFile.exists()) {
            await originalFile.delete();
          }

          // 2. Edited file ko rename karke Original bana dein
          await editedFile.rename(filePath);

          debugPrint("✅ Tags Saved Permanently in File! ($filePath)");
        } catch (e) {
          debugPrint("❌ Error swapping files: $e");
        }
      } else {
        debugPrint(
          "⚠️ Critical: Edited file ($editedPath) not found. Metadata might NOT be saved.",
        );
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
