import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicapp/controller/download_controller.dart';
import 'package:musicapp/models/download_metadata_model.dart';
import 'package:musicapp/utils/extensions.dart';

// ✅ 1. Controller Instance Provider
final downloadControllerProvider = Provider<DownloadController>((ref) {
  return DownloadController.instance;
});

// ✅ 2. Download Queue Provider (reactive)
final downloadQueueProvider = StreamProvider<List<DownloadTaskModel>>((ref) {
  final controller = ref.watch(downloadControllerProvider);
  return controller.downloadQueue.asBroadcastStream;
});

// ✅ 3. Recent Downloads Provider (reactive)
final recentDownloadsProvider = StreamProvider<List<DownloadTaskModel>>((ref) {
  final controller = ref.watch(downloadControllerProvider);
  return controller.recentDownloads.asBroadcastStream;
});

// ✅ 4. Is Processing Provider
final isDownloadingProvider = StreamProvider<bool>((ref) {
  final controller = ref.watch(downloadControllerProvider);
  return controller.isProcessing.asBroadcastStream;
});
