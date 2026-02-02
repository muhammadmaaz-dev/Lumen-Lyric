import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart'; // This requires the package added above
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/provider/playlist_provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongPickerScreen extends ConsumerStatefulWidget {
  final String playlistId;

  const SongPickerScreen({super.key, required this.playlistId});

  // Helper method to show this screen comfortably
  static Future<List<int>?> show(BuildContext context, String playlistId) {
    return showCupertinoModalBottomSheet<List<int>>(
      context: context,
      backgroundColor: Colors.transparent, // Let the Scaffold handle color
      builder: (context) => SongPickerScreen(playlistId: playlistId),
    );
  }

  @override
  ConsumerState<SongPickerScreen> createState() => _SongPickerScreenState();
}

class _SongPickerScreenState extends ConsumerState<SongPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedSongIds = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LocalSongModel> _getFilteredSongs() {
    final allSongs = AudioController.instance.songs.value;
    final playlist = ref.read(playlistByIdProvider(widget.playlistId));

    // Filter out songs already in the playlist
    final existingSongIds = playlist?.songIds.toSet() ?? {};
    var availableSongs = allSongs
        .where((song) => !existingSongIds.contains(song.id))
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      availableSongs = availableSongs.where((song) {
        return song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            song.artist.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return availableSongs;
  }

  void _toggleSelection(int songId) {
    setState(() {
      if (_selectedSongIds.contains(songId)) {
        _selectedSongIds.remove(songId);
      } else {
        _selectedSongIds.add(songId);
      }
    });
  }

  void _confirmSelection() {
    Navigator.of(context).pop(_selectedSongIds.toList());
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : const Color(0xfff3f4f6);
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final cardColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : const Color(0xffffffff);
    final hintColor = isDarkTheme ? Colors.grey[500] : Colors.grey[600];
    final secondaryTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey;

    final filteredSongs = _getFilteredSongs();

    return Material(
      color: backgroundColor,
      child: Scaffold(
        backgroundColor: backgroundColor,
        // Using a Scaffold AppBar ensures it stays pinned at the top while scrolling
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.close, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Add Songs',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          actions: [
            if (_selectedSongIds.isNotEmpty)
              TextButton(
                onPressed: _confirmSelection,
                child: Text(
                  'Add (${_selectedSongIds.length})',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.all(14.r),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search songs...',
                  hintStyle: TextStyle(color: hintColor),
                  prefixIcon: Icon(Icons.search, color: hintColor),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Selected count indicator
            if (_selectedSongIds.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 11.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkTheme ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: Text(
                        '${_selectedSongIds.length} selected',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.black : Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 7.w),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedSongIds.clear();
                        });
                      },
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Songs List
            Expanded(
              child: filteredSongs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.music_off_rounded,
                            size: 48,
                            color: secondaryTextColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'All songs are already in the playlist'
                                : 'No songs found',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      // IMPORTANT: Links scrolling to the Bottom Sheet drag gestures
                      controller: ModalScrollController.of(context),
                      // Add padding at bottom to avoid FAB covering last item
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = filteredSongs[index];
                        final isSelected = _selectedSongIds.contains(song.id);

                        return _buildSongTile(
                          song: song,
                          isSelected: isSelected,
                          isDarkTheme: isDarkTheme,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () => _toggleSelection(song.id),
                        );
                      },
                    ),
            ),
          ],
        ),
        // FAB wrapped in SafeArea for bottom sheet usage
        floatingActionButton: _selectedSongIds.isNotEmpty
            ? SafeArea(
                child: FloatingActionButton.extended(
                  onPressed: _confirmSelection,
                  backgroundColor: isDarkTheme ? Colors.white : Colors.black,
                  icon: Icon(
                    Icons.add,
                    color: isDarkTheme ? Colors.black : Colors.white,
                  ),
                  label: Text(
                    'Add ${_selectedSongIds.length} songs',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildSongTile({
    required LocalSongModel song,
    required bool isSelected,
    required bool isDarkTheme,
    required Color textColor,
    required Color? secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkTheme
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Selection checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? (isDarkTheme ? Colors.white : Colors.black)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? (isDarkTheme ? Colors.white : Colors.black)
                        : (isDarkTheme ? Colors.grey[600]! : Colors.grey[400]!),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: isDarkTheme ? Colors.black : Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Album Art
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDarkTheme
                      ? const Color(0xff2a2a2a)
                      : const Color(0xfff0f0f0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildSongArtwork(song, secondaryTextColor),
                ),
              ),
              const SizedBox(width: 12),

              // Title and info
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${song.artist} • ${_formatDuration(song.duration)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: secondaryTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongArtwork(LocalSongModel song, Color? secondaryTextColor) {
    // 1. Check if artworkUrl exists (for downloaded songs)
    if (song.artworkUrl != null && song.artworkUrl!.isNotEmpty) {
      final artworkPath = song.artworkUrl!;

      // Check if it's a local file or network URL
      if (artworkPath.startsWith('http://') ||
          artworkPath.startsWith('https://')) {
        return Image.network(
          artworkPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultSongArtwork(song, secondaryTextColor);
          },
        );
      } else {
        // Local file path
        final file = File(artworkPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultSongArtwork(song, secondaryTextColor);
            },
          );
        }
      }
    }

    // 2. Fallback to local artwork
    return _buildDefaultSongArtwork(song, secondaryTextColor);
  }

  Widget _buildDefaultSongArtwork(
    LocalSongModel song,
    Color? secondaryTextColor,
  ) {
    return QueryArtworkWidget(
      id: song.id,
      type: ArtworkType.AUDIO,
      nullArtworkWidget: Icon(
        Icons.music_note,
        color: secondaryTextColor,
        size: 24,
      ),
    );
  }
}
