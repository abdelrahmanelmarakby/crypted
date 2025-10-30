// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:crypted_app/app/data/models/messages/message_model.dart';

class PollMessage extends Message {
  final String question;
  final List<String> options;
  final Map<String, List<String>> votes; // optionIndex -> [userId1, userId2, ...]
  final int totalVotes;
  final bool allowMultipleVotes;
  final DateTime? closedAt;
  final bool isAnonymous;

  PollMessage({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.question,
    required this.options,
    this.votes = const {},
    this.totalVotes = 0,
    this.allowMultipleVotes = false,
    this.closedAt,
    this.isAnonymous = false,
    super.reactions,
    super.replyTo,
    super.isPinned,
    super.isFavorite,
    super.isDeleted,
    super.isForwarded,
    super.forwardedFrom,
  });

  // Helper method to get vote count for an option
  int getVoteCount(int optionIndex) {
    return votes[optionIndex.toString()]?.length ?? 0;
  }

  // Check if a user has voted
  bool hasUserVoted(String userId) {
    return votes.values.any((voters) => voters.contains(userId));
  }

  // Get the option a user voted for
  String? getUserVote(String userId) {
    for (var entry in votes.entries) {
      if (entry.value.contains(userId)) {
        final index = int.tryParse(entry.key);
        if (index != null && index < options.length) {
          return options[index];
        }
      }
    }
    return null;
  }

  // Get vote percentage for an option
  double getVotePercentage(int optionIndex) {
    if (totalVotes == 0) return 0.0;
    return getVoteCount(optionIndex) / totalVotes;
  }

  // Check if poll is closed
  bool get isClosed {
    if (closedAt == null) return false;
    return DateTime.now().isAfter(closedAt!);
  }

  // Get list of voters for an option (if not anonymous)
  List<String> getVoters(int optionIndex) {
    if (isAnonymous) return [];
    return votes[optionIndex.toString()] ?? [];
  }

  @override
  Map<String, dynamic> toMap() => {
        ...baseMap(),
        'type': 'poll',
        'question': question,
        'options': options,
        'votes': votes.map((key, value) => MapEntry(key, value)),
        'totalVotes': totalVotes,
        'allowMultipleVotes': allowMultipleVotes,
        'closedAt': closedAt?.toIso8601String(),
        'isAnonymous': isAnonymous,
      };

  factory PollMessage.fromMap(Map<String, dynamic> map) {
    // Parse votes map safely
    final votesData = map['votes'] as Map<String, dynamic>?;
    final votes = votesData?.map(
          (key, value) => MapEntry(
            key,
            List<String>.from(value as List? ?? []),
          ),
        ) ??
        {};

    return PollMessage(
      id: map['id'],
      roomId: map['roomId'],
      senderId: map['senderId'],
      timestamp: DateTime.parse(map['timestamp']),
      question: map['question'],
      options: List<String>.from(map['options']),
      votes: votes,
      totalVotes: map['totalVotes'] ?? 0,
      allowMultipleVotes: map['allowMultipleVotes'] ?? false,
      closedAt: map['closedAt'] != null ? DateTime.parse(map['closedAt']) : null,
      isAnonymous: map['isAnonymous'] ?? false,
      reactions: Message.parseReactions(map['reactions']),
      replyTo: Message.parseReplyTo(map['replyTo']),
      isPinned: map['isPinned'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      isForwarded: map['isForwarded'] ?? false,
      forwardedFrom: map['forwardedFrom'],
    );
  }

  @override
  PollMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    String? question,
    List<String>? options,
    Map<String, List<String>>? votes,
    int? totalVotes,
    bool? allowMultipleVotes,
    DateTime? closedAt,
    bool? isAnonymous,
    List<Reaction>? reactions,
    ReplyToMessage? replyTo,
    bool? isPinned,
    bool? isFavorite,
    bool? isDeleted,
    bool? isForwarded,
    String? forwardedFrom,
  }) {
    return PollMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      question: question ?? this.question,
      options: options ?? this.options,
      votes: votes ?? this.votes,
      totalVotes: totalVotes ?? this.totalVotes,
      allowMultipleVotes: allowMultipleVotes ?? this.allowMultipleVotes,
      closedAt: closedAt ?? this.closedAt,
      isAnonymous: isAnonymous ?? this.isAnonymous,
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
