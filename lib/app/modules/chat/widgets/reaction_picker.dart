import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';

/// Quick reaction picker widget that appears when long-pressing a message
class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onReactionSelected;
  final VoidCallback? onMoreEmojis;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
    this.onMoreEmojis,
  });

  // Quick reaction emojis (common ones)
  static const List<String> quickReactions = [
    '👍', // Thumbs up
    '❤️', // Heart
    '😂', // Laughing
    '😮', // Surprised
    '😢', // Sad
    '🙏', // Praying/thank you
    '🔥', // Fire
    '👏', // Clapping
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Paddings.xSmall,
        vertical: Paddings.small,
      ),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...quickReactions.map((emoji) => _ReactionButton(
                emoji: emoji,
                onTap: () => onReactionSelected(emoji),
              )),
          if (onMoreEmojis != null) ...[
            SizedBox(width: Paddings.xSmall),
            _MoreEmojisButton(onTap: onMoreEmojis!),
          ],
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class _MoreEmojisButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MoreEmojisButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ColorsManager.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.add,
          size: 20,
          color: ColorsManager.primary,
        ),
      ),
    );
  }
}

/// Full emoji picker bottom sheet for extended emoji selection
class EmojiPickerDialog extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;

  const EmojiPickerDialog({
    super.key,
    required this.onEmojiSelected,
  });

  // Extended emoji list grouped by category
  static const Map<String, List<String>> emojiCategories = {
    'Smileys': [
      '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
      '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
      '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩',
      '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣',
      '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬',
    ],
    'Gestures': [
      '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞', '✌️', '🤟', '🤘',
      '👌', '🤌', '🤏', '👈', '👉', '👆', '👇', '☝️', '👋', '🤚',
      '🖐️', '✋', '🖖', '👏', '🙌', '👐', '🤲', '🤝', '🙏',
    ],
    'Hearts': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
      '❤️‍🔥', '❤️‍🩹', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝',
    ],
    'Symbols': [
      '🔥', '⭐', '✨', '💫', '💥', '💢', '💦', '💨', '🕳️', '💬',
      '👁️‍🗨️', '🗨️', '🗯️', '💭', '💤', '✔️', '✅', '❌', '❎', '➕',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Paddings.large),
            child: Row(
              children: [
                Text(
                  'Select Emoji',
                  style: TextStyle(
                    fontSize: FontSize.large,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Paddings.normal),
          SizedBox(
            height: 400,
            child: DefaultTabController(
              length: emojiCategories.length,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    indicatorColor: ColorsManager.primary,
                    labelColor: ColorsManager.primary,
                    unselectedLabelColor: Colors.grey,
                    tabs: emojiCategories.keys
                        .map((category) => Tab(text: category))
                        .toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: emojiCategories.values.map((emojis) {
                        return GridView.builder(
                          padding: EdgeInsets.all(Paddings.normal),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                          itemCount: emojis.length,
                          itemBuilder: (context, index) {
                            final emoji = emojis[index];
                            return InkWell(
                              onTap: () {
                                onEmojiSelected(emoji);
                                Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  static void show(BuildContext context, Function(String) onEmojiSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => EmojiPickerDialog(onEmojiSelected: onEmojiSelected),
    );
  }
}
