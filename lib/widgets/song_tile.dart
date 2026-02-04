import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musicapp/models/local_song_model.dart';

class SongTile extends StatelessWidget {
  final String title;
  final String artist;
  final int duration;
  final int? songId;
  final String? imageUrl;
  final VoidCallback? onTap;

  // ✅ Supports BOTH callbacks now to prevent errors
  final VoidCallback? onMenuTap; // For BottomSheet (Library/Liked Screens)
  final List<PopupMenuEntry<String>>?
  menuItems; // For PopupMenu (Playlist Screen)
  final void Function(String)? onMenuItemSelected; // For PopupMenu Selection

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
    this.onMenuTap, // Restored
    this.menuItems, // New
    this.onMenuItemSelected, // New
    required this.isDarkTheme,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey;
    final titleColor = isPlaying
        ? const Color(0xFF8E97FD)
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
              // Album Art
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

              // ✅ LOGIC: Choose between PopupMenu (Playlist) OR IconButton (Library)
              _buildMenuButton(titleColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(Color iconColor) {
    // 1. If menuItems are provided, use PopupMenuButton (Fixes positioning issue)
    if (menuItems != null && menuItems!.isNotEmpty) {
      return PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: iconColor),
        onSelected: onMenuItemSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDarkTheme ? Colors.grey[900] : Colors.white,
        itemBuilder: (context) => menuItems!,
      );
    }

    // 2. Otherwise use standard IconButton (Fixes "error on other screens")
    return IconButton(
      onPressed: onMenuTap,
      icon: Icon(Icons.more_vert, color: iconColor),
    );
  }

  Widget _buildArtwork(Color? placeholderColor) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Check if it's a local file path or network URL
      if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
        return Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildLocalArtwork(placeholderColor);
          },
        );
      } else {
        // Local file path
        final file = File(imageUrl!);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildLocalArtwork(placeholderColor);
            },
          );
        }
      }
    }
    return _buildLocalArtwork(placeholderColor);
  }

  Widget _buildLocalArtwork(Color? placeholderColor) {
    if (songId != null) {
      return QueryArtworkWidget(
        keepOldArtwork: true,
        id: songId!,
        type: ArtworkType.AUDIO,
        nullArtworkWidget: Icon(
          Icons.music_note,
          color: placeholderColor,
          size: 28.sp,
        ),
      );
    }
    return Icon(Icons.music_note, color: placeholderColor, size: 28.sp);
  }
}

String _formatDuration(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
