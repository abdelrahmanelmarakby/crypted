
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_model.dart';

enum StoryType {
  image,
  video,
  text,
}

enum StoryStatus {
  active,
  expired,
  viewed,
}

class StoryModel {
  String? id;
  String? uid;
  SocialMediaUser? user;
  String? storyFileUrl;
  String? storyText;
  DateTime? createdAt;
  DateTime? expiresAt;
  StoryType? storyType;
  StoryStatus? status;
  List<String>? viewedBy;
  int? duration; // بالثواني
  String? backgroundColor;
  String? textColor;
  double? fontSize;
  String? fontFamily;
  String? textPosition; // top, center, bottom

  StoryModel({
    this.id,
    this.uid,
    this.user,
    this.storyFileUrl,
    this.storyText,
    this.createdAt,
    this.expiresAt,
    this.storyType,
    this.status,
    this.viewedBy,
    this.duration,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.fontFamily,
    this.textPosition,
  });

  StoryModel copyWith({
    String? id,
    String? uid,
    SocialMediaUser? user,
    String? storyFileUrl,
    String? storyText,
    DateTime? createdAt,
    DateTime? expiresAt,
    StoryType? storyType,
    StoryStatus? status,
    List<String>? viewedBy,
    int? duration,
    String? backgroundColor,
    String? textColor,
    double? fontSize,
    String? fontFamily,
    String? textPosition,
  }) {
    return StoryModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      user: user ?? this.user,
      storyFileUrl: storyFileUrl ?? this.storyFileUrl,
      storyText: storyText ?? this.storyText,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      storyType: storyType ?? this.storyType,
      status: status ?? this.status,
      viewedBy: viewedBy ?? this.viewedBy,
      duration: duration ?? this.duration,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      textPosition: textPosition ?? this.textPosition,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    if (id != null) {
      result.addAll({'id': id});
    }
    if (uid != null) {
      result.addAll({'uid': uid});
    }
    if (user != null) {
      result.addAll({'user': user!.toMap()});
    }
    if (storyFileUrl != null) {
      result.addAll({'storyFileUrl': storyFileUrl});
    }
    if (storyText != null) {
      result.addAll({'storyText': storyText});
    }
    if (createdAt != null) {
      result.addAll({'createdAt': Timestamp.fromDate(createdAt!)});
    }
    if (expiresAt != null) {
      result.addAll({'expiresAt': Timestamp.fromDate(expiresAt!)});
    }
    if (storyType != null) {
      result.addAll({'storyType': storyType!.name});
    }
    if (status != null) {
      result.addAll({'status': status!.name});
    }
    if (viewedBy != null) {
      result.addAll({'viewedBy': viewedBy});
    }
    if (duration != null) {
      result.addAll({'duration': duration});
    }
    if (backgroundColor != null) {
      result.addAll({'backgroundColor': backgroundColor});
    }
    if (textColor != null) {
      result.addAll({'textColor': textColor});
    }
    if (fontSize != null) {
      result.addAll({'fontSize': fontSize});
    }
    if (fontFamily != null) {
      result.addAll({'fontFamily': fontFamily});
    }
    if (textPosition != null) {
      result.addAll({'textPosition': textPosition});
    }

    return result;
  }

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    // تحقق من وجود معلومات المستخدم
    SocialMediaUser? user;
    if (map['user'] != null) {
      try {
        user = SocialMediaUser.fromMap(map['user']);
        print('👤 Parsed user data from map: ${user.fullName}');
      } catch (e) {
        print('❌ Error parsing user data from map: $e');
        user = null;
      }
    } else {
      print('⚠️ No user data found in story map');
    }

    return StoryModel(
      id: map['id'],
      uid: map['uid'] ?? map['userId'] ?? map['user_id'],
      user: user,
      storyFileUrl: map['storyFileUrl'] ??
          map['fileUrl'] ??
          map['imageUrl'] ??
          map['videoUrl'],
      storyText: map['storyText'] ?? map['text'] ?? map['content'],
      createdAt: _parseDateTime(
          map['createdAt'] ?? map['timestamp'] ?? map['created_at']),
      expiresAt: _parseDateTime(
          map['expiresAt'] ?? map['expires_at'] ?? map['expireAt']),
      storyType:
          _parseStoryType(map['storyType'] ?? map['type'] ?? map['story_type']),
      status: _parseStoryStatus(map['status'] ?? 'active'),
      viewedBy: map['viewedBy'] != null
          ? List<String>.from(map['viewedBy'])
          : map['viewed_by'] != null
              ? List<String>.from(map['viewed_by'])
              : [],
      duration: map['duration'] ?? 5,
      backgroundColor:
          map['backgroundColor'] ?? map['background_color'] ?? '#000000',
      textColor: map['textColor'] ?? map['text_color'] ?? '#FFFFFF',
      fontSize: (map['fontSize'] ?? map['font_size'] ?? 24.0).toDouble(),
      fontFamily: map['fontFamily'] ?? map['font_family'],
      textPosition: map['textPosition'] ?? map['text_position'] ?? 'center',
    );
  }

  factory StoryModel.fromQuery(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();

    // تحقق من وجود معلومات المستخدم
    SocialMediaUser? user;
    if (data['user'] != null) {
      try {
        user = SocialMediaUser.fromMap(data['user']);
        print('👤 Parsed user data: ${user.fullName}');
      } catch (e) {
        print('❌ Error parsing user data: $e');
        user = null;
      }
    } else {
      print('⚠️ No user data found in story: ${snapshot.id}');
    }

    return StoryModel(
      id: snapshot.id,
      uid: data['uid'] ?? data['userId'] ?? data['user_id'],
      user: user,
      storyFileUrl: data['storyFileUrl'] ??
          data['fileUrl'] ??
          data['imageUrl'] ??
          data['videoUrl'],
      storyText: data['storyText'] ?? data['text'] ?? data['content'],
      createdAt: _parseDateTime(
          data['createdAt'] ?? data['timestamp'] ?? data['created_at']),
      expiresAt: _parseDateTime(
          data['expiresAt'] ?? data['expires_at'] ?? data['expireAt']),
      storyType: _parseStoryType(
          data['storyType'] ?? data['type'] ?? data['story_type']),
      status: _parseStoryStatus(data['status'] ?? 'active'),
      viewedBy: data['viewedBy'] != null
          ? List<String>.from(data['viewedBy'])
          : data['viewed_by'] != null
              ? List<String>.from(data['viewed_by'])
              : [],
      duration: data['duration'] ?? 5,
      backgroundColor:
          data['backgroundColor'] ?? data['background_color'] ?? '#000000',
      textColor: data['textColor'] ?? data['text_color'] ?? '#FFFFFF',
      fontSize: (data['fontSize'] ?? data['font_size'] ?? 24.0).toDouble(),
      fontFamily: data['fontFamily'] ?? data['font_family'],
      textPosition: data['textPosition'] ?? data['text_position'] ?? 'center',
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    // If it's a Timestamp from Firestore
    if (value is Timestamp) {
      try {
        return value.toDate();
      } catch (e) {
        return null;
      }
    }

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
      if (value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return null;
  }

  static StoryType _parseStoryType(dynamic value) {
    if (value == null) return StoryType.image;

    if (value is String) {
      switch (value.toLowerCase()) {
        case 'image':
        case 'photo':
        case 'img':
          return StoryType.image;
        case 'video':
        case 'vid':
          return StoryType.video;
        case 'text':
        case 'txt':
          return StoryType.text;
        default:
          return StoryType.image;
      }
    }

    return StoryType.image;
  }

  static StoryStatus _parseStoryStatus(dynamic value) {
    if (value == null) return StoryStatus.active;

    if (value is String) {
      switch (value.toLowerCase()) {
        case 'active':
          return StoryStatus.active;
        case 'expired':
          return StoryStatus.expired;
        case 'viewed':
          return StoryStatus.viewed;
        default:
          return StoryStatus.active;
      }
    }

    return StoryStatus.active;
  }

  // دالة لفحص إذا كانت الـ story منتهية الصلاحية
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // دالة لفحص إذا كانت الـ story تم مشاهدتها من قبل المستخدم
  bool isViewedBy(String userId) {
    return viewedBy?.contains(userId) ?? false;
  }

  // دالة لإضافة مستخدم إلى قائمة المشاهدين
  void addViewer(String userId) {
    viewedBy ??= [];
    if (!viewedBy!.contains(userId)) {
      viewedBy!.add(userId);
    }
  }

  // دالة لحساب الوقت المتبقي
  Duration? get remainingTime {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }
}
