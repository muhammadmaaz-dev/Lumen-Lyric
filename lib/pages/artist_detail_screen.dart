import 'package:flutter/material.dart';
import 'package:musicapp/models/song_model.dart';
import 'package:musicapp/pages/song_metadata_screen.dart';
import 'package:musicapp/services/youtube_service.dart';
import 'package:musicapp/widgets/artist_detail_skelton.dart'; // Ensure correct spelling (skeleton vs skelton)

class ArtistDetailScreen extends StatefulWidget {
  final String artistName;
  final String artistImageUrl;

  const ArtistDetailScreen({
    Key? key,
    required this.artistName,
    required this.artistImageUrl,
  }) : super(key: key);

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  final YoutubeService _youtubeService = YoutubeService();

  bool _isLoading = true;

  // Do lists maintain karenge:
  List<SongModel> _allTracks = []; // API se aaye hue saare songs
  List<SongModel> _displayedTracks = []; // Screen par dikhane wale songs

  String _subscribers = 'Verified';
  bool _showLoadAllButton = false; // Button dikhana hai ya nahi

  @override
  void initState() {
    super.initState();
    _fetchArtistData();
  }

  Future<void> _fetchArtistData() async {
    try {
      final songs = await _youtubeService.searchSongs(widget.artistName);

      if (mounted) {
        setState(() {
          _allTracks = songs;

          // Logic: Show only 40% initially (or at least 5 songs if list is small)
          if (_allTracks.length > 5) {
            int initialCount = (_allTracks.length * 0.4)
                .ceil(); // 40% calculate kiya
            if (initialCount < 5) initialCount = 5; // Minimum 5 to dikhao

            _displayedTracks = _allTracks.take(initialCount).toList();
            _showLoadAllButton = true; // Button dikhao kyunki aur songs hain
          } else {
            // Agar songs hi kam hain to saare dikha do
            _displayedTracks = List.from(_allTracks);
            _showLoadAllButton = false; // Button ki zaroorat nahi
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading artist data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NEW: Load All Tracks Function ---
  void _loadAllTracks() {
    setState(() {
      _displayedTracks = List.from(_allTracks); // Saare songs copy kar liye
      _showLoadAllButton = false; // Ab button chupa do
    });
  }

  void _handleSongTap(SongModel song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongMetadataScreen(
          songId: song.id, // Metadata fetch karne ke liye ID pass ki
          imageUrl: song.imageUrl,
          title: song.title,
          artist: song.genre, // Artist name/Genre
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ArtistDetailSkeleton();
    }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 80,
              backgroundImage: NetworkImage(widget.artistImageUrl),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(height: 24),
            Text(
              widget.artistName.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 32,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$_subscribers SUBSCRIBERS',
              style: const TextStyle(
                color: Colors.white54,
                fontFamily: 'RobotoMono',
                fontSize: 15,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _roundedButton('SHUFFLE', Icons.shuffle, onTap: () {}),
                const SizedBox(width: 24),
                _roundedButton('FOLLOW', Icons.add, onTap: () {}),
              ],
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'POPULAR TRACKS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    // Yahan Total Count hi dikhayenge, user ko pata chale ke aur bhi hain
                    '${_allTracks.length} TRACKS TOTAL',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontFamily: 'RobotoMono',
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Track List (Displays only partial list initially)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _displayedTracks.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                final track = _displayedTracks[index];
                return _trackTile(index + 1, track);
              },
            ),

            const SizedBox(height: 24),

            // Load All Button (Conditionally Visible)
            if (_showLoadAllButton)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed:
                        _loadAllTracks, // <--- Button press par saare load honge
                    child: const Text(
                      'LOAD ALL TRACKS',
                      style: TextStyle(
                        color: Colors.white54,
                        fontFamily: 'RobotoMono',
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _roundedButton(
    String label,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white38, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        foregroundColor: Colors.white,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 22, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _trackTile(int number, SongModel track) {
    // UPDATED: Wrapped in InkWell to handle taps
    return GestureDetector(
      onTap: () => _handleSongTap(track), // Click par navigate karega
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                number.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: Colors.white38,
                  fontFamily: 'RobotoMono',
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                      fontSize: 17,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    track.genre,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontFamily: 'RobotoMono',
                      fontSize: 13,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              "--:--",
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'RobotoMono',
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.more_horiz, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
