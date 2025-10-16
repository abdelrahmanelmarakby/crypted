// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

enum CallType { uknown, audio, video }

class CallTypeIcon {
  static Icon getIcon(CallType type) {
    IconData iconData;
    Color iconColor;
    switch (type) {
      case CallType.audio:
        iconData = Icons.phone;
        iconColor = Colors.green;
        break;
      case CallType.video:
        iconData = Icons.videocam;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.not_interested;
        iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor);
  }
}

///outgoing->ringing->connected->ended
///outgoing->ringing->canceled->ended
///incoming->ringing->connected->ended
///incoming->ringing->missed->ended
enum CallStatus {
  uknown,
  incoming,
  outgoing,
  missed,
  ringing,
  connected,
  canceled,
  ended;

  static CallStatus? fromString(String? value) {
    switch (value) {
      case 'unknown':
        return CallStatus.uknown;
      case 'incoming':
        return CallStatus.incoming;
      case 'outgoing':
        return CallStatus.outgoing;
      case 'missed':
        return CallStatus.missed;
      case 'connected':
        return CallStatus.connected;
      case 'canceled':
        return CallStatus.canceled;
      case 'ended':
        return CallStatus.ended;
      case 'ringing':
        return CallStatus.ringing;
      default:
        return null;
    }
  }
}

class CallStatusIcon {
  static Icon getIcon(CallStatus status) {
    IconData iconData;
    Color iconColor;

    switch (status) {
      case CallStatus.incoming:
        iconData = Icons.call_received;
        iconColor = Colors.green;
        break;
      case CallStatus.ringing:
        iconData = Icons.call_made;
        iconColor = Colors.green;
        break;
      case CallStatus.outgoing:
        iconData = Icons.call_made;
        iconColor = Colors.blue;
        break;
      case CallStatus.missed:
        iconData = Icons.call_missed;
        iconColor = Colors.red;
        break;
      case CallStatus.connected:
        iconData = Icons.call;
        iconColor = Colors.green;
        break;
      case CallStatus.canceled:
        iconData = Icons.call_end;
        iconColor = Colors.red;
        break;
      case CallStatus.ended:
        iconData = Icons.call_end;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.not_interested;
        iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor);
  }
}

class CallStatusText {
  static Text getText(CallStatus status) {
    String statusText;

    switch (status) {
      case CallStatus.incoming:
        statusText = 'Incoming';
        break;
      case CallStatus.ringing:
        statusText = 'Ringing';
        break;
      case CallStatus.outgoing:
        statusText = 'Outgoing';
        break;
      case CallStatus.missed:
        statusText = 'Missed';
        break;
      case CallStatus.connected:
        statusText = 'Connected';
        break;
      case CallStatus.canceled:
        statusText = 'Canceled';
        break;
      case CallStatus.ended:
        statusText = 'Ended';
        break;
      default:
        statusText = 'Unknown';
    }

    return Text(
      statusText,
      style: TextStyle(
        color: _getTextColor(status),
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static Color _getTextColor(CallStatus status) {
    switch (status) {
      case CallStatus.incoming:
        return Colors.green;
      case CallStatus.ringing:
        return Colors.green;
      case CallStatus.outgoing:
        return Colors.blue;
      case CallStatus.missed:
      case CallStatus.canceled:
        return Colors.red;
      case CallStatus.ended:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

////////////////////////////////////////////////////////////////////////
class CallModel {
  String? channelName;
  String? callId;
  String? callerId;
  String? callerImage;
  String? callerUserName;
  String? calleeId;
  String? calleeImage;
  String? calleeUserName;
  DateTime? time;
  num? callDuration;
  CallType? callType;
  CallStatus? callStatus;

  CallModel({
    this.channelName,
    this.callId,
    this.callerId,
    this.callerImage,
    this.callerUserName,
    this.calleeId,
    this.calleeUserName,
    this.calleeImage,
    this.time,
    this.callDuration,
    this.callType,
    this.callStatus,
  });

  CallModel copyWith({
    String? channelName,
    String? callId,
    String? callerId,
    String? callerImage,
    String? callerUserName,
    String? calleeId,
    String? calleeImage,
    String? calleeUserName,
    DateTime? time,
    num? callDuration,
    CallType? callType,
    CallStatus? callStatus,
  }) {
    return CallModel(
      channelName: channelName ?? this.channelName,
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      callerImage: callerImage ?? this.callerImage,
      callerUserName: callerUserName ?? this.callerUserName,
      calleeId: calleeId ?? this.calleeId,
      calleeImage: calleeImage ?? this.calleeImage,
      calleeUserName: calleeUserName ?? this.calleeUserName,
      time: time ?? this.time,
      callDuration: callDuration ?? this.callDuration,
      callType: callType ?? this.callType,
      callStatus: callStatus ?? this.callStatus,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'channelName': channelName,
      'callId': callId,
      'callerId': callerId,
      'callerImage': callerImage,
      'callerUserName': callerUserName,
      'calleeId': calleeId,
      'calleeImage': calleeImage,
      'calleeUserName': calleeUserName,
      'time': time?.millisecondsSinceEpoch,
      'callDuration': callDuration,
      'callType': callType?.name,
      'callStatus': callStatus?.name,
    };
    print('📞 CallModel.toMap: Generated map: $map');
    return map;
  }

  factory CallModel.fromMap(Map<String, dynamic> map) {
    print('📞 CallModel.fromMap: Parsing map: $map');

    CallType? callType;
    if (map['callType'] != null) {
      try {
        callType = CallType.values.firstWhere(
          (type) => type.name == map['callType'],
          orElse: () => CallType.uknown,
        );
        print('📞 CallModel.fromMap: Parsed callType: ${callType.name}');
      } catch (e) {
        print('📞 CallModel.fromMap: Error parsing callType: $e');
        callType = CallType.uknown;
      }
    }

    CallStatus? callStatus;
    if (map['callStatus'] != null) {
      try {
        callStatus = CallStatus.values.firstWhere(
          (status) => status.name == map['callStatus'],
          orElse: () => CallStatus.uknown,
        );
        print('📞 CallModel.fromMap: Parsed callStatus: ${callStatus.name}');
      } catch (e) {
        print('📞 CallModel.fromMap: Error parsing callStatus: $e');
        callStatus = CallStatus.uknown;
      }
    }

    return CallModel(
      channelName:
          map['channelName'] != null ? map['channelName'] as String : null,
      callId: map['callId'] != null ? map['callId'] as String : null,
      calleeId: map['calleeId'] != null ? map['calleeId'] as String : null,
      calleeImage:
          map['calleeImage'] != null ? map['calleeImage'] as String : null,
      calleeUserName: map['calleeUserName'] != null
          ? map['calleeUserName'] as String
          : null,
      callerId: map['callerId'] != null ? map['callerId'] as String : null,
      callerImage:
          map['callerImage'] != null ? map['callerImage'] as String : null,
      callerUserName: map['callerUserName'] != null
          ? map['callerUserName'] as String
          : null,
      time: _parseDateTimeSafely(map['time']),
      callDuration:
          map['callDuration'] != null ? map['callDuration'] as num : null,
      callType: callType,
      callStatus: callStatus,
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
}
