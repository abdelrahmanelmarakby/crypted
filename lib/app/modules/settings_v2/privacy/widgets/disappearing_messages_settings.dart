import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/privacy_settings_service.dart';

/// Disappearing Messages Duration Selector
/// A reusable widget for selecting disappearing message duration
class DisappearingMessagesDurationSelector extends StatelessWidget {
  final DisappearingDuration currentDuration;
  final ValueChanged<DisappearingDuration> onDurationChanged;
  final bool showHeader;
  final String? headerText;

  const DisappearingMessagesDurationSelector({
    super.key,
    required this.currentDuration,
    required this.onDurationChanged,
    this.showHeader = true,
    this.headerText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Text(
            headerText ?? 'Message Timer',
            style: StylesManager.semiBold(
              fontSize: FontSize.medium,
              color: ColorsManager.grey,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...DisappearingDuration.values.map((duration) {
          final isSelected = duration == currentDuration;
          return _buildDurationOption(
            duration: duration,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              onDurationChanged(duration);
            },
          );
        }),
      ],
    );
  }

  Widget _buildDurationOption({
    required DisappearingDuration duration,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: ColorsManager.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            _buildDurationIcon(duration),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    duration.displayName,
                    style: StylesManager.semiBold(
                      fontSize: FontSize.medium,
                      color: isSelected ? ColorsManager.primary : Colors.black87,
                    ),
                  ),
                  Text(
                    _getDurationDescription(duration),
                    style: StylesManager.regular(
                      fontSize: FontSize.small,
                      color: ColorsManager.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ColorsManager.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationIcon(DisappearingDuration duration) {
    IconData iconData;
    Color iconColor;

    switch (duration) {
      case DisappearingDuration.off:
        iconData = Iconsax.message;
        iconColor = Colors.grey;
        break;
      case DisappearingDuration.hours24:
        iconData = Iconsax.timer_1;
        iconColor = Colors.orange;
        break;
      case DisappearingDuration.days7:
        iconData = Iconsax.calendar;
        iconColor = Colors.blue;
        break;
      case DisappearingDuration.days30:
        iconData = Iconsax.calendar_1;
        iconColor = Colors.purple;
        break;
      case DisappearingDuration.days90:
        iconData = Iconsax.calendar_2;
        iconColor = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconData, color: iconColor, size: 22),
    );
  }

  String _getDurationDescription(DisappearingDuration duration) {
    switch (duration) {
      case DisappearingDuration.off:
        return 'Messages will not disappear';
      case DisappearingDuration.hours24:
        return 'Messages disappear after 24 hours';
      case DisappearingDuration.days7:
        return 'Messages disappear after 1 week';
      case DisappearingDuration.days30:
        return 'Messages disappear after 1 month';
      case DisappearingDuration.days90:
        return 'Messages disappear after 3 months';
    }
  }
}

/// Disappearing Messages Settings Sheet
/// A bottom sheet for configuring disappearing messages for a specific chat
class DisappearingMessagesSheet extends StatefulWidget {
  final String chatId;
  final String chatName;
  final bool isGroup;
  final DisappearingDuration currentDuration;

  const DisappearingMessagesSheet({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.isGroup,
    required this.currentDuration,
  });

  /// Show the disappearing messages sheet
  static Future<DisappearingDuration?> show(
    BuildContext context, {
    required String chatId,
    required String chatName,
    required bool isGroup,
    required DisappearingDuration currentDuration,
  }) async {
    return await showModalBottomSheet<DisappearingDuration>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DisappearingMessagesSheet(
        chatId: chatId,
        chatName: chatName,
        isGroup: isGroup,
        currentDuration: currentDuration,
      ),
    );
  }

  @override
  State<DisappearingMessagesSheet> createState() =>
      _DisappearingMessagesSheetState();
}

class _DisappearingMessagesSheetState extends State<DisappearingMessagesSheet> {
  late DisappearingDuration _selectedDuration;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.currentDuration;
  }

  Future<void> _saveDuration() async {
    if (_selectedDuration == widget.currentDuration) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save to Firestore (this would be implemented in a chat service)
      // For now, we just return the selected duration
      await Future.delayed(const Duration(milliseconds: 300));

      Navigator.of(context).pop(_selectedDuration);

      Get.snackbar(
        'Updated',
        _selectedDuration == DisappearingDuration.off
            ? 'Disappearing messages turned off'
            : 'Messages will disappear after ${_selectedDuration.displayName.toLowerCase()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.primary.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update disappearing messages setting',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    Iconsax.timer,
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
                        'Disappearing Messages',
                        style: StylesManager.bold(fontSize: FontSize.large),
                      ),
                      Text(
                        widget.chatName,
                        style: StylesManager.regular(
                          fontSize: FontSize.small,
                          color: ColorsManager.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Info card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  child: Text(
                    widget.isGroup
                        ? 'When enabled, messages sent in this group will disappear after the selected time. All members will be notified.'
                        : 'When enabled, new messages in this chat will disappear after the selected time for both of you.',
                    style: StylesManager.regular(
                      fontSize: FontSize.small,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Duration selector
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: DisappearingMessagesDurationSelector(
                currentDuration: _selectedDuration,
                onDurationChanged: (duration) {
                  setState(() => _selectedDuration = duration);
                },
                showHeader: false,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
              24, 8, 24, 16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: ColorsManager.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: StylesManager.medium(
                        fontSize: FontSize.medium,
                        color: ColorsManager.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveDuration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save',
                            style: StylesManager.semiBold(fontSize: FontSize.medium),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Default Disappearing Messages Settings
/// Full-screen view for setting default disappearing duration for all new chats
class DefaultDisappearingMessagesSettings extends StatefulWidget {
  const DefaultDisappearingMessagesSettings({super.key});

  static Future<void> show(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DefaultDisappearingMessagesSettings(),
      ),
    );
  }

  @override
  State<DefaultDisappearingMessagesSettings> createState() =>
      _DefaultDisappearingMessagesSettingsState();
}

class _DefaultDisappearingMessagesSettingsState
    extends State<DefaultDisappearingMessagesSettings> {
  late PrivacySettingsService _service;

  @override
  void initState() {
    super.initState();
    _service = Get.find<PrivacySettingsService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Text(
          'Disappearing Messages',
          style: StylesManager.semiBold(fontSize: FontSize.large),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final currentDuration = _service
            .settings.value.contentProtection.defaultDisappearingDuration;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header illustration
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.timer,
                    size: 56,
                    color: ColorsManager.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Description
              Text(
                'Default Timer for New Chats',
                style: StylesManager.bold(fontSize: FontSize.large),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Set a default timer for messages in all new chats. You can also customize this setting for individual chats.',
                style: StylesManager.regular(
                  fontSize: FontSize.medium,
                  color: ColorsManager.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Current setting summary
              _buildCurrentSettingSummary(currentDuration),
              const SizedBox(height: 24),

              // Duration selector
              DisappearingMessagesDurationSelector(
                currentDuration: currentDuration,
                onDurationChanged: (duration) async {
                  HapticFeedback.mediumImpact();
                  await _service.updateDefaultDisappearingDuration(duration);
                },
                headerText: 'Select Default Timer',
              ),
              const SizedBox(height: 32),

              // Info section
              _buildInfoSection(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentSettingSummary(DisappearingDuration duration) {
    final isEnabled = duration != DisappearingDuration.off;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEnabled
            ? ColorsManager.primary.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? ColorsManager.primary.withValues(alpha: 0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEnabled ? ColorsManager.primary : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEnabled ? Iconsax.timer_start : Iconsax.timer_pause,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnabled ? 'Enabled' : 'Disabled',
                  style: StylesManager.semiBold(
                    fontSize: FontSize.medium,
                    color: isEnabled ? ColorsManager.primary : Colors.grey,
                  ),
                ),
                Text(
                  isEnabled
                      ? 'New messages will disappear after ${duration.displayName.toLowerCase()}'
                      : 'Messages will not disappear automatically',
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
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it works',
          style: StylesManager.semiBold(
            fontSize: FontSize.medium,
            color: ColorsManager.grey,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          icon: Iconsax.clock,
          title: 'Timer starts when read',
          description:
              'The countdown begins when the recipient reads the message.',
        ),
        _buildInfoItem(
          icon: Iconsax.notification,
          title: 'Both parties notified',
          description:
              'A notification appears when disappearing messages are enabled.',
        ),
        _buildInfoItem(
          icon: Iconsax.shield_tick,
          title: 'Enhanced privacy',
          description:
              'Messages are permanently deleted after the timer expires.',
        ),
        _buildInfoItem(
          icon: Iconsax.setting_2,
          title: 'Per-chat settings',
          description:
              'You can customize the timer for individual chats anytime.',
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: ColorsManager.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: StylesManager.medium(fontSize: FontSize.medium),
                ),
                Text(
                  description,
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
    );
  }
}

/// Disappearing Messages Tile for Settings Lists
/// A pre-built tile widget to show in settings views
class DisappearingMessagesTile extends StatelessWidget {
  final VoidCallback? onTap;
  final DisappearingDuration? currentDuration;

  const DisappearingMessagesTile({
    super.key,
    this.onTap,
    this.currentDuration,
  });

  @override
  Widget build(BuildContext context) {
    final duration = currentDuration ?? DisappearingDuration.off;
    final isEnabled = duration != DisappearingDuration.off;

    return ListTile(
      onTap: onTap ?? () => DefaultDisappearingMessagesSettings.show(context),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isEnabled
              ? ColorsManager.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Iconsax.timer,
          color: isEnabled ? ColorsManager.primary : ColorsManager.grey,
          size: 22,
        ),
      ),
      title: Text(
        'Disappearing Messages',
        style: StylesManager.medium(fontSize: FontSize.medium),
      ),
      subtitle: Text(
        isEnabled ? duration.displayName : 'Off',
        style: StylesManager.regular(
          fontSize: FontSize.small,
          color: isEnabled ? ColorsManager.primary : ColorsManager.grey,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: ColorsManager.grey,
      ),
    );
  }
}

/// Chat Disappearing Messages Tile
/// For use in chat info/user info views with per-chat settings
class ChatDisappearingMessagesTile extends StatelessWidget {
  final String chatId;
  final String chatName;
  final bool isGroup;
  final DisappearingDuration currentDuration;
  final ValueChanged<DisappearingDuration>? onDurationChanged;

  const ChatDisappearingMessagesTile({
    super.key,
    required this.chatId,
    required this.chatName,
    this.isGroup = false,
    required this.currentDuration,
    this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = currentDuration != DisappearingDuration.off;

    return ListTile(
      onTap: () async {
        final result = await DisappearingMessagesSheet.show(
          context,
          chatId: chatId,
          chatName: chatName,
          isGroup: isGroup,
          currentDuration: currentDuration,
        );
        if (result != null && onDurationChanged != null) {
          onDurationChanged!(result);
        }
      },
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isEnabled
              ? ColorsManager.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Iconsax.timer,
          color: isEnabled ? ColorsManager.primary : ColorsManager.grey,
          size: 22,
        ),
      ),
      title: Text(
        'Disappearing Messages',
        style: StylesManager.medium(fontSize: FontSize.medium),
      ),
      subtitle: Text(
        isEnabled ? currentDuration.displayName : 'Off',
        style: StylesManager.regular(
          fontSize: FontSize.small,
          color: isEnabled ? ColorsManager.primary : ColorsManager.grey,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEnabled)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: ColorsManager.primary,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: ColorsManager.grey,
          ),
        ],
      ),
    );
  }
}
