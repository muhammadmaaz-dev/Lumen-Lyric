import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/models/artist_model.dart';
import 'package:musicapp/models/song_model.dart';
import 'package:musicapp/pages/search_screen.dart';
import 'package:musicapp/widgets/home/featured_artist_card.dart';
import 'package:musicapp/widgets/home/song_card.dart';
import 'package:musicapp/widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Mock data - Replace with backend data later
  List<ArtistModel> get featuredArtists => [
    ArtistModel(
      id: '1',
      name: 'Ayesha Ruhin',
      songTitle: 'Some Feeling',
      imageUrl: 'https://picsum.photos/200?random=10',
    ),
    ArtistModel(
      id: '2',
      name: 'Jane Cooper',
      songTitle: "I Didn't Know",
      imageUrl: 'https://picsum.photos/200?random=11',
    ),
    ArtistModel(
      id: '3',
      name: 'Mike Ross',
      songTitle: 'Feel Good',
      imageUrl: 'https://picsum.photos/200?random=12',
    ),
  ];

  List<SongModel> get discoverSongs => [
    SongModel(
      id: '1',
      title: 'Out of My Mine',
      genre: 'Dance',
      imageUrl: 'https://picsum.photos/300?random=1',
    ),
    SongModel(
      id: '2',
      title: 'Freak In Me',
      genre: 'Electronic',
      imageUrl: 'https://picsum.photos/300?random=2',
    ),
    SongModel(
      id: '3',
      title: 'Lose Control',
      genre: 'Dance',
      imageUrl: 'https://picsum.photos/300?random=3',
    ),
  ];

  List<SongModel> get newReleases => [
    SongModel(
      id: '4',
      title: 'Out of My Mine',
      genre: 'Dance',
      imageUrl: 'https://picsum.photos/300?random=4',
    ),
    SongModel(
      id: '5',
      title: 'Freak In Me',
      genre: 'Electronic',
      imageUrl: 'https://picsum.photos/300?random=5',
    ),
    SongModel(
      id: '6',
      title: 'Lose Control',
      genre: 'Dance',
      imageUrl: 'https://picsum.photos/300?random=6',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 HomeScreen rebuilt');

    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : const Color(0xfff3f4f6);
    final cardColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : const Color(0xffffffff);
    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 14.h),

              // Top Bar - Profile & Search
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: _buildTopBar(context, isDarkTheme, cardColor),
              ),

              SizedBox(height: 21.h),

              // Hero Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: _buildHeroSection(context, textColor),
              ),

              SizedBox(height: 21.h),

              // Featured Artists Horizontal List
              SizedBox(
                height: 70.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  itemCount: featuredArtists.length,
                  itemBuilder: (context, index) {
                    final artist = featuredArtists[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < featuredArtists.length - 1 ? 11.w : 0,
                      ),
                      child: FeaturedArtistCard(
                        artist: artist,
                        isDarkTheme: isDarkTheme,
                        showPlayButton: index == 0,
                        onTap: () {
                          // TODO: Navigate to artist/song detail
                        },
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 26.h),

              // Discover Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: SectionHeader(title: 'Discover', textColor: textColor),
              ),
              SizedBox(height: 14.h),
              _buildSongsList(discoverSongs),

              SizedBox(height: 26.h),

              // New Release Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: SectionHeader(
                  title: 'New Release',
                  textColor: textColor,
                ),
              ),
              SizedBox(height: 14.h),
              _buildSongsList(newReleases),

              SizedBox(height: 18.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDarkTheme, Color cardColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Profile Avatar
        Container(
          width: 44.w,
          height: 44.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xffF5E6D3),
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
          ),
          child: ClipOval(
            child: Image.network(
              'https://picsum.photos/100?random=99',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.person, size: 26.sp);
              },
            ),
          ),
        ),

        // Search Button
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
          child: Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkTheme
                  ? const Color(0xff1a1a1a)
                  : const Color(0xfff0e6ff),
            ),
            child: Icon(
              Icons.search,
              color: isDarkTheme ? Colors.white : const Color(0xff8B5CF6),
              size: 21.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context, Color textColor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Find the best\nmusic for you',
            style: TextStyle(
              fontSize: 25.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.2,
            ),
          ),
        ),
        // Hand pointing emoji/image
        Text('👉', style: TextStyle(fontSize: 44.sp)),
      ],
    );
  }

  Widget _buildSongsList(List<SongModel> songs) {
    return SizedBox(
      height: 176.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < songs.length - 1 ? 14.w : 0,
            ),
            child: SongCard(
              song: song,
              onTap: () {
                // TODO: Navigate to song detail or play song
              },
            ),
          );
        },
      ),
    );
  }
}
