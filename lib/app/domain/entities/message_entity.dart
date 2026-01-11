// ARCH-005 FIX: Domain Layer Message Entities
// Pure domain entities decoupled from Firebase/data layer

import 'package:equatable/equatable.dart';

/// Base domain entity for all message types
/// Independent of Firestore structure
abstract class MessageEntity extends Equatable {
  final String id;
  final String roomId;
  final String senderId;
  final DateTime timestamp;
  final MessageType type;
  final bool isRead;
  final bool isDeleted;
  final bool isPinned;
  final bool isFavorite;
  final ReplyInfo? replyTo;
  final Map<String, List<String>> reactions;

  const MessageEntity({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.isDeleted = false,
    this.isPinned = false,
    this.isFavorite = false,
    this.replyTo,
    this.reactions = const {},
  });

  /// Get a preview of the message content
  String get preview;

  /// Check if this message is from a specific user
  bool isFromUser(String userId) => senderId == userId;

  /// Check if message has reactions
  bool get hasReactions => reactions.isNotEmpty;

  /// Get total reaction count
  int get reactionCount =>
      reactions.values.fold(0, (sum, list) => sum + list.length);

  @override
  List<Object?> get props => [
        id,
        roomId,
        senderId,
        timestamp,
        type,
        isRead,
        isDeleted,
        isPinned,
        isFavorite,
        replyTo,
        reactions,
      ];
}

/// Message types enum
enum MessageType {
  text,
  photo,
  video,
  audio,
  file,
  location,
  contact,
  poll,
  call,
  system,
}

/// Reply information
class ReplyInfo extends Equatable {
  final String messageId;
  final String senderId;
  final String preview;

  const ReplyInfo({
    required this.messageId,
    required this.senderId,
    required this.preview,
  });

  @override
  List<Object?> get props => [messageId, senderId, preview];
}

/// Text message entity
class TextMessageEntity extends MessageEntity {
  final String text;
  final List<String> mentions;
  final List<LinkPreview> linkPreviews;

  const TextMessageEntity({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.text,
    this.mentions = const [],
    this.linkPreviews = const [],
    super.isRead,
    super.isDeleted,
    super.isPinned,
    super.isFavorite,
    super.replyTo,
    super.reactions,
  }) : super(type: MessageType.text);

  @override
  String get preview =>
      text.length > 50 ? '${text.substring(0, 50)}...' : text;

  @override
  List<Object?> get props => [...super.props, text, mentions, linkPreviews];
}

/// Link preview data
class LinkPreview extends Equatable {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;

  const LinkPreview({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [url, title, description, imageUrl];
}

/// Photo message entity
class PhotoMessageEntity extends MessageEntity {
  final String imageUrl;
  final String? thumbnailUrl;
  final String? caption;
  final int? width;
  final int? height;

  const PhotoMessageEntity({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.imageUrl,
    this.thumbnailUrl,
    this.caption,
    this.width,
    this.height,
    super.isRead,
    super.isDeleted,
    super.isPinned,
    super.isFavorite,
    super.replyTo,
    super.reactions,
  }) : super(type: MessageType.photo);

  @override
  String get preview => caption ?? 'Photo';

  @override
  List<Object?> get props =>
      [...super.props, imageUrl, thumbnailUrl, caption, width, height];
}

/// Video message entity
class VideoMessageEntity extends MessageEntity {
  final String videoUrl;
  final String? thumbnailUrl;
  final String? caption;
  final Duration? duration;
  final int? width;
  final int? height;

  const VideoMessageEntity({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.videoUrl,
    this.thumbnailUrl,
    this.caption,
    this.duration,
    this.width,
    this.height,
    super.isRead,
    super.isDeleted,
    super.isPinned,
    super.isFavorite,
    super.replyTo,
    super.reactions,
  }) : super(type: MessageType.video);

  @override
  String get preview => caption ?? 'Video';

  @override
  List<Object?> get props => [
        ...super.props,
        videoUrl,
        thumbnailUrl,
        caption,
        duration,
        width,
        height,
      ];
}

/// Audio message entity
class AudioMessageEntity extends MessageEntity {
  final String audioUrl;
  final Duration duration;
  final List<double>? waveform;
  final bool isVoiceNote;

  const AudioMessageEntity({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.audioUrl,
    required this.duration,
    this.waveform,
    this.isVoiceNote = true,
    super.isRead,
    super.isDeleted,
    super.isPinned,
    super.isFavorite,
    super.replyTo,
    super.reactions,
  }) : super(type: MessageType.audio);

  @override
  String get preview => isVoiceNote ? 'Voice message' : 'Audio';

  @override
  List<Object?> get props =>
      [...super.props, audioUrl, duration, waveform, isVoiceNote];
}

/// File message entity
class FileMessageEntity extends MessageEntity {
  final String fileUrl;
  final String fileName;
  final String? mimeType;
  final int? fileSize;

  const FileMessageEntity({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.fileUrl,
    required this.fileName,
    this.mimeType,
    this.fileSize,
    super.isRead,
    super.isDeleted,
    super.isPinned,
    super.isFavorite,
    super.replyTo,
    super.reactions,
  }) : super(type: MessageType.file);

  @override
  String get preview => fileName;

  @override
  List<Object?> get props =>
      [...super.props, fileUrl, fileName, mimeType, fileSize];
}

/// Location message entity
class LocationMessageEntity extends MessageEntity {
  final double latitude;
  final double longitude;
  final String? address;
  final String? locationName;

  const LocationMessageEntity({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.latitude,
    required this.longitude,
    this.address,
    this.locationName,
    super.isRead,
    super.isDeleted,
    super.isPinned,
    super.isFavorite,
    super.replyTo,
    super.reactions,
  }) : super(type: MessageType.location);

  @override
  String get preview => locationName ?? address ?? 'Location';

  @override
  List<Object?> get props =>
      [...super.props, latitude, longitude, address, locationName];
}

/// Contact message entity
class ContactMessageEntity extends MessageEntity {
  final String contactName;
  final String? phoneNumber;
  final String? email;
  final String? avatarUrl;

  const ContactMessageEntity({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.contactName,
    this.phoneNumber,
    this.email,
    this.avatarUrl,
    super.isRead,
    super.isDeleted,
    super.isPinned,
    super.isFavorite,
    super.replyTo,
    super.reactions,
  }) : super(type: MessageType.contact);

  @override
  String get preview => contactName;

  @override
  List<Object?> get props =>
      [...super.props, contactName, phoneNumber, email, avatarUrl];
}

/// Poll message entity
class PollMessageEntity extends MessageEntity {
  final String question;
  final List<PollOption> options;
  final bool allowMultipleVotes;
  final bool isAnonymous;
  final DateTime? expiresAt;

  const PollMessageEntity({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.question,
    required this.options,
    this.allowMultipleVotes = false,
    this.isAnonymous = false,
    this.expiresAt,
    super.isRead,
    super.isDeleted,
    super.isPinned,
    super.isFavorite,
    super.replyTo,
    super.reactions,
  }) : super(type: MessageType.poll);

  @override
  String get preview => 'Poll: $question';

  /// Get total votes count
  int get totalVotes =>
      options.fold(0, (sum, option) => sum + option.voterIds.length);

  /// Check if poll has expired
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Check if user has voted
  bool hasUserVoted(String userId) =>
      options.any((option) => option.voterIds.contains(userId));

  @override
  List<Object?> get props => [
        ...super.props,
        question,
        options,
        allowMultipleVotes,
        isAnonymous,
        expiresAt,
      ];
}

/// Poll option
class PollOption extends Equatable {
  final String id;
  final String text;
  final List<String> voterIds;

  const PollOption({
    required this.id,
    required this.text,
    this.voterIds = const [],
  });

  int get voteCount => voterIds.length;

  double getPercentage(int totalVotes) =>
      totalVotes > 0 ? (voteCount / totalVotes) * 100 : 0;

  @override
  List<Object?> get props => [id, text, voterIds];
}

/// Call message entity
class CallMessageEntity extends MessageEntity {
  final CallInfo callInfo;

  const CallMessageEntity({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.callInfo,
    super.isRead,
    super.isDeleted,
    super.isPinned,
    super.isFavorite,
    super.replyTo,
    super.reactions,
  }) : super(type: MessageType.call);

  @override
  String get preview {
    final callType = callInfo.isVideoCall ? 'Video' : 'Voice';
    switch (callInfo.status) {
      case CallStatus.missed:
        return 'Missed $callType call';
      case CallStatus.declined:
        return 'Declined $callType call';
      case CallStatus.ended:
        return '$callType call (${_formatDuration(callInfo.duration)})';
      default:
        return '$callType call';
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [...super.props, callInfo];
}

/// Call information
class CallInfo extends Equatable {
  final String callId;
  final bool isVideoCall;
  final CallStatus status;
  final Duration? duration;
  final String callerId;
  final String calleeId;

  const CallInfo({
    required this.callId,
    required this.isVideoCall,
    required this.status,
    this.duration,
    required this.callerId,
    required this.calleeId,
  });

  @override
  List<Object?> get props =>
      [callId, isVideoCall, status, duration, callerId, calleeId];
}

/// Call status
enum CallStatus {
  ongoing,
  ended,
  missed,
  declined,
}

/// System message entity (for events like user joined, left, etc.)
class SystemMessageEntity extends MessageEntity {
  final SystemEventType eventType;
  final String? targetUserId;
  final String? eventData;

  const SystemMessageEntity({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.eventType,
    this.targetUserId,
    this.eventData,
    super.isRead,
    super.isDeleted,
    super.isPinned,
    super.isFavorite,
    super.replyTo,
    super.reactions,
  }) : super(type: MessageType.system);

  @override
  String get preview {
    switch (eventType) {
      case SystemEventType.userJoined:
        return 'User joined the chat';
      case SystemEventType.userLeft:
        return 'User left the chat';
      case SystemEventType.groupCreated:
        return 'Group created';
      case SystemEventType.groupNameChanged:
        return 'Group name changed';
      case SystemEventType.groupImageChanged:
        return 'Group image changed';
      case SystemEventType.userPromoted:
        return 'User promoted to admin';
      case SystemEventType.userDemoted:
        return 'User removed as admin';
    }
  }

  @override
  List<Object?> get props =>
      [...super.props, eventType, targetUserId, eventData];
}

/// System event types
enum SystemEventType {
  userJoined,
  userLeft,
  groupCreated,
  groupNameChanged,
  groupImageChanged,
  userPromoted,
  userDemoted,
}
