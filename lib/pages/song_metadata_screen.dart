import 'package:flutter/material.dart';
import 'package:musicapp/services/youtube_service.dart'; // Ensure path is correct
import 'package:musicapp/widgets/song_metadata_skelton.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

class SongMetadataScreen extends StatefulWidget {
  // Hum sirf basic info lenge, baaki khud fetch karenge
  final String songId;
  final String imageUrl;
  final String title;
  final String artist;

  const SongMetadataScreen({
    Key? key,
    required this.songId,
    required this.imageUrl,
    required this.title,
    required this.artist,
  }) : super(key: key);

  @override
  State<SongMetadataScreen> createState() => _SongMetadataScreenState();
}

class _SongMetadataScreenState extends State<SongMetadataScreen> {
  final YoutubeService _youtubeService = YoutubeService();

  // Variables to hold fetched data
  bool _isLoading = true;
  String _album = '---';
  String _year = '---';
  String _duration = '--:--';
  String _genre = 'Music';
  bool _explicit = false;
  String _views = '---';
  String _likes = '---';
  String _label = 'YouTube';
  String _url = '';

  @override
  void initState() {
    super.initState();
    _fetchFullDetails();
  }

  // --- Link Open Karne Ka Function ---
  Future<void> _launchYoutubeUrl() async {
    if (_url.isEmpty) return;

    final Uri uri = Uri.parse(_url);

    try {
      // mode: LaunchMode.externalApplication ka matlab hai ke
      // ye koshish karega YouTube app kholne ki, warna browser mein kholega.
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $_url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Could not open link: $e")));
      }
    }
  }

  Future<void> _fetchFullDetails() async {
    try {
      // Data fetch ho raha hai...
      yt.Video videoDetails = await _youtubeService.getVideoDetails(
        widget.songId,
      );

      if (mounted) {
        setState(() {
          _album = 'YouTube Music';
          _year = videoDetails.uploadDate?.year.toString() ?? '2024';
          _duration = _formatDuration(videoDetails.duration);
          _genre =
              'Music'; // YouTube API se exact genre mushkil hai, default rakha
          _explicit = false;
          _views = _formatCount(videoDetails.engagement.viewCount);
          _likes = _formatCount(videoDetails.engagement.likeCount);
          _label = videoDetails.author; // Using Author as Label mostly
          _url = videoDetails.url;
          _isLoading = false; // Loading Khatam!
        });
      }
    } catch (e) {
      debugPrint("Error fetching metadata: $e");
      if (mounted) {
        setState(
          () => _isLoading = false,
        ); // Error ke baad bhi content dikha dein (purana wala ya empty)
      }
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "--:--";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inMinutes}:$twoDigitSeconds";
  }

  String _formatCount(int? count) {
    if (count == null) return "0";
    if (count >= 1000000) {
      return "${(count / 1000000).toStringAsFixed(1)}M";
    } else if (count >= 1000) {
      return "${(count / 1000).toStringAsFixed(1)}K";
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Agar loading hai to Skeleton dikhao
    if (_isLoading) {
      return const SongMetadataSkeleton();
    }

    // Loading khatam, asli UI dikhao
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Album Art
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(widget.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              // Song Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.artist,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                _album, // Fetched Data
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              // Metadata Grid
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metaItem('YEAR', _year),
                        _metaItem('DURATION', _duration),
                        _metaItem('GENRE', _genre, highlight: true),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metaItem('EXPLICIT', _explicit ? 'E' : '', box: true),
                        _metaItem('VIEWS', _views),
                        _metaItem('LIKES', _likes),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [_metaItem('LABEL', _label, wide: true)],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          // Open URL
                          _launchYoutubeUrl();
                        },
                        child: const Text(
                          'OPEN URL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.download,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaItem(
    String label,
    String value, {
    bool highlight = false,
    bool box = false,
    bool wide = false,
  }) {
    return Container(
      width: wide ? 180 : 90,
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              color: Colors.white54,
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          box
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    color: highlight ? Colors.white : Colors.white70,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                    fontSize: highlight ? 16 : 15,
                  ),
                ),
        ],
      ),
    );
  }
}
