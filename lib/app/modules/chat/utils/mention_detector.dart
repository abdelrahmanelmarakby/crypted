import 'package:crypted_app/app/data/models/user_model.dart';

/// Utility class for detecting and handling @ mentions in messages
class MentionDetector {
  /// Regular expression to match @ mentions
  static final RegExp mentionRegex = RegExp(r'@(\w+)');

  /// Detect all mentions in a text
  static List<String> detectMentions(String text) {
    final matches = mentionRegex.allMatches(text);
    return matches.map((match) => match.group(1)!).toList();
  }

  /// Check if text contains any mentions
  static bool hasMentions(String text) {
    return mentionRegex.hasMatch(text);
  }

  /// Replace usernames with user IDs in mentions
  static String replaceMentionsWithIds(
    String text,
    List<SocialMediaUser> members,
  ) {
    String result = text;

    for (final member in members) {
      final username = member.fullName ?? member.username ?? member.uid;
      final pattern = '@$username';

      if (result.contains(pattern)) {
        result = result.replaceAll(pattern, '@[${member.uid}]');
      }
    }

    return result;
  }

  /// Replace user IDs with usernames for display
  static String replaceMentionsWithNames(
    String text,
    List<SocialMediaUser> members,
  ) {
    String result = text;
    final idPattern = RegExp(r'@\[([^\]]+)\]');

    final matches = idPattern.allMatches(text);
    for (final match in matches) {
      final userId = match.group(1)!;
      final member = members.firstWhereOrNull((m) => m.uid == userId);

      if (member != null) {
        final displayName = member.fullName ?? member.username ?? userId;
        result = result.replaceFirst(match.group(0)!, '@$displayName');
      }
    }

    return result;
  }

  /// Get list of mentioned user IDs from a message
  static List<String> getMentionedUserIds(String text) {
    final idPattern = RegExp(r'@\[([^\]]+)\]');
    final matches = idPattern.allMatches(text);
    return matches.map((match) => match.group(1)!).toList();
  }

  /// Filter members based on search query for autocomplete
  static List<SocialMediaUser> filterMembersForAutocomplete(
    String query,
    List<SocialMediaUser> members,
  ) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();

    return members.where((member) {
      final name = (member.fullName ?? '').toLowerCase();
      final username = (member.username ?? '').toLowerCase();

      return name.contains(lowerQuery) || username.contains(lowerQuery);
    }).toList();
  }

  /// Extract mention query from cursor position in text
  static MentionQuery? extractMentionQuery(String text, int cursorPosition) {
    if (cursorPosition > text.length) return null;

    // Find the last @ before cursor
    final beforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = beforeCursor.lastIndexOf('@');

    if (lastAtIndex == -1) return null;

    // Check if there's a space between @ and cursor
    final afterAt = beforeCursor.substring(lastAtIndex + 1);
    if (afterAt.contains(' ')) return null;

    // Extract the query
    return MentionQuery(
      query: afterAt,
      startIndex: lastAtIndex,
      endIndex: cursorPosition,
    );
  }
}

/// Extension for List to add firstWhereOrNull
extension ListExtensions<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

/// Model for mention query context
class MentionQuery {
  final String query;
  final int startIndex;
  final int endIndex;

  MentionQuery({
    required this.query,
    required this.startIndex,
    required this.endIndex,
  });

  @override
  String toString() =>
      'MentionQuery(query: $query, start: $startIndex, end: $endIndex)';
}

/// Model for a detected mention
class DetectedMention {
  final String userId;
  final String displayName;
  final int startIndex;
  final int endIndex;

  DetectedMention({
    required this.userId,
    required this.displayName,
    required this.startIndex,
    required this.endIndex,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'startIndex': startIndex,
        'endIndex': endIndex,
      };

  factory DetectedMention.fromMap(Map<String, dynamic> map) =>
      DetectedMention(
        userId: map['userId'],
        displayName: map['displayName'],
        startIndex: map['startIndex'],
        endIndex: map['endIndex'],
      );
}
