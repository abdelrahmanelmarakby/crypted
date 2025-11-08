import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/modules/chat/widgets/reaction_picker.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

class MessageActionsBottomSheet extends StatelessWidget {
  const MessageActionsBottomSheet({
    super.key,
    required this.message,
    required this.onReply,
    required this.onCopy,
    required this.onForward,
    required this.onPin,
    required this.onFavorite,
    required this.onReport,
    required this.onDelete,
    this.onRestore,
    this.onReaction,
    this.onEdit,
    this.isPinned = false,
    this.isFavorite = false,
    this.canPin = true,
    this.canFavorite = true,
    this.canDelete = true,
    this.canRestore = false,
    this.canReply = true,
    this.canForward = true,
    this.canCopy = true,
    this.canReport = true,
    this.canEdit = false,
  });

  final Message message;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback onForward;
  final VoidCallback onPin;
  final VoidCallback onFavorite;
  final VoidCallback? onRestore;
  final VoidCallback onReport;
  final VoidCallback onDelete;
  final Function(String emoji)? onReaction;
  final VoidCallback? onEdit;
  final bool isPinned;
  final bool isFavorite;
  final bool canPin;
  final bool canFavorite;
  final bool canDelete;
  final bool canRestore;
  final bool canReply;
  final bool canForward;
  final bool canCopy;
  final bool canReport;
  final bool canEdit;

  static void show(
    BuildContext context, {
    required Message message,
    required VoidCallback onReply,
    required VoidCallback onCopy,
    required VoidCallback onForward,
    required VoidCallback onPin,
    required VoidCallback onFavorite,
    required VoidCallback onReport,
    required VoidCallback onDelete,
    VoidCallback? onRestore,
    Function(String emoji)? onReaction,
    VoidCallback? onEdit,
    bool isPinned = false,
    bool isFavorite = false,
    bool canPin = true,
    bool canFavorite = true,
    bool canDelete = true,
    bool canRestore = false,
    bool canReply = true,
    bool canForward = true,
    bool canCopy = true,
    bool canReport = true,
    bool canEdit = false,
  }) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MessageActionsBottomSheet(
        message: message,
        onReply: onReply,
        onCopy: onCopy,
        onForward: onForward,
        onPin: onPin,
        onFavorite: onFavorite,
        onReport: onReport,
        onDelete: onDelete,
        onRestore: onRestore,
        onReaction: onReaction,
        onEdit: onEdit,
        isPinned: isPinned,
        isFavorite: isFavorite,
        canPin: canPin,
        canFavorite: canFavorite,
        canDelete: canDelete,
        canRestore: canRestore,
        canReply: canReply,
        canForward: canForward,
        canCopy: canCopy,
        canReport: canReport,
        canEdit: canEdit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: ColorsManager.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'Message Actions',
                  style: TextStyle(
                    fontSize: FontSize.large,
                    fontWeight: FontWeight.w600,
                    color: ColorsManager.black,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorsManager.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: ColorsManager.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick reactions
          if (onReaction != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: ReactionPicker(
                onReactionSelected: (emoji) {
                  Navigator.pop(context);
                  onReaction!(emoji);
                },
                onMoreEmojis: () {
                  Navigator.pop(context);
                  EmojiPickerDialog.show(context, (emoji) {
                    onReaction!(emoji);
                  });
                },
              ),
            ),

          // Action items
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  if (canReply)
                    _buildActionItem(
                      context: context,
                      iconPath: 'assets/icons/fi_9630774.svg',
                      title: 'Reply',
                      onTap: () {
                        Navigator.pop(context);
                        onReply();
                      },
                    ),

                  if (canEdit && onEdit != null)
                    _buildActionItem(
                      context: context,
                      iconPath: 'assets/icons/fi_3648797.svg', // Using edit icon
                      title: 'Edit',
                      onTap: () {
                        Navigator.pop(context);
                        onEdit!();
                      },
                      iconColor: ColorsManager.primary,
                    ),

                  if (canForward)
                    _buildActionItem(
                      context: context,
                      iconPath: 'assets/icons/export.svg',
                      title: 'Forward',
                      onTap: () {
                        Navigator.pop(context);
                        onForward();
                      },
                    ),

                  if (canCopy && message is TextMessage)
                    _buildActionItem(
                      context: context,
                      iconPath: 'assets/icons/copy.svg',
                      title: 'Copy',
                      onTap: () {
                        Navigator.pop(context);
                        onCopy();
                      },
                    ),

                  if (canFavorite)
                    _buildActionItem(
                      context: context,
                      iconPath: 'assets/icons/star.svg',
                      title: isFavorite ? 'Unfavorite' : 'Favorite',
                      onTap: () {
                        Navigator.pop(context);
                        onFavorite();
                      },
                      iconColor: isFavorite ? ColorsManager.star : null,
                    ),

                  if (canPin)
                    _buildActionItem(
                      context: context,
                      iconPath: 'assets/icons/fi_3648797.svg',
                      title: isPinned ? 'Unpin' : 'Pin',
                      onTap: () {
                        Navigator.pop(context);
                        onPin();
                      },
                      iconColor: isPinned ? ColorsManager.primary : null,
                    ),

                  if (canReport)
                    _buildActionItem(
                      context: context,
                      iconPath: 'assets/icons/fi_7689567.svg',
                      title: 'Report',
                      onTap: () {
                        Navigator.pop(context);
                        onReport();
                      },
                      textColor: ColorsManager.error2,
                      iconColor: ColorsManager.error2,
                    ),

                  if (canRestore && onRestore != null)
                    _buildActionItem(
                      context: context,
                      iconPath: 'assets/icons/fi_8114095.svg',
                      title: 'Restore',
                      onTap: () {
                        Navigator.pop(context);
                        onRestore!();
                      },
                      textColor: ColorsManager.primary,
                      iconColor: ColorsManager.primary,
                    ),

                  if (canDelete)
                    _buildActionItem(
                      context: context,
                      iconPath: 'assets/icons/trash.svg',
                      title: 'Delete',
                      onTap: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                      textColor: ColorsManager.error2,
                      iconColor: ColorsManager.error2,
                      isDestructive: true,
                    ),
                ],
              ),
            ),
          ),

          // Bottom padding for safe area
          Container(
            height: MediaQuery.of(context).padding.bottom,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required String iconPath,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isDestructive ? ColorsManager.error2.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? ColorsManager.grey).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              iconColor ?? ColorsManager.grey,
              BlendMode.srcIn,
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: FontSize.medium,
            fontWeight: FontWeight.w500,
            color: textColor ?? ColorsManager.black,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: ColorsManager.grey,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
