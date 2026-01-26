import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:musicapp/models/download_metadata_model.dart';

class DownloadProgressTile extends StatelessWidget {
  final DownloadTaskModel task;
  final bool isDarkTheme;
  final VoidCallback? onCancel;

  const DownloadProgressTile({
    super.key,
    required this.task,
    required this.isDarkTheme,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : const Color(0xffffffff);
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final subTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey[600];

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: task.metadata?.thumbnail != null
                    ? CachedNetworkImage(
                        imageUrl: task.metadata!.thumbnail!,
                        width: 50.w,
                        height: 50.w,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholderIcon(),
                        errorWidget: (_, __, ___) => _placeholderIcon(),
                      )
                    : _placeholderIcon(),
              ),
              SizedBox(width: 12.w),

              // Title & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.metadata?.title ?? 'Loading...',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Icon or Cancel Button
              if (task.status == DownloadStatus.completed)
                Icon(Icons.check_circle, color: Colors.green, size: 24.sp)
              else if (task.status == DownloadStatus.failed)
                Icon(Icons.error, color: Colors.red, size: 24.sp)
              else
                SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: CircularProgressIndicator(
                    value: task.status == DownloadStatus.downloading
                        ? task.progress
                        : null,
                    strokeWidth: 2.5,
                    color: const Color(0xFF1DB954),
                  ),
                ),
            ],
          ),

          // Progress Bar (only during download)
          if (task.status == DownloadStatus.downloading) ...[
            SizedBox(height: 10.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: task.progress,
                backgroundColor: subTextColor?.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF1DB954),
                ),
                minHeight: 4.h,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '${(task.progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: subTextColor, fontSize: 10.sp),
            ),
          ],

          // Error Message
          if (task.status == DownloadStatus.failed &&
              task.errorMessage != null) ...[
            SizedBox(height: 8.h),
            Text(
              task.errorMessage!,
              style: TextStyle(color: Colors.red[300], fontSize: 10.sp),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 50.w,
      height: 50.w,
      color: Colors.grey[800],
      child: Icon(Icons.music_note, color: Colors.grey[600], size: 24.sp),
    );
  }

  String _getStatusText() {
    switch (task.status) {
      case DownloadStatus.pending:
        return 'Waiting...';
      case DownloadStatus.fetchingMetadata:
        return 'Fetching info...';
      case DownloadStatus.converting:
        return 'Converting to MP3...';
      case DownloadStatus.downloading:
        return 'Downloading...';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
    }
  }

  Color _getStatusColor() {
    switch (task.status) {
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
