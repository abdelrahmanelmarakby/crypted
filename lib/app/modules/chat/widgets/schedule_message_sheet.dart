import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/app/data/data_source/scheduled_message_data_source.dart';
import 'package:crypted_app/app/data/models/scheduled_message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';

/// Bottom sheet for scheduling a message to be sent later.
///
/// Shown when the user long-presses the send button.
/// Provides quick-pick chips (1h, 3h, tonight, tomorrow) + custom date/time.
class ScheduleMessageSheet extends StatefulWidget {
  final String messageText;
  final String chatRoomId;
  final List<Map<String, dynamic>> members;

  const ScheduleMessageSheet({
    super.key,
    required this.messageText,
    required this.chatRoomId,
    required this.members,
  });

  /// Show the schedule sheet. Returns true if message was scheduled.
  static Future<bool> show({
    required BuildContext context,
    required String messageText,
    required String chatRoomId,
    required List<Map<String, dynamic>> members,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScheduleMessageSheet(
        messageText: messageText,
        chatRoomId: chatRoomId,
        members: members,
      ),
    );
    return result ?? false;
  }

  @override
  State<ScheduleMessageSheet> createState() => _ScheduleMessageSheetState();
}

class _ScheduleMessageSheetState extends State<ScheduleMessageSheet> {
  DateTime? _selectedDateTime;
  bool _isScheduling = false;
  late final List<_QuickOption> _quickOptions;

  @override
  void initState() {
    super.initState();
    // Cache quick options at init so DateTime.now() doesn't shift on rebuild
    final now = DateTime.now();
    final tonight = DateTime(now.year, now.month, now.day, 21, 0);
    final tomorrowMorning = DateTime(now.year, now.month, now.day + 1, 9, 0);
    final tomorrowAfternoon = DateTime(now.year, now.month, now.day + 1, 14, 0);

    _quickOptions = [
      _QuickOption(
        label: 'In 1 hour',
        icon: Icons.schedule,
        dateTime: now.add(const Duration(hours: 1)),
      ),
      _QuickOption(
        label: 'In 3 hours',
        icon: Icons.timer,
        dateTime: now.add(const Duration(hours: 3)),
      ),
      if (tonight.isAfter(now))
        _QuickOption(
          label: 'Tonight 9 PM',
          icon: Icons.dark_mode_outlined,
          dateTime: tonight,
        ),
      _QuickOption(
        label: 'Tomorrow 9 AM',
        icon: Icons.wb_sunny_outlined,
        dateTime: tomorrowMorning,
      ),
      _QuickOption(
        label: 'Tomorrow 2 PM',
        icon: Icons.wb_cloudy_outlined,
        dateTime: tomorrowAfternoon,
      ),
    ];
  }

  Future<void> _pickCustomDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
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
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
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
      Get.snackbar(Constants.kError.tr, Constants.kSomethingWentWrong.tr);
      return;
    }

    setState(() => _selectedDateTime = combined);
  }

  Future<void> _scheduleMessage(DateTime scheduledFor) async {
    setState(() => _isScheduling = true);

    final uid = UserService.currentUser.value?.uid;
    if (uid == null) {
      Get.snackbar(Constants.kError.tr, Constants.kPleaseLoginFirst.tr);
      setState(() => _isScheduling = false);
      return;
    }

    // Build the message data (same as TextMessage.toMap())
    final textMessage = TextMessage(
      id: '',
      roomId: widget.chatRoomId,
      senderId: uid,
      timestamp: scheduledFor,
      text: widget.messageText,
    );

    final dataSource = ScheduledMessageDataSource();
    final result = await dataSource.scheduleMessage(
      chatRoomId: widget.chatRoomId,
      messageData: textMessage.toMap(),
      scheduledFor: scheduledFor,
      members: widget.members,
    );

    setState(() => _isScheduling = false);

    if (result != null) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
      Get.snackbar(
        Constants.kScheduleMessage.tr,
        'Will be sent ${_formatDateTime(scheduledFor)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.primary.withAlpha(230),
        colorText: Colors.white,
        icon: const Icon(Iconsax.clock, color: Colors.white, size: 20),
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(Constants.kError.tr, Constants.kFailedToSendMessage.tr);
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.scaffoldBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
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
                        Constants.kScheduleMessage.tr,
                        style: TextStyle(
                          fontSize: FontSize.xLarge,
                          fontWeight: FontWeight.bold,
                          color: ColorsManager.textPrimaryAdaptive(context),
                        ),
                      ),
                      Text(
                        'Choose when to send this message',
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
            const SizedBox(height: 8),

            // Message preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorsManager.primary.withAlpha(40),
                ),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.message_text,
                      size: 16, color: ColorsManager.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.messageText,
                      style: TextStyle(
                        fontSize: FontSize.small,
                        color: ColorsManager.textPrimaryAdaptive(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quick-pick chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final option = _quickOptions[index];
                  final isSelected = _selectedDateTime == option.dateTime;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedDateTime = option.dateTime);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ColorsManager.primary
                            : ColorsManager.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? ColorsManager.primary
                              : ColorsManager.primary.withAlpha(40),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            option.icon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : ColorsManager.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            option.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : ColorsManager.textPrimaryAdaptive(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Custom date/time picker button
            InkWell(
              onTap: _pickCustomDateTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withAlpha(60)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.calendar_1,
                        size: 20, color: ColorsManager.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDateTime != null
                            ? _formatDateTime(_selectedDateTime!)
                            : 'Pick a custom date & time',
                        style: TextStyle(
                          fontSize: FontSize.medium,
                          color: _selectedDateTime != null
                              ? ColorsManager.textPrimaryAdaptive(context)
                              : Colors.grey,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Schedule button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _selectedDateTime != null && !_isScheduling
                    ? () => _scheduleMessage(_selectedDateTime!)
                    : null,
                icon: _isScheduling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Iconsax.send_2, size: 20),
                label: Text(
                  _isScheduling ? 'Scheduling...' : 'Schedule Send',
                  style: const TextStyle(
                      fontSize: FontSize.large, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withAlpha(60),
                  disabledForegroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickOption {
  final String label;
  final IconData icon;
  final DateTime dateTime;

  const _QuickOption({
    required this.label,
    required this.icon,
    required this.dateTime,
  });
}
