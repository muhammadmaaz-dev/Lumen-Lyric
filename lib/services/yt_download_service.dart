import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:musicapp/models/download_metadata_model.dart';

class YtDownloadService {
  static const String baseUrl = 'https://yt-mp3-api-mdkk.onrender.com';

  late final Dio _dio;

  YtDownloadService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(
          seconds: 120,
        ), // 2 minutes for cold start
        receiveTimeout: const Duration(
          minutes: 15,
        ), // 15 mins for long conversions
        sendTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  /// Check if API is online
  Future<bool> isApiOnline() async {
    try {
      final response = await _dio.get(
        '/',
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Wake up server (Render.com free tier can take 50+ seconds to cold start)
  Future<bool> wakeUpServer() async {
    debugPrint('🔄 Waking up server...');

    // Try up to 5 times with longer timeouts for cold start
    for (int attempt = 1; attempt <= 5; attempt++) {
      try {
        debugPrint('⏳ Wake attempt $attempt/5...');
        final response = await _dio.get(
          '/',
          options: Options(
            receiveTimeout: const Duration(
              seconds: 60,
            ), // Longer timeout for cold start
            sendTimeout: const Duration(seconds: 30),
          ),
        );
        if (response.statusCode == 200) {
          debugPrint('✅ Server is awake!');
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ Wake attempt $attempt failed: $e');
        if (attempt < 5) {
          await Future.delayed(const Duration(seconds: 3));
        }
      }
    }
    debugPrint('❌ Server wake-up failed after 5 attempts');
    return false;
  }

  bool isValidYoutubeUrl(String url) {
    final youtubeRegex = RegExp(
      r'^(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/|youtube\.com/shorts/)[\w-]+',
      caseSensitive: false,
    );
    return youtubeRegex.hasMatch(url);
  }

  Future<DownloadMetadataModel> getMetadata(String youtubeUrl) async {
    try {
      await wakeUpServer();
      final response = await _dio.post(
        '/metadata',
        data: {'url': youtubeUrl},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
      if (response.statusCode == 200) {
        return DownloadMetadataModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get metadata: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  // --- MAIN DOWNLOAD FUNCTION (Fixed for Offline Image) ---
  Future<DownloadResult> downloadAudio(
    String youtubeUrl, {
    bool includeMetadata = true,
    Function(DownloadStage stage)? onStageChange,
    Function(double progress)? onProgress,
  }) async {
    String? downloadId;

    try {
      final isOnline = await wakeUpServer();
      if (!isOnline)
        throw Exception('Server is unavailable. Please try again.');

      // Stage 1: Convert
      onStageChange?.call(DownloadStage.converting);

      final convertResponse = await _dio.post(
        '/download',
        data: {'url': youtubeUrl, 'include_metadata': includeMetadata},
        options: Options(receiveTimeout: const Duration(minutes: 10)),
      );

      if (convertResponse.statusCode != 200) {
        throw Exception('Conversion failed: ${convertResponse.statusMessage}');
      }

      final data = convertResponse.data;
      downloadId = data['download_id'];
      final serverFilename = data['filename'];
      final metadata = DownloadMetadataModel.fromJson(data['metadata']);

      // Stage 2: Download
      onStageChange?.call(DownloadStage.downloading);

      // --- Directory Setup ---
      Directory storageDir;
      if (Platform.isAndroid) {
        storageDir = Directory('/storage/emulated/0/Music/LumenLyric');
        try {
          if (!await storageDir.exists())
            await storageDir.create(recursive: true);
        } catch (e) {
          // Permission fail hua to App Data folder use karo
          final appDir = await getApplicationDocumentsDirectory();
          storageDir = Directory('${appDir.path}/LumenLyric');
          if (!await storageDir.exists())
            await storageDir.create(recursive: true);
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        storageDir = Directory('${dir.path}/LumenLyric');
        if (!await storageDir.exists())
          await storageDir.create(recursive: true);
      }

      final songTitle = metadata.title ?? "Unknown Song";
      final safeTitle = _sanitizeFilename(songTitle);

      // MP3 File Path
      final localFilename = '$safeTitle.mp3';
      final savePath = '${storageDir.path}/$localFilename';

      // Download MP3
      await _dio.download(
        '/file/$downloadId/$serverFilename',
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress?.call(received / total);
          }
        },
      );

      // Validation
      final file = File(savePath);
      if (!await file.exists() || await file.length() == 0) {
        if (await file.exists()) await file.delete();
        throw Exception("Download failed (Empty file received).");
      }

      // --- NEW: Download Image for Offline Use ---
      String? localImagePath;
      if (metadata.thumbnailUrl != null && metadata.thumbnailUrl!.isNotEmpty) {
        try {
          final imageFilename = '$safeTitle.jpg';
          final imagePath = '${storageDir.path}/$imageFilename';

          await _dio.download(metadata.thumbnailUrl!, imagePath);
          localImagePath = imagePath; // Path save karo result mein
          debugPrint("✅ Image saved: $imagePath");
        } catch (e) {
          debugPrint("⚠️ Image download failed (Song downloaded): $e");
        }
      }

      // Cleanup
      try {
        await _dio.delete('/cleanup/$downloadId');
      } catch (_) {}

      onStageChange?.call(DownloadStage.completed);

      return DownloadResult(
        success: true,
        filePath: savePath,
        localImagePath: localImagePath, // ✅ Added here
        metadata: metadata,
      );
    } on DioException catch (e) {
      if (downloadId != null) {
        try {
          await _dio.delete('/cleanup/$downloadId');
        } catch (_) {}
      }
      onStageChange?.call(DownloadStage.failed);
      throw _handleDioError(e);
    } catch (e) {
      onStageChange?.call(DownloadStage.failed);
      rethrow;
    }
  }

  Exception _handleDioError(DioException e) {
    // ... same error handling logic ...
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timed out.');
    }
    return Exception(e.message ?? 'Network error.');
  }

  String _sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Get the direct download URL after server conversion (for background downloads)
  Future<BackgroundDownloadInfo> getBackgroundDownloadInfo(
    String youtubeUrl,
  ) async {
    try {
      final isOnline = await wakeUpServer();
      if (!isOnline) {
        throw Exception('Server is unavailable. Please try again.');
      }

      // Request conversion on server
      final convertResponse = await _dio.post(
        '/download',
        data: {'url': youtubeUrl, 'include_metadata': true},
        options: Options(receiveTimeout: const Duration(minutes: 10)),
      );

      if (convertResponse.statusCode != 200) {
        throw Exception('Conversion failed: ${convertResponse.statusMessage}');
      }

      final data = convertResponse.data;
      final downloadId = data['download_id'];
      final serverFilename = data['filename'];
      final metadata = DownloadMetadataModel.fromJson(data['metadata']);

      // Build download URL
      final downloadUrl = '$baseUrl/file/$downloadId/$serverFilename';

      // Create safe filename
      final songTitle = metadata.title ?? "Unknown Song";
      final safeTitle = _sanitizeFilename(songTitle);
      final localFilename = '$safeTitle.mp3';

      return BackgroundDownloadInfo(
        downloadUrl: downloadUrl,
        fileName: localFilename,
        downloadId: downloadId,
        metadata: metadata,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Cleanup server resources after download
  Future<void> cleanupDownload(String downloadId) async {
    try {
      await _dio.delete('/cleanup/$downloadId');
    } catch (_) {
      // Ignore cleanup errors
    }
  }
}

/// Info needed for background download
class BackgroundDownloadInfo {
  final String downloadUrl;
  final String fileName;
  final String downloadId;
  final DownloadMetadataModel metadata;

  BackgroundDownloadInfo({
    required this.downloadUrl,
    required this.fileName,
    required this.downloadId,
    required this.metadata,
  });
}

// --- UPDATED RESULT CLASS ---
class DownloadResult {
  final bool success;
  final String? filePath;
  final String? localImagePath; // ✅ New Field
  final DownloadMetadataModel? metadata;
  final String? errorMessage;

  DownloadResult({
    required this.success,
    this.filePath,
    this.localImagePath,
    this.metadata,
    this.errorMessage,
  });
}

enum DownloadStage {
  pending,
  fetchingMetadata,
  converting,
  downloading,
  completed,
  failed,
}
