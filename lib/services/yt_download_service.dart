import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:musicapp/models/download_metadata_model.dart';
import 'package:musicapp/services/storage_path_service.dart';

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

  Future<bool> wakeUpServer() async {
    for (int attempt = 1; attempt <= 5; attempt++) {
      try {
        final response = await _dio.get(
          '/',
          options: Options(
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 30),
          ),
        );
        if (response.statusCode == 200) {
          return true;
        }
      } catch (e) {
        if (attempt < 5) {
          await Future.delayed(const Duration(seconds: 3));
        }
      }
    }
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
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (convertResponse.statusCode != 200) {
        String errorMsg = 'Conversion failed';
        final responseData = convertResponse.data;
        if (responseData is Map) {
          errorMsg =
              responseData['error'] ??
              responseData['message'] ??
              responseData['detail'] ??
              errorMsg;
        } else if (responseData is String && responseData.isNotEmpty) {
          errorMsg = responseData;
        }
        throw Exception(errorMsg);
      }

      final data = convertResponse.data;
      downloadId = data['download_id'];
      final serverFilename = data['filename'];
      final metadata = DownloadMetadataModel.fromJson(data['metadata']);

      // Stage 2: Download
      onStageChange?.call(DownloadStage.downloading);

      final storagePaths = StoragePathService.instance;
      await storagePaths.initialize();
      final songsDir = await storagePaths.songsPath;

      final songTitle = metadata.title ?? "Unknown Song";
      final safeTitle = _sanitizeFilename(songTitle);

      // MP3 File Path
      final localFilename = '$safeTitle.mp3';
      final savePath = '$songsDir/$localFilename';

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

      String? localImagePath;
      if (metadata.thumbnailUrl != null && metadata.thumbnailUrl!.isNotEmpty) {
        try {
          final artworkDir = await storagePaths.artworkPath;
          final imageFilename = '$safeTitle.jpg';
          final imagePath = '$artworkDir/$imageFilename';

          await _dio.download(metadata.thumbnailUrl!, imagePath);
          localImagePath = imagePath;
        } catch (e) {
          // Image download failed
        }
      }
      double durationSeconds = 0.0;
      if (metadata.duration != null) {
        durationSeconds = double.tryParse(metadata.duration.toString()) ?? 0.0;
      }

      await _fetchAndSaveLyrics(songTitle, savePath, durationSeconds);

      // Cleanup Server File
      try {
        await _dio.delete('/cleanup/$downloadId');
      } catch (_) {}

      // Stage: Completed (Sirf ek baar call karo)
      onStageChange?.call(DownloadStage.completed);

      return DownloadResult(
        success: true,
        filePath: savePath,
        localImagePath: localImagePath,
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
    // Extract server error message if available
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      // Try to get error message from response body
      String? serverMessage;
      if (responseData is Map) {
        serverMessage =
            responseData['error'] ??
            responseData['message'] ??
            responseData['detail'];
      } else if (responseData is String && responseData.isNotEmpty) {
        serverMessage = responseData;
      }

      if (statusCode == 400) {
        return Exception(
          serverMessage ?? 'Invalid YouTube URL or video unavailable',
        );
      } else if (statusCode == 404) {
        return Exception(serverMessage ?? 'Video not found');
      } else if (statusCode == 429) {
        return Exception('Too many requests. Please wait a moment.');
      } else if (statusCode == 500) {
        return Exception(serverMessage ?? 'Server error. Try again later.');
      } else if (statusCode == 503) {
        return Exception('Server is busy. Please try again.');
      }

      if (serverMessage != null) {
        return Exception(serverMessage);
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timed out. Please try again.');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception('No internet connection.');
    }
    return Exception(e.message ?? 'Network error. Please try again.');
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
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (convertResponse.statusCode != 200) {
        // Extract error message from response
        String errorMsg = 'Conversion failed';
        final responseData = convertResponse.data;
        if (responseData is Map) {
          errorMsg =
              responseData['error'] ??
              responseData['message'] ??
              responseData['detail'] ??
              errorMsg;
        } else if (responseData is String && responseData.isNotEmpty) {
          errorMsg = responseData;
        }
        throw Exception(errorMsg);
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

  Future<void> _fetchAndSaveLyrics(
    String rawTitle,
    String savePath,
    double durationSeconds,
  ) async {
    try {
      String cleanTitle = rawTitle
          .replaceAll(RegExp(r"\(.*?\)|\[.*?\]"), "")
          .replaceAll(RegExp(r"[^a-zA-Z0-9\s]"), "")
          .replaceAll(RegExp(r"\s+"), " ")
          .trim();

      final url = Uri.parse('https://lrclib.net/api/search?q=$cleanTitle');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          var bestMatch = data.firstWhere((track) {
            final trackDuration = track['duration'];
            return (trackDuration - durationSeconds).abs() < 5;
          }, orElse: () => data.first);

          String? finalLyrics =
              bestMatch['syncedLyrics'] ?? bestMatch['plainLyrics'];

          if (finalLyrics != null && finalLyrics.isNotEmpty) {
            final lrcPath = savePath.replaceAll('.mp3', '.lrc');
            final file = File(lrcPath);
            await file.writeAsString(finalLyrics);
          }
        }
      }
    } catch (e) {
      // Lyrics fetch failed
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
