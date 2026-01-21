import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(35.r),
          boxShadow: isDarkTheme
              ? null
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 9.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Artist Image
            Container(
              width: 48.w,
              height: 48.h,
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
            SizedBox(width: 11.w),

            // Artist Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  artist.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 12.sp,
                      color: const Color(0xff10B981),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      artist.songTitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(width: 11.w),

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
