import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicapp/bloc/theme/theme_cubit.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/widgets/custom_text_field.dart';
import 'package:musicapp/widgets/section_header.dart';
import 'package:musicapp/widgets/song_tile.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  @override
  void initState() {
    super.initState();
    if (AudioController.instance.songs.value.isEmpty) {
      AudioController.instance.loadSongs();
    }
  }

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
                CustomTextField(
                  hintText: 'Paste YouTube Link Here...',
                  suffixIcon: Icons.sync,
                  onSuffixTap: () {},
                  isDarkTheme: isDarkTheme,
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
                SectionHeader(
                  title: 'Recent Conversion',
                  actionText: 'Clear',
                  onActionTap: () {},
                  textColor: textColor,
                ),
                const SizedBox(height: 15),

                // 5. List of Songs
                ValueListenableBuilder<List<LocalSongModel>>(
                  valueListenable: AudioController.instance.songs,
                  builder: (context, songs, child) {
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
