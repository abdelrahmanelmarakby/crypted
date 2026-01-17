import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart';
import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';

/// Export format options
enum ExportFormat {
  txt('Plain Text', 'txt', Iconsax.document_text),
  html('HTML', 'html', Iconsax.code),
  json('JSON', 'json', Iconsax.document_code);

  const ExportFormat(this.displayName, this.extension, this.icon);
  final String displayName;
  final String extension;
  final IconData icon;
}

/// Export options configuration
class ExportOptions {
  final ExportFormat format;
  final bool includeMedia;
  final bool includeTimestamps;
  final bool includeSenderNames;
  final DateTime? startDate;
  final DateTime? endDate;

  const ExportOptions({
    this.format = ExportFormat.txt,
    this.includeMedia = false,
    this.includeTimestamps = true,
    this.includeSenderNames = true,
    this.startDate,
    this.endDate,
  });

  ExportOptions copyWith({
    ExportFormat? format,
    bool? includeMedia,
    bool? includeTimestamps,
    bool? includeSenderNames,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ExportOptions(
      format: format ?? this.format,
      includeMedia: includeMedia ?? this.includeMedia,
      includeTimestamps: includeTimestamps ?? this.includeTimestamps,
      includeSenderNames: includeSenderNames ?? this.includeSenderNames,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// Chat Export Dialog
/// Shows options for exporting chat and handles the export process
class ChatExportDialog extends StatefulWidget {
  final String chatId;
  final String chatName;
  final List<Message> messages;
  final Map<String, String> senderNames;

  const ChatExportDialog({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.messages,
    required this.senderNames,
  });

  /// Show the export dialog
  static Future<void> show(
    BuildContext context, {
    required String chatId,
    required String chatName,
    required List<Message> messages,
    required Map<String, String> senderNames,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatExportDialog(
        chatId: chatId,
        chatName: chatName,
        messages: messages,
        senderNames: senderNames,
      ),
    );
  }

  @override
  State<ChatExportDialog> createState() => _ChatExportDialogState();
}

class _ChatExportDialogState extends State<ChatExportDialog> {
  ExportOptions _options = const ExportOptions();
  bool _isExporting = false;
  double _exportProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.export_1,
                    color: ColorsManager.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Chat',
                        style: StylesManager.bold(fontSize: FontSize.large),
                      ),
                      Text(
                        '${widget.messages.length} messages',
                        style: StylesManager.regular(
                          fontSize: FontSize.small,
                          color: ColorsManager.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Format selection
                  Text(
                    'Export Format',
                    style: StylesManager.semiBold(
                      fontSize: FontSize.medium,
                      color: ColorsManager.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFormatSelector(),
                  const SizedBox(height: 24),

                  // Options
                  Text(
                    'Options',
                    style: StylesManager.semiBold(
                      fontSize: FontSize.medium,
                      color: ColorsManager.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOptionSwitch(
                    'Include timestamps',
                    'Show date and time for each message',
                    _options.includeTimestamps,
                    (value) => setState(() {
                      _options = _options.copyWith(includeTimestamps: value);
                    }),
                  ),
                  _buildOptionSwitch(
                    'Include sender names',
                    'Show who sent each message',
                    _options.includeSenderNames,
                    (value) => setState(() {
                      _options = _options.copyWith(includeSenderNames: value);
                    }),
                  ),
                  _buildOptionSwitch(
                    'Include media references',
                    'Include links to photos, videos, and files',
                    _options.includeMedia,
                    (value) => setState(() {
                      _options = _options.copyWith(includeMedia: value);
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Preview info
                  _buildPreviewCard(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Export progress or button
          Padding(
            padding: EdgeInsets.fromLTRB(
              24, 0, 24, MediaQuery.of(context).padding.bottom + 16,
            ),
            child: _isExporting ? _buildProgressIndicator() : _buildExportButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Row(
      children: ExportFormat.values.map((format) {
        final isSelected = _options.format == format;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _options = _options.copyWith(format: format);
              });
            },
            child: Container(
              margin: EdgeInsets.only(
                right: format != ExportFormat.values.last ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? ColorsManager.primary.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: ColorsManager.primary, width: 2)
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    format.icon,
                    color: isSelected ? ColorsManager.primary : ColorsManager.grey,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    format.displayName,
                    style: StylesManager.medium(
                      fontSize: FontSize.small,
                      color: isSelected ? ColorsManager.primary : Colors.black87,
                    ),
                  ),
                  Text(
                    '.${format.extension}',
                    style: StylesManager.regular(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionSwitch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: StylesManager.medium(fontSize: FontSize.medium),
        ),
        subtitle: Text(
          subtitle,
          style: StylesManager.regular(
            fontSize: FontSize.small,
            color: ColorsManager.grey,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: ColorsManager.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final estimatedSize = _estimateFileSize();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Iconsax.info_circle, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Preview',
                  style: StylesManager.semiBold(
                    fontSize: FontSize.small,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  'Estimated file size: $estimatedSize',
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _exportProgress,
          backgroundColor: Colors.grey.shade200,
          color: ColorsManager.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        Text(
          'Exporting... ${(_exportProgress * 100).toInt()}%',
          style: StylesManager.medium(
            fontSize: FontSize.medium,
            color: ColorsManager.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _exportChat,
        icon: const Icon(Iconsax.export_1),
        label: const Text('Export Chat'),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _estimateFileSize() {
    final messageCount = widget.messages.length;
    int bytesPerMessage;

    switch (_options.format) {
      case ExportFormat.txt:
        bytesPerMessage = 100;
        break;
      case ExportFormat.html:
        bytesPerMessage = 250;
        break;
      case ExportFormat.json:
        bytesPerMessage = 300;
        break;
    }

    final totalBytes = messageCount * bytesPerMessage;

    if (totalBytes < 1024) {
      return '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<void> _exportChat() async {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
    });

    try {
      HapticFeedback.mediumImpact();

      // Generate export content
      final content = await _generateExportContent();

      setState(() => _exportProgress = 0.7);

      // Save to file
      final file = await _saveToFile(content);

      setState(() => _exportProgress = 0.9);

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Chat Export - ${widget.chatName}',
      );

      setState(() => _exportProgress = 1.0);

      // Close dialog
      Navigator.of(context).pop();

      Get.snackbar(
        'Export Complete',
        'Chat exported successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.primary.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Export Failed',
        'Failed to export chat: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<String> _generateExportContent() async {
    switch (_options.format) {
      case ExportFormat.txt:
        return _generateTextExport();
      case ExportFormat.html:
        return _generateHtmlExport();
      case ExportFormat.json:
        return _generateJsonExport();
    }
  }

  String _generateTextExport() {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    buffer.writeln('=' * 50);
    buffer.writeln('Chat Export: ${widget.chatName}');
    buffer.writeln('Exported: ${dateFormat.format(DateTime.now())}');
    buffer.writeln('Messages: ${widget.messages.length}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (int i = 0; i < widget.messages.length; i++) {
      final message = widget.messages[i];
      _writeTextMessage(buffer, message, dateFormat);

      // Update progress
      if (i % 100 == 0) {
        setState(() => _exportProgress = 0.1 + (i / widget.messages.length) * 0.5);
      }
    }

    buffer.writeln();
    buffer.writeln('=' * 50);
    buffer.writeln('End of export');
    buffer.writeln('=' * 50);

    return buffer.toString();
  }

  void _writeTextMessage(StringBuffer buffer, Message message, DateFormat dateFormat) {
    final parts = <String>[];

    if (_options.includeTimestamps) {
      parts.add('[${dateFormat.format(message.timestamp)}]');
    }

    if (_options.includeSenderNames) {
      final senderName = widget.senderNames[message.senderId] ?? 'Unknown';
      parts.add('$senderName:');
    }

    parts.add(_getMessageContent(message));

    buffer.writeln(parts.join(' '));
  }

  String _generateHtmlExport() {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>Chat Export - ${_escapeHtml(widget.chatName)}</title>');
    buffer.writeln('  <style>');
    buffer.writeln(_getHtmlStyles());
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <div class="container">');
    buffer.writeln('    <header>');
    buffer.writeln('      <h1>Chat Export</h1>');
    buffer.writeln('      <p class="chat-name">${_escapeHtml(widget.chatName)}</p>');
    buffer.writeln('      <p class="meta">Exported: ${dateFormat.format(DateTime.now())} • ${widget.messages.length} messages</p>');
    buffer.writeln('    </header>');
    buffer.writeln('    <div class="messages">');

    for (int i = 0; i < widget.messages.length; i++) {
      final message = widget.messages[i];
      _writeHtmlMessage(buffer, message, dateFormat);

      if (i % 100 == 0) {
        setState(() => _exportProgress = 0.1 + (i / widget.messages.length) * 0.5);
      }
    }

    buffer.writeln('    </div>');
    buffer.writeln('  </div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  void _writeHtmlMessage(StringBuffer buffer, Message message, DateFormat dateFormat) {
    final senderName = widget.senderNames[message.senderId] ?? 'Unknown';
    final content = _escapeHtml(_getMessageContent(message));

    buffer.writeln('      <div class="message">');
    if (_options.includeSenderNames) {
      buffer.writeln('        <div class="sender">$senderName</div>');
    }
    buffer.writeln('        <div class="content">$content</div>');
    if (_options.includeTimestamps) {
      buffer.writeln('        <div class="timestamp">${dateFormat.format(message.timestamp)}</div>');
    }
    buffer.writeln('      </div>');
  }

  String _getHtmlStyles() {
    return '''
      * { margin: 0; padding: 0; box-sizing: border-box; }
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; }
      .container { max-width: 800px; margin: 0 auto; padding: 20px; }
      header { background: #31A354; color: white; padding: 24px; border-radius: 12px; margin-bottom: 20px; }
      h1 { font-size: 24px; margin-bottom: 8px; }
      .chat-name { font-size: 18px; opacity: 0.9; }
      .meta { font-size: 14px; opacity: 0.7; margin-top: 8px; }
      .messages { background: white; border-radius: 12px; padding: 16px; }
      .message { padding: 12px 0; border-bottom: 1px solid #eee; }
      .message:last-child { border-bottom: none; }
      .sender { font-weight: 600; color: #31A354; font-size: 14px; margin-bottom: 4px; }
      .content { font-size: 15px; line-height: 1.5; color: #333; }
      .timestamp { font-size: 12px; color: #999; margin-top: 4px; }
    ''';
  }

  String _generateJsonExport() {
    final messages = widget.messages.map((message) {
      final map = <String, dynamic>{
        'id': message.id,
        'type': _getMessageType(message),
        'content': _getMessageContent(message),
      };

      if (_options.includeTimestamps) {
        map['timestamp'] = message.timestamp.toIso8601String();
      }

      if (_options.includeSenderNames) {
        map['senderId'] = message.senderId;
        map['senderName'] = widget.senderNames[message.senderId] ?? 'Unknown';
      }

      if (_options.includeMedia && _hasMediaUrl(message)) {
        map['mediaUrl'] = _getMediaUrl(message);
      }

      return map;
    }).toList();

    final export = {
      'chatName': widget.chatName,
      'chatId': widget.chatId,
      'exportedAt': DateTime.now().toIso8601String(),
      'messageCount': messages.length,
      'messages': messages,
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(export);
  }

  String _getMessageContent(Message message) {
    if (message is TextMessage) {
      return message.text;
    } else if (message is PhotoMessage) {
      if (_options.includeMedia) {
        return '[Photo: ${message.imageUrl}]';
      }
      return '[Photo]';
    } else if (message is AudioMessage) {
      if (_options.includeMedia) {
        return '[Audio: ${message.audioUrl}]';
      }
      return '[Voice Message]';
    } else if (message is VideoMessage) {
      if (_options.includeMedia) {
        return '[Video: ${message.video}]';
      }
      return '[Video]';
    } else if (message is FileMessage) {
      if (_options.includeMedia) {
        return '[File: ${message.fileName} - ${message.file}]';
      }
      return '[File: ${message.fileName}]';
    } else if (message is LocationMessage) {
      return '[Location: ${message.latitude}, ${message.longitude}]';
    } else if (message is ContactMessage) {
      return '[Contact: ${message.name}]';
    } else if (message is PollMessage) {
      return '[Poll: ${message.question}]';
    } else if (message is CallMessage) {
      return '[Call: ${message.callModel.callType?.name ?? 'unknown'} - ${message.callModel.callDuration ?? 0}s]';
    }
    return '[Unknown Message]';
  }

  String _getMessageType(Message message) {
    if (message is TextMessage) return 'text';
    if (message is PhotoMessage) return 'photo';
    if (message is AudioMessage) return 'audio';
    if (message is VideoMessage) return 'video';
    if (message is FileMessage) return 'file';
    if (message is LocationMessage) return 'location';
    if (message is ContactMessage) return 'contact';
    if (message is PollMessage) return 'poll';
    if (message is CallMessage) return 'call';
    return 'unknown';
  }

  bool _hasMediaUrl(Message message) {
    return message is PhotoMessage ||
        message is AudioMessage ||
        message is VideoMessage ||
        message is FileMessage;
  }

  String? _getMediaUrl(Message message) {
    if (message is PhotoMessage) return message.imageUrl;
    if (message is AudioMessage) return message.audioUrl;
    if (message is VideoMessage) return message.video;
    if (message is FileMessage) return message.file;
    return null;
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  Future<File> _saveToFile(String content) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final sanitizedName = widget.chatName.replaceAll(RegExp(r'[^\w\s-]'), '');
    final fileName = 'chat_export_${sanitizedName}_$timestamp.${_options.format.extension}';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }
}

/// Export Chat Tile for Settings Lists
class ExportChatTile extends StatelessWidget {
  final String chatId;
  final String chatName;
  final List<Message> messages;
  final Map<String, String> senderNames;

  const ExportChatTile({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.messages,
    required this.senderNames,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => ChatExportDialog.show(
        context,
        chatId: chatId,
        chatName: chatName,
        messages: messages,
        senderNames: senderNames,
      ),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Iconsax.export_1,
          color: Colors.blue,
          size: 22,
        ),
      ),
      title: Text(
        'Export Chat',
        style: StylesManager.medium(fontSize: FontSize.medium),
      ),
      subtitle: Text(
        'Save chat as text, HTML, or JSON',
        style: StylesManager.regular(
          fontSize: FontSize.small,
          color: ColorsManager.grey,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: ColorsManager.grey,
      ),
    );
  }
}
