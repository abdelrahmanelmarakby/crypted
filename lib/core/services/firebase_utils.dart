import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';

class FirebaseUtils {
  // ⏺️ رفع صوت + يرجّع AudioMessage
  static Future<AudioMessage?> uploadAudio(
    String path,
    SocialMediaUser? sender,
    SocialMediaUser? receiver,
    String duration,
  ) async {
    try {
      final now = DateTime.now();
      final id = generateUniqueId("audio", sender?.uid);
      final url = await _uploadFile(File(path), "audios", id);

      return url == null
          ? null
          : AudioMessage(
              id: id,
              roomId: receiver?.uid ?? '',
              senderId: sender?.uid ?? '',
              timestamp: now,
              audioUrl: url,
              duration: duration,
            );
    } catch (e) {
      log("❌ Error uploading audio: $e");
      return null;
    }
  }

  // 🖼️ رفع صورة + يرجّع PhotoMessage
  static Future<PhotoMessage?> uploadImage(
    String path,
    SocialMediaUser? sender,
    SocialMediaUser? receiver,
  ) async {
    try {
      final now = DateTime.now();
      final id = generateUniqueId("image", sender?.uid);
      final url = await _uploadFile(File(path), "images", id);

      return url == null
          ? null
          : PhotoMessage(
              id: id,
              roomId: receiver?.uid ?? '',
              senderId: sender?.uid ?? '',
              timestamp: now,
              imageUrl: url,
            );
    } catch (e) {
      log("❌ Error uploading image: $e");
      return null;
    }
  }

  // 🎥 رفع فيديو + يرجّع VideoMessage
  static Future<VideoMessage?> uploadVideo(
    String path,
    SocialMediaUser? sender,
    SocialMediaUser? receiver,
  ) async {
    try {
      final now = DateTime.now();
      final id = generateUniqueId("video", sender?.uid);
      final url = await _uploadFile(File(path), "videos", id);

      return url == null
          ? null
          : VideoMessage(
              id: id,
              roomId: receiver?.uid ?? '',
              senderId: sender?.uid ?? '',
              timestamp: now,
              video: url,
            );
    } catch (e) {
      log("❌ Error uploading video: $e");
      return null;
    }
  }

  // 📄 رفع ملف عام + يرجّع FileMessage
  static Future<FileMessage?> uploadFile(
    String path,
    SocialMediaUser? sender,
    SocialMediaUser? receiver,
  ) async {
    try {
      final now = DateTime.now();
      final id = generateUniqueId("file", sender?.uid);
      final url = await _uploadFile(File(path), "files", id);
      final fileName = path.split(Platform.pathSeparator).last;

      return url == null
          ? null
          : FileMessage(
              id: id,
              roomId: receiver?.uid ?? '',
              senderId: sender?.uid ?? '',
              timestamp: now,
              file: url,
              fileName: fileName,
            );
    } catch (e) {
      log("❌ Error uploading file: $e");
      return null;
    }
  }

  // 🧱 دالة مساعدة موحدة لرفع أي ملف
  static Future<String?> _uploadFile(
      File file, String folder, String id) async {
    try {
      final String today = _getTodayString();
      final ref =
          FirebaseStorage.instance.ref().child(folder).child(today).child(id);

      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      log("❌ Error uploading to Firebase Storage: $e");
      return null;
    }
  }

  // 📅 تاريخ اليوم Month-Day
  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.month}-${now.day}';
  }

  // 🆔 توليد ID فريد
  static String generateUniqueId(String type, String? userId) {
    return '${type}_${DateTime.now().millisecondsSinceEpoch}_${userId ?? 'unknown'}';
  }

  // 🔍 هل الملف موجود؟
  static Future<bool> checkFileExists(String path) async {
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  // 🔢 حجم الملف
  static Future<int> getFileSize(String path) async {
    try {
      return File(path).lengthSync();
    } catch (_) {
      return 0;
    }
  }

  // 📏 تنسيق الحجم
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
