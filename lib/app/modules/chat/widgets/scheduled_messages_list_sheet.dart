import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/app/data/data_source/scheduled_message_data_source.dart';
import 'package:crypted_app/app/data/models/scheduled_message_model.dart';

/// A bottom sheet that shows the list of pending scheduled messages
/// for a specific chat room, with options to cancel or reschedule.
class ScheduledMessagesListSheet extends StatefulWidget {
  final String chatRoomId;
  final ScrollController? scrollController;

  const ScheduledMessagesListSheet({
    super.key,
    required this.chatRoomId,
    this.scrollController,
  });

  /// Show the sheet for a given room. Returns void.
  static Future<void> show({
    required BuildContext context,
    required String chatRoomId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (context, scrollController) => ScheduledMessagesListSheet(
            chatRoomId: chatRoomId, scrollController: scrollController),
      ),
    );
  }

  @override
  State<ScheduledMessagesListSheet> createState() =>
      _ScheduledMessagesListSheetState();
}

class _ScheduledMessagesListSheetState
    extends State<ScheduledMessagesListSheet> {
  final ScheduledMessageDataSource _dataSource = ScheduledMessageDataSource();
  late StreamSubscription<List<ScheduledMessage>> _subscription;
  List<ScheduledMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscription = _dataSource
        .getScheduledMessagesForRoom(widget.chatRoomId)
        .listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _cancelMessage(ScheduledMessage msg) async {
    if (msg.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Scheduled Message'),
        content: const Text('This message will not be sent. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Message'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _dataSource.cancelScheduledMessage(msg.id!);
    if (success) {
      HapticFeedback.lightImpact();
      Get.snackbar(
        'Cancelled',
        'Scheduled message has been cancelled',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey.withAlpha(200),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'Error',
        'Could not cancel this message',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _rescheduleMessage(ScheduledMessage msg) async {
    if (msg.id == null) return;

    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: msg.scheduledFor.isAfter(now) ? msg.scheduledFor : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: ColorsManager.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(msg.scheduledFor),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: ColorsManager.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    final combined =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (combined.isBefore(DateTime.now())) {
      Get.snackbar('Invalid Time', 'Please select a time in the future');
      return;
    }

    final success = await _dataSource.rescheduleMessage(msg.id!, combined);
    if (success) {
      HapticFeedback.lightImpact();
      Get.snackbar(
        'Rescheduled',
        'Message will be sent ${_formatDateTime(combined)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.primary.withAlpha(230),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(dt.year, dt.month, dt.day);
    final dayDiff = dateDay.difference(today).inDays;
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (dayDiff == 0) return 'today at $time';
    if (dayDiff == 1) return 'tomorrow at $time';
    return '${dt.day}/${dt.month} at $time';
  }

  String _timeUntilText(ScheduledMessage msg) {
    final diff = msg.timeUntilSend;
    if (diff.isNegative) return 'Sending now...';
    if (diff.inMinutes < 1) return 'In less than a minute';
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes}m';
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      return mins > 0 ? 'In ${hours}h ${mins}m' : 'In ${hours}h';
    }
    final days = diff.inDays;
    return days == 1 ? 'In 1 day' : 'In $days days';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.scaffoldBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.clock,
                      color: ColorsManager.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduled Messages',
                        style: TextStyle(
                          fontSize: FontSize.xLarge,
                          fontWeight: FontWeight.bold,
                          color: ColorsManager.textPrimaryAdaptive(context),
                        ),
                      ),
                      Text(
                        _isLoading
                            ? 'Loading...'
                            : '${_messages.length} pending',
                        style: TextStyle(
                          fontSize: FontSize.small,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Divider(height: 1, color: Colors.grey.withAlpha(40)),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ColorsManager.primary,
                    ),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _buildMessageCard(_messages[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.clock, size: 48, color: Colors.grey.withAlpha(100)),
          const SizedBox(height: 12),
          Text(
            'No scheduled messages',
            style: StylesManager.medium(
              fontSize: FontSize.medium,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Long-press the send button to schedule',
            style: StylesManager.regular(
              fontSize: FontSize.small,
              color: Colors.grey.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(ScheduledMessage msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorsManager.surfaceAdaptive(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time info row
          Row(
            children: [
              Icon(Iconsax.clock, size: 14, color: ColorsManager.primary),
              const SizedBox(width: 6),
              Text(
                _formatDateTime(msg.scheduledFor),
                style: TextStyle(
                  fontSize: FontSize.small,
                  fontWeight: FontWeight.w600,
                  color: ColorsManager.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _timeUntilText(msg),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ColorsManager.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Message preview
          Text(
            msg.preview,
            style: TextStyle(
              fontSize: FontSize.medium,
              color: ColorsManager.textPrimaryAdaptive(context),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              // Reschedule button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rescheduleMessage(msg),
                  icon: const Icon(Iconsax.calendar_edit, size: 16),
                  label:
                      const Text('Reschedule', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorsManager.primary,
                    side:
                        BorderSide(color: ColorsManager.primary.withAlpha(80)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Cancel button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancelMessage(msg),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withAlpha(80)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
