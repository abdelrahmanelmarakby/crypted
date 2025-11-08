import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:intl/intl.dart';

/// Widget to display search results for messages
class SearchResultsWidget extends StatelessWidget {
  final List<Message> results;
  final String searchQuery;
  final Function(Message message) onMessageTap;

  const SearchResultsWidget({
    Key? key,
    required this.results,
    required this.searchQuery,
    required this.onMessageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: ColorsManager.grey.withOpacity(0.5),
            ),
            SizedBox(height: Paddings.medium),
            Text(
              'No messages found',
              style: StylesManager.medium(
                fontSize: FontSize.medium,
                color: ColorsManager.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: ColorsManager.grey.withOpacity(0.5),
            ),
            SizedBox(height: Paddings.medium),
            Text(
              'Search for messages',
              style: StylesManager.medium(
                fontSize: FontSize.medium,
                color: ColorsManager.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(Paddings.medium),
      itemCount: results.length,
      separatorBuilder: (context, index) => Divider(
        height: Paddings.medium,
        color: ColorsManager.grey.withOpacity(0.2),
      ),
      itemBuilder: (context, index) {
        final message = results[index];
        return _SearchResultTile(
          message: message,
          searchQuery: searchQuery,
          onTap: () => onMessageTap(message),
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Message message;
  final String searchQuery;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.message,
    required this.searchQuery,
    required this.onTap,
  });

  String _getMessagePreview() {
    if (message is TextMessage) {
      return (message as TextMessage).text;
    }
    // Handle other message types
    return '[${message.runtimeType.toString().replaceAll('Message', '')}]';
  }

  TextSpan _highlightText(String text, String query) {
    if (query.isEmpty) {
      return TextSpan(
        text: text,
        style: StylesManager.regular(
          fontSize: FontSize.small,
          color: Get.isDarkMode ? Colors.white : ColorsManager.black,
        ),
      );
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    while (start < text.length) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: StylesManager.regular(
            fontSize: FontSize.small,
            color: Get.isDarkMode ? Colors.white : ColorsManager.black,
          ),
        ));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: StylesManager.regular(
            fontSize: FontSize.small,
            color: Get.isDarkMode ? Colors.white : ColorsManager.black,
          ),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: StylesManager.semiBold(
          fontSize: FontSize.small,
          color: ColorsManager.primary,
        ),
      ));

      start = index + query.length;
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _getMessagePreview();
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(Paddings.medium),
        decoration: BoxDecoration(
          color: Get.isDarkMode
              ? Colors.grey[800]?.withOpacity(0.3)
              : ColorsManager.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Text(
              dateFormat.format(message.timestamp),
              style: StylesManager.regular(
                fontSize: FontSize.xSmall,
                color: ColorsManager.grey,
              ),
            ),
            SizedBox(height: Paddings.small),

            // Message preview with highlighted search query
            RichText(
              text: _highlightText(preview, searchQuery),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
