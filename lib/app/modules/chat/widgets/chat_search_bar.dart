import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

/// Search bar for searching messages in a chat
class ChatSearchBar extends StatefulWidget {
  final Function(String query) onSearch;
  final VoidCallback onClose;

  const ChatSearchBar({
    Key? key,
    required this.onSearch,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ChatSearchBar> createState() => _ChatSearchBarState();
}

class _ChatSearchBarState extends State<ChatSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus when search bar appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    // Debounced search
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Simple debounce: wait for user to stop typing
    widget.onSearch(_controller.text);
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Paddings.medium,
        vertical: Paddings.small,
      ),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.arrow_back),
            color: ColorsManager.grey,
          ),

          // Search input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: StylesManager.medium(
                fontSize: FontSize.medium,
                color: Get.isDarkMode ? Colors.white : ColorsManager.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search messages...',
                hintStyle: StylesManager.regular(
                  fontSize: FontSize.medium,
                  color: ColorsManager.grey,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Paddings.small,
                ),
              ),
            ),
          ),

          // Clear button
          if (_controller.text.isNotEmpty)
            IconButton(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear),
              color: ColorsManager.grey,
            ),
        ],
      ),
    );
  }
}
