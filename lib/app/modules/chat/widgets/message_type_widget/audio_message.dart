import 'dart:io';
import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'dart:math' as math;

/// Helper to detect audio MIME type from URL or provide a default
String _getAudioMimeType(String url) {
  final lowerUrl = url.toLowerCase();
  if (lowerUrl.contains('.m4a') || lowerUrl.contains('.mp4')) {
    return 'audio/mp4';
  } else if (lowerUrl.contains('.aac')) {
    return 'audio/aac';
  } else if (lowerUrl.contains('.mp3')) {
    return 'audio/mpeg';
  } else if (lowerUrl.contains('.wav')) {
    return 'audio/wav';
  } else if (lowerUrl.contains('.ogg')) {
    return 'audio/ogg';
  }
  // Default to AAC/M4A for Firebase audio (most common on iOS)
  return 'audio/mp4';
}

class AudioMessageWidget extends StatefulWidget {
  final AudioMessage message;

  const AudioMessageWidget({
    super.key,
    required this.message,
  });

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _waveController;
  bool isLoading = false;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  double playbackSpeed = 1.0;

  /// Check if this is a local file (optimistic/uploading state)
  bool get _isLocalFile {
    final url = widget.message.audioUrl;
    return url.startsWith('/') ||
        url.startsWith('file://') ||
        url.contains('/data/') ||
        url.contains('/cache/');
  }

  /// Check if local file exists
  bool get _localFileExists {
    if (!_isLocalFile) return false;
    final path = widget.message.audioUrl.replaceFirst('file://', '');
    return File(path).existsSync();
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Ensure volume is at max
    _audioPlayer.setVolume(1.0);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

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
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (widget.message.audioUrl.isEmpty) {
        throw Exception('Audio URL is empty');
      }

      // Ensure audio session is configured before loading
      await _configureAudioSession();

      // Log URL details
      final uri = Uri.parse(widget.message.audioUrl);

      // Detect MIME type from URL or use default
      final mimeType = _getAudioMimeType(widget.message.audioUrl);
     
      await _audioPlayer.setUrl(widget.message.audioUrl);


      // If duration is not available from the file, fallback to message.duration
      if (_audioPlayer.duration == null && widget.message.duration != null) {
        duration = _parseDuration(widget.message.duration!);
      }

    } catch (e, stackTrace) {

      if (mounted) {
        Get.snackbar(
          "Audio Error",
          "Failed to load voice message. Please check your connection.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.red,
          colorText: ColorsManager.white,
          duration: Duration(seconds: 2),
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
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

  /// Configure audio session for iOS to enable playback through speakers
  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
      await session.setActive(true);
    } catch (e) {
      Get.snackbar("Error", "Cannot play audio message: ${e.toString()}");
    }
  }

  void _togglePlayPause() async {
    
   

    if (isLoading) {
      return;
    }
    if (_audioPlayer.processingState == ProcessingState.idle) {
      await _loadAudio();
    }
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      try {
        await _audioPlayer.play();
      } catch (e, stackTrace) {
        Get.snackbar("Error", "Cannot play audio message: ${e.toString()}");
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _changePlaybackSpeed() {
    setState(() {
      if (playbackSpeed == 1.0) {
        playbackSpeed = 1.5;
      } else if (playbackSpeed == 1.5) {
        playbackSpeed = 2.0;
      } else {
        playbackSpeed = 1.0;
      }
      _audioPlayer.setSpeed(playbackSpeed);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If uploading, show uploading state
    if (_isLocalFile) {
      return _buildUploadingState();
    }

    final displayDuration = duration.inMilliseconds > 0
        ? duration
        : (widget.message.duration != null
            ? _parseDuration(widget.message.duration!)
            : Duration.zero);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
        minWidth: 240,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsManager.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorsManager.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ColorsManager.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Icon(
                      isPlaying ? Iconsax.pause_copy : Iconsax.play_copy,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Waveform and Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Waveform
                SizedBox(
                  height: 32,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: WaveformPainter(
                          progress: displayDuration.inMilliseconds > 0
                              ? (position.inMilliseconds / displayDuration.inMilliseconds).clamp(0.0, 1.0)
                              : 0.0,
                          isPlaying: isPlaying,
                          animationValue: _waveController.value,
                        ),
                        size: const Size(double.infinity, 32),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),

                // Time and Speed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Duration
                    Text(
                      _formatDuration(isPlaying ? position : displayDuration),
                      style: StylesManager.medium(
                        fontSize: FontSize.xSmall,
                        color: ColorsManager.grey,
                      ),
                    ),

                    // Speed Control
                    GestureDetector(
                      onTap: _changePlaybackSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ColorsManager.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${playbackSpeed}x',
                          style: StylesManager.semiBold(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Audio Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Iconsax.microphone_2_copy,
              color: ColorsManager.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Build uploading state widget
  Widget _buildUploadingState() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
        minWidth: 240,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsManager.primary.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated upload button
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final scale = 1.0 + (_waveController.value * 0.1);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorsManager.primary,
                        ColorsManager.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ColorsManager.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          // Uploading info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated waveform placeholder
                SizedBox(
                  height: 32,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: WaveformPainter(
                          progress: _waveController.value,
                          isPlaying: true,
                          animationValue: _waveController.value,
                          isUploading: true,
                        ),
                        size: const Size(double.infinity, 32),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),

                // Status text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ColorsManager.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Uploading voice...',
                          style: StylesManager.medium(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.primary,
                          ),
                        ),
                      ],
                    ),
                    // Duration if available
                    if (widget.message.duration != null)
                      Text(
                        widget.message.duration!,
                        style: StylesManager.medium(
                          fontSize: FontSize.xSmall,
                          color: ColorsManager.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Mic icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Iconsax.microphone_2_copy,
              color: ColorsManager.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// Waveform Painter
class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final double animationValue;
  final bool isUploading;

  WaveformPainter({
    required this.progress,
    required this.isPlaying,
    required this.animationValue,
    this.isUploading = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 40;
    final barWidth = (size.width / barCount) * 0.6;
    final spacing = (size.width / barCount) * 0.4;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing);

      // Generate pseudo-random heights that look like waveform
      final seed = (i * 123.456) % 1.0;
      var barHeight = (math.sin(seed * math.pi * 2) * 0.5 + 0.5) * size.height * 0.8;

      // Add animation when playing
      if (isPlaying) {
        final wave = math.sin((i / barCount * math.pi * 2) + (animationValue * math.pi * 4));
        barHeight *= (1.0 + wave * 0.3);
      }

      final barProgress = i / barCount;
      final isActive = barProgress <= progress;

      final paint = Paint()
        ..color = isUploading
            ? ColorsManager.primary.withValues(alpha: 0.5 + (animationValue * 0.3))
            : (isActive
                ? ColorsManager.primary
                : ColorsManager.grey.withValues(alpha: 0.3))
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;

      final startY = (size.height - barHeight) / 2;
      final endY = startY + barHeight;

      canvas.drawLine(
        Offset(x + barWidth / 2, startY),
        Offset(x + barWidth / 2, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.isUploading != isUploading;
  }
}
