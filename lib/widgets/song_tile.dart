import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musicapp/models/local_song_model.dart';

class SongTile extends StatelessWidget {
  final String title;
  final String artist;
  final int duration;
  final int? songId; // For QueryArtworkWidget
  final String? imageUrl; // For NetworkImage fallback or alternative
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;
  final bool isDarkTheme;
  final bool isPlaying;

  const SongTile({
    super.key,
    required this.title,
    required this.artist,
    required this.duration,
    this.songId,
    this.imageUrl,
    this.onTap,
    this.onMenuTap,
    required this.isDarkTheme,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey;
    final titleColor = isPlaying
        ? const Color(0xFF8E97FD) // Highlight Color
        : (isDarkTheme ? Colors.white : Colors.black);

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 48.h,
          width: double.infinity,
          child: Row(
            children: [
              // Album Art Placeholder
              Container(
                width: 48.h,
                height: 48.h,
                decoration: BoxDecoration(
                  color: isDarkTheme
                      ? const Color(0xff2a2a2a)
                      : const Color(0xfff0f0f0),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: _buildArtwork(
                    isPlaying ? const Color(0xFF8E97FD) : secondaryTextColor,
                  ),
                ),
              ),
              SizedBox(width: 14.w),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${artist} • ${_formatDuration(duration)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Icon
              IconButton(
                onPressed: onMenuTap,
                icon: Icon(Icons.more_vert, color: titleColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(Color? placeholderColor) {
    if (songId != null) {
      return QueryArtworkWidget(
        keepOldArtwork: true,
        id: songId!,
        type: ArtworkType.AUDIO,
        nullArtworkWidget: Icon(
          Icons.music_note,
          color: placeholderColor,
          size: 30,
        ),
      );
    } else if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.music_note, color: placeholderColor, size: 30);
        },
      );
    } else {
      return Icon(Icons.music_note, color: placeholderColor, size: 30);
    }
  }
}

String _formatDuration(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
