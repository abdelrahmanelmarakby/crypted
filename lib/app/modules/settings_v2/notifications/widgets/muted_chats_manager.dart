import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/notification_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/notifications/controllers/notification_settings_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Muted Chats Manager Widget
/// Displays and manages muted chats with proper names and avatars
class MutedChatsManager extends StatelessWidget {
  const MutedChatsManager({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const MutedChatsManager(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationSettingsController>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
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

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.notifications_off_rounded, color: Colors.grey),
                const SizedBox(width: 12),
                const Text(
                  'Muted Chats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Muted chats list
          Expanded(
            child: Obx(() {
              final mutedChats = controller.mutedChats;

              if (mutedChats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Muted Chats',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All your chats have notifications enabled',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: mutedChats.length,
                itemBuilder: (context, index) {
                  final chat = mutedChats[index];
                  return _MutedChatTile(
                    chatOverride: chat,
                    onUnmute: () => controller.unmuteChat(chat.chatId),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MutedChatTile extends StatelessWidget {
  final ChatNotificationOverride chatOverride;
  final VoidCallback onUnmute;

  const _MutedChatTile({
    required this.chatOverride,
    required this.onUnmute,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ChatInfo?>(
      future: _fetchChatInfo(chatOverride.chatId),
      builder: (context, snapshot) {
        final chatInfo = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
            backgroundImage: chatInfo?.imageUrl != null
                ? NetworkImage(chatInfo!.imageUrl!)
                : null,
            child: chatInfo?.imageUrl == null
                ? Text(
                    (chatInfo?.name ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                      color: ColorsManager.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: isLoading
              ? Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Text(chatInfo?.name ?? 'Unknown Chat'),
          subtitle: Text(
            _getMuteDescription(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chatOverride.sound != null)
                Tooltip(
                  message: 'Custom sound',
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onUnmute,
                child: Text(
                  'Unmute',
                  style: TextStyle(color: ColorsManager.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMuteDescription() {
    if (chatOverride.mutedUntil == null) {
      return 'Muted indefinitely';
    }

    final now = DateTime.now();
    final until = chatOverride.mutedUntil!;

    if (until.isBefore(now)) {
      return 'Mute expired';
    }

    final diff = until.difference(now);

    if (diff.inDays > 0) {
      return 'Muted for ${diff.inDays} more ${diff.inDays == 1 ? 'day' : 'days'}';
    } else if (diff.inHours > 0) {
      return 'Muted for ${diff.inHours} more ${diff.inHours == 1 ? 'hour' : 'hours'}';
    } else {
      return 'Muted for ${diff.inMinutes} more minutes';
    }
  }

  Future<_ChatInfo?> _fetchChatInfo(String chatId) async {
    try {
      // Try chat_rooms collection first
      var doc = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatId)
          .get();

      if (!doc.exists) {
        // Try chats collection
        doc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .get();
      }

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      // Check if it's a group chat
      final isGroup = data['isGroupChat'] == true ||
          data['name'] != null ||
          (data['membersIds'] as List?)?.length != 2;

      if (isGroup) {
        return _ChatInfo(
          name: data['name'] ?? data['groupName'] ?? 'Group',
          imageUrl: data['groupImageUrl'] ?? data['imageUrl'],
          isGroup: true,
        );
      }

      // For direct chats, get the other user's info
      final membersIds = List<String>.from(data['membersIds'] ?? []);
      if (membersIds.length != 2) {
        return _ChatInfo(name: 'Chat', isGroup: false);
      }

      // Get the other user's ID (not current user)
      // For now, just use the first member as we don't have current user context
      final otherUserId = membersIds.first;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();

      if (!userDoc.exists) {
        return _ChatInfo(name: 'Chat', isGroup: false);
      }

      final userData = userDoc.data();
      return _ChatInfo(
        name: userData?['fullName'] ?? userData?['name'] ?? 'User',
        imageUrl: userData?['imageUrl'],
        isGroup: false,
      );
    } catch (e) {
      debugPrint('Error fetching chat info: $e');
      return null;
    }
  }
}

class _ChatInfo {
  final String name;
  final String? imageUrl;
  final bool isGroup;

  _ChatInfo({
    required this.name,
    this.imageUrl,
    this.isGroup = false,
  });
}

/// Mute Chat Dialog
/// Shows options for muting a specific chat
class MuteChatDialog extends StatelessWidget {
  final String chatId;
  final String chatName;
  final Function(MuteDuration) onMute;

  const MuteChatDialog({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.onMute,
  });

  static Future<MuteDuration?> show({
    required BuildContext context,
    required String chatId,
    required String chatName,
  }) async {
    return showModalBottomSheet<MuteDuration>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MuteChatDialog(
        chatId: chatId,
        chatName: chatName,
        onMute: (duration) => Navigator.pop(context, duration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.notifications_off_rounded,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  'Mute "$chatName"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how long to mute notifications',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Duration options
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('8 hours'),
            onTap: () => onMute(MuteDuration.hours8),
          ),
          ListTile(
            leading: const Icon(Icons.today_outlined),
            title: const Text('1 week'),
            onTap: () => onMute(MuteDuration.week1),
          ),
          ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: const Text('Always'),
            subtitle: const Text('Until you unmute'),
            onTap: () => onMute(MuteDuration.forever),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Per-Contact Notification Override Widget
/// Allows setting custom notification settings for specific contacts
class ContactNotificationOverride extends StatefulWidget {
  final String contactId;
  final String contactName;
  final String? contactImageUrl;
  final ChatNotificationOverride? currentOverride;
  final Function(ChatNotificationOverride?) onSave;

  const ContactNotificationOverride({
    super.key,
    required this.contactId,
    required this.contactName,
    this.contactImageUrl,
    this.currentOverride,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String contactId,
    required String contactName,
    String? contactImageUrl,
    ChatNotificationOverride? currentOverride,
    required Function(ChatNotificationOverride?) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ContactNotificationOverride(
        contactId: contactId,
        contactName: contactName,
        contactImageUrl: contactImageUrl,
        currentOverride: currentOverride,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ContactNotificationOverride> createState() =>
      _ContactNotificationOverrideState();
}

class _ContactNotificationOverrideState
    extends State<ContactNotificationOverride> {
  late bool _useCustomSettings;
  late NotificationSound _sound;
  late VibrationPattern _vibration;
  late bool _showPreview;

  @override
  void initState() {
    super.initState();
    final override = widget.currentOverride;
    _useCustomSettings = override?.hasCustomizations ?? false;
    _sound = override?.sound?.sound ?? NotificationSound.default_;
    _vibration = override?.vibration ?? VibrationPattern.medium;
    _showPreview = override?.showPreview ?? true;
  }

  void _save() {
    final now = DateTime.now();
    if (_useCustomSettings) {
      final override = ChatNotificationOverride(
        chatId: widget.contactId,
        enabled: true,
        sound: SoundConfig(sound: _sound),
        vibration: _vibration,
        showPreview: _showPreview,
        createdAt: widget.currentOverride?.createdAt ?? now,
        updatedAt: now,
      );
      widget.onSave(override);
    } else {
      widget.onSave(null); // Remove override
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
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

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
                  backgroundImage: widget.contactImageUrl != null
                      ? NetworkImage(widget.contactImageUrl!)
                      : null,
                  child: widget.contactImageUrl == null
                      ? Text(
                          widget.contactName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            color: ColorsManager.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.contactName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Custom notification settings',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Settings
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    value: _useCustomSettings,
                    onChanged: (v) => setState(() => _useCustomSettings = v),
                    title: const Text('Use custom settings'),
                    subtitle: const Text(
                      'Override default notification settings for this contact',
                    ),
                    contentPadding: EdgeInsets.zero,
                    activeColor: ColorsManager.primary,
                  ),

                  if (_useCustomSettings) ...[
                    const SizedBox(height: 16),

                    Text(
                      'Sound',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<NotificationSound>(
                          value: _sound,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          borderRadius: BorderRadius.circular(12),
                          items: NotificationSound.values.map((sound) {
                            return DropdownMenuItem(
                              value: sound,
                              child: Text(sound.displayName),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _sound = v);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Vibration',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<VibrationPattern>(
                          value: _vibration,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          borderRadius: BorderRadius.circular(12),
                          items: VibrationPattern.values.map((pattern) {
                            return DropdownMenuItem(
                              value: pattern,
                              child: Text(pattern.displayName),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _vibration = v);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SwitchListTile.adaptive(
                      value: _showPreview,
                      onChanged: (v) => setState(() => _showPreview = v),
                      title: const Text('Show preview'),
                      subtitle: const Text(
                        'Show message content in notifications',
                      ),
                      contentPadding: EdgeInsets.zero,
                      activeColor: ColorsManager.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
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
