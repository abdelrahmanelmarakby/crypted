import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

/// Platform-aware file download helper
/// Handles downloads correctly on both Android and iOS
class FileDownloadHelper {
  static final Dio _dio = Dio();

  /// Download a file from URL
  /// On Android: Saves to Downloads folder
  /// On iOS: Opens share sheet for user to save
  static Future<DownloadResult> downloadFile({
    required String url,
    required String fileName,
    void Function(int progress)? onProgress,
  }) async {
    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await _requestStoragePermission();
        if (!status) {
          return DownloadResult.failure('Storage permission denied');
        }
      }

      // Get appropriate directory
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        return DownloadResult.failure('Could not access storage');
      }

      final filePath = '${directory.path}/$fileName';

      // Download file
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            final progress = (received / total * 100).round();
            onProgress(progress);
          }
        },
      );

      final file = File(filePath);
      if (!await file.exists()) {
        return DownloadResult.failure('Download failed');
      }

      // On iOS, open share sheet for user to save
      if (Platform.isIOS) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Save $fileName',
        );
      }

      return DownloadResult.success(filePath);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Download error: $e');
      }
      return DownloadResult.failure('Download failed: $e');
    }
  }

  /// Download and immediately share (useful for iOS)
  static Future<DownloadResult> downloadAndShare({
    required String url,
    required String fileName,
    void Function(int progress)? onProgress,
  }) async {
    try {
      // Download to temp directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            final progress = (received / total * 100).round();
            onProgress(progress);
          }
        },
      );

      final file = File(filePath);
      if (!await file.exists()) {
        return DownloadResult.failure('Download failed');
      }

      // Open share sheet
      await Share.shareXFiles([XFile(filePath)]);

      return DownloadResult.success(filePath);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Download and share error: $e');
      }
      return DownloadResult.failure('Failed: $e');
    }
  }

  /// Get appropriate download directory for each platform
  static Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Try to get external storage downloads directory
      try {
        // For Android 10+ (API 29+), use app-specific directory or MediaStore
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Navigate to Downloads folder in external storage
          final downloadPath = externalDir.path.replaceFirst(
            RegExp(r'/Android/data/[^/]+/files'),
            '/Download',
          );
          final downloadDir = Directory(downloadPath);
          if (await downloadDir.exists()) {
            return downloadDir;
          }
          // Fallback to app's external files directory
          return externalDir;
        }
      } catch (_) {}

      // Fallback to app documents directory
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      // iOS: Use app documents directory, then share
      return await getApplicationDocumentsDirectory();
    }

    // Other platforms
    return await getApplicationDocumentsDirectory();
  }

  /// Request storage permission (Android only)
  static Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Check Android version for appropriate permission
    final status = await Permission.storage.status;
    if (status.isGranted) return true;

    // Request permission
    final result = await Permission.storage.request();
    if (result.isGranted) return true;

    // For Android 11+, try manage external storage
    if (result.isPermanentlyDenied) {
      final manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) {
        final manageResult = await Permission.manageExternalStorage.request();
        return manageResult.isGranted;
      }
      return true;
    }

    return false;
  }

  /// Show download progress snackbar
  static void showDownloadProgress(String fileName) {
    Get.snackbar(
      'Downloading',
      'Downloading $fileName...',
      showProgressIndicator: true,
      duration: const Duration(seconds: 30),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Show download complete snackbar
  static void showDownloadComplete(String fileName, String path) {
    Get.closeCurrentSnackbar();
    if (Platform.isIOS) {
      Get.snackbar(
        'Downloaded',
        'File ready to save',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'Downloaded',
        '$fileName saved to Downloads',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Show download error snackbar
  static void showDownloadError(String message) {
    Get.closeCurrentSnackbar();
    Get.snackbar(
      'Download Failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
}

/// Result of download operation
class DownloadResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;

  const DownloadResult._({
    required this.success,
    this.filePath,
    this.errorMessage,
  });

  factory DownloadResult.success(String path) {
    return DownloadResult._(success: true, filePath: path);
  }

  factory DownloadResult.failure(String message) {
    return DownloadResult._(success: false, errorMessage: message);
  }
}
