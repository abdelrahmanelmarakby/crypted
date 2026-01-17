import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Model for group invite links
class GroupInviteLink {
  final String id;
  final String groupId;
  final String code;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int? maxUses;
  final int usedCount;
  final bool isRevoked;
  final String? name;

  const GroupInviteLink({
    required this.id,
    required this.groupId,
    required this.code,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
    this.maxUses,
    this.usedCount = 0,
    this.isRevoked = false,
    this.name,
  });

  /// Full invite link URL
  String get fullLink => 'https://crypted.app/join/$code';

  /// Check if link is expired
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Check if link has reached max uses
  bool get isMaxedOut => maxUses != null && usedCount >= maxUses!;

  /// Check if link is valid
  bool get isValid => !isRevoked && !isExpired && !isMaxedOut;

  /// Remaining uses
  int? get remainingUses => maxUses != null ? maxUses! - usedCount : null;

  factory GroupInviteLink.fromMap(String id, Map<String, dynamic> map) {
    return GroupInviteLink(
      id: id,
      groupId: map['groupId'] as String? ?? '',
      code: map['code'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      maxUses: map['maxUses'] as int?,
      usedCount: map['usedCount'] as int? ?? 0,
      isRevoked: map['isRevoked'] as bool? ?? false,
      name: map['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'code': code,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      if (maxUses != null) 'maxUses': maxUses,
      'usedCount': usedCount,
      'isRevoked': isRevoked,
      if (name != null) 'name': name,
    };
  }

  GroupInviteLink copyWith({
    String? id,
    String? groupId,
    String? code,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? maxUses,
    int? usedCount,
    bool? isRevoked,
    String? name,
  }) {
    return GroupInviteLink(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      code: code ?? this.code,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      isRevoked: isRevoked ?? this.isRevoked,
      name: name ?? this.name,
    );
  }
}

/// Duration options for invite links
enum InviteLinkExpiry {
  never('Never', null),
  oneHour('1 hour', Duration(hours: 1)),
  oneDay('1 day', Duration(days: 1)),
  oneWeek('7 days', Duration(days: 7)),
  oneMonth('30 days', Duration(days: 30));

  final String label;
  final Duration? duration;

  const InviteLinkExpiry(this.label, this.duration);
}

/// Max uses options for invite links
enum InviteLinkMaxUses {
  unlimited('Unlimited', null),
  one('1 use', 1),
  five('5 uses', 5),
  ten('10 uses', 10),
  twentyFive('25 uses', 25),
  fifty('50 uses', 50),
  hundred('100 uses', 100);

  final String label;
  final int? value;

  const InviteLinkMaxUses(this.label, this.value);
}

/// Widget for managing group invite links
class GroupInviteLinkManager extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isAdmin;

  const GroupInviteLinkManager({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.isAdmin,
  });

  /// Show as bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String groupId,
    required String groupName,
    required bool isAdmin,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: GroupInviteLinkManager(
            groupId: groupId,
            groupName: groupName,
            isAdmin: isAdmin,
          ),
        ),
      ),
    );
  }

  @override
  State<GroupInviteLinkManager> createState() => _GroupInviteLinkManagerState();
}

class _GroupInviteLinkManagerState extends State<GroupInviteLinkManager> {
  bool _isLoading = false;
  GroupInviteLink? _primaryLink;
  List<GroupInviteLink> _allLinks = [];

  @override
  void initState() {
    super.initState();
    _loadInviteLinks();
  }

  Future<void> _loadInviteLinks() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('group_invite_links')
          .where('groupId', isEqualTo: widget.groupId)
          .where('isRevoked', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final links = snapshot.docs
          .map((doc) => GroupInviteLink.fromMap(doc.id, doc.data()))
          .where((link) => link.isValid)
          .toList();

      setState(() {
        _allLinks = links;
        _primaryLink = links.isNotEmpty ? links.first : null;
      });
    } catch (e) {
      debugPrint('Error loading invite links: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<GroupInviteLink> _createInviteLink({
    InviteLinkExpiry expiry = InviteLinkExpiry.never,
    InviteLinkMaxUses maxUses = InviteLinkMaxUses.unlimited,
    String? name,
  }) async {
    final currentUserId = UserService.currentUser.value?.uid ?? '';

    // Generate unique code
    final code = _generateLinkCode();

    final now = DateTime.now();
    final expiresAt = expiry.duration != null ? now.add(expiry.duration!) : null;

    final linkData = {
      'groupId': widget.groupId,
      'code': code,
      'createdBy': currentUserId,
      'createdAt': Timestamp.fromDate(now),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt),
      if (maxUses.value != null) 'maxUses': maxUses.value,
      'usedCount': 0,
      'isRevoked': false,
      if (name != null) 'name': name,
    };

    final docRef = await FirebaseFirestore.instance
        .collection('group_invite_links')
        .add(linkData);

    // Also update group document with primary invite link
    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.groupId)
        .update({
      'inviteLink': 'https://crypted.app/join/$code',
      'inviteLinkCode': code,
    });

    return GroupInviteLink.fromMap(docRef.id, linkData);
  }

  String _generateLinkCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _revokeLink(GroupInviteLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Invite Link'),
        content: Text(
          'Are you sure you want to revoke this invite link? '
          'Anyone with this link will no longer be able to join the group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('group_invite_links')
          .doc(link.id)
          .update({'isRevoked': true});

      await _loadInviteLinks();

      Get.snackbar(
        'Link Revoked',
        'The invite link has been revoked',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to revoke link: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  void _copyLink(GroupInviteLink link) {
    Clipboard.setData(ClipboardData(text: link.fullLink));
    HapticFeedback.lightImpact();

    Get.snackbar(
      'Copied',
      'Invite link copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _shareLink(GroupInviteLink link) {
    Share.share(
      'Join ${widget.groupName} on Crypted!\n\n${link.fullLink}',
      subject: 'Join ${widget.groupName}',
    );
  }

  void _showQRCode(GroupInviteLink link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan to Join'),
        content: SizedBox(
          width: 250,
          height: 250,
          child: Center(
            child: QrImageView(
              data: link.fullLink,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: ColorsManager.primary,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: ColorsManager.primary,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewLink() async {
    InviteLinkExpiry selectedExpiry = InviteLinkExpiry.never;
    InviteLinkMaxUses selectedMaxUses = InviteLinkMaxUses.unlimited;
    final nameController = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Iconsax.link, color: ColorsManager.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Create Invite Link',
                    style: StylesManager.bold(fontSize: FontSize.large),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Link name (optional)
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Link name (optional)',
                  hintText: 'e.g., "Event guests"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Expiry dropdown
              Text(
                'Expires after',
                style: StylesManager.medium(
                  fontSize: FontSize.medium,
                  color: ColorsManager.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<InviteLinkExpiry>(
                    value: selectedExpiry,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(12),
                    items: InviteLinkExpiry.values.map((expiry) {
                      return DropdownMenuItem(
                        value: expiry,
                        child: Text(expiry.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedExpiry = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Max uses dropdown
              Text(
                'Maximum uses',
                style: StylesManager.medium(
                  fontSize: FontSize.medium,
                  color: ColorsManager.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<InviteLinkMaxUses>(
                    value: selectedMaxUses,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(12),
                    items: InviteLinkMaxUses.values.map((maxUses) {
                      return DropdownMenuItem(
                        value: maxUses,
                        child: Text(maxUses.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedMaxUses = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Create button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create Link'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);

      try {
        final link = await _createInviteLink(
          expiry: selectedExpiry,
          maxUses: selectedMaxUses,
          name: nameController.text.isNotEmpty ? nameController.text : null,
        );

        await _loadInviteLinks();

        Get.snackbar(
          'Link Created',
          'New invite link has been created',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to create link: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }

    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Iconsax.link, color: ColorsManager.primary, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Group Invite Links',
                    style: StylesManager.bold(fontSize: FontSize.large),
                  ),
                  Text(
                    widget.groupName,
                    style: StylesManager.regular(
                      fontSize: FontSize.small,
                      color: ColorsManager.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // Primary invite link section
        SliverToBoxAdapter(
          child: _buildPrimaryLinkSection(),
        ),

        // Quick actions
        if (_primaryLink != null)
          SliverToBoxAdapter(
            child: _buildQuickActions(_primaryLink!),
          ),

        // All links header (admin only)
        if (widget.isAdmin && _allLinks.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Text(
                    'All Invite Links',
                    style: StylesManager.bold(fontSize: FontSize.medium),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _createNewLink,
                    icon: const Icon(Iconsax.add, size: 18),
                    label: const Text('New Link'),
                  ),
                ],
              ),
            ),
          ),

        // All links list
        if (widget.isAdmin && _allLinks.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildLinkItem(_allLinks[index]),
              childCount: _allLinks.length,
            ),
          ),

        // Empty state
        if (_primaryLink == null)
          SliverFillRemaining(
            child: _buildEmptyState(),
          ),
      ],
    );
  }

  Widget _buildPrimaryLinkSection() {
    if (_primaryLink == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsManager.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.link_21,
                color: ColorsManager.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Invite Link',
                style: StylesManager.semiBold(
                  fontSize: FontSize.medium,
                  color: ColorsManager.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Link display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _primaryLink!.fullLink,
                    style: StylesManager.medium(
                      fontSize: FontSize.small,
                      color: ColorsManager.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => _copyLink(_primaryLink!),
                  icon: const Icon(Iconsax.copy, size: 20),
                  color: ColorsManager.primary,
                  tooltip: 'Copy link',
                ),
              ],
            ),
          ),

          // Link info
          if (_primaryLink!.expiresAt != null || _primaryLink!.maxUses != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (_primaryLink!.expiresAt != null) ...[
                    Icon(
                      Iconsax.clock,
                      size: 14,
                      color: ColorsManager.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatExpiry(_primaryLink!.expiresAt!),
                      style: StylesManager.regular(
                        fontSize: FontSize.xSmall,
                        color: ColorsManager.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (_primaryLink!.maxUses != null) ...[
                    Icon(
                      Iconsax.people,
                      size: 14,
                      color: ColorsManager.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_primaryLink!.usedCount}/${_primaryLink!.maxUses} uses',
                      style: StylesManager.regular(
                        fontSize: FontSize.xSmall,
                        color: ColorsManager.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(GroupInviteLink link) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionButton(
            icon: Iconsax.copy,
            label: 'Copy',
            onTap: () => _copyLink(link),
          ),
          _buildQuickActionButton(
            icon: Iconsax.share,
            label: 'Share',
            onTap: () => _shareLink(link),
          ),
          _buildQuickActionButton(
            icon: Iconsax.scan_barcode,
            label: 'QR Code',
            onTap: () => _showQRCode(link),
          ),
          if (widget.isAdmin)
            _buildQuickActionButton(
              icon: Iconsax.refresh,
              label: 'Reset',
              onTap: () => _revokeLink(link),
              color: Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (color ?? ColorsManager.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: color ?? ColorsManager.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: StylesManager.medium(
                fontSize: FontSize.xSmall,
                color: color ?? ColorsManager.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkItem(GroupInviteLink link) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorsManager.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Iconsax.link,
            size: 20,
            color: ColorsManager.primary,
          ),
        ),
        title: Text(
          link.name ?? 'Invite link',
          style: StylesManager.medium(fontSize: FontSize.medium),
        ),
        subtitle: Text(
          link.maxUses != null
              ? '${link.usedCount}/${link.maxUses} uses'
              : '${link.usedCount} uses',
          style: StylesManager.regular(
            fontSize: FontSize.xSmall,
            color: ColorsManager.grey,
          ),
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'copy',
              child: Row(
                children: [
                  Icon(Iconsax.copy, size: 18, color: ColorsManager.grey),
                  const SizedBox(width: 12),
                  const Text('Copy'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Iconsax.share, size: 18, color: ColorsManager.grey),
                  const SizedBox(width: 12),
                  const Text('Share'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'revoke',
              child: Row(
                children: [
                  const Icon(Iconsax.trash, size: 18, color: Colors.red),
                  const SizedBox(width: 12),
                  const Text('Revoke', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'copy':
                _copyLink(link);
                break;
              case 'share':
                _shareLink(link);
                break;
              case 'revoke':
                _revokeLink(link);
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.link,
                size: 48,
                color: ColorsManager.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Invite Links',
              style: StylesManager.bold(fontSize: FontSize.large),
            ),
            const SizedBox(height: 8),
            Text(
              'Create an invite link to share with others and let them join the group.',
              textAlign: TextAlign.center,
              style: StylesManager.regular(
                fontSize: FontSize.medium,
                color: ColorsManager.grey,
              ),
            ),
            const SizedBox(height: 24),
            if (widget.isAdmin)
              ElevatedButton.icon(
                onPressed: _createNewLink,
                icon: const Icon(Iconsax.add),
                label: const Text('Create Invite Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatExpiry(DateTime expiresAt) {
    final now = DateTime.now();
    final diff = expiresAt.difference(now);

    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return 'Expires in ${diff.inDays}d';
    if (diff.inHours > 0) return 'Expires in ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Expires in ${diff.inMinutes}m';
    return 'Expiring soon';
  }
}
