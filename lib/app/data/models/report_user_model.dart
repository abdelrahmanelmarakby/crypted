// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:crypted_app/app/data/models/user_model.dart';

class ReportUserModel {
  final String? id;
  final SocialMediaUser? reporter;
  final SocialMediaUser? reported;
  final String? roomId;
  final String? msg;
  ReportUserModel({
    this.id,
    this.reporter,
    this.reported,
    this.roomId,
    this.msg,
  });

  ReportUserModel copyWith({
    String? id,
    SocialMediaUser? reporter,
    SocialMediaUser? reported,
    String? roomId,
    String? msg,
  }) {
    return ReportUserModel(
      id: id ?? this.id,
      reporter: reporter ?? this.reporter,
      reported: reported ?? this.reported,
      roomId: roomId ?? this.roomId,
      msg: msg ?? this.msg,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'reporter': reporter?.toMap(),
      'reported': reported?.toMap(),
      'roomId': roomId,
      'msg': msg,
    };
  }

  factory ReportUserModel.fromMap(Map<String, dynamic> map) {
    return ReportUserModel(
      id: map['id'] != null ? map['id'] as String : null,
      reporter:
          map['reporter'] != null
              ? SocialMediaUser.fromMap(map['reporter'] as Map<String, dynamic>)
              : null,
      reported:
          map['reported'] != null
              ? SocialMediaUser.fromMap(map['reported'] as Map<String, dynamic>)
              : null,
      roomId: map['roomId'] != null ? map['roomId'] as String : null,
      msg: map['msg'] != null ? map['msg'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ReportUserModel.fromJson(String source) =>
      ReportUserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ReportUserModel(id: $id, reporter: $reporter, reported: $reported, roomId: $roomId, msg: $msg)';
  }

  @override
  bool operator ==(covariant ReportUserModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.reporter == reporter &&
        other.reported == reported &&
        other.roomId == roomId &&
        other.msg == msg;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        reporter.hashCode ^
        reported.hashCode ^
        roomId.hashCode ^
        msg.hashCode;
  }
}
