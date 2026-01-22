import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable iOS-style confirmation bottom sheet
///
/// Features:
/// - Handle bar for drag dismiss
/// - Icon with tinted background
/// - Title and description
/// - Primary action button (can be destructive)
/// - Cancel button
/// - Smooth animations
class ConfirmationBottomSheet extends StatelessWidget {
  const ConfirmationBottomSheet({
    super.key,
    required this.title,
    required this.description,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.icon,
    this.iconColor,
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final String cancelLabel;
  final IconData? icon;
  final Color? iconColor;
  final bool isDestructive;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// Show the confirmation bottom sheet and return true if confirmed
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String description,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    IconData? icon,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    HapticFeedback.mediumImpact();

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ConfirmationBottomSheet(
        title: title,
        description: description,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        iconColor: iconColor,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ??
        (isDestructive ? Colors.red : ColorsManager.primary);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          if (icon != null) ...[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: FontSize.large,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: FontSize.small,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onConfirm?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive ? Colors.red : ColorsManager.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                confirmLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onCancel?.call();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                cancelLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS-style text input bottom sheet for inline editing
///
/// Features:
/// - Handle bar
/// - Title
/// - Text field with clear button
/// - Character counter (optional)
/// - Save/Cancel buttons
class EditFieldBottomSheet extends StatefulWidget {
  const EditFieldBottomSheet({
    super.key,
    required this.title,
    required this.initialValue,
    required this.onSave,
    this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
  });

  final String title;
  final String initialValue;
  final void Function(String value) onSave;
  final String? hint;
  final int? maxLength;
  final int maxLines;
  final String? Function(String value)? validator;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String initialValue,
    String? hint,
    int? maxLength,
    int maxLines = 1,
    String? Function(String value)? validator,
  }) {
    HapticFeedback.mediumImpact();

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EditFieldBottomSheet(
          title: title,
          initialValue: initialValue,
          hint: hint,
          maxLength: maxLength,
          maxLines: maxLines,
          validator: validator,
          onSave: (value) => Navigator.of(context).pop(value),
        ),
      ),
    );
  }

  @override
  State<EditFieldBottomSheet> createState() => _EditFieldBottomSheetState();
}

class _EditFieldBottomSheetState extends State<EditFieldBottomSheet> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final value = _controller.text.trim();
    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (error != null) {
        setState(() => _error = error);
        return;
      }
    }
    if (value.isEmpty) {
      setState(() => _error = 'Cannot be empty');
      return;
    }
    HapticFeedback.lightImpact();
    widget.onSave(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            widget.title,
            style: TextStyle(
              fontSize: FontSize.large,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Text field
          TextField(
            controller: _controller,
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: _error,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorsManager.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => _controller.clear(),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _handleSave(),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
