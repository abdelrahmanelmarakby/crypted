class NotificationModel {
  final bool showMessageNotification;
  final String soundMessage;
  final bool reactionMessageNotification;
  final bool showGroupNotification;
  final String soundGroup;
  final bool reactionGroupNotification;
  final String soundStatus;
  final bool reactionStatusNotification;
  final bool reminderNotification;
  final bool showPreviewNotification;
  final String? id;
  final DateTime? createdAt;

  NotificationModel({
    required this.showMessageNotification,
    required this.soundMessage,
    required this.reactionMessageNotification,
    required this.showGroupNotification,
    required this.soundGroup,
    required this.reactionGroupNotification,
    required this.soundStatus,
    required this.reactionStatusNotification,
    required this.reminderNotification,
    required this.showPreviewNotification,
    this.id,
    this.createdAt,
  });

  NotificationModel copyWith({
    bool? showMessageNotification,
    String? soundMessage,
    bool? reactionMessageNotification,
    bool? showGroupNotification,
    String? soundGroup,
    bool? reactionGroupNotification,
    String? soundStatus,
    bool? reactionStatusNotification,
    bool? reminderNotification,
    bool? showPreviewNotification,
    String? id,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      showMessageNotification:
          showMessageNotification ?? this.showMessageNotification,
      soundMessage: soundMessage ?? this.soundMessage,
      reactionMessageNotification:
          reactionMessageNotification ?? this.reactionMessageNotification,
      showGroupNotification:
          showGroupNotification ?? this.showGroupNotification,
      soundGroup: soundGroup ?? this.soundGroup,
      reactionGroupNotification:
          reactionGroupNotification ?? this.reactionGroupNotification,
      soundStatus: soundStatus ?? this.soundStatus,
      reactionStatusNotification:
          reactionStatusNotification ?? this.reactionStatusNotification,
      reminderNotification: reminderNotification ?? this.reminderNotification,
      showPreviewNotification:
          showPreviewNotification ?? this.showPreviewNotification,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      showMessageNotification: map['showMessageNotification'] ?? true,
      soundMessage: map['soundMessage'] ?? '',
      reactionMessageNotification: map['reactionMessageNotification'] ?? true,
      showGroupNotification: map['showGroupNotification'] ?? true,
      soundGroup: map['soundGroup'] ?? '',
      reactionGroupNotification: map['reactionGroupNotification'] ?? true,
      soundStatus: map['soundStatus'] ?? '',
      reactionStatusNotification: map['reactionStatusNotification'] ?? true,
      reminderNotification: map['reminderNotification'] ?? true,
      showPreviewNotification: map['showPreviewNotification'] ?? true,
      id: map['id'],
      createdAt: _parseDateTimeSafely(map['createdAt']),
    );
  }

  static DateTime? _parseDateTimeSafely(dynamic value) {
    if (value == null) return null;

    // If it's a number (milliseconds since epoch)
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        return null;
      }
    }

    // If it's a string (ISO format)
    if (value is String) {
      // Explicitly check for empty strings
      if (value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'showMessageNotification': showMessageNotification,
      'soundMessage': soundMessage,
      'reactionMessageNotification': reactionMessageNotification,
      'showGroupNotification': showGroupNotification,
      'soundGroup': soundGroup,
      'reactionGroupNotification': reactionGroupNotification,
      'soundStatus': soundStatus,
      'reactionStatusNotification': reactionStatusNotification,
      'reminderNotification': reminderNotification,
      'showPreviewNotification': showPreviewNotification,
      'id': id,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  // NotificationModel copyWith({
  //   bool? showMessageNotification,
  //   String? soundMessage,
  //   bool? reactionMessageNotification,
  //   bool? showGroupNotification,
  //   String? soundGroup,
  //   bool? reactionGroupNotification,
  //   String? soundStatus,
  //   bool? reactionStatusNotification,
  //   bool? reminderNotification,
  //   bool? showPreviewNotification,
  // }) {
  //   return NotificationModel(
  //     showMessageNotification:
  //         showMessageNotification ?? this.showMessageNotification,
  //     soundMessage: soundMessage ?? this.soundMessage,
  //     reactionMessageNotification:
  //         reactionMessageNotification ?? this.reactionMessageNotification,
  //     showGroupNotification:
  //         showGroupNotification ?? this.showGroupNotification,
  //     soundGroup: soundGroup ?? this.soundGroup,
  //     reactionGroupNotification:
  //         reactionGroupNotification ?? this.reactionGroupNotification,
  //     soundStatus: soundStatus ?? this.soundStatus,
  //     reactionStatusNotification:
  //         reactionStatusNotification ?? this.reactionStatusNotification,
  //     reminderNotification: reminderNotification ?? this.reminderNotification,
  //     showPreviewNotification:
  //         showPreviewNotification ?? this.showPreviewNotification,
  //   );
  // }

  // final String? id;
  // final String? title;
  // final String? body;
  // final String? type;
  // final String? data;
  // final SocialMediaUser? fromUser;
  // final List<String>? toUsers;
  // final DateTime? createdAt;
  // final String? imageUrl;
  // NotificationModel({
  //   this.id,
  //   this.title,
  //   this.body,
  //   this.type,
  //   this.data,
  //   this.fromUser,
  //   this.toUsers,
  //   this.createdAt,
  //   this.imageUrl,
  // });

  // NotificationModel copyWith({
  //   String? id,
  //   String? title,
  //   String? body,
  //   String? type,
  //   String? data,
  //   SocialMediaUser? fromUser,
  //   List<String>? toUsers,
  //   DateTime? createdAt,
  //   String? imageUrl,
  // }) {
  //   return NotificationModel(
  //     id: id ?? this.id,
  //     title: title ?? this.title,
  //     body: body ?? this.body,
  //     type: type ?? this.type,
  //     data: data ?? this.data,
  //     fromUser: fromUser ?? this.fromUser,
  //     toUsers: toUsers ?? this.toUsers,
  //     createdAt: createdAt ?? this.createdAt,
  //     imageUrl: imageUrl ?? this.imageUrl,
  //   );
  // }

  // Map<String, dynamic> toMap() {
  //   final result = <String, dynamic>{};
  //   result.addAll({'id': id});
  //   result.addAll({'title': title});
  //   result.addAll({'body': body});
  //   result.addAll({'type': type});
  //   result.addAll({'data': data});
  //   result.addAll({'fromUser': fromUser!.toMap()});
  //   result.addAll({'toUsers': toUsers});
  //   result.addAll({'createdAt': createdAt!.millisecondsSinceEpoch});
  //   result.addAll({'imageUrl': imageUrl});

  //   return result;
  // }

  // factory NotificationModel.fromMap(Map<String, dynamic> map) {
  //   return NotificationModel(
  //     id: map['id'],
  //     title: map['title'],
  //     body: map['body'],
  //     type: map['type'],
  //     data: map['data'],
  //     fromUser: map['fromUser'] != null
  //         ? SocialMediaUser.fromMap(map['fromUser'])
  //         : null,
  //     toUsers: List<String>.from(map['toUsers']),
  //     createdAt: map['createdAt'] != null
  //         ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
  //         : null,
  //     imageUrl: map['imageUrl'],
  //   );
  // }

  // String toJson() => json.encode(toMap());

  // factory NotificationModel.fromJson(String source) =>
  //     NotificationModel.fromMap(json.decode(source));

  // @override
  // String toString() {
  //   return 'NotificationModel(id: $id, title: $title, body: $body, type: $type, data: $data, fromUser: $fromUser, toUsers: $toUsers, createdAt: $createdAt, imageUrl: $imageUrl)';
  // }

  // @override
  // bool operator ==(Object other) {
  //   if (identical(this, other)) return true;

  //   return other is NotificationModel &&
  //       other.id == id &&
  //       other.title == title &&
  //       other.body == body &&
  //       other.type == type &&
  //       other.data == data &&
  //       other.fromUser == fromUser &&
  //       listEquals(other.toUsers, toUsers) &&
  //       other.createdAt == createdAt &&
  //       other.imageUrl == imageUrl;
  // }

  // @override
  // int get hashCode {
  //   return id.hashCode ^
  //       title.hashCode ^
  //       body.hashCode ^
  //       type.hashCode ^
  //       data.hashCode ^
  //       fromUser.hashCode ^
  //       toUsers.hashCode ^
  //       createdAt.hashCode ^
  //       imageUrl.hashCode;
  // }
}
