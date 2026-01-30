class DownloadMetadataModel {
  final String? title;
  final String? artist;
  final String? album;
  final String? duration; // Changed to String to handle both formats safely
  final String? thumbnailUrl; // ✅ Renamed from 'thumbnail' to match Service
  final String? description;
  final List<String>? tags;
  final String? channel;
  final String? uploadDate;

  DownloadMetadataModel({
    this.title,
    this.artist,
    this.album,
    this.duration,
    this.thumbnailUrl,
    this.description,
    this.tags,
    this.channel,
    this.uploadDate,
  });

  factory DownloadMetadataModel.fromJson(Map<String, dynamic> json) {
    return DownloadMetadataModel(
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      // Safely handle duration whether it comes as int or String
      duration: json['duration']?.toString(),
      // Handle both keys just in case
      thumbnailUrl:
          json['thumbnail'] as String? ?? json['thumbnail_url'] as String?,
      description: json['description'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      channel: json['channel'] as String?,
      uploadDate: json['upload_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'thumbnail': thumbnailUrl, // Saving as 'thumbnail' for consistency
      'description': description,
      'tags': tags,
      'channel': channel,
      'upload_date': uploadDate,
    };
  }
}

class DownloadTaskModel {
  final String id;
  final String youtubeUrl;
  final DownloadMetadataModel? metadata;
  final DownloadStatus status;
  final double progress;
  final String? filePath;
  final String? localImagePath; // ✅ Added to store offline image path
  final String? errorMessage;
  final DateTime createdAt;

  DownloadTaskModel({
    required this.id,
    required this.youtubeUrl,
    this.metadata,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.filePath,
    this.localImagePath,
    this.errorMessage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  DownloadTaskModel copyWith({
    String? id,
    String? youtubeUrl,
    DownloadMetadataModel? metadata,
    DownloadStatus? status,
    double? progress,
    String? filePath,
    String? localImagePath,
    String? errorMessage,
  }) {
    return DownloadTaskModel(
      id: id ?? this.id,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      localImagePath: localImagePath ?? this.localImagePath,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt,
    );
  }
}

enum DownloadStatus {
  pending,
  fetchingMetadata,
  converting,
  downloading,
  completed,
  failed,
}
