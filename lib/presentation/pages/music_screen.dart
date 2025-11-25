import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicapp/presentation/bloc/theme/theme_cubit.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

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
    final avatarBgColor = isDarkTheme
        ? const Color(0xff3a3a3c)
        : const Color(0xffffffff);
    final dividerColor = isDarkTheme ? Colors.grey[800] : Colors.grey[300];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // 1. Main Title
                Center(
                  child: Text(
                    'Music Downloader',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 2. Input Field (Paste Link)
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      fillColor: cardColor,
                      hintText: 'Paste YouTube Link Here...',
                      hintStyle: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 18,
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.sync),
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Converting Info Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor, // Slightly different grey
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.music_note_outlined,
                        size: 28,
                        color: textColor,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          'Converting may take few seconds depending on video Length',
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 4. Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Conversion',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "Clear",
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // 5. List of Songs
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentConversions.length,
                  itemBuilder: (context, index) {
                    final song = recentConversions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Row(
                        children: [
                          // Album Art / Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 60,
                              width: 60,
                              color: cardColor,
                              child: Image.network(
                                song.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (c, o, s) => Container(
                                  color: cardColor,
                                  child: Icon(
                                    Icons.music_note,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),

                          // Title and Subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${song.genre} · ${song.duration}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Menu Icon
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.more_vert),
                            color: textColor,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Data Model & Dummy Data ---
class SongModel {
  final String title;
  final String genre;
  final String duration;
  final String imageUrl;

  SongModel(this.title, this.genre, this.duration, this.imageUrl);
}

// Dummy data to match the screenshot
List<SongModel> recentConversions = [
  SongModel(
    'Out of My Mine',
    'Dance',
    '4:24',
    'https://picsum.photos/200?random=1',
  ),
  SongModel(
    'Freak in Me',
    'Electronic',
    '4:24',
    'https://picsum.photos/200?random=2',
  ),
  SongModel(
    'Out of My Mine',
    'Dance',
    '4:24',
    'https://picsum.photos/200?random=3',
  ),
  SongModel(
    'Out of My Mine',
    'Dance',
    '4:24',
    'https://picsum.photos/200?random=4',
  ),
  SongModel(
    'Out of My Mine',
    'Dance',
    '4:24',
    'https://picsum.photos/200?random=5',
  ),
  SongModel(
    'Out of My Mine',
    'Dance',
    '4:24',
    'https://picsum.photos/200?random=6',
  ),
  SongModel(
    'Out of My Mine',
    'Dance',
    '4:24',
    'https://picsum.photos/200?random=1',
  ),
  SongModel(
    'Freak in Me',
    'Electronic',
    '4:24',
    'https://picsum.photos/200?random=2',
  ),
  SongModel(
    'Out of My Mine',
    'Dance',
    '4:24',
    'https://picsum.photos/200?random=3',
  ),
  SongModel(
    'Out of My Mine',
    'Dance',
    '4:24',
    'https://picsum.photos/200?random=4',
  ),
  SongModel(
    'Out of My Mine',
    'Dance',
    '4:24',
    'https://picsum.photos/200?random=5',
  ),
  SongModel(
    'Out of My Mine',
    'Dance',
    '4:24',
    'https://picsum.photos/200?random=6',
  ),
];
