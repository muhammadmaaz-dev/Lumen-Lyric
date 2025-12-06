import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicapp/bloc/theme/theme_cubit.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/widgets/custom_text_field.dart';
import 'package:musicapp/widgets/filter_button.dart';
import 'package:musicapp/widgets/mini_player.dart';
import 'package:musicapp/widgets/song_tile.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    if (AudioController.instance.songs.value.isEmpty) {
      AudioController.instance.loadSongs();
    }
  }

  String _formatDuration(int milliseconds) {
    final minutes = (milliseconds / 60000).floor();
    final seconds = ((milliseconds % 60000) / 1000).floor();
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    final isDarkTheme = themeCubit.isDarkMode;

    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : const Color(0xfff3f4f6);
    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,

      body: Stack(
        children: [
          // MAIN SCROLLABLE UI
          SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Search Bar
                    CustomTextField(
                      hintText: 'Search',
                      prefixIcon: Icons.search,
                      onPrefixTap: () {},
                      isDarkTheme: isDarkTheme,
                    ),

                    const SizedBox(height: 24),

                    // Filter Buttons & Song Count
                    Row(
                      children: [
                        FilterButton(
                          text: 'Downloaded',
                          isActive: true,
                          onTap: () {},
                          isDarkTheme: isDarkTheme,
                        ),
                        const SizedBox(width: 12),

                        FilterButton(
                          text: 'Liked',
                          isActive: false,
                          onTap: () {},
                          isDarkTheme: isDarkTheme,
                        ),

                        const Spacer(),

                        ValueListenableBuilder(
                          valueListenable: AudioController.instance.songs,
                          builder: (context, songs, child) {
                            return Text(
                              '${songs.length} Songs',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Songs List
                    ValueListenableBuilder(
                      valueListenable: AudioController.instance.songs,
                      builder: (context, songs, _) {
                        if (songs.isEmpty) {
                          return Center(child: Text("No Song Found"));
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: songs.length,
                          itemBuilder: (context, index) {
                            final song = songs[index];

                            return SongTile(
                              title: song.title,
                              artist: song.artist,
                              songId: song.id,
                              onTap: () {
                                AudioController.instance.playSong(index);
                              },
                              onMenuTap: () {},
                              isDarkTheme: isDarkTheme,
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 120), // space for mini player
                  ],
                ),
              ),
            ),
          ),

          // FLOATING MINI PLAYER (FIXED POSITION)
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: MiniPlayer(),
            ),
          ),
        ],
      ),
    );
  }
}
