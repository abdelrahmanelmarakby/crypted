import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

/// Group permissions model
class GroupPermissions {
  final PermissionLevel editGroupInfo;
  final PermissionLevel sendMessages;
  final PermissionLevel addMembers;
  final PermissionLevel pinMessages;
  final bool approveNewMembers;
  final bool allowMemberInvites;

  const GroupPermissions({
    this.editGroupInfo = PermissionLevel.adminsOnly,
    this.sendMessages = PermissionLevel.everyone,
    this.addMembers = PermissionLevel.adminsOnly,
    this.pinMessages = PermissionLevel.adminsOnly,
    this.approveNewMembers = false,
    this.allowMemberInvites = true,
  });

  GroupPermissions copyWith({
    PermissionLevel? editGroupInfo,
    PermissionLevel? sendMessages,
    PermissionLevel? addMembers,
    PermissionLevel? pinMessages,
    bool? approveNewMembers,
    bool? allowMemberInvites,
  }) {
    return GroupPermissions(
      editGroupInfo: editGroupInfo ?? this.editGroupInfo,
      sendMessages: sendMessages ?? this.sendMessages,
      addMembers: addMembers ?? this.addMembers,
      pinMessages: pinMessages ?? this.pinMessages,
      approveNewMembers: approveNewMembers ?? this.approveNewMembers,
      allowMemberInvites: allowMemberInvites ?? this.allowMemberInvites,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'editGroupInfo': editGroupInfo.name,
      'sendMessages': sendMessages.name,
      'addMembers': addMembers.name,
      'pinMessages': pinMessages.name,
      'approveNewMembers': approveNewMembers,
      'allowMemberInvites': allowMemberInvites,
    };
  }

  factory GroupPermissions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const GroupPermissions();
    return GroupPermissions(
      editGroupInfo: PermissionLevel.values.firstWhere(
        (e) => e.name == map['editGroupInfo'],
        orElse: () => PermissionLevel.adminsOnly,
      ),
      sendMessages: PermissionLevel.values.firstWhere(
        (e) => e.name == map['sendMessages'],
        orElse: () => PermissionLevel.everyone,
      ),
      addMembers: PermissionLevel.values.firstWhere(
        (e) => e.name == map['addMembers'],
        orElse: () => PermissionLevel.adminsOnly,
      ),
      pinMessages: PermissionLevel.values.firstWhere(
        (e) => e.name == map['pinMessages'],
        orElse: () => PermissionLevel.adminsOnly,
      ),
      approveNewMembers: map['approveNewMembers'] ?? false,
      allowMemberInvites: map['allowMemberInvites'] ?? true,
    );
  }
}

enum PermissionLevel {
  everyone,
  adminsOnly,
}

extension PermissionLevelExtension on PermissionLevel {
  String get displayName {
    switch (this) {
      case PermissionLevel.everyone:
        return 'All Members';
      case PermissionLevel.adminsOnly:
        return 'Admins Only';
    }
  }

  IconData get icon {
    switch (this) {
      case PermissionLevel.everyone:
        return Icons.people;
      case PermissionLevel.adminsOnly:
        return Icons.admin_panel_settings;
    }
  }
}

/// Group Permissions Editor Widget
class GroupPermissionsEditor extends StatefulWidget {
  final String roomId;
  final GroupPermissions initialPermissions;
  final Function(GroupPermissions) onSave;

  const GroupPermissionsEditor({
    super.key,
    required this.roomId,
    required this.initialPermissions,
    required this.onSave,
  });

  static Future<GroupPermissions?> show({
    required BuildContext context,
    required String roomId,
    required GroupPermissions initialPermissions,
  }) async {
    GroupPermissions? result;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => GroupPermissionsEditor(
        roomId: roomId,
        initialPermissions: initialPermissions,
        onSave: (permissions) {
          result = permissions;
          Navigator.pop(context);
        },
      ),
    );
    return result;
  }

  @override
  State<GroupPermissionsEditor> createState() => _GroupPermissionsEditorState();
}

class _GroupPermissionsEditorState extends State<GroupPermissionsEditor> {
  late GroupPermissions _permissions;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _permissions = widget.initialPermissions;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.roomId)
          .update({
        'permissions': _permissions.toMap(),
      });

      widget.onSave(_permissions);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save permissions: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                Icon(Icons.security, color: ColorsManager.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group Permissions',
                        style: StylesManager.semiBold(fontSize: FontSize.large),
                      ),
                      Text(
                        'Control what members can do',
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

          // Permissions list
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message permissions section
                  _buildSectionHeader('Messages', Icons.message),
                  const SizedBox(height: 8),
                  _buildPermissionTile(
                    title: 'Send Messages',
                    subtitle: 'Who can send messages in this group',
                    value: _permissions.sendMessages,
                    onChanged: (value) {
                      setState(() {
                        _permissions = _permissions.copyWith(sendMessages: value);
                      });
                    },
                  ),
                  _buildPermissionTile(
                    title: 'Pin Messages',
                    subtitle: 'Who can pin messages to the top',
                    value: _permissions.pinMessages,
                    onChanged: (value) {
                      setState(() {
                        _permissions = _permissions.copyWith(pinMessages: value);
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Group info section
                  _buildSectionHeader('Group Info', Icons.info),
                  const SizedBox(height: 8),
                  _buildPermissionTile(
                    title: 'Edit Group Info',
                    subtitle: 'Who can change name, photo, and description',
                    value: _permissions.editGroupInfo,
                    onChanged: (value) {
                      setState(() {
                        _permissions = _permissions.copyWith(editGroupInfo: value);
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Members section
                  _buildSectionHeader('Members', Icons.group),
                  const SizedBox(height: 8),
                  _buildPermissionTile(
                    title: 'Add Members',
                    subtitle: 'Who can add new members to the group',
                    value: _permissions.addMembers,
                    onChanged: (value) {
                      setState(() {
                        _permissions = _permissions.copyWith(addMembers: value);
                      });
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Approve New Members',
                    subtitle: 'Admins must approve before members can join',
                    value: _permissions.approveNewMembers,
                    onChanged: (value) {
                      setState(() {
                        _permissions = _permissions.copyWith(approveNewMembers: value);
                      });
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Allow Member Invites',
                    subtitle: 'Members can share invite links',
                    value: _permissions.allowMemberInvites,
                    onChanged: (value) {
                      setState(() {
                        _permissions = _permissions.copyWith(allowMemberInvites: value);
                      });
                    },
                  ),
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
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ColorsManager.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: StylesManager.semiBold(
            fontSize: FontSize.medium,
            color: ColorsManager.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required PermissionLevel value,
    required Function(PermissionLevel) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: StylesManager.medium(fontSize: FontSize.medium),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: PermissionLevel.values.map((level) {
                final isSelected = value == level;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(level),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: level != PermissionLevel.values.last ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ColorsManager.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? ColorsManager.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            level.icon,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              level.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: StylesManager.medium(fontSize: FontSize.medium),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
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
}

/// Permissions Summary Widget
/// Shows current permissions in a compact format
class PermissionsSummaryTile extends StatelessWidget {
  final GroupPermissions permissions;
  final VoidCallback onTap;

  const PermissionsSummaryTile({
    super.key,
    required this.permissions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ColorsManager.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.security, color: ColorsManager.primary),
      ),
      title: const Text('Group Permissions'),
      subtitle: Text(
        _getSummaryText(),
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  String _getSummaryText() {
    final restrictions = <String>[];

    if (permissions.sendMessages == PermissionLevel.adminsOnly) {
      restrictions.add('Only admins can send messages');
    }
    if (permissions.editGroupInfo == PermissionLevel.adminsOnly) {
      restrictions.add('Only admins can edit info');
    }
    if (permissions.approveNewMembers) {
      restrictions.add('New members need approval');
    }

    if (restrictions.isEmpty) {
      return 'Standard permissions';
    }

    return restrictions.first;
  }
}
