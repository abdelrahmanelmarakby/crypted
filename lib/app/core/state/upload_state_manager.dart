import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:get/get.dart';

/// STATE-005: Persistent Upload State Manager
/// Manages upload states that persist across widget rebuilds
/// Uses a singleton pattern with GetX for global access

class UploadStateManager extends GetxService {
  static UploadStateManager get instance => Get.find<UploadStateManager>();

  final _logger = LoggerService.instance;

  // Upload states by unique key (can be message ID or temp ID)
  final Map<String, UploadState> _uploads = {};

  // Observers for upload state changes
  final Map<String, List<void Function(UploadState)>> _observers = {};

  // Global upload progress observable
  final RxInt activeUploads = 0.obs;
  final RxDouble overallProgress = 0.0.obs;

  /// Start tracking an upload
  UploadState startUpload({
    required String id,
    required String fileName,
    required int totalBytes,
    String? roomId,
    UploadType type = UploadType.media,
    Map<String, dynamic>? metadata,
  }) {
    final upload = UploadState(
      id: id,
      fileName: fileName,
      totalBytes: totalBytes,
      roomId: roomId,
      type: type,
      metadata: metadata ?? {},
      status: UploadStatus.uploading,
      uploadedBytes: 0,
      progress: 0.0,
      startTime: DateTime.now(),
    );

    _uploads[id] = upload;
    _updateGlobalStats();
    _notifyObservers(id, upload);

    _logger.info('Upload started', context: 'UploadStateManager', data: {
      'id': id,
      'fileName': fileName,
      'totalBytes': totalBytes,
    });

    return upload;
  }

  /// Update upload progress
  void updateProgress(String id, int uploadedBytes) {
    final upload = _uploads[id];
    if (upload == null) return;

    final progress = upload.totalBytes > 0
        ? uploadedBytes / upload.totalBytes
        : 0.0;

    _uploads[id] = upload.copyWith(
      uploadedBytes: uploadedBytes,
      progress: progress.clamp(0.0, 1.0),
    );

    _updateGlobalStats();
    _notifyObservers(id, _uploads[id]!);
  }

  /// Mark upload as completed
  void completeUpload(String id, {String? downloadUrl}) {
    final upload = _uploads[id];
    if (upload == null) return;

    _uploads[id] = upload.copyWith(
      status: UploadStatus.completed,
      progress: 1.0,
      uploadedBytes: upload.totalBytes,
      downloadUrl: downloadUrl,
      endTime: DateTime.now(),
    );

    _updateGlobalStats();
    _notifyObservers(id, _uploads[id]!);

    _logger.info('Upload completed', context: 'UploadStateManager', data: {
      'id': id,
      'duration': _uploads[id]!.duration?.inSeconds,
    });
  }

  /// Mark upload as failed
  void failUpload(String id, {String? error, bool canRetry = true}) {
    final upload = _uploads[id];
    if (upload == null) return;

    _uploads[id] = upload.copyWith(
      status: UploadStatus.failed,
      error: error,
      canRetry: canRetry,
      endTime: DateTime.now(),
    );

    _updateGlobalStats();
    _notifyObservers(id, _uploads[id]!);

    _logger.warning('Upload failed', context: 'UploadStateManager', data: {
      'id': id,
      'error': error,
    });
  }

  /// Cancel an upload
  void cancelUpload(String id) {
    final upload = _uploads[id];
    if (upload == null) return;

    _uploads[id] = upload.copyWith(
      status: UploadStatus.cancelled,
      endTime: DateTime.now(),
    );

    _updateGlobalStats();
    _notifyObservers(id, _uploads[id]!);

    _logger.info('Upload cancelled', context: 'UploadStateManager', data: {
      'id': id,
    });
  }

  /// Pause an upload
  void pauseUpload(String id) {
    final upload = _uploads[id];
    if (upload == null) return;

    _uploads[id] = upload.copyWith(
      status: UploadStatus.paused,
    );

    _updateGlobalStats();
    _notifyObservers(id, _uploads[id]!);
  }

  /// Resume a paused upload
  void resumeUpload(String id) {
    final upload = _uploads[id];
    if (upload == null) return;

    _uploads[id] = upload.copyWith(
      status: UploadStatus.uploading,
    );

    _updateGlobalStats();
    _notifyObservers(id, _uploads[id]!);
  }

  /// Retry a failed upload
  void retryUpload(String id) {
    final upload = _uploads[id];
    if (upload == null || !upload.canRetry) return;

    _uploads[id] = upload.copyWith(
      status: UploadStatus.uploading,
      progress: 0.0,
      uploadedBytes: 0,
      error: null,
      startTime: DateTime.now(),
      endTime: null,
    );

    _updateGlobalStats();
    _notifyObservers(id, _uploads[id]!);

    _logger.info('Upload retry', context: 'UploadStateManager', data: {
      'id': id,
    });
  }

  /// Get upload state
  UploadState? getUpload(String id) => _uploads[id];

  /// Check if upload exists
  bool hasUpload(String id) => _uploads.containsKey(id);

  /// Get all uploads for a room
  List<UploadState> getUploadsForRoom(String roomId) {
    return _uploads.values.where((u) => u.roomId == roomId).toList();
  }

  /// Get all active uploads
  List<UploadState> getActiveUploads() {
    return _uploads.values.where((u) => u.isActive).toList();
  }

  /// Get all pending/failed uploads
  List<UploadState> getPendingUploads() {
    return _uploads.values.where((u) =>
        u.status == UploadStatus.failed ||
        u.status == UploadStatus.paused).toList();
  }

  /// Remove completed/cancelled uploads
  void cleanup({Duration? olderThan}) {
    final cutoff = olderThan != null
        ? DateTime.now().subtract(olderThan)
        : null;

    _uploads.removeWhere((id, upload) {
      if (!upload.isComplete) return false;
      if (cutoff != null && upload.endTime != null) {
        return upload.endTime!.isBefore(cutoff);
      }
      return true;
    });

    _updateGlobalStats();
  }

  /// Remove specific upload
  void removeUpload(String id) {
    _uploads.remove(id);
    _observers.remove(id);
    _updateGlobalStats();
  }

  /// Observe upload state changes
  void observe(String id, void Function(UploadState) callback) {
    _observers[id] ??= [];
    _observers[id]!.add(callback);
  }

  /// Remove observer
  void removeObserver(String id, void Function(UploadState) callback) {
    _observers[id]?.remove(callback);
  }

  /// Notify observers of state change
  void _notifyObservers(String id, UploadState state) {
    final callbacks = _observers[id];
    if (callbacks == null) return;

    for (final callback in callbacks) {
      callback(state);
    }
  }

  /// Update global statistics
  void _updateGlobalStats() {
    final active = _uploads.values.where((u) => u.isActive).toList();
    activeUploads.value = active.length;

    if (active.isEmpty) {
      overallProgress.value = 0.0;
    } else {
      final totalProgress = active.fold<double>(
        0.0,
        (sum, upload) => sum + upload.progress,
      );
      overallProgress.value = totalProgress / active.length;
    }
  }
}

/// Upload state data class
class UploadState {
  final String id;
  final String fileName;
  final int totalBytes;
  final int uploadedBytes;
  final double progress;
  final UploadStatus status;
  final UploadType type;
  final String? roomId;
  final String? downloadUrl;
  final String? error;
  final bool canRetry;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic> metadata;

  const UploadState({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    required this.uploadedBytes,
    required this.progress,
    required this.status,
    required this.type,
    required this.startTime,
    this.roomId,
    this.downloadUrl,
    this.error,
    this.canRetry = true,
    this.endTime,
    this.metadata = const {},
  });

  /// Is upload actively in progress
  bool get isActive =>
      status == UploadStatus.uploading || status == UploadStatus.paused;

  /// Is upload finished (success or failure)
  bool get isComplete =>
      status == UploadStatus.completed ||
      status == UploadStatus.failed ||
      status == UploadStatus.cancelled;

  /// Is upload successful
  bool get isSuccess => status == UploadStatus.completed;

  /// Duration of upload
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  /// Estimated time remaining
  Duration? get estimatedTimeRemaining {
    if (progress <= 0 || status != UploadStatus.uploading) return null;

    final elapsed = DateTime.now().difference(startTime);
    final totalEstimated = elapsed.inMilliseconds / progress;
    final remaining = totalEstimated - elapsed.inMilliseconds;

    return Duration(milliseconds: remaining.round());
  }

  /// Upload speed in bytes per second
  double get bytesPerSecond {
    if (uploadedBytes <= 0) return 0;
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    if (elapsed <= 0) return 0;
    return uploadedBytes / elapsed;
  }

  /// Create a copy with updated fields
  UploadState copyWith({
    String? id,
    String? fileName,
    int? totalBytes,
    int? uploadedBytes,
    double? progress,
    UploadStatus? status,
    UploadType? type,
    String? roomId,
    String? downloadUrl,
    String? error,
    bool? canRetry,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, dynamic>? metadata,
  }) {
    return UploadState(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      totalBytes: totalBytes ?? this.totalBytes,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      error: error ?? this.error,
      canRetry: canRetry ?? this.canRetry,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'UploadState($id, $status, ${(progress * 100).toStringAsFixed(1)}%)';
}

/// Upload status enum
enum UploadStatus {
  uploading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Upload type enum
enum UploadType {
  media,
  document,
  audio,
  other,
}

/// Widget for displaying upload progress
class UploadProgressIndicator extends StatelessWidget {
  final String uploadId;
  final Widget Function(UploadState?) builder;

  const UploadProgressIndicator({
    super.key,
    required this.uploadId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final manager = UploadStateManager.instance;
    final upload = manager.getUpload(uploadId);

    if (upload == null) {
      return builder(null);
    }

    return StreamBuilder<UploadState>(
      initialData: upload,
      stream: _createStream(manager, uploadId),
      builder: (context, snapshot) => builder(snapshot.data),
    );
  }

  Stream<UploadState> _createStream(UploadStateManager manager, String id) {
    final controller = StreamController<UploadState>.broadcast();

    void callback(UploadState state) {
      if (!controller.isClosed) {
        controller.add(state);
      }
    }

    manager.observe(id, callback);

    controller.onCancel = () {
      manager.removeObserver(id, callback);
      controller.close();
    };

    return controller.stream;
  }
}

/// Mixin for controllers with upload tracking
mixin UploadTrackingMixin on GetxController {
  final _uploadManager = UploadStateManager.instance;

  /// Start tracking an upload
  UploadState trackUpload({
    required String id,
    required String fileName,
    required int totalBytes,
    String? roomId,
    UploadType type = UploadType.media,
  }) {
    return _uploadManager.startUpload(
      id: id,
      fileName: fileName,
      totalBytes: totalBytes,
      roomId: roomId,
      type: type,
    );
  }

  /// Update upload progress
  void updateUploadProgress(String id, int uploadedBytes) {
    _uploadManager.updateProgress(id, uploadedBytes);
  }

  /// Complete upload
  void completeUpload(String id, {String? downloadUrl}) {
    _uploadManager.completeUpload(id, downloadUrl: downloadUrl);
  }

  /// Fail upload
  void failUpload(String id, {String? error}) {
    _uploadManager.failUpload(id, error: error);
  }

  /// Cancel upload
  void cancelUpload(String id) {
    _uploadManager.cancelUpload(id);
  }

  /// Get upload state
  UploadState? getUploadState(String id) => _uploadManager.getUpload(id);

  /// Check if has active uploads
  bool get hasActiveUploads => _uploadManager.activeUploads.value > 0;
}
