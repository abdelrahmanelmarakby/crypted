/// Settings Change Notifier
///
/// Provides user feedback for settings changes including:
/// - Save status indicators
/// - Change confirmations
/// - Sync status
/// - Conflict notifications

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Status of a settings save operation
enum SaveStatus {
  /// No pending changes
  idle,

  /// Changes are pending (debouncing)
  pending,

  /// Currently saving to server
  saving,

  /// Save completed successfully
  saved,

  /// Save failed
  failed,

  /// Syncing from server
  syncing,

  /// Conflict detected
  conflict,
}

/// A settings change event
class SettingsChangeEvent {
  final String settingId;
  final String settingName;
  final dynamic previousValue;
  final dynamic newValue;
  final DateTime timestamp;
  final String? category;

  const SettingsChangeEvent({
    required this.settingId,
    required this.settingName,
    required this.previousValue,
    required this.newValue,
    required this.timestamp,
    this.category,
  });

  String get displayMessage {
    if (newValue is bool) {
      return '$settingName ${newValue ? "enabled" : "disabled"}';
    }
    return '$settingName updated';
  }
}

/// Settings change notifier service
class SettingsChangeNotifier extends GetxService {
  static SettingsChangeNotifier get instance => Get.find();

  // Current save status
  final Rx<SaveStatus> saveStatus = SaveStatus.idle.obs;

  // Recent changes
  final RxList<SettingsChangeEvent> recentChanges = <SettingsChangeEvent>[].obs;

  // Pending changes count
  final RxInt pendingChangesCount = 0.obs;

  // Last sync time
  final Rx<DateTime?> lastSyncTime = Rx<DateTime?>(null);

  // Configuration
  final int maxRecentChanges;
  final Duration statusResetDelay;

  // Timer for resetting status
  Timer? _statusResetTimer;

  // Stream controller for change events
  final _changeController = StreamController<SettingsChangeEvent>.broadcast();

  /// Stream of settings changes
  Stream<SettingsChangeEvent> get changeStream => _changeController.stream;

  SettingsChangeNotifier({
    this.maxRecentChanges = 10,
    this.statusResetDelay = const Duration(seconds: 2),
  });

  @override
  void onClose() {
    _statusResetTimer?.cancel();
    _changeController.close();
    super.onClose();
  }

  /// Notify that a setting is about to change
  void notifyPending(String settingId) {
    pendingChangesCount.value++;
    saveStatus.value = SaveStatus.pending;
    _cancelStatusReset();
  }

  /// Notify that a setting has changed locally
  void notifyChanged(SettingsChangeEvent event) {
    recentChanges.insert(0, event);
    if (recentChanges.length > maxRecentChanges) {
      recentChanges.removeLast();
    }

    _changeController.add(event);

    developer.log(
      'Setting changed: ${event.displayMessage}',
      name: 'SettingsChangeNotifier',
    );
  }

  /// Notify that saving has started
  void notifySaving() {
    saveStatus.value = SaveStatus.saving;
    _cancelStatusReset();
  }

  /// Notify that save completed successfully
  void notifySaved() {
    pendingChangesCount.value = (pendingChangesCount.value - 1).clamp(0, 999);
    saveStatus.value = SaveStatus.saved;
    lastSyncTime.value = DateTime.now();

    _scheduleStatusReset();
  }

  /// Notify that save failed
  void notifyFailed({String? errorMessage}) {
    saveStatus.value = SaveStatus.failed;

    if (errorMessage != null) {
      developer.log(
        'Save failed: $errorMessage',
        name: 'SettingsChangeNotifier',
      );
    }

    // Don't auto-reset on failure
  }

  /// Notify syncing from server
  void notifySyncing() {
    saveStatus.value = SaveStatus.syncing;
    _cancelStatusReset();
  }

  /// Notify sync completed
  void notifySyncComplete() {
    saveStatus.value = SaveStatus.idle;
    lastSyncTime.value = DateTime.now();
  }

  /// Notify conflict detected
  void notifyConflict() {
    saveStatus.value = SaveStatus.conflict;
    // Don't auto-reset on conflict
  }

  /// Reset status to idle
  void resetStatus() {
    saveStatus.value = SaveStatus.idle;
    _cancelStatusReset();
  }

  void _scheduleStatusReset() {
    _cancelStatusReset();
    _statusResetTimer = Timer(statusResetDelay, () {
      if (saveStatus.value == SaveStatus.saved) {
        saveStatus.value = SaveStatus.idle;
      }
    });
  }

  void _cancelStatusReset() {
    _statusResetTimer?.cancel();
    _statusResetTimer = null;
  }

  /// Clear recent changes
  void clearRecentChanges() {
    recentChanges.clear();
  }

  /// Get status display text
  String get statusText {
    switch (saveStatus.value) {
      case SaveStatus.idle:
        return '';
      case SaveStatus.pending:
        return 'Changes pending...';
      case SaveStatus.saving:
        return 'Saving...';
      case SaveStatus.saved:
        return 'Saved';
      case SaveStatus.failed:
        return 'Save failed';
      case SaveStatus.syncing:
        return 'Syncing...';
      case SaveStatus.conflict:
        return 'Conflict detected';
    }
  }

  /// Get status icon
  IconData get statusIcon {
    switch (saveStatus.value) {
      case SaveStatus.idle:
        return Icons.check_circle_outline;
      case SaveStatus.pending:
        return Icons.pending_outlined;
      case SaveStatus.saving:
        return Icons.cloud_upload_outlined;
      case SaveStatus.saved:
        return Icons.cloud_done_outlined;
      case SaveStatus.failed:
        return Icons.error_outline;
      case SaveStatus.syncing:
        return Icons.sync;
      case SaveStatus.conflict:
        return Icons.warning_amber_outlined;
    }
  }

  /// Get status color
  Color statusColor(BuildContext context) {
    switch (saveStatus.value) {
      case SaveStatus.idle:
        return Colors.grey;
      case SaveStatus.pending:
        return Colors.orange;
      case SaveStatus.saving:
        return Theme.of(context).primaryColor;
      case SaveStatus.saved:
        return Colors.green;
      case SaveStatus.failed:
        return Colors.red;
      case SaveStatus.syncing:
        return Theme.of(context).primaryColor;
      case SaveStatus.conflict:
        return Colors.amber;
    }
  }
}

/// Widget that displays the current save status
class SaveStatusIndicator extends StatelessWidget {
  final SettingsChangeNotifier notifier;
  final bool showText;
  final double iconSize;

  const SaveStatusIndicator({
    super.key,
    required this.notifier,
    this.showText = true,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = notifier.saveStatus.value;
      if (status == SaveStatus.idle) {
        return const SizedBox.shrink();
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == SaveStatus.saving || status == SaveStatus.syncing)
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: notifier.statusColor(context),
              ),
            )
          else
            Icon(
              notifier.statusIcon,
              size: iconSize,
              color: notifier.statusColor(context),
            ),
          if (showText) ...[
            const SizedBox(width: 4),
            Text(
              notifier.statusText,
              style: TextStyle(
                fontSize: 12,
                color: notifier.statusColor(context),
              ),
            ),
          ],
        ],
      );
    });
  }
}

/// Widget that shows a subtle confirmation when a setting changes
class SettingChangeConfirmation extends StatefulWidget {
  final Widget child;
  final SettingsChangeNotifier notifier;
  final String settingId;

  const SettingChangeConfirmation({
    super.key,
    required this.child,
    required this.notifier,
    required this.settingId,
  });

  @override
  State<SettingChangeConfirmation> createState() => _SettingChangeConfirmationState();
}

class _SettingChangeConfirmationState extends State<SettingChangeConfirmation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _subscription = widget.notifier.changeStream.listen((event) {
      if (event.settingId == widget.settingId) {
        _playConfirmation();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  void _playConfirmation() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// Mixin for controllers that need change notification
mixin SettingsChangeNotification {
  SettingsChangeNotifier get changeNotifier =>
      Get.find<SettingsChangeNotifier>();

  /// Notify and log a setting change
  void notifySettingChanged<T>({
    required String settingId,
    required String settingName,
    required T previousValue,
    required T newValue,
    String? category,
  }) {
    final event = SettingsChangeEvent(
      settingId: settingId,
      settingName: settingName,
      previousValue: previousValue,
      newValue: newValue,
      timestamp: DateTime.now(),
      category: category,
    );

    changeNotifier.notifyChanged(event);
  }

  /// Wrap a save operation with status notifications
  Future<bool> notifiedSave(Future<bool> Function() saveOperation) async {
    changeNotifier.notifySaving();
    try {
      final result = await saveOperation();
      if (result) {
        changeNotifier.notifySaved();
      } else {
        changeNotifier.notifyFailed();
      }
      return result;
    } catch (e) {
      changeNotifier.notifyFailed(errorMessage: e.toString());
      rethrow;
    }
  }
}
