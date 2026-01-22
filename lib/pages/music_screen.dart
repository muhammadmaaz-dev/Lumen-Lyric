import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    debugPrint('🔄 MusicScreen rebuilt');

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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(14.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 9.h),
                    // 1. Main Title
                    Center(
                      child: Text(
                        'Music Downloader',
                        style: TextStyle(
                          fontSize: 25.sp,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 26.h),

                    // 2. Input Field (Paste Link)
                    CustomTextField(
                      hintText: 'Paste YouTube Link Here...',
                      suffixIcon: Icons.sync,
                      onSuffixTap: () {},
                      isDarkTheme: isDarkTheme,
                    ),
                    SizedBox(height: 18.h),

                    // 3. Converting Info Box
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 13.h,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor, // Slightly different grey
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.music_note_outlined,
                            size: 25.sp,
                            color: textColor,
                          ),
                          SizedBox(width: 13.w),
                          Expanded(
                            child: Text(
                              'Converting may take few seconds depending on video Length',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: textColor,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 26.h),

                    // 4. Section Header
                    SectionHeader(
                      title: 'Recent Conversion',
                      actionText: 'Clear',
                      onActionTap: () {},
                      textColor: textColor,
                    ),
                    SizedBox(height: 13.h),

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
                              duration: song.duration,
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
        ],
      ),
    );
  }
}
