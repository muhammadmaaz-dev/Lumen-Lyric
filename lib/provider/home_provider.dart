import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  final bool isOffline;

  HomeState({
    this.trending = const [],
    this.featured = const [],
    this.artists = const [],
    this.isLoading = true,
    this.isOffline = false,
  });

  // Data update karne ke liye helper function
  HomeState copyWith({
    List<SongModel>? trending,
    List<SongModel>? featured,
    List<ArtistModel>? artists,
    bool? isLoading,
    bool? isOffline,
  }) {
    return HomeState(
      trending: trending ?? this.trending,
      featured: featured ?? this.featured,
      artists: artists ?? this.artists,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

// 2. NOTIFIER CLASS (Logic yahan likhenge)
class HomeNotifier extends StateNotifier<HomeState> {
  final YoutubeService _youtubeService = YoutubeService();

  HomeNotifier() : super(HomeState());

  // Search Keywords List
  final List<String> _searchKeywords = [
    "Atif Aslam",
    "Rahat Fateh Ali Khan",
    "Ali Zafar",
    "Asim Azhar",
    "Aima Baig",
    "Momina Mustehsan",
    "Bilal Saeed",
    "Hasan Raheem",
    "Young Stunners",
    "Ali Azmat",
    "Ali Haider",
    "Aamir Saleem",
    "Abrar-ul-Haq",
    "Ahmed Jahanzeb",
    "Annie Khalid",
    "Arshad Mehmood",
    "Mustafa Zahid",
    "Arijit Singh",
    "Neha Kakkar",
    "Armaan Malik",
    "Shreya Ghoshal",
    "Jubin Nautiyal",
    "Sunidhi Chauhan",
    "Darshan Raval",
    "Badshah",
    "Guru Randhawa",
    "Aditiya Rikhari",
    "Bayaan",
    "A.R. Rahman",
    "Coke Studio Pakistan",
    "Talwiinder",
    "Coke Studio India",
    "T-Series",
    "Taimour Baig",
    "UR DEBUT",
    "Aleemrk",
    "Zee Music Company",
    "Tips Official",
    "Sony Music India",
    "Saregama Music",
    "Nehal Naseem",
    "Ishtar Music",
    "Speed Records",
    "Wave Music",
    "Anuv Jain",
    "Talha Anjum",
    "Annural Khalid Songs",
    "TOSHO Official",
    "Young Stunners",
    "Jokhay",
    "Umair",
    "Ap Dhillion",
    "Abdul Hanan",
    "Mitraz",
  ];

  // Main Function: Data Fetch Karna
  Future<void> fetchHomeData() async {
    // 1. Connectivity Check (Safeguarded)
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        state = state.copyWith(isLoading: false, isOffline: true);
        return;
      }
    } catch (e) {
      // Proceed to fetch if check fails
    }

    if (state.trending.isNotEmpty && !state.isLoading) return;

    state = state.copyWith(isLoading: true, isOffline: false);

    try {
      final random = Random();
      String trendingQuery =
          _searchKeywords[random.nextInt(_searchKeywords.length)];
      String featuredQuery =
          _searchKeywords[random.nextInt(_searchKeywords.length)];

      while (featuredQuery == trendingQuery) {
        featuredQuery = _searchKeywords[random.nextInt(_searchKeywords.length)];
      }

      // CHANGE: Future.wait use kiya parallel loading ke liye. Added timeout.
      final results = await Future.wait([
        _youtubeService.searchSongs(trendingQuery),
        _youtubeService.searchSongs(featuredQuery),
      ]).timeout(const Duration(seconds: 15));

      final trending = results[0]; // Pehla result
      final discover = results[1]; // Doosra result

      trending.shuffle();
      discover.shuffle();

      final artists = trending
          .map((song) {
            return ArtistModel(
              id: song.id,
              name: song
                  .genre, // Note: Ensure genre holds the artist name correctly
              songTitle: song.title,
              imageUrl: song.imageUrl,
            );
          })
          .toSet()
          .toList();

      final distinctArtistsMap = <String, ArtistModel>{};
      for (var a in artists) {
        distinctArtistsMap[a.name] = a;
      }

      state = state.copyWith(
        trending: trending,
        featured: discover,
        artists: distinctArtistsMap.values.toList().take(6).toList(),
        isLoading: false,
      );
    } catch (e) {
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
