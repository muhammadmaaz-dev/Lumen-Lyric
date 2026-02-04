import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/services/storage_path_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SONG CACHE SERVICE - FAST STARTUP WITH LAZY LOADING
/// ═══════════════════════════════════════════════════════════════════════════
///
/// PURPOSE: Enable instant app launch regardless of song count.
///
/// ARCHITECTURE:
/// 1. On startup, load from JSON cache (O(1) relative to song count)
/// 2. Show UI immediately with cached data
/// 3. Run full MediaStore scan in background
/// 4. Resolve metadata lazily when songs become visible
/// 5. Update cache periodically
///
/// CACHE STRUCTURE:
/// - Stores minimal song info: id, uri, title, artist, isDownloaded
/// - Does NOT store artwork (loaded on-demand)
/// - Does NOT resolve ID3 tags at cache time
/// ═══════════════════════════════════════════════════════════════════════════
class SongCacheService {
  static final SongCacheService instance = SongCacheService._internal();
  factory SongCacheService() => instance;
  SongCacheService._internal();

  static const String _cacheKey = 'song_cache_v2';
  static const String _cacheTimestampKey = 'song_cache_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 24);

  List<CachedSongEntry>? _memoryCache;
  bool _isLoading = false;

  /// Load songs from cache (fast, O(1))
  /// Returns null if cache is empty or expired
  Future<List<LocalSongModel>?> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check cache timestamp
      final timestampStr = prefs.getString(_cacheTimestampKey);
      if (timestampStr != null) {
        final timestamp = DateTime.tryParse(timestampStr);
        if (timestamp != null) {
          final age = DateTime.now().difference(timestamp);
          if (age > _cacheExpiry) {
            debugPrint('📦 [CACHE] Cache expired (${age.inHours}h old)');
            return null;
          }
        }
      }

      final cacheJson = prefs.getString(_cacheKey);
      if (cacheJson == null || cacheJson.isEmpty) {
        debugPrint('📦 [CACHE] No cache found');
        return null;
      }

      final List<dynamic> decoded = jsonDecode(cacheJson);
      _memoryCache = decoded
          .map((e) => CachedSongEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint('📦 [CACHE] Loaded ${_memoryCache!.length} songs from cache');

      // Convert to LocalSongModel with pending metadata flag
      return _memoryCache!.map((entry) => entry.toLocalSongModel()).toList();
    } catch (e) {
      debugPrint('⚠️ [CACHE] Error loading cache: $e');
      return null;
    }
  }

  /// Save songs to cache
  Future<void> saveToCache(List<LocalSongModel> songs) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final entries = songs
          .map((s) => CachedSongEntry.fromLocalSongModel(s))
          .toList();
      _memoryCache = entries;

      final json = jsonEncode(entries.map((e) => e.toJson()).toList());
      await prefs.setString(_cacheKey, json);
      await prefs.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );

      debugPrint('📦 [CACHE] Saved ${songs.length} songs to cache');
    } catch (e) {
      debugPrint('⚠️ [CACHE] Error saving cache: $e');
    }
  }

  /// Clear the cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      _memoryCache = null;
      debugPrint('📦 [CACHE] Cache cleared');
    } catch (e) {
      debugPrint('⚠️ [CACHE] Error clearing cache: $e');
    }
  }

  /// Check if we have a valid cache
  Future<bool> hasValidCache() async {
    if (_memoryCache != null && _memoryCache!.isNotEmpty) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final cacheJson = prefs.getString(_cacheKey);
    return cacheJson != null && cacheJson.isNotEmpty;
  }

  /// Invalidate cache when songs are added/removed
  void invalidateCache() {
    _memoryCache = null;
    debugPrint('📦 [CACHE] Cache invalidated');
  }
}

/// Minimal song entry for caching (lightweight, no artwork)
class CachedSongEntry {
  final int id;
  final String uri;
  final String title;
  final String artist;
  final int duration;
  final bool isDownloaded;
  final bool isLiked;

  /// Flag indicating metadata needs lazy resolution
  final bool needsMetadataResolution;

  CachedSongEntry({
    required this.id,
    required this.uri,
    required this.title,
    required this.artist,
    required this.duration,
    required this.isDownloaded,
    required this.isLiked,
    this.needsMetadataResolution = false,
  });

  factory CachedSongEntry.fromJson(Map<String, dynamic> json) {
    return CachedSongEntry(
      id: json['id'] as int,
      uri: json['uri'] as String,
      title: json['title'] as String? ?? 'Unknown Title',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      duration: json['duration'] as int? ?? 0,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      isLiked: json['isLiked'] as bool? ?? false,
      needsMetadataResolution: json['needsMeta'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uri': uri,
      'title': title,
      'artist': artist,
      'duration': duration,
      'isDownloaded': isDownloaded,
      'isLiked': isLiked,
      'needsMeta': needsMetadataResolution,
    };
  }

  factory CachedSongEntry.fromLocalSongModel(LocalSongModel model) {
    return CachedSongEntry(
      id: model.id,
      uri: model.uri,
      title: model.title,
      artist: model.artist,
      duration: model.duration,
      isDownloaded: model.isDownloaded,
      isLiked: model.isLiked,
      needsMetadataResolution: false, // Already resolved if in model
    );
  }

  LocalSongModel toLocalSongModel() {
    return LocalSongModel(
      id: id,
      title: title,
      artist: artist,
      uri: uri,
      albumArt: '',
      duration: duration,
      isDownloaded: isDownloaded,
      isLiked: isLiked,
      artworkUrl: null, // Artwork loaded on demand
    );
  }
}
