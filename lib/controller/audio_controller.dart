import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AudioController {
  static final AudioController instance = AudioController._instance();
  factory AudioController() => instance;
  AudioController._instance() {
    _setupAudioPlayer();
  }
  final AudioPlayer audioPlayer = AudioPlayer();
  final OnAudioQuery audioQuery = OnAudioQuery();
  final ValueNotifier<List<LocalSongModel>> songs =
      ValueNotifier<List<LocalSongModel>>([]);

  final ValueNotifier<int> currentIndex = ValueNotifier<int>(-1);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);

  LocalSongModel? get currentsong =>
      currentIndex.value != -1 && currentIndex.value < songs.value.length
      ? songs.value[currentIndex.value]
      : null;

  //function for _setupAudioPlayer()
  void _setupAudioPlayer() {
    //listen to player state change
    audioPlayer.playerStateStream.listen((playerState) {
      isPlaying.value = playerState.playing;

      //autoplay next song when current song end
      if (playerState.processingState == ProcessingState.completed) {
        if (currentIndex.value < songs.value.length - 1) {
          //here we play song
          playSong(currentIndex.value + 1);
        } else {
          currentIndex.value = -1;
          isPlaying.value = false;
        }
      }
    });

    // listen to position change
    audioPlayer.positionStream.listen((_) {
      //this update the ui for progress bar
    });
  }

  //funtion to loadsongs
  Future<void> loadSongs() async {
    // Request permission
    bool hasPermission = await audioQuery.permissionsStatus();
    if (!hasPermission) {
      hasPermission = await audioQuery.permissionsRequest();
    }

    if (!hasPermission) {
      debugPrint("Permission denied");
      return;
    }

    final fetchSongs = await audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    songs.value = fetchSongs
        .map(
          (songs) => LocalSongModel(
            id: songs.id,
            artist: songs.artist ?? "Unknown Artist",
            title: songs.title,
            uri: songs.uri ?? "",
            albumArt: songs.album ?? "",
            duration: songs.duration ?? 0,
          ),
        )
        .toList();
  }

  //ffunction to play song
  Future<void> playSong(int index) async {
    if (index < 0 || index >= songs.value.length) return;

    try {
      if (currentIndex.value == index && isPlaying.value) {
        await pauseSong();
        return;
      }
      currentIndex.value = index;
      final song = songs.value[index];
      await audioPlayer.stop();
      await audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(song.uri)),
        preload: true,
      );
      await audioPlayer.play();
      isPlaying.value = true;
    } catch (e) {
      print("Error While Playing Song : $e");
    }
  }

  //function to pause song
  Future<void> pauseSong() async {
    await audioPlayer.pause();
    isPlaying.value = false;
  }

  //function to resume song
  Future<void> resumeSong() async {
    await audioPlayer.play();
    isPlaying.value = true;
  }

  //fuction to toogle play - pause
  void tooglePlayPause() async {
    if (currentIndex.value == -1) return;

    try {
      if (isPlaying.value) {
        await pauseSong();
      } else {
        await resumeSong();
      }
    } catch (e) {
      print("Erro toogling Play and Pause: $e");
    }
  }

  //function for next song
  Future<void> nextSong() async {
    if (currentIndex.value < songs.value.length - 1) {
      await playSong(currentIndex.value + 1);
    }
  }

  //function for previous song
  Future<void> previousSong() async {
    if (currentIndex.value > 0) {
      await playSong(currentIndex.value - 1);
    }
  }

  //function to dispose
  void dispose() {
    audioPlayer.dispose();
  }
}
