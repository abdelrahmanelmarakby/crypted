import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';

/// A bottom sheet that lets the user pick a mood emoji + optional text.
/// The mood is saved to the user's Firestore document.
class MoodPickerSheet extends StatefulWidget {
  const MoodPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MoodPickerSheet(),
    );
  }

  @override
  State<MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends State<MoodPickerSheet> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedMood;
  bool _isSaving = false;

  // Preset moods grouped by category
  static const List<_MoodCategory> _categories = [
    _MoodCategory('Happy', ['😊', '😄', '🥳', '😁', '🤗', '😎', '🥰', '✨']),
    _MoodCategory('Calm', ['😌', '🧘', '☕', '🌿', '🎧', '📖', '🌙', '💤']),
    _MoodCategory('Working', ['💻', '📝', '🎯', '🔥', '💪', '🧠', '⚡', '🚀']),
    _MoodCategory('Social', ['🎉', '🍕', '🎮', '🎬', '🎵', '⚽', '🏖️', '✈️']),
    _MoodCategory('Feeling', ['🤔', '😢', '😤', '😴', '🤒', '😰', '💔', '🙄']),
  ];

  @override
  void initState() {
    super.initState();
    final user = UserService.currentUser.value;
    _selectedMood = user?.mood;
    _textController.text = user?.moodText ?? '';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveMood() async {
    setState(() => _isSaving = true);

    final uid = UserService.currentUser.value?.uid;
    if (uid == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'mood': _selectedMood,
        'moodText': _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
      });

      // Update local user state
      final updated = UserService.currentUser.value?.copyWith(
        mood: _selectedMood,
        moodText: _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
      );
      if (updated != null) {
        UserService.currentUser.value = updated;
      }

      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
      Get.snackbar(
        'Mood Updated',
        _selectedMood != null
            ? 'Your mood is now $_selectedMood'
            : 'Mood cleared',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.primary.withAlpha(230),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update mood');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clearMood() async {
    setState(() {
      _selectedMood = null;
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.scaffoldBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.emoji_happy,
                      color: ColorsManager.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Your Mood',
                        style: TextStyle(
                          fontSize: FontSize.xLarge,
                          fontWeight: FontWeight.bold,
                          color: ColorsManager.textPrimaryAdaptive(context),
                        ),
                      ),
                      Text(
                        'Show friends how you\'re feeling',
                        style: TextStyle(
                          fontSize: FontSize.small,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Clear button
                if (_selectedMood != null)
                  TextButton(
                    onPressed: _clearMood,
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: Colors.red.withAlpha(180),
                        fontSize: FontSize.small,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Current mood preview
            if (_selectedMood != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: ColorsManager.primary.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Text(_selectedMood!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _textController.text.isEmpty
                            ? 'Add a status text...'
                            : _textController.text,
                        style: TextStyle(
                          fontSize: FontSize.medium,
                          color: _textController.text.isEmpty
                              ? Colors.grey
                              : ColorsManager.textPrimaryAdaptive(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Mood emoji grid by category
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.vertical,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, catIdx) {
                  final category = _categories[catIdx];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: StylesManager.medium(
                          fontSize: FontSize.xSmall,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: category.emojis.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 4),
                          itemBuilder: (context, emojiIdx) {
                            final emoji = category.emojis[emojiIdx];
                            final isSelected = _selectedMood == emoji;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedMood = emoji);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? ColorsManager.primary.withAlpha(30)
                                      : Colors.grey.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color: ColorsManager.primary,
                                          width: 2)
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(emoji,
                                    style: const TextStyle(fontSize: 22)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Status text input
            TextField(
              controller: _textController,
              maxLength: 60,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                hintStyle: TextStyle(color: Colors.grey.withAlpha(150)),
                filled: true,
                fillColor: Colors.grey.withAlpha(20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterStyle: TextStyle(fontSize: 11, color: Colors.grey),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: !_isSaving ? _saveMood : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Iconsax.tick_circle, size: 20),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Mood',
                  style: const TextStyle(
                      fontSize: FontSize.large, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withAlpha(60),
                  disabledForegroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodCategory {
  final String name;
  final List<String> emojis;

  const _MoodCategory(this.name, this.emojis);
}
