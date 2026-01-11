import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/locale/constant.dart';

/// UI-003: Empty State Design
/// Provides meaningful empty states for various chat scenarios

class ChatEmptyState extends StatelessWidget {
  final EmptyStateType type;
  final VoidCallback? onAction;
  final String? customMessage;
  final String? customActionLabel;

  const ChatEmptyState({
    super.key,
    this.type = EmptyStateType.newConversation,
    this.onAction,
    this.customMessage,
    this.customActionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            _buildIllustration(),
            const SizedBox(height: 32),

            // Title
            Text(
              _getTitle(),
              style: StylesManager.bold(
                fontSize: FontSize.xLarge,
                color: ColorsManager.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              customMessage ?? _getMessage(),
              style: StylesManager.regular(
                fontSize: FontSize.medium,
                color: ColorsManager.grey,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (onAction != null) ...[
              const SizedBox(height: 32),
              _buildActionButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: ColorsManager.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: ColorsManager.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIcon(),
            size: 60,
            color: ColorsManager.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: onAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsManager.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getActionIcon(), size: 20),
          const SizedBox(width: 8),
          Text(
            customActionLabel ?? _getActionLabel(),
            style: StylesManager.medium(
              fontSize: FontSize.medium,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case EmptyStateType.newConversation:
        return Icons.chat_bubble_outline_rounded;
      case EmptyStateType.noMessages:
        return Icons.message_outlined;
      case EmptyStateType.noSearchResults:
        return Icons.search_off_rounded;
      case EmptyStateType.error:
        return Icons.error_outline_rounded;
      case EmptyStateType.blocked:
        return Icons.block_rounded;
      case EmptyStateType.archived:
        return Icons.archive_outlined;
    }
  }

  String _getTitle() {
    switch (type) {
      case EmptyStateType.newConversation:
        return Constants.kStartConversation.tr;
      case EmptyStateType.noMessages:
        return Constants.kNoMessages.tr;
      case EmptyStateType.noSearchResults:
        return Constants.kNoResults.tr;
      case EmptyStateType.error:
        return Constants.kError.tr;
      case EmptyStateType.blocked:
        return Constants.kBlocked.tr;
      case EmptyStateType.archived:
        return Constants.kArchived.tr;
    }
  }

  String _getMessage() {
    switch (type) {
      case EmptyStateType.newConversation:
        return 'Say hello and start chatting! Your messages are encrypted and secure.';
      case EmptyStateType.noMessages:
        return 'No messages yet. Start the conversation!';
      case EmptyStateType.noSearchResults:
        return 'No messages found matching your search. Try different keywords.';
      case EmptyStateType.error:
        return 'Something went wrong. Please try again.';
      case EmptyStateType.blocked:
        return 'You cannot send messages to this user.';
      case EmptyStateType.archived:
        return 'This conversation has been archived.';
    }
  }

  String _getActionLabel() {
    switch (type) {
      case EmptyStateType.newConversation:
        return 'Send First Message';
      case EmptyStateType.noMessages:
        return 'Send Message';
      case EmptyStateType.noSearchResults:
        return 'Clear Search';
      case EmptyStateType.error:
        return 'Try Again';
      case EmptyStateType.blocked:
        return 'Unblock User';
      case EmptyStateType.archived:
        return 'Unarchive';
    }
  }

  IconData _getActionIcon() {
    switch (type) {
      case EmptyStateType.newConversation:
        return Icons.send_rounded;
      case EmptyStateType.noMessages:
        return Icons.send_rounded;
      case EmptyStateType.noSearchResults:
        return Icons.clear_rounded;
      case EmptyStateType.error:
        return Icons.refresh_rounded;
      case EmptyStateType.blocked:
        return Icons.lock_open_rounded;
      case EmptyStateType.archived:
        return Icons.unarchive_rounded;
    }
  }
}

/// Empty state types
enum EmptyStateType {
  newConversation,
  noMessages,
  noSearchResults,
  error,
  blocked,
  archived,
}

/// Animated wave greeting for new conversations
class WaveGreeting extends StatefulWidget {
  final String userName;

  const WaveGreeting({
    super.key,
    required this.userName,
  });

  @override
  State<WaveGreeting> createState() => _WaveGreetingState();
}

class _WaveGreetingState extends State<WaveGreeting>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0, end: 0.2),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.2, end: -0.2),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.2, end: 0.2),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.2, end: 0),
        weight: 25,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _waveAnimation.value,
              child: const Text(
                '👋',
                style: TextStyle(fontSize: 64),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Say hi to ${widget.userName}!',
          style: StylesManager.medium(
            fontSize: FontSize.large,
            color: ColorsManager.black,
          ),
        ),
      ],
    );
  }
}

/// Quick message suggestions for new conversations
class QuickMessageSuggestions extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const QuickMessageSuggestions({
    super.key,
    required this.onSuggestionTap,
  });

  static const List<String> suggestions = [
    'Hey! 👋',
    'How are you?',
    'What\'s up?',
    'Hello! 😊',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: suggestions.map((suggestion) {
        return GestureDetector(
          onTap: () => onSuggestionTap(suggestion),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ColorsManager.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              suggestion,
              style: StylesManager.medium(
                fontSize: FontSize.small,
                color: ColorsManager.primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
