import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesNotifier extends StateNotifier<List<int>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  // Key for storage
  static const _key = 'liked_songs_ids';

  // 1. App start hote hi saved songs load karna
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? savedList = prefs.getStringList(_key);

      if (savedList != null) {
        // String list ko wapas int list mein convert kar ke state update karo
        state = savedList.map((id) => int.parse(id)).toList();
      }
    } catch (e) {
      // Error loading favorites
    }
  }

  // 2. Favorite toggle karna aur save karna
  Future<void> toggleFavorite(int songId) async {
    final prefs = await SharedPreferences.getInstance();

    if (state.contains(songId)) {
      // Remove song
      state = state.where((id) => id != songId).toList();
    } else {
      // Add song
      state = [...state, songId];
    }

    // State update hone ke baad permanent save karo
    // List<int> ko List<String> mein convert karna padta hai storage ke liye
    final listToSave = state.map((e) => e.toString()).toList();
    await prefs.setStringList(_key, listToSave);
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<int>>((
  ref,
) {
  return FavoritesNotifier();
});
