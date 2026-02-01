import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// BackgroundDownloadService handles downloads that continue even when app is closed
class BackgroundDownloadService {
  static final BackgroundDownloadService instance =
      BackgroundDownloadService._internal();
  factory BackgroundDownloadService() => instance;
  BackgroundDownloadService._internal();

  static const String _portName = 'downloader_send_port';

  ReceivePort? _port;
  bool _initialized = false;

  // Callbacks for UI updates
  Function(String taskId, int status, int progress)? onProgressUpdate;

  // Store pending download metadata (for post-download processing)
  final Map<String, Map<String, dynamic>> _pendingMetadata = {};

  /// Initialize FlutterDownloader - MUST be called once at app start
  Future<void> initialize() async {
    if (_initialized) return;

    await FlutterDownloader.initialize(
      debug: true, // Set to false in production
      ignoreSsl: true, // If your server uses self-signed certificates
    );

    _initialized = true;
    debugPrint('✅ FlutterDownloader initialized');
  }

  /// Setup port for receiving download updates in UI
  void bindBackgroundIsolate() {
    _unbindBackgroundIsolate();

    _port = ReceivePort();
    final success = IsolateNameServer.registerPortWithName(
      _port!.sendPort,
      _portName,
    );

    if (!success) {
      debugPrint('⚠️ Port registration failed, trying to rebind...');
      _unbindBackgroundIsolate();
      _port = ReceivePort();
      IsolateNameServer.registerPortWithName(_port!.sendPort, _portName);
    }

    _port!.listen((dynamic data) {
      final String taskId = data[0];
      final int status = data[1];
      final int progress = data[2];

      debugPrint(
        '📥 Download Update - TaskId: $taskId, Status: $status, Progress: $progress%',
      );

      // Notify listeners
      onProgressUpdate?.call(taskId, status, progress);

      // Handle completion
      if (status == DownloadTaskStatus.complete.index) {
        _handleDownloadComplete(taskId);
      }
    });

    debugPrint('✅ Background isolate bound');
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping(_portName);
    _port?.close();
    _port = null;
  }

  void dispose() {
    _unbindBackgroundIsolate();
  }

  /// This callback runs in a separate isolate - DO NOT access UI here
  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(_portName);
    send?.send([id, status, progress]);
  }

  /// Register the callback
  void registerCallback() {
    FlutterDownloader.registerCallback(downloadCallback);
  }

  /// Get download directory
  Future<String> getDownloadDirectory() async {
    Directory? directory;

    if (Platform.isAndroid) {
      // Try Music folder first
      directory = Directory('/storage/emulated/0/Music/LumenLyric');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } else {
      // iOS/others: use app documents directory
      directory = await getApplicationDocumentsDirectory();
      directory = Directory('${directory.path}/LumenLyric');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }

    return directory.path;
  }

  /// Start a background download
  Future<String?> enqueueDownload({
    required String url,
    required String fileName,
    Map<String, dynamic>? metadata,
    bool showNotification = true,
    bool openFileFromNotification = true,
  }) async {
    try {
      final saveDir = await getDownloadDirectory();

      // Sanitize filename
      final sanitizedName = _sanitizeFileName(fileName);

      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: saveDir,
        fileName: sanitizedName,
        showNotification: showNotification,
        openFileFromNotification: openFileFromNotification,
        saveInPublicStorage: true, // Save to public storage for media scanner
      );

      if (taskId != null && metadata != null) {
        // Store metadata for post-processing
        _pendingMetadata[taskId] = {
          ...metadata,
          'filePath': '$saveDir/$sanitizedName',
        };
        await _savePendingMetadata();
      }

      debugPrint('✅ Download enqueued: $taskId');
      return taskId;
    } catch (e) {
      debugPrint('❌ Error enqueuing download: $e');
      return null;
    }
  }

  String _sanitizeFileName(String fileName) {
    // Remove invalid characters and limit length
    String sanitized = fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Ensure it ends with .mp3
    if (!sanitized.toLowerCase().endsWith('.mp3')) {
      sanitized = '$sanitized.mp3';
    }

    // Limit length
    if (sanitized.length > 100) {
      sanitized = '${sanitized.substring(0, 96)}.mp3';
    }

    return sanitized;
  }

  /// Handle download completion - trigger post-processing
  Future<void> _handleDownloadComplete(String taskId) async {
    debugPrint('🎉 Download complete: $taskId');

    final metadata = _pendingMetadata[taskId];
    if (metadata != null) {
      // Store completed download for later metadata writing
      await _addToCompletedQueue(taskId, metadata);
      _pendingMetadata.remove(taskId);
      await _savePendingMetadata();
    }
  }

  /// Pause a download
  Future<void> pauseDownload(String taskId) async {
    await FlutterDownloader.pause(taskId: taskId);
  }

  /// Resume a download
  Future<String?> resumeDownload(String taskId) async {
    return await FlutterDownloader.resume(taskId: taskId);
  }

  /// Cancel a download
  Future<void> cancelDownload(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
    _pendingMetadata.remove(taskId);
  }

  /// Retry a failed download
  Future<String?> retryDownload(String taskId) async {
    return await FlutterDownloader.retry(taskId: taskId);
  }

  /// Remove a download task
  Future<void> removeDownload(
    String taskId, {
    bool shouldDeleteContent = false,
  }) async {
    await FlutterDownloader.remove(
      taskId: taskId,
      shouldDeleteContent: shouldDeleteContent,
    );
    _pendingMetadata.remove(taskId);
  }

  /// Open downloaded file
  Future<bool> openDownloadedFile(String taskId) async {
    return await FlutterDownloader.open(taskId: taskId);
  }

  /// Get all download tasks
  Future<List<DownloadTask>?> getAllTasks() async {
    return await FlutterDownloader.loadTasks();
  }

  /// Get tasks with specific status
  Future<List<DownloadTask>?> getTasksWithStatus(
    DownloadTaskStatus status,
  ) async {
    return await FlutterDownloader.loadTasksWithRawQuery(
      query: "SELECT * FROM task WHERE status=${status.index}",
    );
  }

  /// Cancel all downloads
  Future<void> cancelAllDownloads() async {
    await FlutterDownloader.cancelAll();
    _pendingMetadata.clear();
  }

  // ========== Persistence Methods ==========

  Future<void> _savePendingMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_pendingMetadata);
    await prefs.setString('pending_download_metadata', data);
  }

  Future<void> loadPendingMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('pending_download_metadata');
    if (data != null) {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      _pendingMetadata.clear();
      decoded.forEach((key, value) {
        _pendingMetadata[key] = Map<String, dynamic>.from(value);
      });
    }
  }

  Future<void> _addToCompletedQueue(
    String taskId,
    Map<String, dynamic> metadata,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> queue = [];

    final existing = prefs.getString('completed_downloads_queue');
    if (existing != null) {
      queue = List<Map<String, dynamic>>.from(jsonDecode(existing));
    }

    queue.add({
      'taskId': taskId,
      'metadata': metadata,
      'completedAt': DateTime.now().toIso8601String(),
    });

    await prefs.setString('completed_downloads_queue', jsonEncode(queue));
  }

  /// Get and clear completed downloads queue (for post-processing)
  Future<List<Map<String, dynamic>>> getAndClearCompletedQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('completed_downloads_queue');

    if (data != null) {
      await prefs.remove('completed_downloads_queue');
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    }

    return [];
  }
}
