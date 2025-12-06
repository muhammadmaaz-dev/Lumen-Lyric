import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongTile extends StatelessWidget {
  final String title;
  final String artist;
  final int? songId; // For QueryArtworkWidget
  final String? imageUrl; // For NetworkImage fallback or alternative
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;
  final bool isDarkTheme;

  const SongTile({
    super.key,
    required this.title,
    required this.artist,
    this.songId,
    this.imageUrl,
    this.onTap,
    this.onMenuTap,
    required this.isDarkTheme,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 55,
          width: double.infinity,
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
                  child: _buildArtwork(secondaryTextColor),
                ),
              ),
              const SizedBox(width: 16),

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
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                onPressed: onMenuTap,
                icon: Icon(
                  Icons.more_vert,
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
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
