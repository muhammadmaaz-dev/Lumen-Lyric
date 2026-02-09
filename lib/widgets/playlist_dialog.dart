import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musicapp/models/playlist_model.dart';
import 'package:musicapp/provider/playlist_provider.dart';

class PlaylistDialog extends StatefulWidget {
  final String? initialName;
  final bool isEditing;

  const PlaylistDialog({super.key, this.initialName, this.isEditing = false});

  static Future<String?> show({
    required BuildContext context,
    String? initialName,
    bool isEditing = false,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          PlaylistDialog(initialName: initialName, isEditing: isEditing),
    );
  }

  @override
  State<PlaylistDialog> createState() => _PlaylistDialogState();
}

class _PlaylistDialogState extends State<PlaylistDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorText = 'Playlist name cannot be empty';
      });
      return;
    }

    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final hintColor = isDarkTheme ? Colors.grey[500] : Colors.grey[600];
    final borderColor = isDarkTheme ? Colors.grey[700] : Colors.grey[300];
    final errorColor = Colors.red[400];
    final cancelButtonColor = isDarkTheme ? Colors.grey[800] : Colors.grey[200];

    return Dialog(
      backgroundColor: backgroundColor,
      // ✅ Removed const because .r is calculated at runtime
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(22.r), // ✅ Removed const
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              widget.isEditing ? 'Edit Playlist' : 'Create Playlist',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 24.h), // ✅ Removed const
            // Text Field
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Enter playlist name',
                hintStyle: TextStyle(color: hintColor),
                errorText: _errorText,
                errorStyle: TextStyle(color: errorColor),
                filled: true,
                fillColor: isDarkTheme ? Colors.grey[900] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: borderColor!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: textColor, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: errorColor!),
                ),
                // ✅ FIXED: Removed 'const' here which caused the build error
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              onSubmitted: (_) => _validateAndSubmit(),
              textInputAction: TextInputAction.done,
            ),

            SizedBox(height: 24.h),

            // Buttons Row
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: cancelButtonColor,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // Create/Save Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _validateAndSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkTheme
                          ? Colors.white
                          : Colors.black,
                      foregroundColor: isDarkTheme
                          ? Colors.black
                          : Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.isEditing ? 'Save' : 'Create',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A confirmation dialog for deleting playlists.
class DeletePlaylistDialog extends StatelessWidget {
  final String playlistName;

  const DeletePlaylistDialog({super.key, required this.playlistName});

  static Future<bool> show({
    required BuildContext context,
    required String playlistName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => DeletePlaylistDialog(playlistName: playlistName),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final subtitleColor = isDarkTheme ? Colors.grey[400] : Colors.grey[600];
    final cancelButtonColor = isDarkTheme ? Colors.grey[800] : Colors.grey[200];

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
      ), // ✅ Removed const
      child: Padding(
        padding: EdgeInsets.all(22.r), // ✅ Removed const
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning Icon
            Icon(
              Icons.warning_amber_rounded,
              size: 44.sp,
              color: Colors.orange[400],
            ),

            SizedBox(height: 16.h),

            // Title
            Text(
              'Delete Playlist?',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12.h),

            // Subtitle
            Text(
              'Are you sure you want to delete "$playlistName"? This action cannot be undone.',
              style: TextStyle(fontSize: 12.sp, color: subtitleColor),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 24.h),

            // Buttons Row
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor: cancelButtonColor,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[500],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog to select an EXISTING playlist only
class PlaylistSelectorDialog extends ConsumerWidget {
  final int songId;

  const PlaylistSelectorDialog({super.key, required this.songId});

  static Future<void> show(BuildContext context, int songId) {
    return showDialog(
      context: context,
      builder: (context) => PlaylistSelectorDialog(songId: songId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final itemColor = isDarkTheme ? Colors.grey[800] : Colors.grey[100];

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ), // ✅ Removed const
      child: Padding(
        padding: EdgeInsets.all(20.r), // ✅ Removed const
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add to Playlist',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),

            // Existing Playlists List
            Flexible(
              child: SizedBox(
                height: 200.h,
                child: playlists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.playlist_remove,
                              size: 40.sp,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              "No playlists found",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14.sp,
                              ),
                            ),
                            Text(
                              "Create one from setting first",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: playlists.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          final alreadyInPlaylist = playlist.songIds.contains(
                            songId,
                          );

                          return InkWell(
                            onTap: () async {
                              if (alreadyInPlaylist) {
                                Fluttertoast.showToast(
                                  msg: 'Already in playlist',
                                );
                                return;
                              }

                              await ref
                                  .read(playlistProvider.notifier)
                                  .addSongToPlaylist(playlist.id, songId);

                              if (context.mounted) {
                                Navigator.pop(context);
                                Fluttertoast.showToast(
                                  msg: 'Added to "${playlist.name}"',
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 12.h,
                                horizontal: 16.w,
                              ),
                              decoration: BoxDecoration(
                                color: itemColor,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.queue_music_rounded,
                                    color: textColor.withOpacity(0.7),
                                    size: 22.sp,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Text(
                                      playlist.name,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (alreadyInPlaylist)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18.sp,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            SizedBox(height: 16.h),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
