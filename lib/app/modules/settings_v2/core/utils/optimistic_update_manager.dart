/// Optimistic Update Manager for Settings
///
/// Provides immediate UI updates with automatic rollback on failure,
/// conflict resolution, and pending change tracking.
library;

import 'dart:async';
import 'dart:developer' as developer;
import 'package:get/get.dart';

/// State of an optimistic update
enum OptimisticUpdateState {
  /// Update applied locally, waiting for server confirmation
  pending,

  /// Server confirmed the update
  confirmed,

  /// Server rejected the update, rolled back
  rolledBack,

  /// Update failed with error
  failed,
}

/// A single optimistic update operation
class OptimisticUpdate<T> {
  final String id;
  final String description;
  final T previousValue;
  final T newValue;
  final DateTime timestamp;
  final Future<bool> Function() serverOperation;
  final void Function(T) rollbackAction;

  OptimisticUpdateState _state = OptimisticUpdateState.pending;
  String? _errorMessage;

  OptimisticUpdate({
    required this.id,
    required this.description,
    required this.previousValue,
    required this.newValue,
    required this.serverOperation,
    required this.rollbackAction,
  }) : timestamp = DateTime.now();

  OptimisticUpdateState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isPending => _state == OptimisticUpdateState.pending;
  bool get isConfirmed => _state == OptimisticUpdateState.confirmed;
  bool get isRolledBack => _state == OptimisticUpdateState.rolledBack;
  bool get isFailed => _state == OptimisticUpdateState.failed;

  void _confirm() {
    _state = OptimisticUpdateState.confirmed;
  }

  void _rollback() {
    _state = OptimisticUpdateState.rolledBack;
    rollbackAction(previousValue);
  }

  void _fail(String message) {
    _state = OptimisticUpdateState.failed;
    _errorMessage = message;
    rollbackAction(previousValue);
  }
}

/// Manager for optimistic updates with automatic rollback
class OptimisticUpdateManager extends GetxService {
  static OptimisticUpdateManager get instance => Get.find();

  // Pending updates queue
  final RxList<OptimisticUpdate> _pendingUpdates = <OptimisticUpdate>[].obs;

  // Update history for undo support
  final RxList<OptimisticUpdate> _updateHistory = <OptimisticUpdate>[].obs;

  // Configuration
  final int maxHistorySize;
  final Duration confirmationTimeout;
  final int maxRetries;

  // Callbacks
  void Function(OptimisticUpdate)? onUpdateConfirmed;
  void Function(OptimisticUpdate, String)? onUpdateFailed;
  void Function(OptimisticUpdate)? onUpdateRolledBack;

  OptimisticUpdateManager({
    this.maxHistorySize = 50,
    this.confirmationTimeout = const Duration(seconds: 30),
    this.maxRetries = 2,
  });

  /// Get list of pending updates
  List<OptimisticUpdate> get pendingUpdates => _pendingUpdates.toList();

  /// Get update history
  List<OptimisticUpdate> get updateHistory => _updateHistory.toList();

  /// Check if there are pending updates
  bool get hasPendingUpdates => _pendingUpdates.isNotEmpty;

  /// Apply an optimistic update
  ///
  /// Immediately applies the update locally, then confirms with server.
  /// Rolls back automatically if server operation fails.
  Future<OptimisticUpdate<T>> applyUpdate<T>({
    required String id,
    required String description,
    required T previousValue,
    required T newValue,
    required void Function(T) applyAction,
    required Future<bool> Function() serverOperation,
    required void Function(T) rollbackAction,
  }) async {
    // Check for duplicate pending updates
    _pendingUpdates.removeWhere((u) => u.id == id);

    final update = OptimisticUpdate<T>(
      id: id,
      description: description,
      previousValue: previousValue,
      newValue: newValue,
      serverOperation: serverOperation,
      rollbackAction: rollbackAction,
    );

    // Apply locally immediately
    applyAction(newValue);
    _pendingUpdates.add(update);

    developer.log(
      'Optimistic update applied: $description',
      name: 'OptimisticUpdateManager',
    );

    // Confirm with server asynchronously
    _confirmUpdate(update);

    return update;
  }

  Future<void> _confirmUpdate<T>(OptimisticUpdate<T> update) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        final success = await update.serverOperation()
            .timeout(confirmationTimeout);

        if (success) {
          update._confirm();
          _pendingUpdates.remove(update);
          _addToHistory(update);
          onUpdateConfirmed?.call(update);

          developer.log(
            'Update confirmed: ${update.description}',
            name: 'OptimisticUpdateManager',
          );
          return;
        } else {
          // Server explicitly rejected
          update._rollback();
          _pendingUpdates.remove(update);
          onUpdateRolledBack?.call(update);

          developer.log(
            'Update rejected by server: ${update.description}',
            name: 'OptimisticUpdateManager',
          );
          return;
        }
      } on TimeoutException {
        attempts++;
        if (attempts >= maxRetries) {
          update._fail('Operation timed out');
          _pendingUpdates.remove(update);
          onUpdateFailed?.call(update, 'Operation timed out');

          developer.log(
            'Update timed out: ${update.description}',
            name: 'OptimisticUpdateManager',
          );
        }
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          update._fail(e.toString());
          _pendingUpdates.remove(update);
          onUpdateFailed?.call(update, e.toString());

          developer.log(
            'Update failed: ${update.description}',
            name: 'OptimisticUpdateManager',
            error: e,
          );
        } else {
          // Wait before retry
          await Future.delayed(Duration(milliseconds: 100 * attempts));
        }
      }
    }
  }

  void _addToHistory(OptimisticUpdate update) {
    _updateHistory.insert(0, update);
    if (_updateHistory.length > maxHistorySize) {
      _updateHistory.removeLast();
    }
  }

  /// Cancel a pending update and rollback
  void cancelUpdate(String id) {
    final update = _pendingUpdates.firstWhereOrNull((u) => u.id == id);
    if (update != null) {
      update._rollback();
      _pendingUpdates.remove(update);

      developer.log(
        'Update cancelled: ${update.description}',
        name: 'OptimisticUpdateManager',
      );
    }
  }

  /// Cancel all pending updates
  void cancelAllPending() {
    for (final update in _pendingUpdates.toList()) {
      update._rollback();
    }
    _pendingUpdates.clear();

    developer.log(
      'All pending updates cancelled',
      name: 'OptimisticUpdateManager',
    );
  }

  /// Clear update history
  void clearHistory() {
    _updateHistory.clear();
  }
}

/// Simplified optimistic update helper for common settings operations
class SettingsOptimisticHelper {
  final OptimisticUpdateManager _manager;

  SettingsOptimisticHelper(this._manager);

  /// Apply a simple toggle update
  Future<OptimisticUpdate<bool>> applyToggle({
    required String settingId,
    required String settingName,
    required bool currentValue,
    required void Function(bool) updateLocal,
    required Future<bool> Function() saveToServer,
  }) {
    return _manager.applyUpdate(
      id: 'toggle_$settingId',
      description: '${currentValue ? "Disable" : "Enable"} $settingName',
      previousValue: currentValue,
      newValue: !currentValue,
      applyAction: updateLocal,
      serverOperation: saveToServer,
      rollbackAction: updateLocal,
    );
  }

  /// Apply a value change update
  Future<OptimisticUpdate<T>> applyValueChange<T>({
    required String settingId,
    required String settingName,
    required T previousValue,
    required T newValue,
    required void Function(T) updateLocal,
    required Future<bool> Function() saveToServer,
  }) {
    return _manager.applyUpdate(
      id: 'change_$settingId',
      description: 'Update $settingName',
      previousValue: previousValue,
      newValue: newValue,
      applyAction: updateLocal,
      serverOperation: saveToServer,
      rollbackAction: updateLocal,
    );
  }

  /// Apply a list add operation
  Future<OptimisticUpdate<List<T>>> applyListAdd<T>({
    required String settingId,
    required String itemName,
    required List<T> currentList,
    required T newItem,
    required void Function(List<T>) updateLocal,
    required Future<bool> Function() saveToServer,
  }) {
    final newList = [...currentList, newItem];
    return _manager.applyUpdate(
      id: 'add_${settingId}_${newItem.hashCode}',
      description: 'Add $itemName',
      previousValue: currentList,
      newValue: newList,
      applyAction: updateLocal,
      serverOperation: saveToServer,
      rollbackAction: updateLocal,
    );
  }

  /// Apply a list remove operation
  Future<OptimisticUpdate<List<T>>> applyListRemove<T>({
    required String settingId,
    required String itemName,
    required List<T> currentList,
    required bool Function(T) removeCondition,
    required void Function(List<T>) updateLocal,
    required Future<bool> Function() saveToServer,
  }) {
    final newList = currentList.where((item) => !removeCondition(item)).toList();
    return _manager.applyUpdate(
      id: 'remove_${settingId}_${DateTime.now().millisecondsSinceEpoch}',
      description: 'Remove $itemName',
      previousValue: currentList,
      newValue: newList,
      applyAction: updateLocal,
      serverOperation: saveToServer,
      rollbackAction: updateLocal,
    );
  }
}

/// Batch update handler for multiple related changes
class BatchOptimisticUpdate {
  final String id;
  final String description;
  final List<OptimisticUpdate> updates = [];
  final DateTime timestamp = DateTime.now();

  bool _isCommitted = false;
  bool _isRolledBack = false;

  BatchOptimisticUpdate({
    required this.id,
    required this.description,
  });

  bool get isCommitted => _isCommitted;
  bool get isRolledBack => _isRolledBack;

  /// Add an update to the batch
  void add<T>(OptimisticUpdate<T> update) {
    if (_isCommitted || _isRolledBack) {
      throw StateError('Cannot add to committed or rolled back batch');
    }
    updates.add(update);
  }

  /// Commit all updates in the batch
  Future<bool> commit() async {
    if (_isCommitted || _isRolledBack) {
      return false;
    }

    try {
      // Execute all server operations
      for (final update in updates) {
        final success = await update.serverOperation();
        if (!success) {
          // Rollback all previous updates in this batch
          _rollbackAll();
          return false;
        }
        update._confirm();
      }

      _isCommitted = true;
      return true;
    } catch (e) {
      _rollbackAll();
      return false;
    }
  }

  void _rollbackAll() {
    _isRolledBack = true;
    for (final update in updates.reversed) {
      if (update.isPending || update.isConfirmed) {
        update._rollback();
      }
    }
  }

  /// Rollback all updates in the batch
  void rollback() {
    if (!_isRolledBack) {
      _rollbackAll();
    }
  }
}
