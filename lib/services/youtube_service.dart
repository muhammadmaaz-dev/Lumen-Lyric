// lib/services/youtube_service.dart
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:musicapp/models/song_model.dart';

class YoutubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  // 1. YouTube par songs search karna
  Future<List<SongModel>> searchSongs(String query) async {
    try {
      var searchList = await _yt.search.search(query);

      // Results ko aapke SongModel mein convert kar rahe hain
      return searchList.map((video) {
        return SongModel(
          id: video.id.value,
          title: video.title,
          genre:
              video.author, // Artist ka naam genre ki jagah use kar rahe hain
          imageUrl: video.thumbnails.highResUrl,
        );
      }).toList();
    } catch (e) {
      throw Exception("Search error: $e");
    }
  }

  // 2. Full Video Details fetch karna (Metadata Screen ke liye)
  Future<Video> getVideoDetails(String videoId) async {
    try {
      return await _yt.videos.get(VideoId(videoId));
    } catch (e) {
      throw Exception("Error fetching video details: $e");
    }
  }

  // 3. Audio Stream URL nikalna (High Quality)
  Future<String> getAudioStreamUrl(String videoId) async {
    try {
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      var audioInfo = manifest.audioOnly;

      // Pehle koshish karein ke MP4 (m4a) format mile jo ziada compatible hai
      var streamInfo = audioInfo.firstWhere(
        (s) => s.container.name == 'mp4',
        orElse: () => audioInfo
            .withHighestBitrate(), // Agar mp4 na mile to high quality utha le
      );

      return streamInfo.url.toString();
    } catch (e) {
      throw Exception("Error fetching audio stream: $e");
    }
  }

  // Dispose method if needed
  void dispose() {
    _yt.close();
  }
}
