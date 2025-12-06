import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicapp/bloc/theme/theme_cubit.dart';
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
    final themeCubit = context.watch<ThemeCubit>();
    final isDarkTheme = themeCubit.isDarkMode;

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
              const SizedBox(height: 16),

              // Top Bar - Profile & Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildTopBar(context, isDarkTheme, cardColor),
              ),

              const SizedBox(height: 24),

              // Hero Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildHeroSection(context, textColor),
              ),

              const SizedBox(height: 24),

              // Featured Artists Horizontal List
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: featuredArtists.length,
                  itemBuilder: (context, index) {
                    final artist = featuredArtists[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < featuredArtists.length - 1 ? 12 : 0,
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

              const SizedBox(height: 30),

              // Discover Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SectionHeader(title: 'Discover', textColor: textColor),
              ),
              const SizedBox(height: 16),
              _buildSongsList(discoverSongs),

              const SizedBox(height: 30),

              // New Release Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SectionHeader(
                  title: 'New Release',
                  textColor: textColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildSongsList(newReleases),

              const SizedBox(height: 20),
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
          width: 50,
          height: 50,
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
                return const Icon(Icons.person, size: 30);
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkTheme
                  ? const Color(0xff1a1a1a)
                  : const Color(0xfff0e6ff),
            ),
            child: Icon(
              Icons.search,
              color: isDarkTheme ? Colors.white : const Color(0xff8B5CF6),
              size: 24,
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
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.2,
            ),
          ),
        ),
        // Hand pointing emoji/image
        const Text('👉', style: TextStyle(fontSize: 50)),
      ],
    );
  }

  Widget _buildSongsList(List<SongModel> songs) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Padding(
            padding: EdgeInsets.only(right: index < songs.length - 1 ? 16 : 0),
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
