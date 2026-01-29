// lib/provider/search_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:musicapp/models/song_model.dart';
import 'package:musicapp/services/youtube_service.dart';

final youtubeServiceProvider = Provider((ref) => YoutubeService());

// User jo search karega wo yahan save hoga
final searchQueryProvider = StateProvider<String>((ref) => '');

// Ye future provider automatically search run karega jab query change hogi
final searchResultsProvider = FutureProvider.autoDispose<List<SongModel>>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);
  final youtubeService = ref.watch(youtubeServiceProvider);

  if (query.isEmpty) return [];

  return await youtubeService.searchSongs(query);
});
