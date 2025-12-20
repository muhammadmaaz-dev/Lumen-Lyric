import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/models/local_song_model.dart';

class SongsNotifier extends StateNotifier<List<LocalSongModel>> {
  SongsNotifier() : super([]) {
    // Initial load
    state = AudioController.instance.songs.value;

    // Listen to controller changes
    AudioController.instance.songs.addListener(() {
      state = AudioController.instance.songs.value;
    });
  }

  Future<void> deleteSong(int songId, String filePath) async {
    await AudioController.instance.deleteSong(songId, filePath);
  }
}

final songsProvider =
    StateNotifierProvider<SongsNotifier, List<LocalSongModel>>((ref) {
      return SongsNotifier();
    });
