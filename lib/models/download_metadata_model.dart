class DownloadMetadataModel {
  final String? title;
  final String? artist;
  final String? album;
  final int? duration;
  final String? thumbnail;
  final String? description;
  final List<String>? tags;
  final String? channel;
  final String? uploadDate;

  DownloadMetadataModel({
    this.title,
    this.artist,
    this.album,
    this.duration,
    this.thumbnail,
    this.description,
    this.tags,
    this.channel,
    this.uploadDate,
  });

  factory DownloadMetadataModel.fromJson(Map<String, dynamic> json) {
    return DownloadMetadataModel(
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      duration: json['duration'],
      thumbnail: json['thumbnail'],
      description: json['description'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      channel: json['channel'],
      uploadDate: json['upload_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'thumbnail': thumbnail,
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
  final String? errorMessage;
  final DateTime createdAt;

  DownloadTaskModel({
    required this.id,
    required this.youtubeUrl,
    this.metadata,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.filePath,
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
    String? errorMessage,
  }) {
    return DownloadTaskModel(
      id: id ?? this.id,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
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