import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musicapp/controller/audio_controller.dart'; // Apne controller ka path check kr lena
import 'package:musicapp/utils/extensions.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/models/progressbar_model.dart';

// 1. Controller ka instance access karne ke liye
final audioControllerProvider = Provider((ref) => AudioController.instance);

// 2. Current Song Provider (ValueListenable ko convert kiya)
final currentSongProvider = StreamProvider<LocalSongModel?>((ref) {
  final controller = ref.watch(audioControllerProvider);
  // Assuming 'currentIndex' change hone par song update hota hai
  return controller.currentIndex.asBroadcastStream.map(
    (_) => controller.currentsong,
  );
  // Note: Agar tumhara controller direct song ka stream deta hai to wo use kro.
  // Filhal simplify krne ke liye hum ye maan rahe hain ke tumhara UI rebuild hoga.
});

// 3. Play/Pause State Provider
final isPlayingProvider = StreamProvider<bool>((ref) {
  final controller = ref.watch(audioControllerProvider);
  return controller
      .isPlaying
      .asBroadcastStream; // ValueNotifier ko stream mein badla
});

// 4. Position/Duration Stream (Seekbar ke liye)
final positionProvider = StreamProvider<Duration>((ref) {
  final controller = ref.watch(audioControllerProvider);
  return controller.audioPlayer.positionStream;
});

// 5. Lyrics Provider
final lyricsProvider = StreamProvider<String>((ref) {
  final controller = ref.watch(audioControllerProvider);
  return controller.currentLyrics.asBroadcastStream;
});

// Purane providers ke sath hi add kar do
final progressProvider = StreamProvider<ProgressBarState>((ref) {
  final controller = ref.watch(audioControllerProvider);

  // Position stream ko map kar rahe hain ProgressBarState mein
  return controller.audioPlayer.positionStream.map((position) {
    return ProgressBarState(
      current: position,
      // Duration hum direct player se utha rahe hain kyunki ye baar baar change nahi hoti
      total: controller.audioPlayer.duration ?? Duration.zero,
    );
  });
});
