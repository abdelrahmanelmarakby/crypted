import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/notification_settings_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Sound Picker Widget for notification settings
/// Allows selecting and previewing notification sounds
class NotificationSoundPicker extends StatefulWidget {
  final NotificationSound currentSound;
  final String title;
  final Color? accentColor;
  final Function(NotificationSound) onSoundSelected;

  const NotificationSoundPicker({
    super.key,
    required this.currentSound,
    required this.title,
    this.accentColor,
    required this.onSoundSelected,
  });

  static Future<NotificationSound?> show({
    required BuildContext context,
    required NotificationSound currentSound,
    required String title,
    Color? accentColor,
  }) async {
    return await showModalBottomSheet<NotificationSound>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SoundPickerSheet(
        currentSound: currentSound,
        title: title,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<NotificationSoundPicker> createState() => _NotificationSoundPickerState();
}

class _NotificationSoundPickerState extends State<NotificationSoundPicker> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (widget.accentColor ?? ColorsManager.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.volume_up_rounded,
          color: widget.accentColor ?? ColorsManager.primary,
        ),
      ),
      title: Text(widget.title),
      subtitle: Text(widget.currentSound.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final result = await NotificationSoundPicker.show(
          context: context,
          currentSound: widget.currentSound,
          title: widget.title,
          accentColor: widget.accentColor,
        );
        if (result != null) {
          widget.onSoundSelected(result);
        }
      },
    );
  }
}

class _SoundPickerSheet extends StatefulWidget {
  final NotificationSound currentSound;
  final String title;
  final Color? accentColor;

  const _SoundPickerSheet({
    required this.currentSound,
    required this.title,
    this.accentColor,
  });

  @override
  State<_SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<_SoundPickerSheet> {
  late NotificationSound _selectedSound;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  NotificationSound? _playingSound;

  @override
  void initState() {
    super.initState();
    _selectedSound = widget.currentSound;
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playingSound = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(NotificationSound sound) async {
    try {
      // Stop current sound if playing
      await _audioPlayer.stop();

      if (_playingSound == sound && _isPlaying) {
        setState(() {
          _isPlaying = false;
          _playingSound = null;
        });
        return;
      }

      setState(() {
        _isPlaying = true;
        _playingSound = sound;
      });

      // Map sound to asset path
      final assetPath = _getSoundAssetPath(sound);
      if (assetPath != null) {
        await _audioPlayer.play(AssetSource(assetPath));
      } else {
        // Use system notification sound as fallback
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
      // Fallback to haptic feedback
      HapticFeedback.mediumImpact();
      setState(() {
        _isPlaying = false;
        _playingSound = null;
      });
    }
  }

  String? _getSoundAssetPath(NotificationSound sound) {
    // Map sounds to asset files
    switch (sound) {
      case NotificationSound.defaultSound:
      case NotificationSound.default_:
        return 'sounds/notification_default.mp3';
      case NotificationSound.chime:
        return 'sounds/notification_chime.mp3';
      case NotificationSound.ding:
        return 'sounds/notification_ding.mp3';
      case NotificationSound.pop:
        return 'sounds/notification_pop.mp3';
      case NotificationSound.bubble:
        return 'sounds/notification_bubble.mp3';
      case NotificationSound.swoosh:
        return 'sounds/notification_swoosh.mp3';
      case NotificationSound.bell:
        return 'sounds/notification_bell.mp3';
      case NotificationSound.gentle:
        return 'sounds/notification_gentle.mp3';
      case NotificationSound.none:
        return null;
      default:
        return 'sounds/notification_default.mp3';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? ColorsManager.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.volume_up_rounded, color: accentColor),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Sound list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: NotificationSound.values.length,
              itemBuilder: (context, index) {
                final sound = NotificationSound.values[index];
                final isSelected = sound == _selectedSound;
                final isCurrentlyPlaying = _playingSound == sound && _isPlaying;

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      sound == NotificationSound.none
                          ? Icons.notifications_off_rounded
                          : Icons.music_note_rounded,
                      color: isSelected ? accentColor : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    sound.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? accentColor : null,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sound != NotificationSound.none)
                        IconButton(
                          icon: Icon(
                            isCurrentlyPlaying
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            color: accentColor,
                          ),
                          onPressed: () => _playSound(sound),
                        ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: accentColor),
                    ],
                  ),
                  onTap: () {
                    setState(() => _selectedSound = sound);
                  },
                );
              },
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedSound),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Select'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vibration Pattern Picker Widget
class VibrationPatternPicker extends StatelessWidget {
  final VibrationPattern currentPattern;
  final String title;
  final Color? accentColor;
  final Function(VibrationPattern) onPatternSelected;

  const VibrationPatternPicker({
    super.key,
    required this.currentPattern,
    required this.title,
    this.accentColor,
    required this.onPatternSelected,
  });

  static Future<VibrationPattern?> show({
    required BuildContext context,
    required VibrationPattern currentPattern,
    required String title,
    Color? accentColor,
  }) async {
    return await showModalBottomSheet<VibrationPattern>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _VibrationPickerSheet(
        currentPattern: currentPattern,
        title: title,
        accentColor: accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (accentColor ?? ColorsManager.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.vibration_rounded,
          color: accentColor ?? ColorsManager.primary,
        ),
      ),
      title: Text(title),
      subtitle: Text(currentPattern.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final result = await VibrationPatternPicker.show(
          context: context,
          currentPattern: currentPattern,
          title: title,
          accentColor: accentColor,
        );
        if (result != null) {
          onPatternSelected(result);
        }
      },
    );
  }
}

class _VibrationPickerSheet extends StatefulWidget {
  final VibrationPattern currentPattern;
  final String title;
  final Color? accentColor;

  const _VibrationPickerSheet({
    required this.currentPattern,
    required this.title,
    this.accentColor,
  });

  @override
  State<_VibrationPickerSheet> createState() => _VibrationPickerSheetState();
}

class _VibrationPickerSheetState extends State<_VibrationPickerSheet> {
  late VibrationPattern _selectedPattern;

  @override
  void initState() {
    super.initState();
    _selectedPattern = widget.currentPattern;
  }

  void _previewVibration(VibrationPattern pattern) {
    switch (pattern) {
      case VibrationPattern.defaultPattern:
        HapticFeedback.mediumImpact();
        break;
      case VibrationPattern.short:
        HapticFeedback.lightImpact();
        break;
      case VibrationPattern.long:
      case VibrationPattern.long_:
        HapticFeedback.heavyImpact();
        break;
      case VibrationPattern.doubleShort:
      case VibrationPattern.double_:
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.lightImpact();
        });
        break;
      case VibrationPattern.heartbeat:
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 150), () {
          HapticFeedback.lightImpact();
        });
        break;
      case VibrationPattern.none:
        // No vibration
        break;
      default:
        HapticFeedback.mediumImpact();
        break;
    }
  }

  IconData _getPatternIcon(VibrationPattern pattern) {
    switch (pattern) {
      case VibrationPattern.none:
        return Icons.notifications_off_rounded;
      case VibrationPattern.short:
        return Icons.short_text_rounded;
      case VibrationPattern.long:
        return Icons.horizontal_rule_rounded;
      case VibrationPattern.doubleShort:
        return Icons.more_horiz_rounded;
      case VibrationPattern.heartbeat:
        return Icons.favorite_rounded;
      default:
        return Icons.vibration_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? ColorsManager.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.vibration_rounded, color: accentColor),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Pattern list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: VibrationPattern.values.length,
              itemBuilder: (context, index) {
                final pattern = VibrationPattern.values[index];
                final isSelected = pattern == _selectedPattern;

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getPatternIcon(pattern),
                      color: isSelected ? accentColor : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    pattern.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? accentColor : null,
                    ),
                  ),
                  subtitle: Text(_getPatternDescription(pattern)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pattern != VibrationPattern.none)
                        IconButton(
                          icon: Icon(
                            Icons.play_arrow_rounded,
                            color: accentColor,
                          ),
                          onPressed: () => _previewVibration(pattern),
                        ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: accentColor),
                    ],
                  ),
                  onTap: () {
                    setState(() => _selectedPattern = pattern);
                    _previewVibration(pattern);
                  },
                );
              },
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedPattern),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Select'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPatternDescription(VibrationPattern pattern) {
    switch (pattern) {
      case VibrationPattern.none:
        return 'No vibration';
      case VibrationPattern.defaultPattern:
        return 'Standard vibration pattern';
      case VibrationPattern.short:
        return 'Quick, subtle vibration';
      case VibrationPattern.long:
      case VibrationPattern.long_:
        return 'Longer, stronger vibration';
      case VibrationPattern.doubleShort:
      case VibrationPattern.double_:
        return 'Two quick vibrations';
      case VibrationPattern.heartbeat:
        return 'Like a heartbeat pulse';
      default:
        return 'Custom vibration pattern';
    }
  }
}
