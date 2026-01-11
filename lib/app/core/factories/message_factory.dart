// ARCH-012 FIX: Message Factory with Registry Pattern
// This allows dynamic message type registration without modifying base class

import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/app/data/models/messages/event_message_model.dart';
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:flutter/foundation.dart';

/// Type definition for message parser functions
typedef MessageParser = Message Function(Map<String, dynamic> map);

/// Message Factory with Registry Pattern
/// Allows registering new message types without modifying existing code
class MessageFactory {
  // Singleton instance
  static final MessageFactory _instance = MessageFactory._internal();
  factory MessageFactory() => _instance;
  MessageFactory._internal() {
    _registerDefaultParsers();
  }

  /// Registry of message type parsers
  final Map<String, MessageParser> _parsers = {};

  /// Register default message type parsers
  void _registerDefaultParsers() {
    register('text', (map) => TextMessage.fromMap(map));
    register('photo', (map) => PhotoMessage.fromMap(map));
    register('audio', (map) => AudioMessage.fromMap(map));
    register('video', (map) => VideoMessage.fromMap(map));
    register('file', (map) => FileMessage.fromMap(map));
    register('location', (map) => LocationMessage.fromMap(map));
    register('contact', (map) => ContactMessage.fromMap(map));
    register('poll', (map) => PollMessage.fromMap(map));
    register('event', (map) => EventMessage.fromMap(map));
    register('call', (map) => CallMessage.fromMap(map));
  }

  /// Register a new message type parser
  /// Can be used to add custom message types without modifying this class
  void register(String type, MessageParser parser) {
    _parsers[type] = parser;
    if (kDebugMode) {
      print('MessageFactory: Registered parser for type "$type"');
    }
  }

  /// Unregister a message type parser
  void unregister(String type) {
    _parsers.remove(type);
  }

  /// Check if a message type is registered
  bool isRegistered(String type) {
    return _parsers.containsKey(type);
  }

  /// Get all registered message types
  List<String> get registeredTypes => _parsers.keys.toList();

  /// Create a message from a map using the registry
  /// Throws [UnknownMessageTypeException] if type is not registered
  Message fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String?;

    if (type == null) {
      throw MessageParsingException(
        'Message type is null',
        map,
      );
    }

    final parser = _parsers[type];

    if (parser == null) {
      throw UnknownMessageTypeException(type, map);
    }

    try {
      return parser(map);
    } catch (e, stackTrace) {
      throw MessageParsingException(
        'Failed to parse message of type "$type": $e',
        map,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Try to create a message from a map, returns null on failure
  Message? tryFromMap(Map<String, dynamic> map) {
    try {
      return fromMap(map);
    } catch (e) {
      if (kDebugMode) {
        print('MessageFactory.tryFromMap error: $e');
      }
      return null;
    }
  }

  /// Create a message from a map with a fallback for unknown types
  Message fromMapWithFallback(
    Map<String, dynamic> map, {
    required Message Function(Map<String, dynamic>) fallback,
  }) {
    try {
      return fromMap(map);
    } catch (e) {
      if (kDebugMode) {
        print('MessageFactory: Using fallback for map: $map');
      }
      return fallback(map);
    }
  }

  /// Batch parse multiple messages
  List<Message> fromMapList(List<Map<String, dynamic>> maps) {
    return maps
        .map((map) => tryFromMap(map))
        .where((msg) => msg != null)
        .cast<Message>()
        .toList();
  }
}

/// Exception thrown when an unknown message type is encountered
class UnknownMessageTypeException implements Exception {
  final String type;
  final Map<String, dynamic> originalData;

  UnknownMessageTypeException(this.type, this.originalData);

  @override
  String toString() => 'UnknownMessageTypeException: Unknown message type "$type"';
}

/// Exception thrown when message parsing fails
class MessageParsingException implements Exception {
  final String message;
  final Map<String, dynamic> originalData;
  final dynamic originalError;
  final StackTrace? stackTrace;

  MessageParsingException(
    this.message,
    this.originalData, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'MessageParsingException: $message';
}

/// Extension to easily use the factory from Message class
extension MessageFactoryExtension on Message {
  /// Create a message using the factory
  static Message create(Map<String, dynamic> map) {
    return MessageFactory().fromMap(map);
  }

  /// Try to create a message using the factory
  static Message? tryCreate(Map<String, dynamic> map) {
    return MessageFactory().tryFromMap(map);
  }
}

/// Convenience function for creating messages
Message createMessage(Map<String, dynamic> map) {
  return MessageFactory().fromMap(map);
}

/// Convenience function for trying to create messages
Message? tryCreateMessage(Map<String, dynamic> map) {
  return MessageFactory().tryFromMap(map);
}
