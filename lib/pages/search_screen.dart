import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/models/song_model.dart';
import 'package:musicapp/provider/audio_provider.dart';
import 'package:musicapp/provider/search_provider.dart'; // Ensure ye file bani ho
import 'package:musicapp/services/youtube_service.dart'; // Ensure ye file bani ho

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isNavigating = false; // Double tap prevent karne ke liye

  @override
  void initState() {
    super.initState();
    // Screen khulte hi search clear kar dein agar zaroorat ho
    // Future.microtask(() => ref.read(searchQueryProvider.notifier).state = '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- Search Logic with Debounce ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // 600ms ka wait taake har letter pe request na jaye
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).state = query;
      }
    });
  }

  // --- Clear Search ---
  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  // --- Play Song Logic ---
  Future<void> _playOnlineSong(SongModel song) async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    try {
      // 1. User ko feedback dein
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fetching stream for: ${song.title}...'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 2. Stream URL fetch karein (YoutubeService se)
      final youtubeService = ref.read(youtubeServiceProvider);
      final streamUrl = await youtubeService.getAudioStreamUrl(song.id);

      // 3. Audio Controller ke through play karein
      final audioController = ref.read(audioControllerProvider);
      await audioController.playNetworkAudio(streamUrl, song);

      // Optional: Agar player screen pe le jana ho to navigate karein
      // Navigator.push(context, MaterialPageRoute(builder: (_) => FullPlayer()));
    } catch (e) {
      debugPrint("Error playing song: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Riverpod se state watch kar rahe hain
    final searchResultsValue = ref.watch(searchResultsProvider);
    final currentQuery = ref.watch(searchQueryProvider);

    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : const Color(0xfff3f4f6);
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkTheme
        ? Colors.grey[400]
        : Colors.grey[600];
    final borderColor = isDarkTheme ? Colors.grey[800] : Colors.grey[300];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- Search Bar Header ---
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: borderColor ?? Colors.grey,
                    width: 0.5.h,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back,
                      color: textColor,
                      size: 21.sp,
                    ),
                  ),
                  SizedBox(width: 11.w),

                  // Search Input
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(color: textColor, fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: 'Search Online Music...',
                        hintStyle: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),

                  // Clear Button
                  if (currentQuery.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Icon(
                        Icons.close,
                        color: secondaryTextColor,
                        size: 18.sp,
                      ),
                    ),
                ],
              ),
            ),

            // --- Search Results List ---
            Expanded(
              child: searchResultsValue.when(
                data: (songs) {
                  if (songs.isEmpty) {
                    // Empty State
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 60,
                            color: secondaryTextColor?.withOpacity(0.5),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            currentQuery.isEmpty
                                ? 'Type to search songs'
                                : 'No results found',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Results List
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return _buildSongItem(
                        song,
                        textColor,
                        secondaryTextColor,
                      );
                    },
                  );
                },
                // Loading State
                loading: () => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor,
                  ),
                ),
                // Error State
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Error: $error',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget: Individual Song Tile ---
  Widget _buildSongItem(
    SongModel song,
    Color textColor,
    Color? secondaryTextColor,
  ) {
    return InkWell(
      onTap: () => _playOnlineSong(song),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Row(
          children: [
            // Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: Image.network(
                song.imageUrl,
                width: 45.w,
                height: 45.w,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 45.w,
                    height: 45.w,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, color: Colors.white),
                  );
                },
              ),
            ),
            SizedBox(width: 14.w),

            // Song Title & Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    song.genre, // Using genre field for Artist Name as per logic
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),

            // Play Icon
            Icon(
              Icons.play_circle_outline,
              color: secondaryTextColor,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
}
