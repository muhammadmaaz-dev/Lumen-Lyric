import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musicapp/models/playlist_model.dart';

class PlaylistNotifier extends StateNotifier<List<PlaylistModel>> {
  static const String _storageKey = 'playlists_data';

  PlaylistNotifier() : super([]) {
    _loadPlaylists();
  }

  // Load playlists from SharedPreferences
  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        state = jsonList.map((json) => PlaylistModel.fromJson(json)).toList();
      }
    } catch (e) {
      // If there's an error loading, start with empty list
      state = [];
    }
  }

  // Save playlists to SharedPreferences
  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((playlist) => playlist.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      // Handle save error silently
    }
  }

  // Create a new playlist
  Future<PlaylistModel> createPlaylist(String name) async {
    final newPlaylist = PlaylistModel.create(name: name);
    state = [...state, newPlaylist];
    await _savePlaylists();
    return newPlaylist;
  }

  // Update playlist name
  Future<void> updatePlaylistName(String playlistId, String newName) async {
    state = state.map((playlist) {
      if (playlist.id == playlistId) {
        return playlist.copyWith(name: newName);
      }
      return playlist;
    }).toList();
    await _savePlaylists();
  }

  // Delete a playlist
  Future<void> deletePlaylist(String playlistId) async {
    state = state.where((playlist) => playlist.id != playlistId).toList();
    await _savePlaylists();
  }

  // Add a song to playlist
  Future<void> addSongToPlaylist(String playlistId, int songId) async {
    state = state.map((playlist) {
      if (playlist.id == playlistId) {
        // Don't add duplicates
        if (!playlist.songIds.contains(songId)) {
          return playlist.copyWith(songIds: [...playlist.songIds, songId]);
        }
      }
      return playlist;
    }).toList();
    await _savePlaylists();
  }

  // Add multiple songs to playlist
  Future<void> addSongsToPlaylist(String playlistId, List<int> songIds) async {
    state = state.map((playlist) {
      if (playlist.id == playlistId) {
        final existingSongIds = Set<int>.from(playlist.songIds);
        final newSongIds = songIds.where((id) => !existingSongIds.contains(id));
        return playlist.copyWith(songIds: [...playlist.songIds, ...newSongIds]);
      }
      return playlist;
    }).toList();
    await _savePlaylists();
  }

  // Remove a song from playlist
  Future<void> removeSongFromPlaylist(String playlistId, int songId) async {
    state = state.map((playlist) {
      if (playlist.id == playlistId) {
        return playlist.copyWith(
          songIds: playlist.songIds.where((id) => id != songId).toList(),
        );
      }
      return playlist;
    }).toList();
    await _savePlaylists();
  }

  // Get playlist by ID
  PlaylistModel? getPlaylistById(String playlistId) {
    try {
      return state.firstWhere((playlist) => playlist.id == playlistId);
    } catch (e) {
      return null;
    }
  }
}

// Main playlist provider
final playlistProvider =
    StateNotifierProvider<PlaylistNotifier, List<PlaylistModel>>((ref) {
      return PlaylistNotifier();
    });

// Provider to get a specific playlist by ID
final playlistByIdProvider = Provider.family<PlaylistModel?, String>((ref, id) {
  final playlists = ref.watch(playlistProvider);
  // Use where + firstOrNull pattern to avoid exception when playlist is deleted
  final matches = playlists.where((playlist) => playlist.id == id);
  return matches.isEmpty ? null : matches.first;
});
