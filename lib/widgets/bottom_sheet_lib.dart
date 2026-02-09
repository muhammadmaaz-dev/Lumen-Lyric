import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/widgets/playlist_dialog.dart';
import 'package:on_audio_query/on_audio_query.dart'; // ✅ Import Added
import 'package:musicapp/provider/download_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NetworkSongOptionsWidget extends ConsumerWidget {
  final String songId; // This acts as the video ID
  final String title;
  final String artist;
  final String imageUrl;

  const NetworkSongOptionsWidget({
    super.key,
    required this.songId,
    required this.title,
    required this.artist,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),

          // Header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  imageUrl,
                  width: 55.h,
                  height: 55.h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 55.h,
                    height: 55.h,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      artist,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Divider(color: Colors.white12, thickness: 1.h),
          SizedBox(height: 12.h),

          // Download Action
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.download_rounded,
              color: Colors.white,
              size: 26.sp,
            ),
            title: Text(
              "Download",
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
            ),
            onTap: () {
              Navigator.pop(context);
              final url = "https://youtube.com/watch?v=$songId";
              ref.read(downloadControllerProvider).addToQueue(url);
              Fluttertoast.showToast(msg: "Download started...");
            },
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

class SongOptionsWidget extends ConsumerWidget {
  final int songId;
  final String title;
  final String artist;
  final String filePath;
  final String? imageUrl;

  const SongOptionsWidget({
    super.key,
    required this.songId,
    required this.title,
    required this.artist,
    required this.filePath,
    this.imageUrl,
  });

  void _showRenameDialog(BuildContext context) {
    final TextEditingController textController = TextEditingController(
      text: title,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Rename Song",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: textController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter new title",
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  AudioController.instance.renameSong(
                    songId,
                    textController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<List<LocalSongModel>>(
      valueListenable: AudioController.instance.songs,
      builder: (context, songs, child) {
        // Find the song to get live updates (Like status, Artwork URL)
        final song = songs.firstWhere(
          (element) => element.id == songId,
          orElse: () => LocalSongModel(
            id: -1,
            title: title,
            artist: artist,
            uri: filePath,
            albumArt: '',
            duration: 0,
            isLiked: false,
            // Fallback artwork URL from constructor if song not found in list
            artworkUrl: imageUrl,
          ),
        );

        final isLiked = song.isLiked;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Container(
                width: 35.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 18.h),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              Row(
                children: [
                  // ✅ Updated Artwork Logic
                  Container(
                    width: 44.w,
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: _buildArtwork(song),
                    ),
                  ),
                  SizedBox(width: 13.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          artist == "<unknown>" ? "Unknown Artist" : artist,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      AudioController.instance.toggleLike(songId);
                    },
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 18.h),
              const Divider(color: Colors.white12, thickness: 1),
              SizedBox(height: 18.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionBox(
                    Icons.edit,
                    "Edit",
                    onTap: () => _showRenameDialog(context),
                  ),
                  SizedBox(width: 9.w),
                  _buildActionBox(
                    Icons.playlist_add,
                    "Add to playlist",
                    onTap: () {
                      Navigator.pop(context);
                      PlaylistSelectorDialog.show(context, songId);
                    },
                  ),
                ],
              ),

              SizedBox(height: 18.h),
              const Divider(color: Colors.white12, thickness: 1),

              _buildListTile(
                Icons.offline_pin_outlined,
                "Remove download",
                textColor: const Color(0xFFD85D5D),
                iconColor: const Color(0xFFD85D5D),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      title: const Text(
                        "Delete Song?",
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        "Are you sure you want to delete this file from your device?",
                        style: TextStyle(color: Colors.grey),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            AudioController.instance.deleteSong(
                              songId,
                              filePath,
                            );
                            Navigator.pop(context); // Close Alert
                            Navigator.pop(context); // Close BottomSheet
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArtwork(LocalSongModel song) {
    if (song.artworkUrl != null && song.artworkUrl!.isNotEmpty) {
      return _buildImageFromPath(song.artworkUrl!);
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return _buildImageFromPath(imageUrl!);
    }
    return _buildLocalArtwork();
  }

  Widget _buildImageFromPath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildLocalArtwork(),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildLocalArtwork(),
        );
      }
      return _buildLocalArtwork();
    }
  }

  Widget _buildLocalArtwork() {
    return QueryArtworkWidget(
      id: songId,
      type: ArtworkType.AUDIO,
      nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white),
    );
  }

  Widget _buildActionBox(
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF303030),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 26.sp),
              SizedBox(height: 8.h),
              Text(
                label,
                style: TextStyle(color: Colors.white, fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title, {
    Color iconColor = Colors.grey,
    Color textColor = Colors.white,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: iconColor == Colors.grey ? Colors.grey[400] : iconColor,
        size: 26.sp,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
