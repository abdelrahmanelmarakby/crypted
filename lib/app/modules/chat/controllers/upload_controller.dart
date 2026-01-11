import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:crypted_app/app/core/services/error_handler_service.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;

/// ARCH-001: Extracted Upload Controller
/// Handles all media upload operations
///
/// Responsibilities:
/// - Upload images, videos, audio, files
/// - Track upload progress
/// - Cancel uploads
/// - Manage upload state
class UploadController extends GetxController {
  final String _roomId;

  UploadController({required String roomId}) : _roomId = roomId;

  // Services
  final _logger = LoggerService.instance;
  final _errorHandler = ErrorHandlerService.instance;

  // Upload state
  final RxMap<String, UploadTask?> activeUploads = <String, UploadTask?>{}.obs;
  final RxMap<String, double> uploadProgress = <String, double>{}.obs;
  final RxMap<String, UploadStatus> uploadStatuses = <String, UploadStatus>{}.obs;

  // Callbacks for upload completion
  final Map<String, Function(String downloadUrl)?> _completionCallbacks = {};
  final Map<String, StreamSubscription?> _progressSubscriptions = {};

  String? get _currentUserId => UserService.currentUser.value?.uid;

  @override
  void onClose() {
    // Cancel all active uploads
    cancelAllUploads();
    super.onClose();
  }

  /// Upload an image file
  Future<String?> uploadImage(File file, {Function(double)? onProgress}) async {
    return _uploadFile(
      file: file,
      folder: 'chat_images',
      onProgress: onProgress,
    );
  }

  /// Upload a video file
  Future<String?> uploadVideo(File file, {Function(double)? onProgress}) async {
    return _uploadFile(
      file: file,
      folder: 'chat_videos',
      onProgress: onProgress,
    );
  }

  /// Upload an audio file
  Future<String?> uploadAudio(File file, {Function(double)? onProgress}) async {
    return _uploadFile(
      file: file,
      folder: 'chat_audio',
      onProgress: onProgress,
    );
  }

  /// Upload a general file
  Future<String?> uploadFile(File file, {Function(double)? onProgress}) async {
    return _uploadFile(
      file: file,
      folder: 'chat_files',
      onProgress: onProgress,
    );
  }

  /// Internal upload method
  Future<String?> _uploadFile({
    required File file,
    required String folder,
    Function(double)? onProgress,
  }) async {
    if (_currentUserId == null) {
      _errorHandler.showError('User not logged in');
      return null;
    }

    final uploadId = _generateUploadId();
    final fileName = path.basename(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$folder/$_roomId/${timestamp}_$fileName';

    _logger.debug('Starting upload', context: 'UploadController', data: {
      'uploadId': uploadId,
      'fileName': fileName,
      'folder': folder,
    });

    try {
      // Initialize upload state
      uploadStatuses[uploadId] = UploadStatus.uploading;
      uploadProgress[uploadId] = 0.0;

      // Create storage reference
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      // Start upload
      final uploadTask = storageRef.putFile(file);
      activeUploads[uploadId] = uploadTask;

      // Track progress
      _progressSubscriptions[uploadId] = uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          uploadProgress[uploadId] = progress;
          onProgress?.call(progress);
        },
        onError: (error) {
          _logger.logError('Upload error', error: error, context: 'UploadController');
          uploadStatuses[uploadId] = UploadStatus.failed;
        },
      );

      // Wait for completion
      await uploadTask;

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Update state
      uploadStatuses[uploadId] = UploadStatus.completed;
      uploadProgress[uploadId] = 1.0;

      _logger.info('Upload completed', context: 'UploadController', data: {
        'uploadId': uploadId,
        'downloadUrl': downloadUrl,
      });

      // Call completion callback if set
      _completionCallbacks[uploadId]?.call(downloadUrl);

      // Cleanup
      _cleanupUpload(uploadId);

      return downloadUrl;
    } catch (e, stackTrace) {
      uploadStatuses[uploadId] = UploadStatus.failed;

      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'UploadController._uploadFile',
        showToUser: true,
      );

      _cleanupUpload(uploadId);
      return null;
    }
  }

  /// Start a tracked upload with UI updates
  Future<String?> startTrackedUpload({
    required File file,
    required String uploadType,
    String? thumbnailPath,
    Function(String downloadUrl)? onComplete,
  }) async {
    final uploadId = _generateUploadId();
    final fileName = path.basename(file.path);
    final fileSize = await file.length();

    // Store completion callback
    if (onComplete != null) {
      _completionCallbacks[uploadId] = onComplete;
    }

    _logger.debug('Starting tracked upload', context: 'UploadController', data: {
      'uploadId': uploadId,
      'fileName': fileName,
      'fileSize': fileSize,
      'uploadType': uploadType,
    });

    // Determine folder based on type
    String folder;
    switch (uploadType.toLowerCase()) {
      case 'image':
      case 'photo':
        folder = 'chat_images';
        break;
      case 'video':
        folder = 'chat_videos';
        break;
      case 'audio':
        folder = 'chat_audio';
        break;
      default:
        folder = 'chat_files';
    }

    return _uploadFile(
      file: file,
      folder: folder,
      onProgress: (progress) {
        uploadProgress[uploadId] = progress;
      },
    );
  }

  /// Cancel a specific upload
  void cancelUpload(String uploadId) {
    _logger.debug('Cancelling upload', context: 'UploadController', data: {
      'uploadId': uploadId,
    });

    final uploadTask = activeUploads[uploadId];
    if (uploadTask != null) {
      uploadTask.cancel();
    }

    uploadStatuses[uploadId] = UploadStatus.cancelled;
    _cleanupUpload(uploadId);

    BotToast.showText(text: 'Upload cancelled');
  }

  /// Cancel all active uploads
  void cancelAllUploads() {
    _logger.debug('Cancelling all uploads', context: 'UploadController', data: {
      'count': activeUploads.length,
    });

    for (final uploadId in activeUploads.keys.toList()) {
      cancelUpload(uploadId);
    }
  }

  /// Get upload progress for a specific upload
  double getUploadProgress(String uploadId) {
    return uploadProgress[uploadId] ?? 0.0;
  }

  /// Get upload status for a specific upload
  UploadStatus getUploadStatus(String uploadId) {
    return uploadStatuses[uploadId] ?? UploadStatus.idle;
  }

  /// Check if there are any active uploads
  bool get hasActiveUploads => activeUploads.values.any((task) => task != null);

  /// Get count of active uploads
  int get activeUploadCount => activeUploads.values.where((task) => task != null).length;

  /// Cleanup upload resources
  void _cleanupUpload(String uploadId) {
    activeUploads.remove(uploadId);
    _progressSubscriptions[uploadId]?.cancel();
    _progressSubscriptions.remove(uploadId);
    _completionCallbacks.remove(uploadId);

    // Remove progress and status after a delay (for UI updates)
    Future.delayed(const Duration(seconds: 2), () {
      uploadProgress.remove(uploadId);
      uploadStatuses.remove(uploadId);
    });
  }

  /// Generate unique upload ID
  String _generateUploadId() {
    return '${_roomId}_${DateTime.now().millisecondsSinceEpoch}_${_currentUserId ?? 'unknown'}';
  }

  /// Retry a failed upload
  Future<String?> retryUpload(String uploadId, File file, String uploadType) async {
    if (uploadStatuses[uploadId] != UploadStatus.failed) {
      _errorHandler.showError('Upload is not in failed state');
      return null;
    }

    _cleanupUpload(uploadId);
    return startTrackedUpload(file: file, uploadType: uploadType);
  }
}

/// Upload status enum
enum UploadStatus {
  idle,
  uploading,
  completed,
  failed,
  cancelled,
}
