import 'dart:io';
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';

class FileMessageWidget extends StatefulWidget {
  const FileMessageWidget({
    super.key,
    required this.message,
  });

  final FileMessage message;

  @override
  State<FileMessageWidget> createState() => _FileMessageWidgetState();
}

class _FileMessageWidgetState extends State<FileMessageWidget>
    with SingleTickerProviderStateMixin {
  bool _isDownloading = false;
  late AnimationController _uploadAnimController;

  @override
  void initState() {
    super.initState();
    _uploadAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _uploadAnimController.dispose();
    super.dispose();
  }

  /// Check if this is a local file (optimistic/uploading state)
  bool get _isLocalFile {
    final url = widget.message.file;
    return url.startsWith('/') ||
        url.startsWith('file://') ||
        url.contains('/data/') ||
        url.contains('/cache/');
  }

  /// Check if local file exists
  bool get _localFileExists {
    if (!_isLocalFile) return false;
    final path = widget.message.file.replaceFirst('file://', '');
    return File(path).existsSync();
  }

  // Get file extension
  String get _fileExtension {
    final fileName = widget.message.fileName.toLowerCase();
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) return '';
    return fileName.substring(dotIndex + 1);
  }

  // Get file type category
  FileType get _fileType {
    switch (_fileExtension) {
      case 'pdf':
        return FileType.pdf;
      case 'doc':
      case 'docx':
        return FileType.word;
      case 'xls':
      case 'xlsx':
        return FileType.excel;
      case 'ppt':
      case 'pptx':
        return FileType.powerpoint;
      case 'zip':
      case 'rar':
      case '7z':
        return FileType.archive;
      case 'txt':
        return FileType.text;
      case 'csv':
        return FileType.csv;
      case 'apk':
        return FileType.apk;
      default:
        return FileType.generic;
    }
  }

  // Get file icon based on type
  IconData get _fileIcon {
    switch (_fileType) {
      case FileType.pdf:
        return Iconsax.document_copy;
      case FileType.word:
        return Iconsax.document_text_copy;
      case FileType.excel:
        return Iconsax.document_1_copy;
      case FileType.powerpoint:
        return Iconsax.chart_copy;
      case FileType.archive:
        return Iconsax.archive_copy;
      case FileType.text:
        return Iconsax.document_text_1_copy;
      case FileType.csv:
        return Iconsax.data_copy;
      case FileType.apk:
        return Iconsax.mobile_copy;
      default:
        return Iconsax.document_copy;
    }
  }

  // Get file color based on type
  Color get _fileColor {
    switch (_fileType) {
      case FileType.pdf:
        return const Color(0xFFE74C3C); // Red for PDF
      case FileType.word:
        return const Color(0xFF2B579A); // Blue for Word
      case FileType.excel:
        return const Color(0xFF217346); // Green for Excel
      case FileType.powerpoint:
        return const Color(0xFFD24726); // Orange for PowerPoint
      case FileType.archive:
        return const Color(0xFFF39C12); // Yellow for Archives
      case FileType.text:
        return ColorsManager.grey;
      case FileType.csv:
        return const Color(0xFF16A085); // Teal for CSV
      case FileType.apk:
        return const Color(0xFF3DDC84); // Android green
      default:
        return ColorsManager.primary;
    }
  }

  // Format file size (placeholder - actual size should come from message model)
  String get _fileSize {
    return '< 1 MB';
  }

  Future<void> _handleFileTap() async {
    if (_isLocalFile) {
      // Local file - show uploading message
      Get.snackbar(
        'Uploading',
        'File is being uploaded...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.primary,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (widget.message.file.isEmpty) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final uri = Uri.parse(widget.message.file);
      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Error',
          'Cannot open this file',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.error,
          colorText: Colors.white,
          icon: const Icon(Iconsax.info_circle_copy, color: Colors.white),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open file: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.error,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.7,
        minWidth: 240,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isLocalFile
              ? ColorsManager.primary.withValues(alpha: 0.5)
              : _fileColor.withValues(alpha: 0.3),
          width: _isLocalFile ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleFileTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // File icon with background
                _buildFileIcon(),
                const SizedBox(width: 12),

                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // File name
                      Text(
                        widget.message.fileName,
                        style: StylesManager.medium(
                          fontSize: FontSize.small,
                          color: ColorsManager.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // File metadata row
                      Row(
                        children: [
                          // Status badge for uploading
                          if (_isLocalFile)
                            _buildUploadingBadge()
                          else ...[
                            // File size
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: ColorsManager.navbarColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Iconsax.document_download_copy,
                                    size: 12,
                                    color: ColorsManager.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _fileSize,
                                    style: StylesManager.regular(
                                      fontSize: FontSize.xSmall,
                                      color: ColorsManager.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),

                            // File type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _fileColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _fileType.name.toUpperCase(),
                                style: StylesManager.semiBold(
                                  fontSize: FontSize.xSmall,
                                  color: _fileColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Download/Upload button
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    return AnimatedBuilder(
      animation: _uploadAnimController,
      builder: (context, child) {
        final isUploading = _isLocalFile;
        final scale = isUploading ? 1.0 + (_uploadAnimController.value * 0.05) : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isUploading
                  ? ColorsManager.primary.withValues(alpha: 0.15)
                  : _fileColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: isUploading
                  ? Border.all(
                      color: ColorsManager.primary.withValues(alpha: 0.3),
                      width: 2,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isUploading ? Iconsax.arrow_up_2 : _fileIcon,
                  color: isUploading ? ColorsManager.primary : _fileColor,
                  size: 24,
                ),
                if (_fileExtension.isNotEmpty && !isUploading)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _fileExtension.toUpperCase(),
                      style: StylesManager.bold(
                        fontSize: 8,
                        color: _fileColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadingBadge() {
    return AnimatedBuilder(
      animation: _uploadAnimController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorsManager.primary.withValues(alpha: 0.2),
                ColorsManager.primary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ColorsManager.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorsManager.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Uploading...',
                style: StylesManager.medium(
                  fontSize: FontSize.xSmall,
                  color: ColorsManager.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton() {
    if (_isLocalFile) {
      // Uploading state - show animated progress
      return AnimatedBuilder(
        animation: _uploadAnimController,
        builder: (context, child) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorsManager.primary,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    // Download button
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _isDownloading
            ? _fileColor.withValues(alpha: 0.12)
            : _fileColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _isDownloading
          ? Padding(
              padding: const EdgeInsets.all(10),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(_fileColor),
              ),
            )
          : Icon(
              Iconsax.document_download_copy,
              color: _fileColor,
              size: 22,
            ),
    );
  }
}

// File type enum for categorization
enum FileType {
  pdf,
  word,
  excel,
  powerpoint,
  archive,
  text,
  csv,
  apk,
  generic,
}
