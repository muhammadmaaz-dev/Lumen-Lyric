import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifierProvider, StateNotifier;
import 'package:musicapp/models/song_model.dart';
import 'package:musicapp/services/youtube_service.dart';

// 1. STATE: Data hold karne ke liye
class ArtistState {
  final bool isLoading;
  final List<SongModel> songs;

  ArtistState({this.isLoading = true, this.songs = const []});

  ArtistState copyWith({bool? isLoading, List<SongModel>? songs}) {
    return ArtistState(
      isLoading: isLoading ?? this.isLoading,
      songs: songs ?? this.songs,
    );
  }
}

// 2. NOTIFIER: Logic handle karne ke liye
class ArtistNotifier extends StateNotifier<ArtistState> {
  final YoutubeService _youtubeService = YoutubeService();
  final String artistName;

  // Constructor mein hi fetch call kar diya
  ArtistNotifier(this.artistName) : super(ArtistState()) {
    _fetchArtistSongs();
  }

  Future<void> _fetchArtistSongs() async {
    try {
      final songs = await _youtubeService.searchSongs(artistName);
      if (mounted) {
        state = state.copyWith(isLoading: false, songs: songs);
      }
    } catch (e) {
      // Error handling
      if (mounted) {
        state = state.copyWith(isLoading: false, songs: []);
      }
    }
  }
}

// 3. PROVIDER: .family use kiya taake unique artist name ke liye alag state bane
// autoDispose mat lagana, warna back karne par data udd jayega
final artistProvider =
    StateNotifierProvider.family<ArtistNotifier, ArtistState, String>((
      ref,
      artistName,
    ) {
      return ArtistNotifier(artistName);
    });
