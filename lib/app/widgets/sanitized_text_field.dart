// UI Migration: Sanitized Text Field Widget
// Integrates input sanitization with text fields

import 'package:crypted_app/app/core/security/input_sanitizer.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A TextField that automatically sanitizes input
class SanitizedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final InputDecoration? decoration;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ContentValidationConfig? validationConfig;
  final bool showValidationErrors;
  final bool sanitizeOnChange;

  const SanitizedTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.decoration,
    this.focusNode,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validationConfig,
    this.showValidationErrors = true,
    this.sanitizeOnChange = false,
  });

  @override
  State<SanitizedTextField> createState() => _SanitizedTextFieldState();
}

class _SanitizedTextFieldState extends State<SanitizedTextField> {
  late TextEditingController _controller;
  final InputSanitizer _sanitizer = InputSanitizer();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleChange(String value) {
    if (widget.sanitizeOnChange) {
      final result = _sanitizer.sanitize(
        value,
        config: widget.validationConfig ?? const ContentValidationConfig(),
      );

      if (!result.isValid && widget.showValidationErrors) {
        setState(() {
          _errorText = result.error;
        });
      } else {
        setState(() {
          _errorText = null;
        });
      }
    }

    widget.onChanged?.call(value);
  }

  void _handleSubmitted(String value) {
    // Sanitize on submit
    final result = _sanitizer.sanitize(
      value,
      config: widget.validationConfig ?? const ContentValidationConfig(),
    );

    if (result.isValid) {
      widget.onSubmitted?.call(result.sanitized);
    } else if (widget.showValidationErrors) {
      setState(() {
        _errorText = result.error;
      });
    }
  }

  String? _validate(String? value) {
    if (value == null || value.isEmpty) {
      return widget.validator?.call(value);
    }

    final result = _sanitizer.sanitize(
      value,
      config: widget.validationConfig ?? const ContentValidationConfig(),
    );

    if (!result.isValid) {
      return result.error ?? 'Invalid input';
    }

    return widget.validator?.call(result.sanitized);
  }

  @override
  Widget build(BuildContext context) {
    final defaultDecoration = InputDecoration(
      labelText: widget.labelText,
      hintText: widget.hintText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      errorText: _errorText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorsManager.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorsManager.error),
      ),
    );

    return TextFormField(
      controller: _controller,
      decoration: widget.decoration ?? defaultDecoration,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: _handleChange,
      onFieldSubmitted: _handleSubmitted,
      onEditingComplete: widget.onEditingComplete,
      validator: widget.validator != null || widget.showValidationErrors ? _validate : null,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
    );
  }
}

/// A message input field with built-in sanitization
class SanitizedMessageInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLength;
  final FocusNode? focusNode;

  const SanitizedMessageInput({
    super.key,
    required this.controller,
    this.onSend,
    this.onChanged,
    this.hintText = 'Type a message...',
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength = 5000,
    this.focusNode,
  });

  @override
  State<SanitizedMessageInput> createState() => _SanitizedMessageInputState();
}

class _SanitizedMessageInputState extends State<SanitizedMessageInput> {
  final InputSanitizer _sanitizer = InputSanitizer();
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _hasContent = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_updateHasContent);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateHasContent);
    super.dispose();
  }

  void _updateHasContent() {
    final hasContent = widget.controller.text.trim().isNotEmpty;
    if (hasContent != _hasContent) {
      setState(() {
        _hasContent = hasContent;
      });
    }
  }

  void _handleSend() {
    final text = widget.controller.text;
    if (text.trim().isEmpty) return;

    // Sanitize message before sending
    final result = _sanitizer.validateMessage(text);

    if (result.isValid) {
      widget.onSend?.call();
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Invalid message'),
          backgroundColor: ColorsManager.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.prefixIcon != null) widget.prefixIcon!,
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: widget.enabled,
              maxLength: widget.maxLength,
              maxLines: 5,
              minLines: 1,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                counterText: '',
              ),
              onChanged: widget.onChanged,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          widget.suffixIcon ??
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  onPressed: _hasContent && widget.enabled ? _handleSend : null,
                  icon: Icon(
                    Icons.send_rounded,
                    color: _hasContent && widget.enabled
                        ? ColorsManager.primary
                        : Colors.grey,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Input formatter that prevents potentially dangerous content
class SafeInputFormatter extends TextInputFormatter {
  final InputSanitizer _sanitizer = InputSanitizer();
  final ContentValidationConfig config;

  SafeInputFormatter({
    this.config = const ContentValidationConfig(),
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow deletion
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    // Check the new content
    final newContent = newValue.text.substring(oldValue.text.length);
    final result = _sanitizer.sanitize(newContent, config: config);

    if (result.wasModified) {
      // If content was sanitized, update with sanitized version
      final sanitizedText = oldValue.text + result.sanitized;
      return TextEditingValue(
        text: sanitizedText,
        selection: TextSelection.collapsed(offset: sanitizedText.length),
      );
    }

    return newValue;
  }
}
