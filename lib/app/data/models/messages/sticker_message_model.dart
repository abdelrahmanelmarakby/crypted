import 'package:crypted_app/app/data/models/messages/message_model.dart';

/// A sticker message — displays a static or animated sticker image.
///
/// Stickers are identified by a [stickerUrl] pointing to a PNG/WebP/GIF
/// hosted on a CDN (e.g. Giphy stickers endpoint) plus optional metadata.
class StickerMessage extends Message {
  /// Direct URL of the sticker image (PNG, WebP, or GIF).
  final String stickerUrl;

  /// Optional sticker pack identifier (for grouping in the picker).
  final String? packId;

  /// Optional human-readable pack name.
  final String? packName;

  /// Width in logical pixels (original asset size for aspect-ratio layout).
  final int? width;

  /// Height in logical pixels.
  final int? height;

  StickerMessage({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.stickerUrl,
    this.packId,
    this.packName,
    this.width,
    this.height,
    super.reactions,
    super.replyTo,
    super.isPinned,
    super.isFavorite,
    super.isDeleted,
    super.isForwarded,
    super.forwardedFrom,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...baseMap(),
        'type': 'sticker',
        'stickerUrl': stickerUrl,
        if (packId != null) 'packId': packId,
        if (packName != null) 'packName': packName,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };

  factory StickerMessage.fromMap(Map<String, dynamic> map) => StickerMessage(
        id: map['id'] ?? '',
        roomId: map['roomId'] ?? '',
        senderId: map['senderId'] ?? '',
        timestamp: Message.parseTimestamp(map['timestamp']),
        stickerUrl: map['stickerUrl'] ?? '',
        packId: map['packId'],
        packName: map['packName'],
        width: map['width'] as int?,
        height: map['height'] as int?,
        reactions: Message.parseReactions(map['reactions']),
        replyTo: Message.parseReplyTo(map['replyTo']),
        isPinned: map['isPinned'] ?? false,
        isFavorite: map['isFavorite'] ?? false,
        isDeleted: map['isDeleted'] ?? false,
        isForwarded: map['isForwarded'] ?? false,
        forwardedFrom: map['forwardedFrom'],
      );

  @override
  StickerMessage copyWith({
    String? stickerUrl,
    String? packId,
    String? packName,
    int? width,
    int? height,
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
  }) {
    return StickerMessage(
      stickerUrl: stickerUrl ?? this.stickerUrl,
      packId: packId ?? this.packId,
      packName: packName ?? this.packName,
      width: width ?? this.width,
      height: height ?? this.height,
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
    );
  }
}
