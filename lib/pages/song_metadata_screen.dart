import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtil
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musicapp/widgets/song_metadata_skelton.dart';
import 'package:musicapp/provider/song_detail_provider.dart';
import 'package:musicapp/provider/download_provider.dart'; // ✅ Import This
import 'package:musicapp/models/download_metadata_model.dart'; // ✅ Import This
import 'package:url_launcher/url_launcher.dart';

class SongMetadataScreen extends ConsumerStatefulWidget {
  final String songId;
  final String imageUrl;
  final String title;
  final String artist;

  const SongMetadataScreen({
    Key? key,
    required this.songId,
    required this.imageUrl,
    required this.title,
    required this.artist,
  }) : super(key: key);

  @override
  ConsumerState<SongMetadataScreen> createState() => _SongMetadataScreenState();
}

class _SongMetadataScreenState extends ConsumerState<SongMetadataScreen> {
  Future<void> _launchYoutubeUrl(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: "Could not open link: $e");
      }
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "--:--";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inMinutes}:$twoDigitSeconds";
  }

  String _formatCount(int? count) {
    if (count == null) return "0";
    if (count >= 1000000) {
      return "${(count / 1000000).toStringAsFixed(1)}M";
    } else if (count >= 1000) {
      return "${(count / 1000).toStringAsFixed(1)}K";
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final metadataState = ref.watch(songDetailProvider(widget.songId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (metadataState.isLoading) {
      return const SongMetadataSkeleton();
    }

    final video = metadataState.videoDetails;
    final String album = 'YouTube Music';
    final String year = video?.uploadDate?.year.toString() ?? '2024';
    final String duration = _formatDuration(video?.duration);
    final String genre = 'Music';
    final bool explicit = false;
    final String views = _formatCount(video?.engagement.viewCount);
    final String likes = _formatCount(video?.engagement.likeCount);
    final String label = video?.author ?? 'YouTube';
    final String url = video?.url ?? '';

    // ✅ Download Status Check Logic
    final downloadTask = ref.watch(downloadTaskByUrlProvider(url));

    // Check if active (not completed, not failed, and exists)
    final bool isDownloading =
        downloadTask != null &&
        downloadTask.status != DownloadStatus.completed &&
        downloadTask.status != DownloadStatus.failed;

    final double progress = downloadTask?.progress ?? 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 8.h),
              Container(
                width: 280.w,
                height: 280.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black54 : Colors.black26,
                      blurRadius: 24.r,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(widget.imageUrl),
                    fit: BoxFit.cover, // Changed to cover for better look
                  ),
                ),
              ),
              SizedBox(height: 15.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 17.w),
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textTheme.headlineMedium?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 19.sp,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                widget.artist,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 15.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                album,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14.sp,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 19.h),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metaItem('YEAR', year, theme, isDark),
                        _metaItem('DURATION', duration, theme, isDark),
                        _metaItem(
                          'GENRE',
                          genre,
                          theme,
                          isDark,
                          highlight: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metaItem(
                          'EXPLICIT',
                          explicit ? 'E' : 'E',
                          theme,
                          isDark,
                          box: true,
                        ),
                        _metaItem('VIEWS', views, theme, isDark),
                        _metaItem('LIKES', likes, theme, isDark),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _metaItem('LABEL', label, theme, isDark, wide: true),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 36.h),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 22.0.w,
                  vertical: 14.0.h,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: theme.textTheme.bodyLarge?.color,
                          side: BorderSide(
                            color: theme.dividerColor.withOpacity(0.5),
                            width: 2.w,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _launchYoutubeUrl(url),
                        child: Text(
                          'OPEN URL',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),

                    // ✅ DOWNLOAD BUTTON / PROGRESS INDICATOR
                    Container(
                      width: 55.w,
                      height: 55.h,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.5),
                          width: 2.w,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: isDownloading
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress, // Show actual progress
                                  color: theme.primaryColor,
                                  strokeWidth: 3.w,
                                ),
                                if (progress > 0)
                                  Text(
                                    "${(progress * 100).toInt()}", // Show %
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                              ],
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.download,
                                color: theme.iconTheme.color,
                                size: 24.sp,
                              ),
                              onPressed: () {
                                // Start Download
                                ref
                                    .read(downloadControllerProvider)
                                    .addToQueue(url);
                                Fluttertoast.showToast(
                                  msg: "Download started...",
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaItem(
    String label,
    String value,
    ThemeData theme,
    bool isDark, {
    bool highlight = false,
    bool box = false,
    bool wide = false,
  }) {
    return Container(
      width: wide ? 170.w : 80.w,
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 11.sp,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 6.h),
          box
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: theme.textTheme.bodyLarge?.color,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: theme.scaffoldBackgroundColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    color: highlight
                        ? theme.textTheme.bodyLarge?.color
                        : theme.textTheme.bodyMedium?.color,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                    fontSize: highlight ? 16.sp : 15.sp,
                  ),
                ),
        ],
      ),
    );
  }
}
