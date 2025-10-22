import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestType {
  support('Support'),
  inquiry('General Inquiry'),
  bugReport('Bug Report'),
  featureRequest('Feature Request'),
  recommendation('Recommendation'),
  complaint('Complaint'),
  other('Other');

  const RequestType(this.displayName);
  final String displayName;

  static RequestType fromString(String value) {
    return RequestType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => RequestType.other,
    );
  }
}

class HelpMessage {
  final String? id;
  final String fullName;
  final String email;
  final String message;
  final RequestType requestType;
  final String status; // 'pending', 'in_progress', 'resolved', 'closed'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? response;
  final String? adminId;
  final String userId;
  final List<String>? attachmentUrls; // List of file URLs for attachments
  final String? priority; // 'low', 'medium', 'high', 'urgent'

  HelpMessage({
    this.id,
    required this.fullName,
    required this.email,
    required this.message,
    this.requestType = RequestType.support,
    this.status = 'pending',
    DateTime? createdAt,
    this.updatedAt,
    this.response,
    this.adminId,
    required this.userId,
    this.attachmentUrls,
    this.priority = 'medium',
  }) : createdAt = createdAt ?? DateTime.now();

  // Create from Firestore document
  factory HelpMessage.fromMap(Map<String, dynamic> map, {String? id}) {
    return HelpMessage(
      id: id,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      message: map['message'] ?? '',
      requestType: RequestType.fromString(map['requestType'] ?? 'support'),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      response: map['response'],
      adminId: map['adminId'],
      userId: map['userId'] ?? '',
      attachmentUrls: map['attachmentUrls'] != null
          ? List<String>.from(map['attachmentUrls'])
          : null,
      priority: map['priority'] ?? 'medium',
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'message': message,
      'requestType': requestType.name,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'response': response,
      'adminId': adminId,
      'userId': userId,
      'attachmentUrls': attachmentUrls,
      'priority': priority,
    };
  }

  // Create a copy with updated fields
  HelpMessage copyWith({
    String? id,
    String? fullName,
    String? email,
    String? message,
    RequestType? requestType,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? response,
    String? adminId,
    String? userId,
    List<String>? attachmentUrls,
    String? priority,
  }) {
    return HelpMessage(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      message: message ?? this.message,
      requestType: requestType ?? this.requestType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      response: response ?? this.response,
      adminId: adminId ?? this.adminId,
      userId: userId ?? this.userId,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      priority: priority ?? this.priority,
    );
  }

  // Get status color for UI
  String get statusColor {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'in_progress':
        return 'blue';
      case 'resolved':
        return 'green';
      case 'closed':
        return 'grey';
      default:
        return 'grey';
    }
  }

  // Get priority color for UI
  String get priorityColor {
    switch (priority) {
      case 'urgent':
        return 'red';
      case 'high':
        return 'orange';
      case 'medium':
        return 'blue';
      case 'low':
        return 'green';
      default:
        return 'grey';
    }
  }

  @override
  String toString() {
    return 'HelpMessage(id: $id, fullName: $fullName, email: $email, message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}, status: $status, userId: $userId, type: ${requestType.displayName})';
  }
}
