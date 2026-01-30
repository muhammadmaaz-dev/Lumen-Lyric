import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:musicapp/controller/download_controller.dart';
import 'package:musicapp/models/download_metadata_model.dart';

// 1. Controller Provider (Singleton Access)
final downloadControllerProvider = Provider<DownloadController>((ref) {
  return DownloadController.instance;
});

// 2. Queue Provider (Bridge: ValueNotifier -> Riverpod State)
final downloadQueueProvider =
    StateNotifierProvider<DownloadQueueNotifier, List<DownloadTaskModel>>((
      ref,
    ) {
      return DownloadQueueNotifier();
    });

// Yeh class Controller ki ValueNotifier ko sunta hai aur Riverpod state update karta hai
class DownloadQueueNotifier extends StateNotifier<List<DownloadTaskModel>> {
  DownloadQueueNotifier() : super([]) {
    // Initial Load
    state = DownloadController.instance.downloadQueue.value;

    // Listener attach karo
    DownloadController.instance.downloadQueue.addListener(() {
      state = DownloadController.instance.downloadQueue.value;
    });
  }
}

// 3. Specific Task Provider (UI mein kisi specific song ka status dekhne ke liye)
// Hum URL match karke check karenge ke ye song queue mein hai ya nahi
final downloadTaskByUrlProvider = Provider.family<DownloadTaskModel?, String>((
  ref,
  url,
) {
  final queue = ref.watch(downloadQueueProvider);
  try {
    // Find task with matching URL
    return queue.firstWhere((task) => task.youtubeUrl == url);
  } catch (e) {
    return null; // Agar queue mein nahi hai
  }
});
