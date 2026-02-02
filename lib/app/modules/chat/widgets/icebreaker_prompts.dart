import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

/// Shows icebreaker conversation prompts when a chat is empty.
///
/// Displays a friendly greeting, random conversation-starter cards,
/// and quick-tap message chips. When the user taps a prompt,
/// [onPromptSelected] is called with the text to send.
class IcebreakerPrompts extends StatefulWidget {
  final String? otherUserName;
  final ValueChanged<String> onPromptSelected;
  final bool isGroupChat;

  const IcebreakerPrompts({
    super.key,
    this.otherUserName,
    required this.onPromptSelected,
    this.isGroupChat = false,
  });

  @override
  State<IcebreakerPrompts> createState() => _IcebreakerPromptsState();
}

class _IcebreakerPromptsState extends State<IcebreakerPrompts> {
  late final List<_IcebreakerCard> _selectedCards;
  late final List<_QuickChip> _selectedChips;

  // Full pool of icebreaker prompts
  static const _allCards = [
    _IcebreakerCard(
      emoji: '🌤️',
      title: 'Weekend Plans',
      prompt: 'Got any plans for the weekend?',
    ),
    _IcebreakerCard(
      emoji: '🎵',
      title: 'Music Taste',
      prompt: 'What are you listening to lately?',
    ),
    _IcebreakerCard(
      emoji: '🍿',
      title: 'Shows & Movies',
      prompt: 'Watching anything good lately?',
    ),
    _IcebreakerCard(
      emoji: '✈️',
      title: 'Travel',
      prompt: 'Where would you love to travel next?',
    ),
    _IcebreakerCard(
      emoji: '🎮',
      title: 'Gaming',
      prompt: 'Are you into any games right now?',
    ),
    _IcebreakerCard(
      emoji: '📖',
      title: 'Books',
      prompt: 'Read any good books recently?',
    ),
    _IcebreakerCard(
      emoji: '🍕',
      title: 'Food',
      prompt: 'What\'s your go-to comfort food?',
    ),
    _IcebreakerCard(
      emoji: '💡',
      title: 'Fun Fact',
      prompt: 'Tell me a random fun fact about yourself!',
    ),
    _IcebreakerCard(
      emoji: '🏆',
      title: 'Achievement',
      prompt: 'What\'s something you\'re proud of recently?',
    ),
    _IcebreakerCard(
      emoji: '🌍',
      title: 'Dream Destination',
      prompt: 'If you could teleport anywhere right now, where would you go?',
    ),
  ];

  // Quick-tap chips
  static const _allChips = [
    _QuickChip('Hey! 👋', 'Hey! 👋'),
    _QuickChip('How are you?', 'How are you?'),
    _QuickChip('What\'s up?', 'What\'s up?'),
    _QuickChip('Hello! 😊', 'Hello! 😊'),
    _QuickChip('Hi there!', 'Hi there!'),
    _QuickChip('Good morning ☀️', 'Good morning ☀️'),
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    // Pick 3 random cards
    final shuffledCards = List.of(_allCards)..shuffle(rng);
    _selectedCards = shuffledCards.take(3).toList();
    // Pick 4 random chips
    final shuffledChips = List.of(_allChips)..shuffle(rng);
    _selectedChips = shuffledChips.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.otherUserName ?? 'them';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Greeting
          Icon(
            widget.isGroupChat
                ? Icons.group_outlined
                : Iconsax.message_favorite,
            size: 56,
            color: ColorsManager.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isGroupChat ? 'Start the conversation!' : 'Say hi to $name',
            style: StylesManager.semiBold(
              fontSize: FontSize.xLarge,
              color: ColorsManager.textPrimaryAdaptive(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Break the ice with a conversation starter',
            style: StylesManager.regular(
              fontSize: FontSize.small,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Quick-tap chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _selectedChips.map((chip) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onPromptSelected(chip.message);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: ColorsManager.primary.withAlpha(40)),
                  ),
                  child: Text(
                    chip.label,
                    style: TextStyle(
                      fontSize: FontSize.small,
                      fontWeight: FontWeight.w500,
                      color: ColorsManager.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Icebreaker cards
          ...List.generate(_selectedCards.length, (i) {
            final card = _selectedCards[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onPromptSelected(card.prompt);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ColorsManager.surfaceAdaptive(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withAlpha(25)),
                  ),
                  child: Row(
                    children: [
                      Text(card.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.title,
                              style: TextStyle(
                                fontSize: FontSize.xSmall,
                                fontWeight: FontWeight.w600,
                                color: ColorsManager.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              card.prompt,
                              style: TextStyle(
                                fontSize: FontSize.small,
                                color:
                                    ColorsManager.textPrimaryAdaptive(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Iconsax.send_2,
                        size: 18,
                        color: ColorsManager.primary.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _IcebreakerCard {
  final String emoji;
  final String title;
  final String prompt;

  const _IcebreakerCard({
    required this.emoji,
    required this.title,
    required this.prompt,
  });
}

class _QuickChip {
  final String label;
  final String message;

  const _QuickChip(this.label, this.message);
}
