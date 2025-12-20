import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class FavoritesNotifier extends StateNotifier<List<int>> {
  FavoritesNotifier() : super([]);

  void toggleFavorite(int songId) {
    if (state.contains(songId)) {
      state = state.where((id) => id != songId).toList();
    } else {
      state = [...state, songId];
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<int>>((
  ref,
) {
  return FavoritesNotifier();
});
