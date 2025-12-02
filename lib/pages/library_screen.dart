import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicapp/bloc/theme/theme_cubit.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

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

    // Button Colors
    final activeBtnColor = isDarkTheme
        ? const Color.fromARGB(255, 255, 255, 255)
        : const Color(0xff000000);
    final activeBtnText = isDarkTheme
        ? const Color.fromARGB(255, 0, 0, 0)
        : const Color.fromARGB(255, 255, 255, 255);
    final inactiveBtnColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : const Color(0xffffffff);
    final inactiveBtnText = isDarkTheme ? Colors.grey[400] : Colors.black;

    // Mock Data for the list
    final List<Map<String, String>> songs = [
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Freak in Me',
        'artist': 'Electronic • 4:24',
        'image': 'assets/cover2.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
      {
        'title': 'Out of My Mine',
        'artist': 'Dance • 4:24',
        'image': 'assets/cover1.jpg',
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Search Bar
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      fillColor: cardColor,
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 18,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.search),
                          iconSize: 24,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),

                // Container(
                //   height: 50,
                //   decoration: BoxDecoration(
                //     color: cardColor,
                //     borderRadius: BorderRadius.circular(30),
                //   ),
                //   padding: const EdgeInsets.symmetric(horizontal: 16),
                //   child: Row(
                //     children: [
                //       Icon(Icons.search, color: textColor, size: 24),
                //       const SizedBox(width: 12),
                //       Text(
                //         'Search',
                //         style: TextStyle(color: searchIconColor, fontSize: 16),
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 24),

                // Filter Buttons & Song Count
                Row(
                  children: [
                    // Downloaded Button (Active)
                    GestureDetector(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: activeBtnColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Downloaded',
                          style: TextStyle(
                            color: activeBtnText,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      onTap: () {},
                    ),
                    const SizedBox(width: 12),

                    // Liked Button (Inactive)
                    GestureDetector(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: inactiveBtnColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Liked',
                          style: TextStyle(
                            color: inactiveBtnText,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      onTap: () {},
                    ),

                    const Spacer(),

                    // Song Count
                    Text(
                      '9 Songs',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Songs List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          // Album Art Placeholder
                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: isDarkTheme
                                  ? const Color(0xff2a2a2a)
                                  : const Color(0xfff0f0f0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                'https://picsum.photos/200?random=$index',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.music_note,
                                    color: secondaryTextColor,
                                    size: 30,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Title and Subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song['title']!,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song['artist']!,
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Menu Icon
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.more_vert,
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
