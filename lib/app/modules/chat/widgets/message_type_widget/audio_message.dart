import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:just_audio/just_audio.dart';

class AudioMessageWidget extends StatefulWidget {
  final AudioMessage message;

  const AudioMessageWidget({
    super.key,
    required this.message,
  });

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  late AudioPlayer _audioPlayer;
  bool isLoading = false;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    print("Audio Url:${widget.message.audioUrl}");
    // Listen to duration and position changes
    _audioPlayer.durationStream.listen((d) {
      if (d != null && mounted) {
        setState(() {
          duration = d;
        });
      }
    });
    _audioPlayer.positionStream.listen((p) {
      if (mounted) {
        setState(() {
          position = p;
        });
      }
    });
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.pause();
          }
        });
      }
    });

    _loadAudio();
  }

  Future<void> _loadAudio() async {
    setState(() {
      isLoading = true;
    });
    try {
      await _audioPlayer.setUrl(widget.message.audioUrl);
      // If duration is not available from the file, fallback to message.duration
      if (_audioPlayer.duration == null && widget.message.duration != null) {
        duration = _parseDuration(widget.message.duration!);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load audio");
    }
    setState(() {
      isLoading = false;
    });
  }

  Duration _parseDuration(String durationStr) {
    // Accepts "mm:ss" or "m:ss"
    final parts = durationStr.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return Duration(minutes: minutes, seconds: seconds);
    }
    return Duration.zero;
  }

  void _togglePlayPause() async {
    if (isLoading) return;
    if (_audioPlayer.processingState == ProcessingState.idle) {
      await _loadAudio();
    }
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      try {
        await _audioPlayer.play();
      } catch (e) {
        Get.snackbar("Error", "Cannot play audio message");
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    // _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayDuration = duration.inMilliseconds > 0
        ? duration
        : (widget.message.duration != null
            ? _parseDuration(widget.message.duration!)
            : Duration.zero);

    return Container(
      width: Sizes.size200,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Sizes.size12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: ColorsManager.white,
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.grey,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: ColorsManager.darkGrey,
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: Sizes.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: ColorsManager.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                  child: LinearProgressIndicator(
                    value: displayDuration.inMilliseconds > 0
                        ? (position.inMilliseconds /
                                displayDuration.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      ColorsManager.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(isPlaying ? position : displayDuration),
                  style: StylesManager.regular(
                    fontSize: FontSize.xSmall,
                    color: ColorsManager.grey,
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
