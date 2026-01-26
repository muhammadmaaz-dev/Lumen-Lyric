import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/controller/download_controller.dart';
import 'package:musicapp/models/download_metadata_model.dart';
import 'package:musicapp/widgets/custom_text_field.dart';
import 'package:musicapp/widgets/section_header.dart';
import 'package:musicapp/widgets/song_tile.dart';
import 'package:musicapp/widgets/download_progress_tile.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final TextEditingController _urlController = TextEditingController();
  final DownloadController _downloadController = DownloadController.instance;

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

  // ✅ New Logic: Direct Download
  Future<void> _processUrl(String rawUrl) async {
    final url = rawUrl.trim();
    if (url.isEmpty) return;

    if (!_downloadController.isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid YouTube URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Direct Queue Add
      await _downloadController.addToQueue(url);

      // Cleanup UI
      _urlController.clear();
      FocusScope.of(context).unfocus();

      // Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to download queue...'),
          backgroundColor: Color(0xFF1DB954),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ✅ SMART BUTTON LOGIC (2-in-1)
  Future<void> _handleSmartConvert() async {
    final currentText = _urlController.text.trim();

    if (currentText.isEmpty) {
      // Case 1: Agar khali hai -> Paste & Download
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null &&
          clipboardData!.text!.trim().isNotEmpty) {
        final pastedUrl = clipboardData.text!.trim();

        // UI Update karein taake user ko link nazar aaye
        setState(() {
          _urlController.text = pastedUrl;
        });

        // Process karein
        _processUrl(pastedUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Case 2: Agar text hai -> Direct Download
      _processUrl(currentText);
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

                    // 2. Input Field (Single Widget with Smart Button)
                    CustomTextField(
                      controller: _urlController,
                      hintText: 'Paste YouTube Link...',
                      // ✅ Yeh icon ab 2 kaam karega: Paste & Convert
                      suffixIcon: Icons.download_rounded,
                      onSuffixTap: _handleSmartConvert,
                      isDarkTheme: isDarkTheme,
                      onSubmitted: (val) => _processUrl(val), // Keyboard 'Done'
                      onChanged: (_) {},
                    ),

                    SizedBox(height: 18.h),

                    // 3. Info Box
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
                            Icons.info_outline,
                            size: 20.sp,
                            color: textColor.withOpacity(0.7),
                          ),
                          SizedBox(width: 13.w),
                          Expanded(
                            child: Text(
                              'On free servers, the first request may take up to 50 seconds if server is not idle also conversion time depends on video size',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: textColor.withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 26.h),

                    // 4. Active Downloads Section
                    ValueListenableBuilder<List<DownloadTaskModel>>(
                      valueListenable: _downloadController.downloadQueue,
                      builder: (context, queue, _) {
                        final activeDownloads = queue
                            .where((t) => t.status != DownloadStatus.completed)
                            .toList();

                        if (activeDownloads.isEmpty)
                          return const SizedBox.shrink();

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

                    // 5. Recent Conversions
                    SectionHeader(
                      title: 'Recent Downloads',
                      actionText: 'Clear',
                      onActionTap: () =>
                          _downloadController.clearRecentDownloads(),
                      textColor: textColor,
                    ),
                    SizedBox(height: 13.h),

                    // 6. Recent Downloads List
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
                                    Icons.download_done,
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
                              imageUrl: task.metadata?.thumbnail,
                              isDarkTheme: isDarkTheme,
                              onTap: () {
                                // Find and play song
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
}
