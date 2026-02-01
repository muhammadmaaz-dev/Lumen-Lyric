import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ScreenUtil Import
import 'package:cached_network_image/cached_network_image.dart'; // Cache Import
import 'package:musicapp/models/song_model.dart';
import 'package:musicapp/pages/song_metadata_screen.dart';
import 'package:musicapp/utils/slide_route.dart';
import 'package:musicapp/widgets/artist_detail_skelton.dart';
import 'package:musicapp/provider/artist_provider.dart'; // Provider Import
import 'package:musicapp/widgets/bottom_sheet_lib.dart';

class ArtistDetailScreen extends ConsumerStatefulWidget {
  final String artistName;
  final String artistImageUrl;

  const ArtistDetailScreen({
    Key? key,
    required this.artistName,
    required this.artistImageUrl,
  }) : super(key: key);

  @override
  ConsumerState<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends ConsumerState<ArtistDetailScreen> {
  List<SongModel> _displayedTracks = [];
  bool _showLoadAllButton = false;
  bool _isDataLoadedInitial = false;

  void _updateDisplayedTracks(List<SongModel> allTracks) {
    if (_isDataLoadedInitial) return;
    setState(() {
      if (allTracks.length > 5) {
        int initialCount = (allTracks.length * 0.4).ceil();
        if (initialCount < 5) initialCount = 5;
        _displayedTracks = allTracks.take(initialCount).toList();
        _showLoadAllButton = true;
      } else {
        _displayedTracks = List.from(allTracks);
        _showLoadAllButton = false;
      }
      _isDataLoadedInitial = true;
    });
  }

  void _loadAllTracks(List<SongModel> allTracks) {
    setState(() {
      _displayedTracks = List.from(allTracks);
      _showLoadAllButton = false;
    });
  }

  void _handleSongTap(SongModel song) {
    Navigator.push(
      context,
      SlideRightToLeftRoute(
        page: SongMetadataScreen(
          songId: song.id,
          imageUrl: song.imageUrl,
          title: song.title,
          artist: song.genre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Theme Variable
    final artistState = ref.watch(artistProvider(widget.artistName));

    ref.listen(artistProvider(widget.artistName), (previous, next) {
      if (!next.isLoading && next.songs.isNotEmpty) {
        if (_displayedTracks.isEmpty) {
          _updateDisplayedTracks(next.songs);
        }
      }
    });

    if (!artistState.isLoading &&
        _displayedTracks.isEmpty &&
        artistState.songs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateDisplayedTracks(artistState.songs);
      });
    }

    if (artistState.isLoading) {
      return const ArtistDetailSkeleton();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Dynamic Color
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.iconTheme.color),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            // Cached Image
            CircleAvatar(
              radius: 80.r,
              backgroundColor: theme.cardColor,
              backgroundImage: CachedNetworkImageProvider(
                widget.artistImageUrl,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              widget.artistName.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 28.sp,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Verified SUBSCRIBERS',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'RobotoMono',
                fontSize: 12.sp,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _roundedButton('SHUFFLE', Icons.shuffle, theme, onTap: () {}),
                SizedBox(width: 20.w),
                _roundedButton('FOLLOW', Icons.add, theme, onTap: () {}),
              ],
            ),
            SizedBox(height: 32.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'POPULAR TRACKS',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '${artistState.songs.length} TRACKS TOTAL',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'RobotoMono',
                      fontSize: 10.sp,
                      letterSpacing: 1.5,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _displayedTracks.length,
              separatorBuilder: (context, index) =>
                  Divider(color: theme.dividerColor, height: 1.h),
              itemBuilder: (context, index) {
                final track = _displayedTracks[index];
                return _trackTile(index + 1, track, theme);
              },
            ),

            SizedBox(height: 20.h),

            if (_showLoadAllButton)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0.w),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.dividerColor, width: 1.5.w),
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                    ),
                    onPressed: () => _loadAllTracks(artistState.songs),
                    child: Text(
                      'LOAD ALL TRACKS',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'RobotoMono',
                        fontSize: 13.sp,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: 28.h),
          ],
        ),
      ),
    );
  }

  Widget _roundedButton(
    String label,
    IconData icon,
    ThemeData theme, {
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: theme.dividerColor, width: 2.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18.sp, color: theme.iconTheme.color),
      label: Text(
        label,
        style: TextStyle(
          color: theme.textTheme.bodyLarge?.color,
          fontWeight: FontWeight.bold,
          fontSize: 12.sp,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _trackTile(int number, SongModel track, ThemeData theme) {
    return GestureDetector(
      onTap: () => _handleSongTap(track),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 10.h),
        child: Row(
          children: [
            SizedBox(
              width: 24.w,
              child: Text(
                number.toString().padLeft(2, '0'),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'RobotoMono',
                  fontSize: 12.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: 13.sp,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    track.genre,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'RobotoMono',
                      fontSize: 10.sp,
                      letterSpacing: 1.1,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 8.w),
            IconButton(
              icon: Icon(
                Icons.more_horiz,
                color: theme.iconTheme.color?.withOpacity(0.5),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => NetworkSongOptionsWidget(
                    songId: track.id,
                    title: track.title,
                    artist: track.genre,
                    imageUrl: track.imageUrl,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
