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
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(minutes: 10),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  /// Check if API is online (with wake-up retry)
  Future<bool> isApiOnline() async {
    try {
      final response = await _dio.get(
        '/',
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('❌ API Health Check Failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ API Health Check Error: $e');
      return false;
    }
  }

  /// Wake up the Hugging Face Space (they sleep after inactivity)
  Future<bool> wakeUpServer() async {
    debugPrint('🔄 Waking up Hugging Face Space...');

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint('   Attempt $attempt/3...');
        final response = await _dio.get(
          '/',
          options: Options(receiveTimeout: const Duration(seconds: 45)),
        );

        if (response.statusCode == 200) {
          debugPrint('✅ Server is awake!');
          return true;
        }
      } on DioException catch (e) {
        debugPrint('   Attempt $attempt failed: ${e.message}');
        if (attempt < 3) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }

    debugPrint('❌ Failed to wake up server after 3 attempts');
    return false;
  }

  /// Validate YouTube URL
  bool isValidYoutubeUrl(String url) {
    final youtubeRegex = RegExp(
      r'^(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/|youtube\.com/shorts/)[\w-]+',
      caseSensitive: false,
    );
    return youtubeRegex.hasMatch(url);
  }

  /// Get metadata for a YouTube URL without downloading
  Future<DownloadMetadataModel> getMetadata(String youtubeUrl) async {
    try {
      // First, try to wake up the server
      final isOnline = await wakeUpServer();
      if (!isOnline) {
        throw Exception(
          'Server is unavailable. Please try again in a few seconds.',
        );
      }

      debugPrint('📡 Fetching metadata for: $youtubeUrl');

      final response = await _dio.post(
        '/metadata',
        data: {'url': youtubeUrl},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Metadata received successfully');
        return DownloadMetadataModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get metadata: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      debugPrint('❌ DioException: ${e.type} - ${e.message}');
      throw _handleDioError(e);
    } on SocketException catch (e) {
      debugPrint('❌ SocketException: $e');
      throw Exception('Network error. Please check your internet connection.');
    } on TimeoutException catch (e) {
      debugPrint('❌ TimeoutException: $e');
      throw Exception(
        'Request timed out. The server may be starting up, please try again.',
      );
    } catch (e) {
      debugPrint('❌ Unknown error: $e');
      rethrow;
    }
  }

  /// Download audio and save to device
  Future<DownloadResult> downloadAudio(
    String youtubeUrl, {
    bool includeMetadata = true,
    Function(DownloadStage stage)? onStageChange,
    Function(double progress)? onProgress,
  }) async {
    String? downloadId;

    try {
      final isOnline = await wakeUpServer();
      if (!isOnline) {
        throw Exception('Server is unavailable. Please try again.');
      }

      // Stage 1: Request conversion
      onStageChange?.call(DownloadStage.converting);
      debugPrint('🔄 Starting conversion...');

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

      // ✅ Server ab "audio.mp3" bhejega, isay download URL ke liye use karein
      final serverFilename = data['filename'];

      final metadata = DownloadMetadataModel.fromJson(data['metadata']);

      debugPrint('✅ Conversion complete on server');

      // Stage 2: Download the MP3
      onStageChange?.call(DownloadStage.downloading);
      debugPrint('📥 Downloading MP3...');

      // Path setup
      Directory? musicDir;
      if (Platform.isAndroid) {
        musicDir = Directory('/storage/emulated/0/Music/LumenLyric');
      } else {
        final dir = await getApplicationDocumentsDirectory();
        musicDir = Directory('${dir.path}/LumenLyric');
      }

      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      // ✅ FIX: Use metadata.title for local filename (User friendly name)
      final songTitle = metadata.title ?? "Unknown Song";
      final safeTitle = _sanitizeFilename(songTitle);
      final localFilename = '$safeTitle.mp3';

      final savePath = '${musicDir.path}/$localFilename';

      // Download from server (using ID + audio.mp3) -> Save to Local (using Song Title.mp3)
      await _dio.download(
        '/file/$downloadId/$serverFilename',
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress?.call(progress);
            debugPrint('   Download: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
      );

      debugPrint('✅ Download saved to: $savePath');

      // Stage 3: Cleanup
      try {
        await _dio.delete('/cleanup/$downloadId');
      } catch (e) {
        debugPrint('⚠️ Cleanup warning: $e');
      }

      onStageChange?.call(DownloadStage.completed);

      return DownloadResult(
        success: true,
        filePath: savePath,
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

  /// Handle Dio errors with user-friendly messages
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timed out. The server may be waking up, please try again in 30 seconds.',
        );
      case DioExceptionType.connectionError:
        return Exception(
          'Cannot connect to server. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final detail = e.response?.data?['detail'];
        return Exception(
          detail ?? 'Server error ($statusCode). Please try again.',
        );
      case DioExceptionType.cancel:
        return Exception('Request was cancelled.');
      default:
        return Exception('Network error: ${e.message}');
    }
  }

  String _sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class DownloadResult {
  final bool success;
  final String? filePath;
  final DownloadMetadataModel? metadata;
  final String? errorMessage;

  DownloadResult({
    required this.success,
    this.filePath,
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
