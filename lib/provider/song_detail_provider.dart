import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:musicapp/services/youtube_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

// 1. STATE
class SongDetailState {
  final bool isLoading;
  final yt.Video? videoDetails; // Raw details save karenge

  SongDetailState({this.isLoading = true, this.videoDetails});

  SongDetailState copyWith({bool? isLoading, yt.Video? videoDetails}) {
    return SongDetailState(
      isLoading: isLoading ?? this.isLoading,
      videoDetails: videoDetails ?? this.videoDetails,
    );
  }
}

// 2. NOTIFIER
class SongDetailNotifier extends StateNotifier<SongDetailState> {
  final YoutubeService _youtubeService = YoutubeService();
  final String songId;

  SongDetailNotifier(this.songId) : super(SongDetailState()) {
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      yt.Video video = await _youtubeService.getVideoDetails(songId);
      if (mounted) {
        state = state.copyWith(isLoading: false, videoDetails: video);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }
}

// 3. PROVIDER
final songDetailProvider =
    StateNotifierProvider.family<SongDetailNotifier, SongDetailState, String>((
      ref,
      songId,
    ) {
      return SongDetailNotifier(songId);
    });
