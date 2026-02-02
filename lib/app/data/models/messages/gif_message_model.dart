import 'package:crypted_app/app/data/models/messages/message_model.dart';

/// An animated GIF message powered by Giphy.
///
/// Stores both the full-size GIF URL and an optional low-bandwidth preview
/// (Giphy's "fixed_height_small" or "downsized" variant) so the chat list
/// can show a lightweight thumbnail while the detail view loads the original.
class GifMessage extends Message {
  /// Full-size GIF URL (Giphy original or fixed-height).
  final String gifUrl;

  /// Optional smaller/lighter preview URL for list views.
  final String? previewUrl;

  /// Giphy content ID (for attribution / deep-linking).
  final String? giphyId;

  /// Title / alt-text supplied by Giphy.
  final String? title;

  /// Original asset width (logical pixels).
  final int? width;

  /// Original asset height (logical pixels).
  final int? height;

  GifMessage({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.gifUrl,
    this.previewUrl,
    this.giphyId,
    this.title,
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
        'type': 'gif',
        'gifUrl': gifUrl,
        if (previewUrl != null) 'previewUrl': previewUrl,
        if (giphyId != null) 'giphyId': giphyId,
        if (title != null) 'title': title,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };

  factory GifMessage.fromMap(Map<String, dynamic> map) => GifMessage(
        id: map['id'] ?? '',
        roomId: map['roomId'] ?? '',
        senderId: map['senderId'] ?? '',
        timestamp: Message.parseTimestamp(map['timestamp']),
        gifUrl: map['gifUrl'] ?? '',
        previewUrl: map['previewUrl'],
        giphyId: map['giphyId'],
        title: map['title'],
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
  GifMessage copyWith({
    String? gifUrl,
    String? previewUrl,
    String? giphyId,
    String? title,
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
    return GifMessage(
      gifUrl: gifUrl ?? this.gifUrl,
      previewUrl: previewUrl ?? this.previewUrl,
      giphyId: giphyId ?? this.giphyId,
      title: title ?? this.title,
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
