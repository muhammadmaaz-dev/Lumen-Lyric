import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicapp/widgets/song_metadata_skelton.dart';
import 'package:musicapp/provider/song_detail_provider.dart';
import 'package:musicapp/provider/download_provider.dart'; // ✅ Import This
import 'package:musicapp/models/download_metadata_model.dart'; // ✅ Import This
import 'package:url_launcher/url_launcher.dart';

class SongMetadataScreen extends ConsumerStatefulWidget {
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
  ConsumerState<SongMetadataScreen> createState() => _SongMetadataScreenState();
}

class _SongMetadataScreenState extends ConsumerState<SongMetadataScreen> {
  Future<void> _launchYoutubeUrl(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Could not open link: $e")));
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
    final metadataState = ref.watch(songDetailProvider(widget.songId));

    if (metadataState.isLoading) {
      return const SongMetadataSkeleton();
    }

    final video = metadataState.videoDetails;
    final String album = 'YouTube Music';
    final String year = video?.uploadDate?.year.toString() ?? '2024';
    final String duration = _formatDuration(video?.duration);
    final String genre = 'Music';
    final bool explicit = false;
    final String views = _formatCount(video?.engagement.viewCount);
    final String likes = _formatCount(video?.engagement.likeCount);
    final String label = video?.author ?? 'YouTube';
    final String url = video?.url ?? '';

    // ✅ Download Status Check Logic
    final downloadTask = ref.watch(downloadTaskByUrlProvider(url));

    // Check if active (not completed, not failed, and exists)
    final bool isDownloading =
        downloadTask != null &&
        downloadTask.status != DownloadStatus.completed &&
        downloadTask.status != DownloadStatus.failed;

    final double progress = downloadTask?.progress ?? 0.0;

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
                    fit: BoxFit.cover, // Changed to cover for better look
                  ),
                ),
              ),
              const SizedBox(height: 22),
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
                album,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 32),
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
                        _metaItem('YEAR', year),
                        _metaItem('DURATION', duration),
                        _metaItem('GENRE', genre, highlight: true),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metaItem('EXPLICIT', explicit ? 'E' : '', box: true),
                        _metaItem('VIEWS', views),
                        _metaItem('LIKES', likes),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [_metaItem('LABEL', label, wide: true)],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
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
                        onPressed: () => _launchYoutubeUrl(url),
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

                    // ✅ DOWNLOAD BUTTON / PROGRESS INDICATOR
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isDownloading
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress, // Show actual progress
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                                if (progress > 0)
                                  Text(
                                    "${(progress * 100).toInt()}", // Show %
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.download,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () {
                                // Start Download
                                ref
                                    .read(downloadControllerProvider)
                                    .addToQueue(url);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Download started..."),
                                  ),
                                );
                              },
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
