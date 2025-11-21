// media_preview.dart
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:crypted_app/app/modules/group_info/controllers/group_info_controller.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:crypted_app/core/themes/color_manager.dart';


/// Example usage:
/// onPreview: () => _previewMedia(context, mediaType, data),
/// onOpenExternally: () => _openExternally(context, data['url'] ?? data['fileUrl'] ?? '')
class MediaPreview {
  // Open externally: prefer url_launcher; for remote files attempt download then open with native app
  static Future<void> openExternally(BuildContext context, String url) async {
    if (url.isEmpty) {
      _showSnack(context, 'No URL provided to open.');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack(context, 'Invalid URL.');
      return;
    }

    try {
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        // try to open directly (external browser / native handler)
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          // fallback: download then open via OpenFile
          final local = await _downloadToTemp(url);
          if (local != null) {
            await OpenFile.open(local.path);
          } else {
            _showSnack(context, 'Could not open file.');
          }
        }
      } else if (uri.scheme == 'file') {
        await OpenFile.open(uri.toFilePath());
      } else {
        // unknown scheme (maybe data: or custom). try launch regardless.
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) _showSnack(context, 'Could not open externally.');
      }
    } catch (e) {
      debugPrint('openExternally error: $e');
      _showSnack(context, 'Failed to open externally.');
    }
  }

  // Core preview handler
  static Future<void> previewMedia(BuildContext context, MediaType mediaType, Map<String, dynamic> data) async {
    final url = (data['url'] ?? data['fileUrl'] ?? '') as String;
    final thumbnail = (data['thumbnailUrl'] ?? '') as String;
    final heroTag = url.isNotEmpty ? url : ('media_preview_${DateTime.now().millisecondsSinceEpoch}');

    switch (mediaType) {
      case MediaType.image:
        await Navigator.of(context).push(PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => _ImagePreviewPage(url: url, heroTag: heroTag, caption: data['caption']),
        ));
        break;
      case MediaType.video:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _VideoPreviewPage(url: url, poster: thumbnail, caption: data['caption']),
        ));
        break;
      case MediaType.audio:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _AudioPreviewPage(url: url, title: data['caption'] ?? data['title']),
        ));
        break;
      case MediaType.file:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _FilePreviewPage(url: url, name: data['caption'] ?? url.split('/').last),
        ));
        break;
    }
  }

  // Helpers

  static Future<File?> _downloadToTemp(String url, {String filename = ''}) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;
      final dir = await getTemporaryDirectory();
      
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(res.bodyBytes);
      return file;
    } catch (e) {
      debugPrint('downloadToTemp error: $e');
      return null;
    }
  }

  static void _showSnack(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// --- UI pages below (image / video / audio / file) --- ///

class _ImagePreviewPage extends StatelessWidget {
  final String url;
  final Object heroTag;
  final String? caption;
  const _ImagePreviewPage({required this.url, required this.heroTag, this.caption});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: heroTag,
                child: url.isEmpty
                    ? const Icon(Icons.broken_image, size: 120, color: Colors.white24)
                    : PhotoView(
                        imageProvider: NetworkImage(url),
                        loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
                        backgroundDecoration: const BoxDecoration(color: Colors.black),
                        enableRotation: true,
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 2.5,
                      ),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: _roundIcon(context, Icons.close, onTap: () => Navigator.of(context).pop()),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _roundIcon(context, Icons.open_in_full, onTap: () => MediaPreview.openExternally(context, url)),
                  const SizedBox(width: 8),
                  _roundIcon(context, Icons.download, onTap: () async {
                    final file = await MediaPreview._downloadToTemp(url);
                    if (file != null) {
                      await OpenFile.open(file.path);
                    } else {
                      MediaPreview._showSnack(context, 'Download failed.');
                    }
                  }),
                ],
              ),
            ),
            if (caption != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Text(
                  caption ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _roundIcon(BuildContext context, IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _VideoPreviewPage extends StatefulWidget {
  final String url;
  final String? poster;
  final String? caption;
  const _VideoPreviewPage({required this.url, this.poster, this.caption});

  @override
  State<_VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<_VideoPreviewPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _initFailed = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    if (widget.url.isEmpty) {
      setState(() => _initFailed = true);
      return;
    }
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: ColorsManager.primary,
          handleColor: Colors.white,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
      );
      setState(() {});
    } catch (e) {
      debugPrint('video init error: $e');
      setState(() => _initFailed = true);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initFailed) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.black, elevation: 0),
        backgroundColor: Colors.black,
        body: const Center(child: Text('Unable to load video', style: TextStyle(color: Colors.white70))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.open_in_full, color: Colors.white),
                  onPressed: () => MediaPreview.openExternally(context, widget.url),
                )
              ],
            ),
            Expanded(
              child: Center(
                child: _chewieController != null
                    ? Hero(
                        tag: widget.url,
                        child: Chewie(controller: _chewieController!),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
            if (widget.caption != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(widget.caption!, style: const TextStyle(color: Colors.white70)),
              ),
            _videoActions(),
          ],
        ),
      ),
    );
  }

  Widget _videoActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () async {
              final f = await MediaPreview._downloadToTemp(widget.url);
              if (f != null) {
                await OpenFile.open(f.path);
              } else {
                MediaPreview._showSnack(context, 'Download failed.');
              }
            },
          ),
          const Spacer(),
          PopupMenuButton<double>(
            color: Colors.grey[900],
            onSelected: (v) => _videoController?.setPlaybackSpeed(v),
            itemBuilder: (ctx) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
              return PopupMenuItem<double>(value: s, child: Text('${s}x', style: const TextStyle(color: Colors.white)));
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: const [Icon(Icons.speed, color: Colors.white), SizedBox(width: 6), Text('Speed', style: TextStyle(color: Colors.white))]),
            ),
          )
        ],
      ),
    );
  }
}

class _AudioPreviewPage extends StatefulWidget {
  final String url;
  final String? title;
  const _AudioPreviewPage({required this.url, this.title});

  @override
  State<_AudioPreviewPage> createState() => _AudioPreviewPageState();
}

class _AudioPreviewPageState extends State<_AudioPreviewPage> {
  late AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.url);
      _duration = _player.duration ?? Duration.zero;
      _player.positionStream.listen((p) => setState(() => _position = p));
      _player.playerStateStream.listen((s) => setState(() {}));
    } catch (e) {
      debugPrint('audio init error: $e');
      MediaPreview._showSnack(context, 'Could not play audio.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) => d == Duration.zero ? '0:00' : DateFormat('m:ss').format(DateTime.fromMillisecondsSinceEpoch(d.inMilliseconds));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0, title: Text(widget.title ?? 'Audio')),
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Icon(Icons.audiotrack, size: 96, color: Colors.white70),
                  const SizedBox(height: 24),
                  Text(widget.title ?? 'Audio file', style: const TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 18),
                  Slider(
                    min: 0,
                    max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1,
                    value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                    onChanged: (v) => _player.seek(Duration(milliseconds: v.round())),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(_format(_position), style: const TextStyle(color: Colors.white70)), Text(_format(_duration), style: const TextStyle(color: Colors.white70))],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(icon: const Icon(Icons.replay_10, color: Colors.white), onPressed: () => _player.seek(_position - const Duration(seconds: 10))),
                      IconButton(
                        iconSize: 48,
                        icon: Icon(_player.playing ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white),
                        onPressed: () async {
                          if (_player.playing) {
                            await _player.pause();
                          } else {
                            await _player.play();
                          }
                          setState(() {});
                        },
                      ),
                      IconButton(icon: const Icon(Icons.forward_10, color: Colors.white), onPressed: () => _player.seek(_position + const Duration(seconds: 10))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final f = await MediaPreview._downloadToTemp(widget.url);
                          if (f != null) {
                            await OpenFile.open(f.path);
                          } else {
                            MediaPreview._showSnack(context, 'Download failed.');
                          }
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => MediaPreview.openExternally(context, widget.url),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Externally'),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }
}

class _FilePreviewPage extends StatefulWidget {
  final String url;
  final String name;
  const _FilePreviewPage({required this.url, required this.name});

  @override
  State<_FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<_FilePreviewPage> {
  String? _previewText;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tryPreview();
  }

  Future<void> _tryPreview() async {
    try {
      if (widget.url.toLowerCase().endsWith('.txt') || widget.url.toLowerCase().endsWith('.log')) {
        final res = await http.get(Uri.parse(widget.url));
        if (res.statusCode == 200 && mounted) {
          setState(() => _previewText = res.body);
        }
      }
    } catch (e) {
      debugPrint('file preview error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name), actions: [
        IconButton(icon: const Icon(Icons.open_in_full), onPressed: () => MediaPreview.openExternally(context, widget.url)),
        IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final f = await MediaPreview._downloadToTemp(widget.url);
              if (f != null) {
                await OpenFile.open(f.path);
              } else {
                MediaPreview._showSnack(context, 'Download failed.');
              }
            })
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _previewText != null
              ? SingleChildScrollView(padding: const EdgeInsets.all(12), child: Text(_previewText!))
              : Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.insert_drive_file, size: 64),
                    const SizedBox(height: 12),
                    Text(widget.name),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final f = await MediaPreview._downloadToTemp(widget.url);
                        if (f != null) {
                          await OpenFile.open(f.path);
                        } else {
                          MediaPreview._showSnack(context, 'Download failed.');
                        }
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    )
                  ]),
                ),
    );
  }
}
