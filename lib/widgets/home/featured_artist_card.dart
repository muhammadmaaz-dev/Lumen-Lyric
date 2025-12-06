import 'package:flutter/material.dart';
import 'package:musicapp/models/artist_model.dart';

class FeaturedArtistCard extends StatelessWidget {
  final ArtistModel artist;
  final bool isDarkTheme;
  final bool showPlayButton;
  final VoidCallback? onTap;

  const FeaturedArtistCard({
    super.key,
    required this.artist,
    required this.isDarkTheme,
    this.showPlayButton = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : const Color(0xffffffff);
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                      style: TextStyle(fontSize: 13, color: secondaryTextColor),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Play Button (only on first card in design)
            if (showPlayButton)
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
  }
}
