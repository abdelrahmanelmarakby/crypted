import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

/// Bottom sheet for editing text messages
class EditMessageSheet extends StatefulWidget {
  final TextMessage message;
  final Function(String newText) onSave;

  const EditMessageSheet({
    Key? key,
    required this.message,
    required this.onSave,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required TextMessage message,
    required Function(String newText) onSave,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditMessageSheet(
        message: message,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditMessageSheet> createState() => _EditMessageSheetState();
}

class _EditMessageSheetState extends State<EditMessageSheet> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  int _characterCount = 0;
  static const int _maxCharacters = 4000;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.text);
    _characterCount = widget.message.text.length;
    _controller.addListener(_updateCharacterCount);

    // Auto-focus the text field when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Move cursor to end of text
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateCharacterCount);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _controller.text.length;
    });
  }

  void _handleSave() {
    final newText = _controller.text.trim();

    // Validation
    if (newText.isEmpty) {
      Get.snackbar(
        'Error',
        'Message cannot be empty',
        backgroundColor: ColorsManager.error2.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (newText == widget.message.text) {
      Get.back();
      return;
    }

    if (newText.length > _maxCharacters) {
      Get.snackbar(
        'Error',
        'Message exceeds maximum length of $_maxCharacters characters',
        backgroundColor: ColorsManager.error2.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    widget.onSave(newText);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Get.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(
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
            Padding(
              padding: EdgeInsets.all(Paddings.large),
              child: Row(
                children: [
                  Text(
                    'Edit Message',
                    style: StylesManager.semiBold(
                      fontSize: FontSize.large,
                      color: Get.isDarkMode ? Colors.white : ColorsManager.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                    color: ColorsManager.grey,
                  ),
                ],
              ),
            ),

            // Text editor
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Paddings.large),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 100,
                  maxHeight: 300,
                ),
                decoration: BoxDecoration(
                  color: Get.isDarkMode
                      ? Colors.grey[800]
                      : ColorsManager.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorsManager.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  maxLength: _maxCharacters,
                  style: StylesManager.medium(
                    fontSize: FontSize.medium,
                    color: Get.isDarkMode ? Colors.white : ColorsManager.black,
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(Paddings.normal),
                    border: InputBorder.none,
                    hintText: 'Edit your message...',
                    hintStyle: StylesManager.regular(
                      fontSize: FontSize.medium,
                      color: ColorsManager.grey,
                    ),
                    counterText: '', // Hide default counter
                  ),
                ),
              ),
            ),

            // Character counter
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Paddings.large,
                vertical: Paddings.small,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Characters: $_characterCount / $_maxCharacters',
                    style: StylesManager.regular(
                      fontSize: FontSize.small,
                      color: _characterCount > _maxCharacters
                          ? ColorsManager.error2
                          : ColorsManager.grey,
                    ),
                  ),
                  if (widget.message.isEdited)
                    Text(
                      'Previously edited',
                      style: StylesManager.regular(
                        fontSize: FontSize.small,
                        color: ColorsManager.grey,
                      ),
                    ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: EdgeInsets.all(Paddings.large),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: Paddings.normal),
                        side: BorderSide(color: ColorsManager.grey.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: StylesManager.semiBold(
                          fontSize: FontSize.medium,
                          color: ColorsManager.grey,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Paddings.normal),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.primary,
                        padding: EdgeInsets.symmetric(vertical: Paddings.normal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: StylesManager.semiBold(
                          fontSize: FontSize.medium,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
