import 'package:flutter/material.dart';
import 'package:crypted_app/app/core/services/chat_privacy_helper.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:get/get.dart';

/// Banner displayed in chat when communication is blocked
/// Shows appropriate message and action button based on blocking state
class BlockedChatBanner extends StatelessWidget {
  final BlockedChatInfo blockInfo;
  final VoidCallback? onUnblock;
  final VoidCallback? onReport;

  const BlockedChatBanner({
    super.key,
    required this.blockInfo,
    this.onUnblock,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    if (!blockInfo.isBlocked) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.red.shade100, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              blockInfo.blockedByMe ? Icons.block : Icons.info_outline,
              color: Colors.red.shade700,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    blockInfo.blockedByMe
                        ? Constants.kYouBlockedThisContact.tr
                        : Constants.kMessageUnavailable.tr,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    blockInfo.message,
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (blockInfo.blockedByMe && onUnblock != null)
              TextButton(
                onPressed: onUnblock,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(Constants.kUnblock.tr),
              ),
          ],
        ),
      ),
    );
  }
}

/// Blocked input bar replacement
/// Shows when user cannot send messages
class BlockedChatInputBar extends StatelessWidget {
  final BlockedChatInfo blockInfo;
  final VoidCallback? onUnblock;

  const BlockedChatInputBar({
    super.key,
    required this.blockInfo,
    this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              color: Colors.grey.shade500,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                blockInfo.blockedByMe
                    ? Constants.kUnblockThisContactToSendMessages.tr
                    : Constants.kYouCantSendMessages.tr,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (blockInfo.blockedByMe && onUnblock != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: onUnblock,
                style: TextButton.styleFrom(
                  foregroundColor: ColorsManager.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(Constants.kUnblock.tr),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Badge shown on chat list items for blocked users
class BlockedUserBadge extends StatelessWidget {
  final bool isBlocked;
  final bool compact;

  const BlockedUserBadge({
    super.key,
    required this.isBlocked,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isBlocked) return const SizedBox.shrink();

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.block,
          color: Colors.red.shade600,
          size: 12,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block,
            color: Colors.red.shade600,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            Constants.kBlocked.tr,
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog shown when trying to interact with blocked user
class BlockedUserDialog extends StatelessWidget {
  final String userName;
  final bool blockedByMe;
  final VoidCallback? onUnblock;
  final VoidCallback? onCancel;

  const BlockedUserDialog({
    super.key,
    required this.userName,
    required this.blockedByMe,
    this.onUnblock,
    this.onCancel,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String userName,
    required bool blockedByMe,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BlockedUserDialog(
        userName: userName,
        blockedByMe: blockedByMe,
        onUnblock: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.block,
              color: Colors.red.shade600,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            blockedByMe
                ? Constants.kContactBlocked.tr
                : Constants.kCannotContact.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            blockedByMe
                ? 'You have blocked $userName. Would you like to unblock them to continue this conversation?'
                : 'You cannot contact $userName at this time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          if (blockedByMe && onUnblock != null) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onUnblock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  Constants.kUnblock.tr,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: onCancel ?? () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                blockedByMe ? Constants.kKeepBlocked.tr : Constants.kOK.tr,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unblock confirmation bottom sheet
class UnblockConfirmationSheet extends StatelessWidget {
  final String userName;
  final String? userPhotoUrl;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const UnblockConfirmationSheet({
    super.key,
    required this.userName,
    this.userPhotoUrl,
    required this.onConfirm,
    required this.onCancel,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String userName,
    String? userPhotoUrl,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => UnblockConfirmationSheet(
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Avatar
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  userPhotoUrl != null ? NetworkImage(userPhotoUrl!) : null,
              child: userPhotoUrl == null
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.grey.shade600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Unblock $userName?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'They will be able to call you, message you, and see your status updates.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(Constants.kCancel.tr),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(Constants.kUnblock.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
