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
    Key? key,
    required this.onReactionSelected,
    this.onMoreEmojis,
  }) : super(key: key);

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
        horizontal: Paddings.medium,
        vertical: Paddings.small,
      ),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            SizedBox(width: Paddings.extraSmall),
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
          color: ColorsManager.primary.withOpacity(0.1),
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

/// Full emoji picker dialog for extended emoji selection
class EmojiPickerDialog extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;

  const EmojiPickerDialog({
    Key? key,
    required this.onEmojiSelected,
  }) : super(key: key);

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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        height: 500,
        padding: EdgeInsets.all(Paddings.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Emoji',
              style: TextStyle(
                fontSize: FontSize.large,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Paddings.medium),
            Expanded(
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
                            padding: EdgeInsets.all(Paddings.medium),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: emojis.length,
                            itemBuilder: (context, index) {
                              final emoji = emojis[index];
                              return InkWell(
                                onTap: () {
                                  onEmojiSelected(emoji);
                                  Get.back();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 28),
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
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, Function(String) onEmojiSelected) {
    showDialog(
      context: context,
      builder: (context) => EmojiPickerDialog(onEmojiSelected: onEmojiSelected),
    );
  }
}
