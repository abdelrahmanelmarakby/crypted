import 'dart:io';
import 'package:crypted_app/app/core/exceptions/app_exceptions.dart';
import 'package:crypted_app/app/core/services/error_handler_service.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:crypted_app/app/core/services/premium_service.dart';
import 'package:crypted_app/app/core/state/upload_state_manager.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

/// Media Controller - Handles all media operations
///
/// Responsibilities:
/// - Pick media (images, videos, files)
/// - Upload media to Firebase Storage
/// - Compress images and videos
/// - Track upload progress
/// - Generate thumbnails
///
/// Features:
/// - Professional error handling
/// - Progress tracking with UploadStateManager integration
/// - Automatic compression
/// - File type validation
/// - Size validation
/// - Upload speed and ETA calculation
class MediaController extends GetxController with UploadTrackingMixin {
  final String roomId;

  MediaController({required this.roomId});

  // Upload state
  final RxDouble uploadProgress = 0.0.obs;
  final RxBool isUploading = false.obs;
  final RxString uploadStatus = ''.obs;
  final RxString currentFileName = ''.obs;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  // Compression settings
  final int imageQuality = 85;
  final int maxImageDimension = 1920;
  final int maxImageSizeKB = 2048; // 2MB

  // File size limits — now premium-aware via PremiumService
  int get maxFileSizeMB => PremiumService.instance.fileUploadLimitMB;
  int get maxVideoSizeMB => PremiumService.instance.fileUploadLimitMB;

  // Services
  final _logger = LoggerService.instance;
  final _errorHandler = ErrorHandlerService.instance;

  // Storage reference
  FirebaseStorage get _storage => FirebaseStorage.instance;

  // ========== IMAGE OPERATIONS ==========

  /// Pick image from camera or gallery
  Future<File?> pickImage(ImageSource source) async {
    try {
      _logger.debug('Picking image', context: 'MediaController', data: {
        'source': source.name,
      });

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxImageDimension.toDouble(),
        maxHeight: maxImageDimension.toDouble(),
      );

      if (pickedFile == null) {
        _logger.debug('Image picking cancelled', context: 'MediaController');
        return null;
      }

      final file = File(pickedFile.path);

      // Check file size
      final fileSizeKB = await file.length() ~/ 1024;

      _logger
          .info('Image picked successfully', context: 'MediaController', data: {
        'sizeKB': fileSizeKB,
      });

      return file;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MediaController.pickImage',
        showToUser: true,
      );
      return null;
    }
  }

  /// Upload image to Firebase Storage (EXIF stripped for privacy)
  Future<String?> uploadImage(File image) async {
    try {
      // Strip EXIF data (GPS location, camera info) before upload
      final strippedImage = await _stripExifData(image);
      final uploadFile = strippedImage ?? image;

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(uploadFile.path)}';
      currentFileName.value = fileName;

      _logger.debug('Uploading image', context: 'MediaController', data: {
        'fileName': fileName,
        'sizeKB': (await uploadFile.length()) ~/ 1024,
        'exifStripped': strippedImage != null,
      });

      return await _uploadFile(
        file: uploadFile,
        storagePath: 'chats/$roomId/images/$fileName',
      );
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MediaController.uploadImage',
        showToUser: true,
      );
      return null;
    }
  }

  /// Strip EXIF data from an image file for privacy
  /// Returns the stripped file, or null if stripping failed (fallback to original)
  Future<File?> _stripExifData(File image) async {
    try {
      final targetPath =
          '${image.parent.path}/stripped_${path.basename(image.path)}';
      final result = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        targetPath,
        quality: imageQuality,
        keepExif: false, // Strip all EXIF data including GPS
      );
      if (result != null) {
        return File(result.path);
      }
      return null;
    } catch (e) {
      _logger.error('EXIF stripping failed (non-critical): $e',
          context: 'MediaController');
      return null; // Fall back to original file
    }
  }

  // ========== VIDEO OPERATIONS ==========

  /// Pick video from camera or gallery
  Future<File?> pickVideo() async {
    try {
      _logger.debug('Picking video', context: 'MediaController');

      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (pickedFile == null) {
        _logger.debug('Video picking cancelled', context: 'MediaController');
        return null;
      }

      final file = File(pickedFile.path);

      // Check file size
      final fileSizeMB = (await file.length()) ~/ (1024 * 1024);
      if (fileSizeMB > maxVideoSizeMB) {
        throw MediaException(
          'video',
          'فيديو كبير جداً (حد أقصى ${maxVideoSizeMB}MB) / Video too large (max ${maxVideoSizeMB}MB)',
        );
      }

      _logger
          .info('Video picked successfully', context: 'MediaController', data: {
        'sizeMB': fileSizeMB,
      });

      return file;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MediaController.pickVideo',
        showToUser: true,
      );
      return null;
    }
  }

  /// Upload video to Firebase Storage
  Future<String?> uploadVideo(File video) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(video.path)}';
      currentFileName.value = fileName;

      _logger.debug('Uploading video', context: 'MediaController', data: {
        'fileName': fileName,
        'sizeMB': (await video.length()) ~/ (1024 * 1024),
      });

      return await _uploadFile(
        file: video,
        storagePath: 'chats/$roomId/videos/$fileName',
      );
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MediaController.uploadVideo',
        showToUser: true,
      );
      return null;
    }
  }

  // ========== AUDIO OPERATIONS ==========

  /// Upload audio to Firebase Storage
  Future<String?> uploadAudio(File audio) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(audio.path)}';
      currentFileName.value = fileName;

      _logger.debug('Uploading audio', context: 'MediaController', data: {
        'fileName': fileName,
        'sizeKB': (await audio.length()) ~/ 1024,
      });

      return await _uploadFile(
        file: audio,
        storagePath: 'chats/$roomId/audio/$fileName',
      );
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MediaController.uploadAudio',
        showToUser: true,
      );
      return null;
    }
  }

  // ========== FILE OPERATIONS ==========

  /// Pick file (documents, etc.)
  Future<File?> pickFile() async {
    try {
      _logger.debug('Picking file', context: 'MediaController');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        _logger.debug('File picking cancelled', context: 'MediaController');
        return null;
      }

      final file = File(result.files.first.path!);

      // Check file size
      final fileSizeMB = (await file.length()) ~/ (1024 * 1024);
      if (fileSizeMB > maxFileSizeMB) {
        throw MediaException(
          'file',
          'ملف كبير جداً (حد أقصى ${maxFileSizeMB}MB) / File too large (max ${maxFileSizeMB}MB)',
        );
      }

      _logger
          .info('File picked successfully', context: 'MediaController', data: {
        'fileName': result.files.first.name,
        'sizeMB': fileSizeMB,
      });

      return file;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MediaController.pickFile',
        showToUser: true,
      );
      return null;
    }
  }

  /// Upload file to Firebase Storage
  Future<String?> uploadFile(File file) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      currentFileName.value = fileName;

      _logger.debug('Uploading file', context: 'MediaController', data: {
        'fileName': fileName,
        'sizeMB': (await file.length()) ~/ (1024 * 1024),
      });

      return await _uploadFile(
        file: file,
        storagePath: 'chats/$roomId/files/$fileName',
      );
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MediaController.uploadFile',
        showToUser: true,
      );
      return null;
    }
  }

  // ========== INTERNAL METHODS ==========

  /// Internal upload method with progress tracking
  /// Integrates with UploadStateManager for centralized state management
  Future<String> _uploadFile({
    required File file,
    required String storagePath,
    String? uploadId,
  }) async {
    isUploading.value = true;
    uploadProgress.value = 0.0;
    uploadStatus.value = 'جاري الرفع... / Uploading...';

    // Generate upload ID if not provided
    final trackingId =
        uploadId ?? 'upload_${DateTime.now().millisecondsSinceEpoch}';
    final fileName = path.basename(file.path);
    final fileSize = await file.length();

    // Determine upload type based on file extension
    final ext = path.extension(file.path).toLowerCase();
    final uploadType = _getUploadType(ext);

    // Track upload using UploadStateManager
    trackUpload(
      id: trackingId,
      fileName: fileName,
      totalBytes: fileSize,
      roomId: roomId,
      type: uploadType,
    );

    try {
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(file);

      // Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        uploadProgress.value = progress;
        uploadStatus.value =
            'رفع ${(progress * 100).toStringAsFixed(0)}% / Uploading ${(progress * 100).toStringAsFixed(0)}%';

        // Update UploadStateManager with bytes transferred
        updateUploadProgress(trackingId, snapshot.bytesTransferred);

        _logger.debug('Upload progress', context: 'MediaController', data: {
          'progress': '${(progress * 100).toStringAsFixed(1)}%',
          'bytesTransferred': snapshot.bytesTransferred,
          'totalBytes': snapshot.totalBytes,
        });
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;

      if (snapshot.state != TaskState.success) {
        throw StorageException('Upload failed');
      }

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      uploadProgress.value = 1.0;
      uploadStatus.value = 'اكتمل! / Complete!';

      // Mark upload as completed in UploadStateManager
      completeUpload(trackingId, downloadUrl: downloadUrl);

      _logger.info('File uploaded successfully',
          context: 'MediaController',
          data: {
            'storagePath': storagePath,
            'url': downloadUrl,
            'trackingId': trackingId,
          });

      _errorHandler.showSuccess('رفع ناجح / Upload successful');

      return downloadUrl;
    } catch (e, stackTrace) {
      uploadStatus.value = 'فشل / Failed';

      // Mark upload as failed in UploadStateManager
      failUpload(trackingId, error: e.toString());

      _logger.logError(
        'Upload failed',
        error: e,
        stackTrace: stackTrace,
        context: 'MediaController._uploadFile',
      );

      throw StorageException('فشل الرفع / Upload failed');
    } finally {
      isUploading.value = false;
      currentFileName.value = '';

      // Reset progress after delay
      Future.delayed(const Duration(seconds: 2), () {
        uploadProgress.value = 0.0;
        uploadStatus.value = '';
      });
    }
  }

  /// Get upload type based on file extension
  UploadType _getUploadType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
      case '.mp4':
      case '.mov':
      case '.avi':
        return UploadType.media;
      case '.mp3':
      case '.wav':
      case '.aac':
      case '.m4a':
        return UploadType.audio;
      case '.pdf':
      case '.doc':
      case '.docx':
      case '.xls':
      case '.xlsx':
        return UploadType.document;
      default:
        return UploadType.other;
    }
  }

  /// Reset upload state
  void resetUploadState() {
    isUploading.value = false;
    uploadProgress.value = 0.0;
    uploadStatus.value = '';
    currentFileName.value = '';
  }

  @override
  void onClose() {
    _logger.info('MediaController disposed', context: 'MediaController');
    super.onClose();
  }
}
