import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypted_app/app/modules/group_info/controllers/group_info_controller.dart';
import 'package:crypted_app/app/widgets/loader.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:just_audio/just_audio.dart';

/// Rich media tile used inside the group info media grid.
class GroupMediaItem extends StatefulWidget {
  const GroupMediaItem({
    super.key,
    required this.mediaType,
    required this.mediaUrl,
    required this.heroTag,
    required this.title,
    this.thumbnailUrl,
    this.subtitle,
    this.timestampLabel,
    this.fileSizeLabel,
    this.durationLabel,
    this.onPreview,
    this.onDownload,
    this.onOpenExternally,
    this.onShare,
  });

  final MediaType mediaType;
  final String mediaUrl;
  final String heroTag;
  final String title;
  final String? thumbnailUrl;
  final String? subtitle;
  final String? timestampLabel;
  final String? fileSizeLabel;
  final String? durationLabel;
  final Future<void> Function()? onPreview;
  final Future<void> Function()? onDownload;
  final Future<void> Function()? onOpenExternally;
  final Future<void> Function()? onShare;

  @override
  State<GroupMediaItem> createState() => _GroupMediaItemState();
}

class _GroupMediaItemState extends State<GroupMediaItem> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  AudioPlayer? _audioPlayer;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  bool _isAudioLoading = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: ColorsManager.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onPreview,
        onLongPress: () => _pulseController.forward(from: 0),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMediaBody(),
              const SizedBox(height: 12),
              _buildMeta(),
              const SizedBox(height: 12),
              _buildActions(),
            ],
          ),
        ),
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .94, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final opacity = 0.08 + (0.12 * (1 - (math.cos(_pulseController.value * math.pi) + 1) / 2));
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ColorsManager.primary.withValues(alpha: opacity)),
            ),
            child: child,
          );
        },
        child: card,
      ),
    );
  }

  Widget _buildMediaBody() {
    switch (widget.mediaType) {
      case MediaType.image:
        return _buildVisualTile(isVideo: false);
      case MediaType.video:
        return _buildVisualTile(isVideo: true);
      case MediaType.file:
        return _buildFileTile(Iconsax.document_1);
      case MediaType.audio:
        return _buildAudioTile();
    }
  }

  Widget _buildVisualTile({required bool isVideo}) {
    final url = widget.thumbnailUrl ?? widget.mediaUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url.isNotEmpty)
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(child: AppLoader()),
                errorWidget: (_, __, ___) => Icon(Iconsax.image, color: ColorsManager.lightGrey.withValues(alpha: .8)),
              )
            else
              Container(color: ColorsManager.light),
            if (isVideo)
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: .85, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) => Transform.scale(scale: value, child: child),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorsManager.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.play, color: Colors.white, size: 26),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTile(IconData icon) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: ColorsManager.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: ColorsManager.primary, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: StylesManager.medium(fontSize: 14)),
              if (widget.fileSizeLabel?.isNotEmpty == true)
                Text(widget.fileSizeLabel!, style: StylesManager.regular(fontSize: 12, color: ColorsManager.grey)),
            ],
          ),
        ),
        IconButton(
          onPressed: widget.onOpenExternally,
          icon: const Icon(Iconsax.export_3, size: 20),
          color: ColorsManager.primary,
        ),
      ],
    );
  }

  Widget _buildAudioTile() {
    final progress = _audioDuration.inMilliseconds == 0
        ? 0.0
        : (_audioPosition.inMilliseconds / _audioDuration.inMilliseconds).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _isAudioLoading || widget.mediaUrl.isEmpty ? null : _toggleAudio,
              icon: _isAudioLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorsManager.primary,
                      ),
                    )
                  : Icon(_audioPlayer?.playing == true ? Iconsax.pause : Iconsax.play, color: ColorsManager.primary),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: StylesManager.medium(fontSize: 14)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      value: progress,
                      color: ColorsManager.primary,
                      backgroundColor: ColorsManager.lightGrey.withValues(alpha: .3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatAudioLabel(),
                    style: StylesManager.regular(fontSize: 11, color: ColorsManager.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeta() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: StylesManager.semiBold(fontSize: 14)),
              if (widget.subtitle?.isNotEmpty == true)
                Text(widget.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: StylesManager.regular(fontSize: 12, color: ColorsManager.grey)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.timestampLabel?.isNotEmpty == true)
              Text(widget.timestampLabel!, style: StylesManager.regular(fontSize: 11, color: ColorsManager.grey)),
            if (widget.durationLabel?.isNotEmpty == true)
              Text(widget.durationLabel!, style: StylesManager.regular(fontSize: 11, color: ColorsManager.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    final buttons = <Widget>[];
    if (widget.onPreview != null && widget.mediaType != MediaType.file) {
      buttons.add(_buildActionButton(Iconsax.maximize_3, widget.onPreview));
    }
    if (widget.onShare != null) {
      buttons.add(_buildActionButton(Iconsax.send_2, widget.onShare));
    }
    if (widget.onDownload != null) {
      buttons.add(_buildActionButton(Iconsax.arrow_down_1, widget.onDownload));
    }
    if (widget.onOpenExternally != null && widget.mediaType == MediaType.file) {
      buttons.add(_buildActionButton(Iconsax.link_1, widget.onOpenExternally));
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(children: buttons);
  }

  Widget _buildActionButton(IconData icon, Future<void> Function()? onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: ColorsManager.light,
          ),
          child: Icon(icon, size: 18, color: ColorsManager.primary),
        ),
      ),
    );
  }

  Future<void> _toggleAudio() async {
    try {
      if (_audioPlayer == null) {
        setState(() => _isAudioLoading = true);
        _audioPlayer = AudioPlayer();
        await _audioPlayer!.setUrl(widget.mediaUrl);
        _audioDuration = _audioPlayer!.duration ?? Duration.zero;
        _audioPlayer!.positionStream.listen((pos) {
          if (!mounted) return;
          setState(() => _audioPosition = pos);
        });
        setState(() => _isAudioLoading = false);
      }

      if (_audioPlayer!.playing) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play();
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _isAudioLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio unavailable')),
        );
      }
    }
  }

  String _formatAudioLabel() {
    if (_audioDuration == Duration.zero) {
      return widget.durationLabel ?? '';
    }

    final position = _audioPosition.inSeconds;
    final total = _audioDuration.inSeconds;
    final remaining = math.max(0, total - position);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final currentLabel = '${twoDigits(position ~/ 60)}:${twoDigits(position % 60)}';
    final remainingLabel = '${twoDigits(remaining ~/ 60)}:${twoDigits(remaining % 60)}';
    return '$currentLabel / $remainingLabel';
  }
}
