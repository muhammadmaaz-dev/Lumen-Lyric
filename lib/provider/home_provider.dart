import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:musicapp/models/artist_model.dart';
import 'package:musicapp/models/song_model.dart';
import 'package:musicapp/services/youtube_service.dart';

// 1. STATE CLASS (Data ko hold karne ke liye)
class HomeState {
  final List<SongModel> trending;
  final List<SongModel> featured;
  final List<ArtistModel> artists;
  final bool isLoading;

  HomeState({
    this.trending = const [],
    this.featured = const [],
    this.artists = const [],
    this.isLoading = true,
  });

  // Data update karne ke liye helper function
  HomeState copyWith({
    List<SongModel>? trending,
    List<SongModel>? featured,
    List<ArtistModel>? artists,
    bool? isLoading,
  }) {
    return HomeState(
      trending: trending ?? this.trending,
      featured: featured ?? this.featured,
      artists: artists ?? this.artists,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// 2. NOTIFIER CLASS (Logic yahan likhenge)
class HomeNotifier extends StateNotifier<HomeState> {
  final YoutubeService _youtubeService = YoutubeService();

  HomeNotifier() : super(HomeState());

  // Search Keywords List
  final List<String> _searchKeywords = [
    "Global Top Music Hits 2024",
    "Latest Hindi Songs",
    "Punjabi Hits 2024",
    "Coke Studio Pakistan",
    "Lo-Fi Study Music",
    "Top Global Music Hits 2026",
    "Most Streamed Songs Worldwide",
    "Trending TikTok Songs 2026",
    "Spotify Viral Hits",
    "YouTube Music Top Charts",
    "Pasoori Song",
    "Coke Studio Pakistan Songs",
    "Latest Bollywood Songs 2026",
    "Punjabi Songs Chartbusters",
    "Hindi Pop Hits",
    "Hip Hop Hits India Pakistan",
    "Urdu Punjabi Rap Music",
    "Relaxing Lo-Fi Beats",
    "Study Music Playlist",
    "English Pop Hits 2026",
    "K-Pop Trending Tracks",
    "Best Playlist for Working Out",
    "Top R&B Songs",
    "Rock Classics Top Songs",
    "Indie Music Hits",
    "Spotify Top 50 India Pakistan",
    "Apple Music Top 100",
    "Worldwide Music Charts",
    "Global EDM Hits",
    "Atif Aslam Songs",
    "Arijit Singh Hits",
    "Talha Anjum Tracks",
    "Kaifi Khalil Songs",
    "Best Spotify Playlists 2026",
    "YouTube Music Hotlist 2026",
    "Apple Music Top Songs Global",
    "Shazam Top Chart Songs",
    "Music Search by Lyrics",
    "Most Hummed Songs Worldwide",
    "Best Hip Hop Songs",
    "Atif Aslam Best Songs",
    "Arijit Singh Hits",
    "English Pop Hits",
    "Viral TikTok Songs",
    "Relaxing Piano Music",
    "Rock Classics",
    "Urdu Rap",
    "90s Bollywood Hits",
    "Talha Anjum",
    "Anuv Jain",
  ];

  // Main Function: Data Fetch Karna
  Future<void> fetchHomeData() async {
    // LOGIC: Agar data pehle se hai, toh dubara load mat karo!
    if (state.trending.isNotEmpty && !state.isLoading) {
      return;
    }

    try {
      final random = Random();

      // Random Keywords pick karo
      String trendingQuery =
          _searchKeywords[random.nextInt(_searchKeywords.length)];
      String featuredQuery =
          _searchKeywords[random.nextInt(_searchKeywords.length)];

      // Ensure both queries are different
      while (featuredQuery == trendingQuery) {
        featuredQuery = _searchKeywords[random.nextInt(_searchKeywords.length)];
      }

      // API Calls
      final trending = await _youtubeService.searchSongs(trendingQuery);
      final discover = await _youtubeService.searchSongs(featuredQuery);

      trending.shuffle();
      discover.shuffle();

      // Artists Generate karo
      final artists = trending
          .map((song) {
            return ArtistModel(
              id: song.id,
              name: song.genre,
              songTitle: song.title,
              imageUrl: song.imageUrl,
            );
          })
          .toSet()
          .toList();

      // Distinct Artists Logic
      final distinctArtistsMap = <String, ArtistModel>{};
      for (var a in artists) {
        distinctArtistsMap[a.name] = a;
      }

      // State Update karo (Loading False)
      state = state.copyWith(
        trending: trending,
        featured: discover,
        artists: distinctArtistsMap.values.toList().take(6).toList(),
        isLoading: false,
      );
    } catch (e) {
      // Agar error aaye toh bas loading band kar do
      state = state.copyWith(isLoading: false);
    }
  }

  // Force Refresh (Pull-to-Refresh ke liye)
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true); // Loading shuru
    // Trending empty kar denge taake fetchHomeData dubara chal sake logic ke hisaab se
    // Ya direct logic likh sakte hain, but let's reset and fetch.
    state = HomeState(isLoading: true);
    await fetchHomeData();
  }
}

// 3. PROVIDER (Isko hum UI mein use karenge)
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});
