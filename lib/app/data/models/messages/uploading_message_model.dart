import 'package:crypted_app/app/data/models/messages/message_model.dart';

/// Temporary message model for uploads in progress
class UploadingMessage extends Message {
  final String filePath;
  final String fileName;
  final int fileSize;
  final String uploadType; // 'image', 'video', 'file', 'audio'
  final double progress; // 0.0 to 1.0
  final String? thumbnailPath;

  UploadingMessage({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    super.reactions = const [],
    super.replyTo,
    super.isPinned = false,
    super.isFavorite = false,
    super.isDeleted = false,
    super.isForwarded = false,
    super.forwardedFrom,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.uploadType,
    this.progress = 0.0,
    this.thumbnailPath,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.baseMap(),
      'type': 'uploading',
      'filePath': filePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'uploadType': uploadType,
      'progress': progress,
      'thumbnailPath': thumbnailPath,
    };
  }

  @override
  UploadingMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    List<Reaction>? reactions,
    ReplyToMessage? replyTo,
    bool? isPinned,
    bool? isFavorite,
    bool? isDeleted,
    bool? isForwarded,
    String? forwardedFrom,
    String? filePath,
    String? fileName,
    int? fileSize,
    String? uploadType,
    double? progress,
    String? thumbnailPath,
  }) {
    return UploadingMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
      isForwarded: isForwarded ?? this.isForwarded,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      uploadType: uploadType ?? this.uploadType,
      progress: progress ?? this.progress,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}
