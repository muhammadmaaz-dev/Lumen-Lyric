import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicapp/controller/audio_controller.dart'; // Controller Import
import 'package:musicapp/models/local_song_model.dart'; // Model Import

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hum AudioController ko sunenge taake status update ho sake
    return ValueListenableBuilder<List<LocalSongModel>>(
      valueListenable: AudioController.instance.songs,
      builder: (context, songs, child) {
        // Current Song ko list mein dhundo
        // (Taake hamein latest isLiked status mile)
        final song = songs.firstWhere(
          (element) => element.id == songId,
          orElse: () => LocalSongModel(
            id: -1,
            title: title,
            artist: artist,
            uri: filePath,
            albumArt: '',
            duration: 0,
            isLiked: false, // Default
          ),
        );

        final isLiked = song.isLiked;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 2. Song Header
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artist == "<unknown>" ? "Unknown Artist" : artist,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // --- LIKE BUTTON (Connected to Controller) ---
                  IconButton(
                    onPressed: () {
                      // Controller ko bolo Like toggle kare
                      AudioController.instance.toggleLike(songId);
                    },
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.white12, thickness: 1),
              const SizedBox(height: 20),

              // 3. Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionBox(Icons.edit, "Edit"),
                  const SizedBox(width: 10),
                  _buildActionBox(Icons.playlist_add, "Add to playlist"),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.white12, thickness: 1),

              // 4. List Options
              _buildListTile(
                Icons.library_add_check_outlined,
                "Add to library",
              ),

              // --- DELETE OPTION (Connected to Controller) ---
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
                            // 1. Controller se delete function call
                            AudioController.instance.deleteSong(
                              songId,
                              filePath,
                            );

                            // 2. Dialog Band
                            Navigator.pop(context);

                            // 3. Bottom Sheet Band
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

  // --- Helpers ---

  Widget _buildActionBox(IconData icon, String label) {
    return Expanded(
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
