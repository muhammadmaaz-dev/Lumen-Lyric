import 'dart:math'; // Imported to generate random view counts
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/models/artist_model.dart';
import 'package:musicapp/models/song_model.dart';
import 'package:musicapp/pages/artist_detail_screen.dart';
import 'package:musicapp/pages/search_screen.dart';
import 'package:musicapp/pages/song_metadata_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- DATA SOURCE ---

  List<ArtistModel> get featuredArtists => [
    ArtistModel(
      id: '1',
      name: 'Kanye West',
      songTitle: 'Dark Fantasy',
      imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
    ),
    ArtistModel(
      id: '2',
      name: 'Drake',
      songTitle: "God's Plan",
      imageUrl: 'https://randomuser.me/api/portraits/men/33.jpg',
    ),
    ArtistModel(
      id: '3',
      name: 'Ariana Grande',
      songTitle: '7 Rings',
      imageUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
    ),
    ArtistModel(
      id: '4',
      name: 'Kanye West',
      songTitle: 'Dark Fantasy',
      imageUrl: 'https://randomuser.me/api/portraits/men/320.jpg',
    ),
    ArtistModel(
      id: '5',
      name: 'Drake',
      songTitle: "God's Plan",
      imageUrl: 'https://randomuser.me/api/portraits/men/30.jpg',
    ),
    ArtistModel(
      id: '6',
      name: 'Anjum',
      songTitle: '7 Rings',
      imageUrl: 'https://randomuser.me/api/portraits/women/49.jpg',
    ),
  ];

  List<SongModel> get discoverSongs => [
    SongModel(
      id: '1',
      title: 'Midnight City',
      genre: 'Electronic',
      imageUrl:
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=400&q=80',
    ),
    SongModel(
      id: '2',
      title: 'Blinding Lights',
      genre: 'Pop',
      imageUrl:
          'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80',
    ),
    SongModel(
      id: '3',
      title: 'Midnight City',
      genre: 'Electronic',
      imageUrl:
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=400&q=80',
    ),
    SongModel(
      id: '4',
      title: 'Blinding Lights',
      genre: 'Pop',
      imageUrl:
          'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  List<SongModel> get trendingSongs => [
    // Column 1
    SongModel(
      id: '1',
      title: 'Bad Habit',
      genre: 'Steve Lacy',
      imageUrl: 'https://picsum.photos/seed/1/100',
    ),
    SongModel(
      id: '2',
      title: 'As It Was',
      genre: 'Harry Styles',
      imageUrl: 'https://picsum.photos/seed/2/100',
    ),
    SongModel(
      id: '3',
      title: 'Glimpse of Us',
      genre: 'Joji',
      imageUrl: 'https://picsum.photos/seed/3/100',
    ),
    SongModel(
      id: '4',
      title: 'Die For You',
      genre: 'The Weeknd',
      imageUrl: 'https://picsum.photos/seed/4/100',
    ),

    // Column 2
    SongModel(
      id: '5',
      title: 'About Damn Time',
      genre: 'Lizzo',
      imageUrl: 'https://picsum.photos/seed/5/100',
    ),
    SongModel(
      id: '6',
      title: 'Late Night Talking',
      genre: 'Harry Styles',
      imageUrl: 'https://picsum.photos/seed/6/100',
    ),
    SongModel(
      id: '7',
      title: 'Heat Waves',
      genre: 'Glass Animals',
      imageUrl: 'https://picsum.photos/seed/7/100',
    ),
    SongModel(
      id: '8',
      title: 'Stay',
      genre: 'Justin Bieber',
      imageUrl: 'https://picsum.photos/seed/8/100',
    ),

    // Column 3
    SongModel(
      id: '9',
      title: 'Rich Flex',
      genre: 'Drake',
      imageUrl: 'https://picsum.photos/seed/9/100',
    ),
    SongModel(
      id: '10',
      title: 'Anti-Hero',
      genre: 'Taylor Swift',
      imageUrl: 'https://picsum.photos/seed/10/100',
    ),
    SongModel(
      id: '9',
      title: 'Rich Flex',
      genre: 'Drake',
      imageUrl: 'https://picsum.photos/seed/9/100',
    ),
    SongModel(
      id: '10',
      title: 'Anti-Hero',
      genre: 'Taylor Swift',
      imageUrl: 'https://picsum.photos/seed/10/100',
    ),
  ];

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                _buildHeader(context),
                SizedBox(height: 24.h),

                // Trending Now
                _buildSectionTitle('Trending Now'),
                SizedBox(height: 12.h),
                _buildTrendingList(context, trendingSongs),

                SizedBox(height: 28.h),

                // Featured
                _buildSectionTitle('Featured Songs'),
                SizedBox(height: 16.h),
                _buildFeaturedTracks(context, discoverSongs),

                SizedBox(height: 28.h),

                // Popular Artists
                _buildSectionTitle('Popular Artist'),
                SizedBox(height: 16.h),
                _buildPopularArtists(context, featuredArtists),

                SizedBox(height: 80.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'MUSIC',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 32,
              letterSpacing: 1.5,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? actionText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.2,
            ),
          ),
          if (actionText != null)
            Text(
              actionText,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 15,
                decoration: TextDecoration.underline,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendingList(BuildContext context, List<SongModel> songs) {
    const int itemsPerColumn = 4;
    final int pageCount = (songs.length / itemsPerColumn).ceil();

    return SizedBox(
      height: (70.h * itemsPerColumn).toDouble(),
      // CHANGED: Use PageView.builder for snapping behavior
      child: PageView.builder(
        // viewportFraction: 0.9 means the current column takes 90% of screen,
        // showing a sneak peek of the next one (YouTube style).
        controller: PageController(viewportFraction: 0.92),
        padEnds: false, // Starts aligned to the left
        physics: const BouncingScrollPhysics(), // Nice bounce on edges
        itemCount: pageCount,
        itemBuilder: (context, pageIndex) {
          final int startIndex = pageIndex * itemsPerColumn;
          final int endIndex = (startIndex + itemsPerColumn < songs.length)
              ? startIndex + itemsPerColumn
              : songs.length;

          final List<SongModel> columnSongs = songs.sublist(
            startIndex,
            endIndex,
          );

          return Container(
            // Add margin right to create the gap between "pages"
            margin: EdgeInsets.only(right: 12.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: columnSongs.map((song) {
                return _buildSongRow(context, song);
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSongRow(BuildContext context, SongModel song) {
    // Generate a random view count for demo purposes (e.g., "4.2M")
    // In a real app, pass this data via the SongModel
    final randomViews = (Random().nextDouble() * 100).toStringAsFixed(1);

    return Container(
      height: 60.h,
      margin: EdgeInsets.only(bottom: 10.h, left: 20.w), // Added left margin
      child: InkWell(
        onTap: () => _navigateToMetadata(context, song),
        borderRadius: BorderRadius.circular(6),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                song.imageUrl,
                width: 50.h,
                height: 50.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50.h,
                  height: 50.h,
                  color: Colors.grey[900],
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // CHANGED: Combined Artist Name + Views
                  Text(
                    '${song.genre} • ${randomViews}M Views',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white60, fontSize: 13.sp),
                  ),
                ],
              ),
            ),

            Icon(Icons.more_vert, color: Colors.white54, size: 20.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedTracks(BuildContext context, List<SongModel> songs) {
    return SizedBox(
      height: 210.h, // Fixed height container is required for horizontal lists
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: songs.length,
        separatorBuilder: (context, index) => SizedBox(width: 16.w),
        itemBuilder: (context, index) {
          final song = songs[index];

          return GestureDetector(
            onTap: () => _navigateToMetadata(context, song),
            child: SizedBox(
              width: 160.w, // Fixed width for each card
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Container
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          song.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[900]),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Title
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),

                  // Subtitle
                  Text(
                    song.genre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularArtists(BuildContext context, List<ArtistModel> artists) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: artists.length,
        separatorBuilder: (context, index) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final artist = artists[index];

          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArtistDetailScreen(
                        artistName: artist.name,
                        artistImageUrl: artist.imageUrl,
                        subscribers: '5.2M',
                        totalTracks: 22,
                        // FIX: Convert SongModel to Map
                        tracks: trendingSongs
                            .map(
                              (song) => {
                                'title': song.title,
                                'artist': song
                                    .genre, // Assuming genre is used as subtitle
                                'imageUrl': song.imageUrl,
                                'duration':
                                    '3:00', // Dummy data if model doesn't have it
                              },
                            )
                            .toList(),
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(artist.imageUrl),
                  onBackgroundImageError: (_, __) {},
                ),
              ),
              const SizedBox(height: 8),
              Text(
                artist.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToMetadata(BuildContext context, SongModel song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongMetadataScreen(
          imageUrl: song.imageUrl,
          title: song.title,
          artist: 'Unknown Artist',
          album: 'Single',
          year: '2024',
          duration: '3:00',
          genre: song.genre,
          explicit: false,
          views: '1M',
          likes: '100K',
          label: 'Music Label',
          url: '',
        ),
      ),
    );
  }
}
