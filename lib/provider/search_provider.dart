import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musicapp/models/artist_model.dart';
import 'package:musicapp/models/song_model.dart';
import 'package:musicapp/services/youtube_service.dart';
import 'package:musicapp/provider/theme_provider.dart';

class SearchState {
  final bool isLoading;
  final List<String> suggestions;
  final List<SongModel> songs;
  final List<ArtistModel> artists;
  final List<String> history;

  SearchState({
    this.isLoading = false,
    this.suggestions = const [],
    this.songs = const [],
    this.artists = const [],
    this.history = const [],
  });

  SearchState copyWith({
    bool? isLoading,
    List<String>? suggestions,
    List<SongModel>? songs,
    List<ArtistModel>? artists,
    List<String>? history,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      suggestions: suggestions ?? this.suggestions,
      songs: songs ?? this.songs,
      artists: artists ?? this.artists,
      history: history ?? this.history,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final YoutubeService _youtubeService = YoutubeService();
  final SharedPreferences prefs;

  SearchNotifier(this.prefs) : super(SearchState()) {
    _loadHistory();
  }

  // --- ERROR FIX: Explicit Type Casting & Error Handling ---
  void _loadHistory() {
    try {
      final List<String>? storedHistory = prefs.getStringList('search_history');
      if (storedHistory != null) {
        state = state.copyWith(history: storedHistory);
      } else {
        state = state.copyWith(history: []);
      }
    } catch (e) {
      // Agar type mismatch ho to history clear kar do
      prefs.remove('search_history');
      state = state.copyWith(history: []);
    }
  }

  void _addToHistory(String query) {
    if (query.trim().isEmpty) return;
    List<String> history = List.from(state.history);

    history.remove(query);
    history.insert(0, query);

    if (history.length > 10) {
      history = history.sublist(0, 10);
    }

    prefs.setStringList('search_history', history);
    state = state.copyWith(history: history);
  }

  void removeFromHistory(String query) {
    List<String> history = List.from(state.history);
    history.remove(query);
    prefs.setStringList('search_history', history);
    state = state.copyWith(history: history);
  }

  void clearHistory() {
    prefs.remove('search_history');
    state = state.copyWith(history: []);
  }

  Future<void> fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(suggestions: []);
      return;
    }
    try {
      final results = await _youtubeService.getSearchSuggestions(query);
      state = state.copyWith(suggestions: results);
    } catch (e) {
      state = state.copyWith(suggestions: []);
    }
  }

  Future<void> search(String query) async {
    _addToHistory(query);
    state = state.copyWith(isLoading: true);

    try {
      final results = await _youtubeService.searchSongs(query);

      final Map<String, ArtistModel> artistMap = {};
      for (var song in results) {
        if (!artistMap.containsKey(song.genre)) {
          artistMap[song.genre] = ArtistModel(
            id: song.id,
            name: song.genre,
            songTitle: song.title,
            imageUrl: song.imageUrl,
          );
        }
      }

      state = state.copyWith(
        isLoading: false,
        songs: results,
        artists: artistMap.values.toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, songs: [], artists: []);
    }
  }

  void clearSuggestions() {
    state = state.copyWith(suggestions: []);
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SearchNotifier(prefs);
});
