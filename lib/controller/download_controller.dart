import 'package:flutter/material.dart';
import 'package:musicapp/models/download_metadata_model.dart';
import 'package:musicapp/services/yt_download_service.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DownloadController {
  static final DownloadController instance = DownloadController._internal();
  factory DownloadController() => instance;
  DownloadController._internal();

  final YtDownloadService _downloadService = YtDownloadService();
  final Uuid _uuid = const Uuid();

  // Observable state
  final ValueNotifier<List<DownloadTaskModel>> downloadQueue =
      ValueNotifier<List<DownloadTaskModel>>([]);

  final ValueNotifier<List<DownloadTaskModel>> recentDownloads =
      ValueNotifier<List<DownloadTaskModel>>([]);

  final ValueNotifier<bool> isProcessing = ValueNotifier<bool>(false);

  Future<void> init() async {
    await _loadRecentDownloads();
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
    // Start with minimal info
    final task = DownloadTaskModel(
      id: taskId,
      youtubeUrl: youtubeUrl,
      status: DownloadStatus.pending,
    );

    downloadQueue.value = [...downloadQueue.value, task];

    // Start processing immediately
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
        // 1. Metadata Fetch Karein (Taa ke list mein naam show ho)
        _updateTask(task.id, status: DownloadStatus.fetchingMetadata);
        final metadata = await _downloadService.getMetadata(task.youtubeUrl);
        _updateTask(task.id, metadata: metadata);

        // 2. Download Start Karein
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
          _updateTask(
            task.id,
            status: DownloadStatus.completed,
            filePath: result.filePath,
            metadata: result.metadata, // Use final metadata from server
            progress: 1.0,
          );

          await _addToRecentDownloads(
            downloadQueue.value.firstWhere((t) => t.id == task.id),
          );

          debugPrint("✅ Download Done. Triggering Scan...");
          await AudioController.instance.scanNewMedia(result.filePath!);
          await AudioController.instance.loadSongs();
        } else {
          _updateTask(
            task.id,
            status: DownloadStatus.failed,
            errorMessage: result.errorMessage ?? 'Download failed',
          );
        }
      } catch (e) {
        _updateTask(
          task.id,
          status: DownloadStatus.failed,
          errorMessage: e.toString(),
        );
      }
    }

    isProcessing.value = false;
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
