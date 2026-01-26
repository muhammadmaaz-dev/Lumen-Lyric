import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/controller/download_controller.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/models/download_metadata_model.dart';
import 'package:musicapp/widgets/custom_text_field.dart';
import 'package:musicapp/widgets/section_header.dart';
import 'package:musicapp/widgets/song_tile.dart';
import 'package:musicapp/widgets/download_progress_tile.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final TextEditingController _urlController = TextEditingController();
  final DownloadController _downloadController = DownloadController.instance;

  bool _isLoadingPreview = false;
  DownloadMetadataModel? _previewMetadata;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _downloadController.init();
    if (AudioController.instance.songs.value.isEmpty) {
      AudioController.instance.loadSongs();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _fetchPreview() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() => _errorMessage = 'Please paste a YouTube link');
      return;
    }

    if (!_downloadController.isValidUrl(url)) {
      setState(() => _errorMessage = 'Invalid YouTube URL');
      return;
    }

    setState(() {
      _isLoadingPreview = true;
      _errorMessage = null;
      _previewMetadata = null;
    });

    try {
      final metadata = await _downloadController.getMetadata(url);
      if (mounted) {
        setState(() {
          _previewMetadata = metadata;
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoadingPreview = false;
        });
      }
    }
  }

  Future<void> _startDownload() async {
    final url = _urlController.text.trim();

    try {
      await _downloadController.addToQueue(url);

      // Clear input and preview
      _urlController.clear();
      setState(() {
        _previewMetadata = null;
        _errorMessage = null;
      });

      // Show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Download started: ${_previewMetadata?.title ?? 'Song'}',
            ),
            backgroundColor: const Color(0xFF1DB954),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      _urlController.text = clipboardData!.text!;
      _fetchPreview();
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
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _urlController,
                            hintText: 'Paste YouTube Link Here...',
                            suffixIcon: Icons.content_paste,
                            onSuffixTap: _pasteFromClipboard,
                            isDarkTheme: isDarkTheme,
                            onChanged: (_) {
                              // Clear preview when text changes
                              if (_previewMetadata != null) {
                                setState(() => _previewMetadata = null);
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 10.w),
                        // Fetch Button
                        GestureDetector(
                          onTap: _isLoadingPreview ? null : _fetchPreview,
                          child: Container(
                            width: 44.w,
                            height: 44.h,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1DB954),
                              borderRadius: BorderRadius.circular(22.r),
                            ),
                            child: _isLoadingPreview
                                ? Padding(
                                    padding: EdgeInsets.all(12.r),
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 22.sp,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // 3. Error Message
                    if (_errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 4. Preview Card (when metadata is loaded)
                    if (_previewMetadata != null) ...[
                      SizedBox(height: 18.h),
                      _buildPreviewCard(cardColor, textColor, isDarkTheme),
                    ],

                    SizedBox(height: 18.h),

                    // 5. Info Box
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 13.h,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
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
                              'Converting may take few seconds depending on video length',
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

                    // 6. Active Downloads Section
                    ValueListenableBuilder<List<DownloadTaskModel>>(
                      valueListenable: _downloadController.downloadQueue,
                      builder: (context, queue, _) {
                        final activeDownloads = queue
                            .where((t) => t.status != DownloadStatus.completed)
                            .toList();

                        if (activeDownloads.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              title: 'Downloading',
                              actionText: '',
                              onActionTap: () {},
                              textColor: textColor,
                            ),
                            SizedBox(height: 13.h),
                            ...activeDownloads.map(
                              (task) => DownloadProgressTile(
                                task: task,
                                isDarkTheme: isDarkTheme,
                              ),
                            ),
                            SizedBox(height: 18.h),
                          ],
                        );
                      },
                    ),

                    // 7. Recent Conversions Section Header
                    SectionHeader(
                      title: 'Recent Conversions',
                      actionText: 'Clear',
                      onActionTap: () {
                        _downloadController.clearRecentDownloads();
                      },
                      textColor: textColor,
                    ),
                    SizedBox(height: 13.h),

                    // 8. Recent Downloads List
                    ValueListenableBuilder<List<DownloadTaskModel>>(
                      valueListenable: _downloadController.recentDownloads,
                      builder: (context, recentDownloads, _) {
                        if (recentDownloads.isEmpty) {
                          return Container(
                            padding: EdgeInsets.all(40.r),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.download_outlined,
                                    size: 48.sp,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    'No recent downloads',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentDownloads.length,
                          itemBuilder: (context, index) {
                            final task = recentDownloads[index];
                            return SongTile(
                              title: task.metadata?.title ?? 'Unknown',
                              artist: task.metadata?.artist ?? 'Unknown Artist',
                              duration: (task.metadata?.duration ?? 0) * 1000,
                              songId: task.id.hashCode,
                              onTap: () {
                                // Find and play the song
                                final songs =
                                    AudioController.instance.songs.value;
                                final songIndex = songs.indexWhere(
                                  (s) => s.uri.contains(
                                    task.filePath?.split('/').last ?? '',
                                  ),
                                );
                                if (songIndex != -1) {
                                  AudioController.instance.playSong(songIndex);
                                }
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

  Widget _buildPreviewCard(Color cardColor, Color textColor, bool isDarkTheme) {
    final metadata = _previewMetadata!;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF1DB954).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail & Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: metadata.thumbnail != null
                    ? CachedNetworkImage(
                        imageUrl: metadata.thumbnail!,
                        width: 80.w,
                        height: 80.w,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 80.w,
                          height: 80.w,
                          color: Colors.grey[800],
                          child: Icon(
                            Icons.music_note,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : Container(
                        width: 80.w,
                        height: 80.w,
                        color: Colors.grey[800],
                        child: Icon(Icons.music_note, color: Colors.grey[600]),
                      ),
              ),
              SizedBox(width: 14.w),

              // Title, Artist, Duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata.title ?? 'Unknown Title',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      metadata.artist ?? metadata.channel ?? 'Unknown Artist',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    if (metadata.duration != null)
                      Text(
                        _formatDuration(metadata.duration!),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Download Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startDownload,
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text(
                'Download MP3',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}
