import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget to display reactions on a message
class MessageReactionsDisplay extends StatelessWidget {
  final List<Reaction> reactions;
  final String currentUserId;
  final Function(String emoji) onReactionTap;
  final VoidCallback onShowDetails;

  const MessageReactionsDisplay({
    Key? key,
    required this.reactions,
    required this.currentUserId,
    required this.onReactionTap,
    required this.onShowDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by emoji
    final Map<String, List<Reaction>> groupedReactions = {};
    for (var reaction in reactions) {
      groupedReactions.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return Padding(
      padding: EdgeInsets.only(top: Paddings.xSmall),
      child: Wrap(
        spacing: Paddings.xSmall,
        runSpacing: Paddings.xSmall,
        children: groupedReactions.entries.map((entry) {
          final emoji = entry.key;
          final reactionList = entry.value;
          final count = reactionList.length;
          final hasUserReacted = reactionList.any((r) => r.userId == currentUserId);

          return _ReactionChip(
            emoji: emoji,
            count: count,
            isUserReacted: hasUserReacted,
            onTap: () => onReactionTap(emoji),
            onLongPress: count > 1 ? () => _showReactionDetails(context, emoji, reactionList) : null,
          );
        }).toList(),
      ),
    );
  }

  void _showReactionDetails(BuildContext context, String emoji, List<Reaction> reactions) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReactionDetailsSheet(
        emoji: emoji,
        reactions: reactions,
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool isUserReacted;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.isUserReacted,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Paddings.small,
          vertical: Paddings.xSmall / 2,
        ),
        decoration: BoxDecoration(
          color: isUserReacted
              ? ColorsManager.primary.withOpacity(0.2)
              : (Get.isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUserReacted
                ? ColorsManager.primary.withOpacity(0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            if (count > 1) ...[
              SizedBox(width: Paddings.xSmall / 2),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: FontSize.small,
                  fontWeight: isUserReacted ? FontWeight.bold : FontWeight.normal,
                  color: isUserReacted ? ColorsManager.primary : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet showing who reacted with a specific emoji
class ReactionDetailsSheet extends StatelessWidget {
  final String emoji;
  final List<Reaction> reactions;

  const ReactionDetailsSheet({
    Key? key,
    required this.emoji,
    required this.reactions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Paddings.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
              SizedBox(width: Paddings.normal),
              Text(
                '${reactions.length} ${reactions.length == 1 ? 'Reaction' : 'Reactions'}',
                style: TextStyle(
                  fontSize: FontSize.large,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: Paddings.large),

          // List of users who reacted
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: reactions.length,
              separatorBuilder: (context, index) => Divider(height: Paddings.normal),
              itemBuilder: (context, index) {
                final reaction = reactions[index];
                return _ReactionUserTile(userId: reaction.userId);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionUserTile extends StatelessWidget {
  final String userId;

  const _ReactionUserTile({required this.userId});

  @override
  Widget build(BuildContext context) {
    // Fetch user data from UserService
    return FutureBuilder<SocialMediaUser?>(
      future: UserService().getProfile(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: ColorsManager.primary.withOpacity(0.2),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            title: Text(
              'Loading...',
              style: TextStyle(
                fontSize: FontSize.medium,
                color: Colors.grey,
              ),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          // User not found, show placeholder
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: ColorsManager.primary.withOpacity(0.2),
              child: Icon(Icons.person, color: ColorsManager.primary),
            ),
            title: Text(
              'Unknown User',
              style: TextStyle(
                fontSize: FontSize.medium,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          );
        }

        // Display actual user data
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: user.imageUrl != null && user.imageUrl!.isNotEmpty
              ? CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(user.imageUrl!),
                  backgroundColor: ColorsManager.primary.withOpacity(0.2),
                )
              : CircleAvatar(
                  backgroundColor: ColorsManager.primary.withOpacity(0.2),
                  child: Text(
                    user.fullName?.isNotEmpty == true
                        ? user.fullName![0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: ColorsManager.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          title: Text(
            user.fullName ?? 'Unknown',
            style: TextStyle(
              fontSize: FontSize.medium,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: user.bio != null && user.bio!.isNotEmpty
              ? Text(
                  user.bio!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: FontSize.small,
                    color: Colors.grey,
                  ),
                )
              : null,
        );
      },
    );
  }
}

/// Dialog showing all reactions on a message grouped by emoji
class AllReactionsDialog extends StatelessWidget {
  final List<Reaction> reactions;

  const AllReactionsDialog({
    Key? key,
    required this.reactions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group reactions by emoji
    final Map<String, List<Reaction>> groupedReactions = {};
    for (var reaction in reactions) {
      groupedReactions.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(Paddings.large),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Reactions',
              style: TextStyle(
                fontSize: FontSize.large,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Paddings.normal),

            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: groupedReactions.length,
                separatorBuilder: (context, index) => Divider(height: Paddings.large),
                itemBuilder: (context, index) {
                  final entry = groupedReactions.entries.elementAt(index);
                  return _ReactionGroup(
                    emoji: entry.key,
                    reactions: entry.value,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, List<Reaction> reactions) {
    showDialog(
      context: context,
      builder: (context) => AllReactionsDialog(reactions: reactions),
    );
  }
}

class _ReactionGroup extends StatelessWidget {
  final String emoji;
  final List<Reaction> reactions;

  const _ReactionGroup({
    required this.emoji,
    required this.reactions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            SizedBox(width: Paddings.small),
            Text(
              '${reactions.length}',
              style: TextStyle(
                fontSize: FontSize.medium,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: Paddings.small),
        Wrap(
          spacing: Paddings.small,
          runSpacing: Paddings.small,
          children: reactions.map((reaction) {
            return Chip(
              label: Text('User ${reaction.userId}'), // Replace with actual user name
              backgroundColor: ColorsManager.primary.withOpacity(0.1),
              labelStyle: TextStyle(
                fontSize: FontSize.small,
                color: ColorsManager.primary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
