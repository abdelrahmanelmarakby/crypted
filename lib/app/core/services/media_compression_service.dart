import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for compressing images and videos before upload
class MediaCompressionService {
  static final MediaCompressionService instance = MediaCompressionService._();
  MediaCompressionService._();

  /// Compress an image file
  Future<File?> compressImage(
    File imageFile, {
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    try {
      if (kDebugMode) {
        dev.log('🖼️ Image compression requested: ${imageFile.path}');
        dev.log('   Quality: $quality%, Max: ${maxWidth}x$maxHeight');
      }

      // Get file size before compression
      final originalSize = await imageFile.length();

      // Create output path
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed${path.extension(imageFile.path)}',
      );

      // Compress the image
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        if (kDebugMode) {
          dev.log('⚠️ Image compression returned null, using original file');
        }
        return imageFile;
      }

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();
      final compressionRatio = (1 - (compressedSize / originalSize)) * 100;

      if (kDebugMode) {
        dev.log('✅ Image compressed successfully');
        dev.log('   Original: ${(originalSize / 1024).toStringAsFixed(2)} KB');
        dev.log('   Compressed: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
        dev.log('   Saved: ${compressionRatio.toStringAsFixed(1)}%');
      }

      return compressedFile;
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error compressing image: $e');
      }
      // Return original file on error
      return imageFile;
    }
  }

  /// Compress a video file
  Future<File?> compressVideo(
    File videoFile, {
    String quality = 'medium', // low, medium, high
  }) async {
    try {
      if (kDebugMode) {
        dev.log('🎥 Video compression requested: ${videoFile.path}');
        dev.log('   Quality: $quality');
      }

      // Get file size before compression
      final originalSize = await videoFile.length();

      // Map quality to video quality enum
      VideoQuality videoQuality;
      switch (quality.toLowerCase()) {
        case 'low':
          videoQuality = VideoQuality.LowQuality;
          break;
        case 'high':
          videoQuality = VideoQuality.HighestQuality;
          break;
        case 'medium':
        default:
          videoQuality = VideoQuality.MediumQuality;
          break;
      }

      // Compress the video
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: videoQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info == null || info.file == null) {
        if (kDebugMode) {
          dev.log('⚠️ Video compression returned null, using original file');
        }
        return videoFile;
      }

      final compressedFile = info.file!;
      final compressedSize = await compressedFile.length();
      final compressionRatio = (1 - (compressedSize / originalSize)) * 100;

      if (kDebugMode) {
        dev.log('✅ Video compressed successfully');
        dev.log('   Original: ${(originalSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        dev.log('   Compressed: ${(compressedSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        dev.log('   Saved: ${compressionRatio.toStringAsFixed(1)}%');
        dev.log('   Duration: ${info.duration?.toStringAsFixed(2)}s');
      }

      return compressedFile;
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error compressing video: $e');
      }
      // Return original file on error
      return videoFile;
    }
  }

  /// Generate thumbnail for video
  Future<File?> generateVideoThumbnail(File videoFile) async {
    try {
      if (kDebugMode) {
        dev.log('📸 Thumbnail generation requested: ${videoFile.path}');
      }

      // Generate thumbnail
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        maxHeight: 512,
        quality: 85,
      );

      if (thumbnailPath == null) {
        if (kDebugMode) {
          dev.log('⚠️ Thumbnail generation returned null');
        }
        return null;
      }

      final thumbnailFile = File(thumbnailPath);
      final thumbnailSize = await thumbnailFile.length();

      if (kDebugMode) {
        dev.log('✅ Thumbnail generated successfully');
        dev.log('   Path: $thumbnailPath');
        dev.log('   Size: ${(thumbnailSize / 1024).toStringAsFixed(2)} KB');
      }

      return thumbnailFile;
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error generating thumbnail: $e');
      }
      return null;
    }
  }

  /// Dispose and clean up resources
  void dispose() {
    VideoCompress.deleteAllCache();
    if (kDebugMode) {
      dev.log('🧹 MediaCompressionService: Video cache cleared');
    }
  }
}
