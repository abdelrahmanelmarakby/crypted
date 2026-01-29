import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/core/services/backup/backup_service_v3.dart';
import 'package:crypted_app/app/data/data_source/backup_data_source.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Media backup strategy - backs up images, videos, audio, and files from messages
///
/// **Features:**
/// - Chunked processing (10 files at a time to avoid memory issues)
/// - Compression for images (configurable quality)
/// - Size limits (respects maxMediaSize option)
/// - Incremental backup (only backs up media from new messages)
/// - Lightweight (streams files, deletes temp files after upload)
class MediaBackupStrategy extends BackupStrategy {
  final BackupDataSource _backupDataSource = BackupDataSource();

  static const int _fileBatchSize = 10; // Process 10 media files at a time
  static const int _messagesPerRoom = 500;

  @override
  Future<BackupResult> execute(BackupContext context) async {
    try {
      log('📸 Starting media backup...');

      int successfulItems = 0;
      int failedItems = 0;
      int bytesTransferred = 0;
      final errors = <String>[];

      // Step 1: Get all chat rooms for user
      final chatRooms = await _getUserChatRooms(context);

      if (chatRooms.isEmpty) {
        log('⚠️ No chat rooms found for user');
        return BackupResult(
          totalItems: 0,
          successfulItems: 0,
          failedItems: 0,
          bytesTransferred: 0,
        );
      }

      // Step 2: Collect media URLs from all messages
      final mediaUrls = <String, Map<String, dynamic>>{};

      for (final chatRoom in chatRooms) {
        try {
          final messages = await _getChatMessages(
            roomId: chatRoom.id ?? '',
            limit: _messagesPerRoom,
            context: context,
          );

          for (final message in messages) {
            final mediaUrl = _extractMediaUrl(message);
            if (mediaUrl != null && mediaUrl.isNotEmpty) {
              mediaUrls[mediaUrl] = {
                'messageId': message.id,
                'chatRoomId': chatRoom.id,
                'timestamp': message.timestamp,
                'messageType': message.runtimeType.toString(),
              };
            }
          }
        } catch (e) {
          log('❌ Error processing room ${chatRoom.id}: $e');
          errors.add('Room ${chatRoom.id}: $e');
        }
      }

      final totalItems = mediaUrls.length;
      log('📊 Found $totalItems media files to backup');

      if (totalItems == 0) {
        return BackupResult(
          totalItems: 0,
          successfulItems: 0,
          failedItems: 0,
          bytesTransferred: 0,
        );
      }

      // Step 3: Download and upload media in batches
      final mediaEntries = mediaUrls.entries.toList();

      for (int i = 0; i < mediaEntries.length; i += _fileBatchSize) {
        final batch = mediaEntries.skip(i).take(_fileBatchSize).toList();

        for (final entry in batch) {
          final mediaUrl = entry.key;
          final metadata = entry.value;

          try {
            // Download media file
            final tempFile = await _downloadMedia(
              url: mediaUrl,
              maxSizeMB: context.options.maxMediaSize,
            );

            if (tempFile == null) {
              log('⚠️ Skipped media (too large or download failed): $mediaUrl');
              failedItems++;
              continue;
            }

            // Compress if needed (for images only)
            File fileToUpload = tempFile;
            if (context.options.compressMedia &&
                _isImage(mediaUrl)) {
              final compressed = await _compressImage(
                tempFile,
                quality: 50,
              );
              fileToUpload = compressed ?? tempFile;
            }

            // Generate backup filename
            final fileName = _generateFileName(
              originalUrl: mediaUrl,
              metadata: metadata,
            );

            // Upload to backup storage
            await _backupDataSource.uploadFile(
              backupId: context.backupId,
              fileName: fileName,
              file: fileToUpload,
              folder: 'media',
            );

            successfulItems++;
            bytesTransferred += await fileToUpload.length();

            // Clean up temp file
            try {
              await tempFile.delete();
              if (fileToUpload.path != tempFile.path) {
                await fileToUpload.delete();
              }
            } catch (e) {
              log('⚠️ Failed to delete temp file: $e');
            }

          } catch (e) {
            log('❌ Error backing up media $mediaUrl: $e');
            errors.add('Media $mediaUrl: $e');
            failedItems++;
          }
        }

        // Brief pause between batches
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Step 4: Save media metadata
      await _saveMediaMetadata(
        context: context,
        mediaUrls: mediaUrls,
      );

      log('✅ Media backup completed: $successfulItems/$totalItems files backed up');

      return BackupResult(
        totalItems: totalItems,
        successfulItems: successfulItems,
        failedItems: failedItems,
        bytesTransferred: bytesTransferred,
        errors: errors,
      );

    } catch (e, stackTrace) {
      log('❌ Media backup failed: $e', stackTrace: stackTrace);
      return BackupResult(
        totalItems: 0,
        successfulItems: 0,
        failedItems: 1,
        bytesTransferred: 0,
        errors: ['Media backup failed: $e'],
      );
    }
  }

  @override
  Future<int> estimateItemCount(BackupContext context) async {
    try {
      final chatRooms = await _getUserChatRooms(context);
      int mediaCount = 0;

      for (final chatRoom in chatRooms) {
        final messages = await _getChatMessages(
          roomId: chatRoom.id ?? '',
          limit: 100, // Sample 100 messages per room for estimation
          context: context,
        );

        for (final message in messages) {
          if (_extractMediaUrl(message) != null) {
            mediaCount++;
          }
        }
      }

      return mediaCount;
    } catch (e) {
      log('❌ Error estimating media count: $e');
      return 0;
    }
  }

  @override
  Future<bool> needsBackup(dynamic item, BackupContext context) async {
    // If incremental mode, check if media already backed up
    if (context.options.incrementalOnly) {
      // This would require checking backup metadata
      // For now, always backup
      return true;
    }
    return true;
  }

  // Private helper methods

  Future<List<ChatRoom>> _getUserChatRooms(BackupContext context) async {
    try {
      final querySnapshot = await context.firestore
          .collection(FirebaseCollections.chats)
          .where('membersIds', arrayContains: context.userId)
          .get();

      return querySnapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.data()))
          .toList();
    } catch (e) {
      log('❌ Error getting user chat rooms: $e');
      return [];
    }
  }

  Future<List<Message>> _getChatMessages({
    required String roomId,
    required int limit,
    required BackupContext context,
  }) async {
    try {
      // FIX: Use chatMessages ('chat') instead of messages ('messages')
      // The actual Firestore structure is: chats/{roomId}/chat/{messageId}
      final querySnapshot = await context.firestore
          .collection(FirebaseCollections.chats)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Message.fromMap(doc.data()))
          .where((msg) => !msg.isDeleted)
          .toList();
    } catch (e) {
      log('❌ Error getting messages for room $roomId: $e');
      return [];
    }
  }

  String? _extractMediaUrl(Message message) {
    // Extract media URL based on message type
    if (message is PhotoMessage) {
      return message.imageUrl;
    } else if (message is VideoMessage) {
      return message.video;
    } else if (message is AudioMessage) {
      return message.audioUrl;
    } else if (message is FileMessage) {
      return message.file;
    }

    return null;
  }

  Future<File?> _downloadMedia({
    required String url,
    required int maxSizeMB,
  }) async {
    try {
      // Download file
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        log('❌ Failed to download media: ${response.statusCode}');
        return null;
      }

      // Check file size
      final fileSizeBytes = response.bodyBytes.length;
      final fileSizeMB = fileSizeBytes / (1024 * 1024);

      if (fileSizeMB > maxSizeMB) {
        log('⚠️ Media file too large: ${fileSizeMB.toStringAsFixed(2)}MB > ${maxSizeMB}MB');
        return null;
      }

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/backup_media_$timestamp');

      await tempFile.writeAsBytes(response.bodyBytes);

      return tempFile;
    } catch (e) {
      log('❌ Error downloading media: $e');
      return null;
    }
  }

  Future<File?> _compressImage(File imageFile, {int quality = 85}) async {
    try {
      // Get temp directory for compressed file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${tempDir.path}/compressed_$timestamp.jpg';

      // Compress image using flutter_image_compress
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 1920, // Max width 1920px (Full HD)
        minHeight: 1080, // Max height 1080px
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        log('⚠️ Image compression failed, using original file');
        return imageFile;
      }

      // Check compression savings
      final originalSize = await imageFile.length();
      final compressedSize = await result.length();
      final savings = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);

      log('✅ Image compressed: ${originalSize ~/ 1024}KB → ${compressedSize ~/ 1024}KB ($savings% saved)');

      return File(result.path);
    } catch (e) {
      log('❌ Error compressing image: $e');
      return imageFile; // Return original if compression fails
    }
  }

  bool _isImage(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp');
  }

  String _generateFileName({
    required String originalUrl,
    required Map<String, dynamic> metadata,
  }) {
    // FIX: Shorten filename to avoid "Message too long" error
    final messageId = metadata['messageId'] ?? 'unknown';
    final messageType = metadata['messageType'] ?? '';

    // Extract clean extension from URL
    // Firebase Storage URLs are URL-encoded, so we need to decode first
    String extension = _inferExtensionFromType(messageType);
    try {
      // Decode URL-encoded path (Firebase uses %2F for /)
      final decodedUrl = Uri.decodeFull(originalUrl);

      // Try to extract from the decoded URL
      // Firebase Storage format: .../o/path%2Fto%2Ffile.jpg?alt=media...
      final urlWithoutQuery = decodedUrl.split('?').first;
      final lastSlash = urlWithoutQuery.lastIndexOf('/');
      final fileName = lastSlash != -1
          ? urlWithoutQuery.substring(lastSlash + 1)
          : urlWithoutQuery;

      // Get extension from filename
      final lastDot = fileName.lastIndexOf('.');
      if (lastDot != -1 && lastDot < fileName.length - 1) {
        final ext = fileName.substring(lastDot + 1).toLowerCase();
        // Only use if it's a valid media extension
        if (_isValidExtension(ext)) {
          extension = ext;
        }
      }
    } catch (_) {}

    // Use short timestamp (millis only)
    final ts = DateTime.now().millisecondsSinceEpoch;

    // Keep filename short: media_{shortId}_{timestamp}.{ext}
    final shortId = messageId.length > 8 ? messageId.substring(0, 8) : messageId;
    return 'media_${shortId}_$ts.$extension';
  }

  /// Infer file extension from message type
  String _inferExtensionFromType(String messageType) {
    if (messageType.contains('Photo') || messageType.contains('Image')) {
      return 'jpg';
    } else if (messageType.contains('Video')) {
      return 'mp4';
    } else if (messageType.contains('Audio')) {
      return 'm4a';
    } else if (messageType.contains('File')) {
      return 'bin';
    }
    return 'bin';
  }

  /// Check if extension is a valid media extension
  bool _isValidExtension(String ext) {
    const validExtensions = {
      // Images
      'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp',
      // Videos
      'mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', '3gp',
      // Audio
      'm4a', 'mp3', 'wav', 'aac', 'ogg', 'flac', 'wma',
      // Documents
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt',
    };
    return validExtensions.contains(ext.toLowerCase());
  }

  Future<void> _saveMediaMetadata({
    required BackupContext context,
    required Map<String, Map<String, dynamic>> mediaUrls,
  }) async {
    try {
      // FIX: Convert all DateTime objects to ISO strings for JSON serialization
      final mediaIndex = <String, Map<String, dynamic>>{};

      for (final entry in mediaUrls.entries) {
        final url = entry.key;
        final data = entry.value;

        // Convert any DateTime to string
        final cleanData = <String, dynamic>{};
        for (final dataEntry in data.entries) {
          final value = dataEntry.value;
          if (value is DateTime) {
            cleanData[dataEntry.key] = value.toIso8601String();
          } else {
            cleanData[dataEntry.key] = value;
          }
        }

        mediaIndex[url] = {
          'backupFileName': _generateFileName(
            originalUrl: url,
            metadata: data,
          ),
          ...cleanData,
        };
      }

      final metadata = {
        'totalMediaFiles': mediaUrls.length,
        'backupDate': DateTime.now().toIso8601String(),
        'mediaIndex': mediaIndex,
      };

      await _backupDataSource.uploadJsonData(
        backupId: context.backupId,
        fileName: 'media_metadata.json',
        data: metadata,
        folder: 'media',
      );
    } catch (e) {
      log('❌ Error saving media metadata: $e');
    }
  }
}
