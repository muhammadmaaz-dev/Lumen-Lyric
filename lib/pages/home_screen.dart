import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicapp/bloc/theme/theme_cubit.dart';
import 'package:musicapp/pages/search_screen.dart';

// Data Models - Ready for backend integration
class ArtistModel {
  final String id;
  final String name;
  final String songTitle;
  final String imageUrl;

  ArtistModel({
    required this.id,
    required this.name,
    required this.songTitle,
    required this.imageUrl,
  });

  // Factory constructor for JSON parsing (backend ready)
  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      songTitle: json['songTitle'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}

class SongModel {
  final String id;
  final String title;
  final String genre;
  final String imageUrl;

  SongModel({
    required this.id,
    required this.title,
    required this.genre,
    required this.imageUrl,
  });

  // Factory constructor for JSON parsing (backend ready)
  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      genre: json['genre'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}

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
    final secondaryTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey;

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
              _buildFeaturedArtists(
                context,
                isDarkTheme,
                cardColor,
                textColor,
                secondaryTextColor,
              ),

              const SizedBox(height: 30),

              // Discover Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildSectionTitle('Discover', textColor),
              ),
              const SizedBox(height: 16),
              _buildSongsList(discoverSongs),

              const SizedBox(height: 30),

              // New Release Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildSectionTitle('New Release', textColor),
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

  Widget _buildFeaturedArtists(
    BuildContext context,
    bool isDarkTheme,
    Color cardColor,
    Color textColor,
    Color? secondaryTextColor,
  ) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: featuredArtists.length,
        itemBuilder: (context, index) {
          final artist = featuredArtists[index];
          return GestureDetector(
            onTap: () {
              // TODO: Navigate to artist/song detail
            },
            child: Container(
              margin: EdgeInsets.only(
                right: index < featuredArtists.length - 1 ? 12 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: isDarkTheme
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // Artist Image
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withOpacity(0.3),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        artist.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.person, color: secondaryTextColor);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Artist Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        artist.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.music_note,
                            size: 14,
                            color: const Color(0xff10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            artist.songTitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Play Button (only on first card in design)
                  if (index == 0)
                    Container(
                      width: 35,
                      height: 35,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
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
          return GestureDetector(
            onTap: () {
              // TODO: Navigate to song detail or play song
            },
            child: Container(
              width: 160,
              margin: EdgeInsets.only(right: index < songs.length - 1 ? 16 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Song Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      song.imageUrl,
                      width: 160,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 160,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.teal.shade300,
                                Colors.purple.shade300,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.music_note,
                            size: 50,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),

                  // Gradient Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Song Info
                  Positioned(
                    bottom: 16,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.genre,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
