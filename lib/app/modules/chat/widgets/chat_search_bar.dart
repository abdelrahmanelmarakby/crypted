import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

/// Enhanced search bar for searching messages in a chat
/// Features:
/// - Debounced search input
/// - Navigation controls (up/down arrows)
/// - Result counter showing current/total
/// - Smooth animations
class ChatSearchBar extends StatefulWidget {
  final Function(String query) onSearch;
  final VoidCallback onClose;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final int resultCount;
  final int currentIndex;

  const ChatSearchBar({
    super.key,
    required this.onSearch,
    required this.onClose,
    this.onNext,
    this.onPrevious,
    this.resultCount = 0,
    this.currentIndex = 0,
  });

  @override
  State<ChatSearchBar> createState() => _ChatSearchBarState();
}

class _ChatSearchBarState extends State<ChatSearchBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Auto-focus when search bar appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    // Listen for text changes
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});

    // Debounce search - wait for user to stop typing
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(_controller.text);
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
  }

  void _close() {
    _animationController.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Paddings.small,
          vertical: Paddings.small,
        ),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              // Back button
              IconButton(
                onPressed: _close,
                icon: const Icon(Icons.arrow_back),
                color: ColorsManager.grey,
                tooltip: 'Close search',
              ),

              // Search input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Get.isDarkMode
                        ? Colors.grey[800]
                        : ColorsManager.offWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: Paddings.normal),
                        child: Icon(
                          Iconsax.search_normal,
                          size: 18,
                          color: ColorsManager.grey,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: StylesManager.medium(
                            fontSize: FontSize.medium,
                            color: Get.isDarkMode
                                ? Colors.white
                                : ColorsManager.black,
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
                              vertical: Paddings.normal,
                            ),
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) {
                            // Navigate to first result on submit
                            if (widget.resultCount > 0) {
                              widget.onNext?.call();
                            }
                          },
                        ),
                      ),
                      // Clear button
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear, size: 18),
                          color: ColorsManager.grey,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Result counter and navigation
              if (_controller.text.isNotEmpty) ...[
                SizedBox(width: Paddings.small),

                // Result counter
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    key: ValueKey('${widget.resultCount}_${widget.currentIndex}'),
                    padding: EdgeInsets.symmetric(
                      horizontal: Paddings.small,
                      vertical: Paddings.xSmall,
                    ),
                    decoration: BoxDecoration(
                      color: widget.resultCount > 0
                          ? ColorsManager.primary.withValues(alpha: 0.1)
                          : ColorsManager.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.resultCount > 0
                          ? '${widget.currentIndex + 1}/${widget.resultCount}'
                          : '0/0',
                      style: StylesManager.medium(
                        fontSize: FontSize.small,
                        color: widget.resultCount > 0
                            ? ColorsManager.primary
                            : ColorsManager.grey,
                      ),
                    ),
                  ),
                ),

                // Navigation arrows
                IconButton(
                  onPressed:
                      widget.resultCount > 0 ? widget.onPrevious : null,
                  icon: const Icon(Iconsax.arrow_up_2, size: 20),
                  color: widget.resultCount > 0
                      ? ColorsManager.primary
                      : ColorsManager.grey.withValues(alpha: 0.4),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  tooltip: 'Previous result',
                ),
                IconButton(
                  onPressed: widget.resultCount > 0 ? widget.onNext : null,
                  icon: const Icon(Iconsax.arrow_down_1, size: 20),
                  color: widget.resultCount > 0
                      ? ColorsManager.primary
                      : ColorsManager.grey.withValues(alpha: 0.4),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  tooltip: 'Next result',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
