import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

/// Bar showing pinned messages at the top of chat
class PinnedMessagesBar extends StatefulWidget {
  final List<Message> pinnedMessages;
  final Function(Message message) onMessageTap;
  final VoidCallback onViewAll;

  const PinnedMessagesBar({
    Key? key,
    required this.pinnedMessages,
    required this.onMessageTap,
    required this.onViewAll,
  }) : super(key: key);

  @override
  State<PinnedMessagesBar> createState() => _PinnedMessagesBarState();
}

class _PinnedMessagesBarState extends State<PinnedMessagesBar> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getMessagePreview(Message message) {
    if (message is TextMessage) {
      return message.text.length > 50
          ? '${message.text.substring(0, 50)}...'
          : message.text;
    }
    return '[${message.runtimeType.toString().replaceAll('Message', '')}]';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pinnedMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: ColorsManager.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 60,
            child: widget.pinnedMessages.length == 1
                ? _buildSinglePinnedMessage(widget.pinnedMessages.first)
                : _buildMultiplePinnedMessages(),
          ),
          if (widget.pinnedMessages.length > 1)
            _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildSinglePinnedMessage(Message message) {
    return InkWell(
      onTap: () => widget.onMessageTap(message),
      child: Padding(
        padding: EdgeInsets.all(Paddings.normal),
        child: Row(
          children: [
            Icon(
              Icons.push_pin,
              size: 20,
              color: ColorsManager.primary,
            ),
            SizedBox(width: Paddings.normal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pinned Message',
                    style: StylesManager.semiBold(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.primary,
                    ),
                  ),
                  SizedBox(height: Paddings.xSmall / 2),
                  Text(
                    _getMessagePreview(message),
                    style: StylesManager.regular(
                      fontSize: FontSize.small,
                      color: Get.isDarkMode ? Colors.white : ColorsManager.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onViewAll,
              icon: const Icon(Icons.arrow_forward_ios),
              iconSize: 16,
              color: ColorsManager.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiplePinnedMessages() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemCount: widget.pinnedMessages.length,
      itemBuilder: (context, index) {
        final message = widget.pinnedMessages[index];
        return InkWell(
          onTap: () => widget.onMessageTap(message),
          child: Padding(
            padding: EdgeInsets.all(Paddings.normal),
            child: Row(
              children: [
                Icon(
                  Icons.push_pin,
                  size: 20,
                  color: ColorsManager.primary,
                ),
                SizedBox(width: Paddings.normal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pinned Message ${index + 1}/${widget.pinnedMessages.length}',
                        style: StylesManager.semiBold(
                          fontSize: FontSize.xSmall,
                          color: ColorsManager.primary,
                        ),
                      ),
                      SizedBox(height: Paddings.xSmall / 2),
                      Text(
                        _getMessagePreview(message),
                        style: StylesManager.regular(
                          fontSize: FontSize.small,
                          color: Get.isDarkMode ? Colors.white : ColorsManager.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onViewAll,
                  icon: const Icon(Icons.arrow_forward_ios),
                  iconSize: 16,
                  color: ColorsManager.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: Paddings.small),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.pinnedMessages.length,
          (index) => Container(
            margin: EdgeInsets.symmetric(horizontal: Paddings.xSmall / 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == index
                  ? ColorsManager.primary
                  : ColorsManager.primary.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }
}
