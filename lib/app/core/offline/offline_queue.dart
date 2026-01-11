// ARCH-010 FIX: Offline Support Implementation
// Queue-based offline message handling with sync support

import 'dart:async';
import 'dart:convert';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Status of a pending operation
enum OperationStatus {
  pending,
  inProgress,
  completed,
  failed,
}

/// Type of operation to queue
enum OperationType {
  sendMessage,
  deleteMessage,
  editMessage,
  markAsRead,
  toggleReaction,
  updateChatRoom,
  addMember,
  removeMember,
}

/// A pending operation to be executed when online
class PendingOperation {
  final String id;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final OperationStatus status;
  final String? error;

  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.status = OperationStatus.pending,
    this.error,
  });

  PendingOperation copyWith({
    String? id,
    OperationType? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    OperationStatus? status,
    String? error,
  }) {
    return PendingOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'status': status.name,
        'error': error,
      };

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'],
      type: OperationType.values.byName(json['type']),
      data: Map<String, dynamic>.from(json['data']),
      createdAt: DateTime.parse(json['createdAt']),
      retryCount: json['retryCount'] ?? 0,
      status: OperationStatus.values.byName(json['status'] ?? 'pending'),
      error: json['error'],
    );
  }
}

/// Offline operation queue manager
class OfflineQueue {
  static final OfflineQueue _instance = OfflineQueue._internal();
  factory OfflineQueue() => _instance;
  OfflineQueue._internal();

  static const String _storageKey = 'offline_queue';
  static const int _maxRetries = 3;

  final List<PendingOperation> _queue = [];
  final EventBus _eventBus = EventBus();
  bool _isOnline = true;
  bool _isSyncing = false;
  Timer? _syncTimer;

  /// Get pending operations count
  int get pendingCount => _queue.where((op) =>
      op.status == OperationStatus.pending ||
      op.status == OperationStatus.failed).length;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Check if online
  bool get isOnline => _isOnline;

  /// Initialize the queue from persistent storage
  Future<void> initialize() async {
    await _loadFromStorage();
    _startSyncTimer();
  }

  /// Set online status
  void setOnlineStatus(bool isOnline) {
    final wasOffline = !_isOnline;
    _isOnline = isOnline;

    _eventBus.emit(ConnectivityChangedEvent(isOnline: isOnline));

    // If coming back online, trigger sync
    if (isOnline && wasOffline) {
      syncPendingOperations();
    }
  }

  /// Add an operation to the queue
  Future<String> enqueue(OperationType type, Map<String, dynamic> data) async {
    final operation = PendingOperation(
      id: _generateId(),
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );

    _queue.add(operation);
    await _saveToStorage();

    _eventBus.emit(SyncStatusEvent(
      isSyncing: _isSyncing,
      pendingCount: pendingCount,
    ));

    if (kDebugMode) {
      print('[OfflineQueue] Enqueued: ${type.name} - ${operation.id}');
    }

    // Try to sync immediately if online
    if (_isOnline && !_isSyncing) {
      syncPendingOperations();
    }

    return operation.id;
  }

  /// Remove an operation from the queue
  Future<void> remove(String operationId) async {
    _queue.removeWhere((op) => op.id == operationId);
    await _saveToStorage();
  }

  /// Get pending operations for a specific room
  List<PendingOperation> getOperationsForRoom(String roomId) {
    return _queue.where((op) => op.data['roomId'] == roomId).toList();
  }

  /// Sync all pending operations
  Future<void> syncPendingOperations() async {
    if (!_isOnline || _isSyncing) return;

    _isSyncing = true;
    _eventBus.emit(SyncStatusEvent(
      isSyncing: true,
      pendingCount: pendingCount,
    ));

    final pendingOps = _queue.where((op) =>
        op.status == OperationStatus.pending ||
        (op.status == OperationStatus.failed && op.retryCount < _maxRetries));

    for (final operation in pendingOps.toList()) {
      try {
        // Mark as in progress
        _updateOperationStatus(operation.id, OperationStatus.inProgress);

        // Execute the operation
        await _executeOperation(operation);

        // Mark as completed and remove
        _updateOperationStatus(operation.id, OperationStatus.completed);
        await remove(operation.id);

        if (kDebugMode) {
          print('[OfflineQueue] Synced: ${operation.type.name} - ${operation.id}');
        }
      } catch (e) {
        // Mark as failed with retry count
        final updatedIndex = _queue.indexWhere((op) => op.id == operation.id);
        if (updatedIndex != -1) {
          _queue[updatedIndex] = operation.copyWith(
            status: OperationStatus.failed,
            retryCount: operation.retryCount + 1,
            error: e.toString(),
          );
        }

        if (kDebugMode) {
          print('[OfflineQueue] Failed: ${operation.type.name} - ${operation.id}: $e');
        }

        // If max retries exceeded, emit failure event
        if (operation.retryCount + 1 >= _maxRetries) {
          _emitFailureEvent(operation, e.toString());
        }
      }
    }

    _isSyncing = false;
    await _saveToStorage();

    _eventBus.emit(SyncStatusEvent(
      isSyncing: false,
      pendingCount: pendingCount,
    ));
  }

  /// Execute a single operation
  Future<void> _executeOperation(PendingOperation operation) async {
    // This method should be overridden or injected with actual repository calls
    // For now, it throws to indicate it needs implementation
    switch (operation.type) {
      case OperationType.sendMessage:
        await _executeSendMessage(operation.data);
        break;
      case OperationType.deleteMessage:
        await _executeDeleteMessage(operation.data);
        break;
      case OperationType.editMessage:
        await _executeEditMessage(operation.data);
        break;
      case OperationType.markAsRead:
        await _executeMarkAsRead(operation.data);
        break;
      case OperationType.toggleReaction:
        await _executeToggleReaction(operation.data);
        break;
      case OperationType.updateChatRoom:
        await _executeUpdateChatRoom(operation.data);
        break;
      case OperationType.addMember:
        await _executeAddMember(operation.data);
        break;
      case OperationType.removeMember:
        await _executeRemoveMember(operation.data);
        break;
    }
  }

  // Operation handlers - should be connected to repository
  OperationHandler? _sendMessageHandler;
  OperationHandler? _deleteMessageHandler;
  OperationHandler? _editMessageHandler;
  OperationHandler? _markAsReadHandler;
  OperationHandler? _toggleReactionHandler;
  OperationHandler? _updateChatRoomHandler;
  OperationHandler? _addMemberHandler;
  OperationHandler? _removeMemberHandler;

  /// Register operation handlers
  void registerHandlers({
    OperationHandler? sendMessage,
    OperationHandler? deleteMessage,
    OperationHandler? editMessage,
    OperationHandler? markAsRead,
    OperationHandler? toggleReaction,
    OperationHandler? updateChatRoom,
    OperationHandler? addMember,
    OperationHandler? removeMember,
  }) {
    _sendMessageHandler = sendMessage;
    _deleteMessageHandler = deleteMessage;
    _editMessageHandler = editMessage;
    _markAsReadHandler = markAsRead;
    _toggleReactionHandler = toggleReaction;
    _updateChatRoomHandler = updateChatRoom;
    _addMemberHandler = addMember;
    _removeMemberHandler = removeMember;
  }

  Future<void> _executeSendMessage(Map<String, dynamic> data) async {
    if (_sendMessageHandler == null) {
      throw UnimplementedError('Send message handler not registered');
    }
    await _sendMessageHandler!(data);
  }

  Future<void> _executeDeleteMessage(Map<String, dynamic> data) async {
    if (_deleteMessageHandler == null) {
      throw UnimplementedError('Delete message handler not registered');
    }
    await _deleteMessageHandler!(data);
  }

  Future<void> _executeEditMessage(Map<String, dynamic> data) async {
    if (_editMessageHandler == null) {
      throw UnimplementedError('Edit message handler not registered');
    }
    await _editMessageHandler!(data);
  }

  Future<void> _executeMarkAsRead(Map<String, dynamic> data) async {
    if (_markAsReadHandler == null) {
      throw UnimplementedError('Mark as read handler not registered');
    }
    await _markAsReadHandler!(data);
  }

  Future<void> _executeToggleReaction(Map<String, dynamic> data) async {
    if (_toggleReactionHandler == null) {
      throw UnimplementedError('Toggle reaction handler not registered');
    }
    await _toggleReactionHandler!(data);
  }

  Future<void> _executeUpdateChatRoom(Map<String, dynamic> data) async {
    if (_updateChatRoomHandler == null) {
      throw UnimplementedError('Update chat room handler not registered');
    }
    await _updateChatRoomHandler!(data);
  }

  Future<void> _executeAddMember(Map<String, dynamic> data) async {
    if (_addMemberHandler == null) {
      throw UnimplementedError('Add member handler not registered');
    }
    await _addMemberHandler!(data);
  }

  Future<void> _executeRemoveMember(Map<String, dynamic> data) async {
    if (_removeMemberHandler == null) {
      throw UnimplementedError('Remove member handler not registered');
    }
    await _removeMemberHandler!(data);
  }

  void _emitFailureEvent(PendingOperation operation, String error) {
    if (operation.type == OperationType.sendMessage) {
      _eventBus.emit(MessageSendFailedEvent(
        roomId: operation.data['roomId'] ?? '',
        localId: operation.id,
        error: error,
      ));
    }
  }

  void _updateOperationStatus(String operationId, OperationStatus status) {
    final index = _queue.indexWhere((op) => op.id == operationId);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(status: status);
    }
  }

  /// Load queue from persistent storage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _queue.clear();
        _queue.addAll(
          jsonList.map((j) => PendingOperation.fromJson(j)).toList(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[OfflineQueue] Error loading from storage: $e');
      }
    }
  }

  /// Save queue to persistent storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _queue.map((op) => op.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      if (kDebugMode) {
        print('[OfflineQueue] Error saving to storage: $e');
      }
    }
  }

  /// Start periodic sync timer
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_isOnline && pendingCount > 0) {
        syncPendingOperations();
      }
    });
  }

  /// Generate unique ID for operation
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_queue.length}';
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
  }
}

/// Type alias for operation handlers
typedef OperationHandler = Future<void> Function(Map<String, dynamic> data);

/// Connectivity monitor for detecting online/offline status
class ConnectivityMonitor {
  final OfflineQueue _queue;
  StreamSubscription? _subscription;

  ConnectivityMonitor(this._queue);

  /// Start monitoring connectivity
  void start() {
    // Note: In production, use connectivity_plus package
    // This is a placeholder implementation
    _checkConnectivity();
  }

  void _checkConnectivity() {
    // Placeholder - in production use:
    // Connectivity().onConnectivityChanged.listen((result) {
    //   _queue.setOnlineStatus(result != ConnectivityResult.none);
    // });
    _queue.setOnlineStatus(true);
  }

  /// Stop monitoring
  void stop() {
    _subscription?.cancel();
  }
}
