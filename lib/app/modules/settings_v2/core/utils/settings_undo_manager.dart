/// Settings Undo/Redo Manager
///
/// Provides undo and redo functionality for settings changes with:
/// - Command pattern implementation
/// - Grouped undo for related changes
/// - Expiration of old undo entries
/// - Memory-efficient state snapshots

import 'dart:async';
import 'dart:developer' as developer;
import 'package:get/get.dart';

/// A single undoable action
abstract class UndoableAction<T> {
  /// Unique identifier for this action
  final String id;

  /// Human-readable description
  final String description;

  /// When this action was created
  final DateTime timestamp;

  /// Category for grouping related actions
  final String? category;

  UndoableAction({
    required this.id,
    required this.description,
    DateTime? timestamp,
    this.category,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Execute the action (do/redo)
  Future<void> execute();

  /// Reverse the action (undo)
  Future<void> reverse();

  /// Get a snapshot of the current state (optional, for debugging)
  T? getSnapshot() => null;
}

/// Simple value change action
class ValueChangeAction<T> extends UndoableAction<T> {
  final T previousValue;
  final T newValue;
  final void Function(T) applyValue;
  final Future<void> Function()? onExecute;
  final Future<void> Function()? onReverse;

  ValueChangeAction({
    required super.id,
    required super.description,
    required this.previousValue,
    required this.newValue,
    required this.applyValue,
    this.onExecute,
    this.onReverse,
    super.category,
  });

  @override
  Future<void> execute() async {
    applyValue(newValue);
    await onExecute?.call();
  }

  @override
  Future<void> reverse() async {
    applyValue(previousValue);
    await onReverse?.call();
  }

  @override
  T? getSnapshot() => newValue;
}

/// Toggle action (special case of value change)
class ToggleAction extends ValueChangeAction<bool> {
  ToggleAction({
    required super.id,
    required super.description,
    required bool currentValue,
    required void Function(bool) toggle,
    super.onExecute,
    super.onReverse,
    super.category,
  }) : super(
          previousValue: currentValue,
          newValue: !currentValue,
          applyValue: toggle,
        );
}

/// List modification action
class ListModificationAction<T> extends UndoableAction<List<T>> {
  final List<T> previousList;
  final List<T> newList;
  final void Function(List<T>) applyList;
  final Future<void> Function()? onExecute;
  final Future<void> Function()? onReverse;

  ListModificationAction({
    required super.id,
    required super.description,
    required this.previousList,
    required this.newList,
    required this.applyList,
    this.onExecute,
    this.onReverse,
    super.category,
  });

  @override
  Future<void> execute() async {
    applyList(List.from(newList));
    await onExecute?.call();
  }

  @override
  Future<void> reverse() async {
    applyList(List.from(previousList));
    await onReverse?.call();
  }

  @override
  List<T>? getSnapshot() => newList;
}

/// Group of related actions that should be undone together
class ActionGroup extends UndoableAction<void> {
  final List<UndoableAction> actions;

  ActionGroup({
    required super.id,
    required super.description,
    required this.actions,
    super.category,
  });

  @override
  Future<void> execute() async {
    for (final action in actions) {
      await action.execute();
    }
  }

  @override
  Future<void> reverse() async {
    // Reverse in opposite order
    for (final action in actions.reversed) {
      await action.reverse();
    }
  }
}

/// Settings undo/redo manager
class SettingsUndoManager extends GetxService {
  static SettingsUndoManager get instance => Get.find();

  // Undo stack
  final RxList<UndoableAction> _undoStack = <UndoableAction>[].obs;

  // Redo stack
  final RxList<UndoableAction> _redoStack = <UndoableAction>[].obs;

  // Configuration
  final int maxUndoStackSize;
  final Duration? actionExpiration;

  // Callbacks
  void Function(UndoableAction)? onUndo;
  void Function(UndoableAction)? onRedo;

  // Timer for cleaning expired actions
  Timer? _cleanupTimer;

  SettingsUndoManager({
    this.maxUndoStackSize = 30,
    this.actionExpiration,
  });

  @override
  void onInit() {
    super.onInit();
    if (actionExpiration != null) {
      _startCleanupTimer();
    }
  }

  @override
  void onClose() {
    _cleanupTimer?.cancel();
    super.onClose();
  }

  /// Check if undo is available
  bool get canUndo => _undoStack.isNotEmpty;

  /// Check if redo is available
  bool get canRedo => _redoStack.isNotEmpty;

  /// Get the number of available undo actions
  int get undoCount => _undoStack.length;

  /// Get the number of available redo actions
  int get redoCount => _redoStack.length;

  /// Get description of the next undo action
  String? get nextUndoDescription =>
      _undoStack.isNotEmpty ? _undoStack.last.description : null;

  /// Get description of the next redo action
  String? get nextRedoDescription =>
      _redoStack.isNotEmpty ? _redoStack.last.description : null;

  /// Record an action that has been executed
  void recordAction(UndoableAction action) {
    _undoStack.add(action);
    _redoStack.clear(); // Clear redo stack when new action is recorded

    // Limit stack size
    while (_undoStack.length > maxUndoStackSize) {
      _undoStack.removeAt(0);
    }

    developer.log(
      'Action recorded: ${action.description}',
      name: 'SettingsUndoManager',
    );
  }

  /// Execute and record an action
  Future<void> executeAndRecord(UndoableAction action) async {
    await action.execute();
    recordAction(action);
  }

  /// Undo the last action
  Future<bool> undo() async {
    if (!canUndo) {
      developer.log(
        'Nothing to undo',
        name: 'SettingsUndoManager',
      );
      return false;
    }

    final action = _undoStack.removeLast();

    try {
      await action.reverse();
      _redoStack.add(action);
      onUndo?.call(action);

      developer.log(
        'Undone: ${action.description}',
        name: 'SettingsUndoManager',
      );
      return true;
    } catch (e) {
      developer.log(
        'Undo failed: ${action.description}',
        name: 'SettingsUndoManager',
        error: e,
      );
      // Put action back on undo stack
      _undoStack.add(action);
      return false;
    }
  }

  /// Redo the last undone action
  Future<bool> redo() async {
    if (!canRedo) {
      developer.log(
        'Nothing to redo',
        name: 'SettingsUndoManager',
      );
      return false;
    }

    final action = _redoStack.removeLast();

    try {
      await action.execute();
      _undoStack.add(action);
      onRedo?.call(action);

      developer.log(
        'Redone: ${action.description}',
        name: 'SettingsUndoManager',
      );
      return true;
    } catch (e) {
      developer.log(
        'Redo failed: ${action.description}',
        name: 'SettingsUndoManager',
        error: e,
      );
      // Put action back on redo stack
      _redoStack.add(action);
      return false;
    }
  }

  /// Undo all actions in a category
  Future<int> undoCategory(String category) async {
    int undoneCount = 0;

    while (canUndo) {
      final action = _undoStack.last;
      if (action.category != category) break;

      if (await undo()) {
        undoneCount++;
      } else {
        break;
      }
    }

    return undoneCount;
  }

  /// Clear all undo history
  void clearUndo() {
    _undoStack.clear();
    developer.log(
      'Undo stack cleared',
      name: 'SettingsUndoManager',
    );
  }

  /// Clear all redo history
  void clearRedo() {
    _redoStack.clear();
    developer.log(
      'Redo stack cleared',
      name: 'SettingsUndoManager',
    );
  }

  /// Clear all history
  void clearAll() {
    _undoStack.clear();
    _redoStack.clear();
    developer.log(
      'All history cleared',
      name: 'SettingsUndoManager',
    );
  }

  /// Get undo history
  List<UndoableAction> get undoHistory => _undoStack.toList();

  /// Get redo history
  List<UndoableAction> get redoHistory => _redoStack.toList();

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanupExpired(),
    );
  }

  void _cleanupExpired() {
    if (actionExpiration == null) return;

    final now = DateTime.now();
    final cutoff = now.subtract(actionExpiration!);

    _undoStack.removeWhere((action) => action.timestamp.isBefore(cutoff));
    _redoStack.removeWhere((action) => action.timestamp.isBefore(cutoff));
  }
}

/// Builder for creating undoable actions with a fluent API
class UndoableActionBuilder<T> {
  String? _id;
  String? _description;
  String? _category;
  T? _previousValue;
  T? _newValue;
  void Function(T)? _applyValue;
  Future<void> Function()? _onExecute;
  Future<void> Function()? _onReverse;

  UndoableActionBuilder<T> id(String id) {
    _id = id;
    return this;
  }

  UndoableActionBuilder<T> description(String description) {
    _description = description;
    return this;
  }

  UndoableActionBuilder<T> category(String category) {
    _category = category;
    return this;
  }

  UndoableActionBuilder<T> previousValue(T value) {
    _previousValue = value;
    return this;
  }

  UndoableActionBuilder<T> newValue(T value) {
    _newValue = value;
    return this;
  }

  UndoableActionBuilder<T> applyValue(void Function(T) apply) {
    _applyValue = apply;
    return this;
  }

  UndoableActionBuilder<T> onExecute(Future<void> Function() callback) {
    _onExecute = callback;
    return this;
  }

  UndoableActionBuilder<T> onReverse(Future<void> Function() callback) {
    _onReverse = callback;
    return this;
  }

  ValueChangeAction<T> build() {
    if (_id == null) throw StateError('id is required');
    if (_description == null) throw StateError('description is required');
    if (_previousValue == null) throw StateError('previousValue is required');
    if (_newValue == null) throw StateError('newValue is required');
    if (_applyValue == null) throw StateError('applyValue is required');

    return ValueChangeAction<T>(
      id: _id!,
      description: _description!,
      previousValue: _previousValue as T,
      newValue: _newValue as T,
      applyValue: _applyValue!,
      onExecute: _onExecute,
      onReverse: _onReverse,
      category: _category,
    );
  }
}

/// Extension methods for easy undo manager access
extension UndoManagerExtension on GetxController {
  SettingsUndoManager get undoManager => Get.find<SettingsUndoManager>();

  /// Record a value change with undo support
  Future<void> recordChange<T>({
    required String id,
    required String description,
    required T previousValue,
    required T newValue,
    required void Function(T) applyValue,
    Future<void> Function()? saveToServer,
    String? category,
  }) async {
    final action = ValueChangeAction<T>(
      id: id,
      description: description,
      previousValue: previousValue,
      newValue: newValue,
      applyValue: applyValue,
      onExecute: saveToServer,
      onReverse: saveToServer,
      category: category,
    );

    undoManager.recordAction(action);
  }

  /// Record a toggle with undo support
  Future<void> recordToggle({
    required String id,
    required String description,
    required bool currentValue,
    required void Function(bool) toggle,
    Future<void> Function()? saveToServer,
    String? category,
  }) async {
    final action = ToggleAction(
      id: id,
      description: description,
      currentValue: currentValue,
      toggle: toggle,
      onExecute: saveToServer,
      onReverse: saveToServer,
      category: category,
    );

    undoManager.recordAction(action);
  }
}
