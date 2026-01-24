import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/controller/audio_controller.dart';
import 'package:musicapp/models/local_song_model.dart';
import 'package:musicapp/widgets/playlist_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Required for saving

class SongOptionsWidget extends ConsumerWidget {
  final int songId;
  final String title;
  final String artist;
  final String filePath;

  const SongOptionsWidget({
    super.key,
    required this.songId,
    required this.title,
    required this.artist,
    required this.filePath,
  });

  // ✅ Function to show Rename Dialog
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
                  // Controller ke through rename karein
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

              // 2. Song Header
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: Container(
                      width: 44.w,
                      height: 44.h,
                      color: Colors.grey[800],
                      child: Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 21.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 13.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title, // Use live title from controller
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

              // 3. Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // ✅ Pass the onEdit function here
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
                    }, // Add logic later
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
                            Navigator.pop(context);
                            Navigator.pop(context);
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

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ✅ Updated Helper: Added onTap
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
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
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
        size: 26,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
