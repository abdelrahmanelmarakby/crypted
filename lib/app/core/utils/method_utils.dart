import 'package:flutter/material.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:get/get.dart';

/// QUALITY-007: Method Extraction Utilities
/// Extracted common operations from long methods into reusable utilities

// ============================================================================
// MESSAGE UTILITIES
// ============================================================================

/// Message text extraction utility
class MessageTextExtractor {
  static String getDisplayText(Message message) {
    switch (message) {
      case TextMessage m:
        return m.text;
      case PhotoMessage _:
        return '📷 ${Constants.kPhoto.tr}';
      case VideoMessage _:
        return '🎥 ${Constants.kVideo.tr}';
      case AudioMessage m:
        return '🎵 ${_formatDuration(m.duration)}';
      case FileMessage m:
        return '📎 ${m.fileName}';
      default:
        return Constants.kMessage.tr;
    }
  }

  static String getPreviewText(Message message, {int maxLength = 50}) {
    final text = getDisplayText(message);
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String _formatDuration(String duration) {
    // Handle "MM:SS" or "HH:MM:SS" format
    final parts = duration.split(':');
    if (parts.length == 2) {
      return '${parts[0]}:${parts[1]}';
    } else if (parts.length == 3) {
      return '${parts[0]}:${parts[1]}:${parts[2]}';
    }
    return duration;
  }
}

/// Message timestamp formatting utility
class MessageTimeFormatter {
  static String formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return Constants.kToday.tr;
    } else if (messageDate == yesterday) {
      return Constants.kYesterday.tr;
    } else {
      return _formatFullDate(date);
    }
  }

  static String formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return _formatFullDate(timestamp);
    }
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static String _formatFullDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ============================================================================
// USER UTILITIES
// ============================================================================

/// User display utilities
class UserDisplayUtils {
  /// Get the other user in a 1-on-1 chat
  static SocialMediaUser? getOtherUser(
    List<SocialMediaUser> members,
    String currentUserId,
  ) {
    final others = members.where((u) => u.uid != currentUserId);
    return others.isNotEmpty ? others.first : null;
  }

  /// Get display name with fallback
  static String getDisplayName(SocialMediaUser? user, {String fallback = 'Unknown'}) {
    if (user == null) return fallback;
    return user.fullName?.isNotEmpty == true ? user.fullName! : fallback;
  }

  /// Get initials for avatar
  static String getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Get color from name (for avatar backgrounds)
  static Color getColorFromName(String? name) {
    if (name == null || name.isEmpty) return ColorsManager.primary;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  /// Format member count for display
  static String formatMemberCount(int count) {
    if (count == 1) return '1 member';
    return '$count members';
  }
}

// ============================================================================
// FILE UTILITIES
// ============================================================================

/// File size and type utilities
class FileUtils {
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  static String getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) return '';
    return fileName.substring(lastDot + 1).toLowerCase();
  }

  static IconData getFileIcon(String fileName) {
    final ext = getFileExtension(fileName);
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audio_file;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  static bool isImage(String fileName) {
    final ext = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  static bool isVideo(String fileName) {
    final ext = getFileExtension(fileName);
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }

  static bool isAudio(String fileName) {
    final ext = getFileExtension(fileName);
    return ['mp3', 'wav', 'aac', 'm4a', 'ogg'].contains(ext);
  }

  static bool isDocument(String fileName) {
    final ext = getFileExtension(fileName);
    return ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(ext);
  }
}

// ============================================================================
// VALIDATION UTILITIES
// ============================================================================

/// Input validation utilities
class ValidationUtils {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    return cleaned.length >= 7 &&
        cleaned.length <= 15 &&
        RegExp(r'^\d+$').hasMatch(cleaned);
  }

  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static bool isInRange(int value, int min, int max) {
    return value >= min && value <= max;
  }
}

// ============================================================================
// STRING UTILITIES
// ============================================================================

/// String manipulation utilities
class StringUtils {
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) {
    return text.split(' ').map(capitalize).join(' ');
  }

  static String removeExtraSpaces(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static List<String> extractUrls(String text) {
    final urlRegex = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    );
    return urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  static List<String> extractMentions(String text) {
    final mentionRegex = RegExp(r'@(\w+)');
    return mentionRegex.allMatches(text).map((m) => m.group(1)!).toList();
  }

  static List<String> extractHashtags(String text) {
    final hashtagRegex = RegExp(r'#(\w+)');
    return hashtagRegex.allMatches(text).map((m) => m.group(1)!).toList();
  }
}

// ============================================================================
// COLOR UTILITIES
// ============================================================================

/// Color manipulation utilities
class ColorUtils {
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightened = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }

  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  static bool isDark(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
  }

  static Color contrastingTextColor(Color backgroundColor) {
    return isDark(backgroundColor) ? Colors.white : Colors.black;
  }
}
