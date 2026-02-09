// lib/services/youtube_service.dart
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:musicapp/models/song_model.dart';

class YoutubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<List<SongModel>> searchSongs(String query) async {
    try {
      var searchList = await _yt.search.search(query);

      return searchList.map((video) {
        return SongModel(
          id: video.id.value,
          title: video.title,
          genre: video.author,
          imageUrl: video.thumbnails.highResUrl,
        );
      }).toList();
    } catch (e) {
      throw Exception("Search error: $e");
    }
  }

  Future<Video> getVideoDetails(String videoId) async {
    try {
      return await _yt.videos.get(VideoId(videoId));
    } catch (e) {
      throw Exception("Error fetching video details: $e");
    }
  }

  Future<String> getAudioStreamUrl(String videoId) async {
    try {
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      var audioInfo = manifest.audioOnly;

      var streamInfo = audioInfo.firstWhere(
        (s) => s.container.name == 'mp4',
        orElse: () => audioInfo.withHighestBitrate(),
      );

      return streamInfo.url.toString();
    } catch (e) {
      throw Exception("Error fetching audio stream: $e");
    }
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      var suggestions = await _yt.search.getQuerySuggestions(query);
      return suggestions ?? <String>[];
    } catch (e) {
      return <String>[];
    }
  }

  void dispose() {
    _yt.close();
  }
}
