import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';

enum MediumType { image, video }

class Medium {
  final String id;
  final String filename;
  final DateTime? creationDate;
  final int? width;
  final int? height;
  final int? duration;
  final MediumType mediumType;

  Medium({
    required this.id,
    required this.filename,
    this.creationDate,
    this.width,
    this.height,
    this.duration,
    required this.mediumType,
  });

  Future<File> getFile() async {
    final result = await const MethodChannel('photo_gallery')
        .invokeMethod<String>('getFile', {'id': id});
    if (result == null) {
      throw Exception('Failed to get file');
    }
    return File(result);
  }
}

class Album {
  final String id;
  final String name;
  final int? count;

  Album({
    required this.id,
    required this.name,
    this.count,
  });

  Future<MediaPage> listMedia() async {
    final result = await const MethodChannel('photo_gallery')
        .invokeMethod<Map<dynamic, dynamic>>('listMedia', {'albumId': id});
    if (result == null) {
      throw Exception('Failed to list media');
    }
    return MediaPage.fromJson(result);
  }
}

class MediaPage {
  final List<Medium> items;
  final Album album;
  final String? nextCursor;

  MediaPage({
    required this.items,
    required this.album,
    this.nextCursor,
  });

  factory MediaPage.fromJson(Map<dynamic, dynamic> json) {
    return MediaPage(
      items: (json['items'] as List)
          .map((item) => Medium(
                id: item['id'] as String,
                filename: item['filename'] as String,
                creationDate: item['creationDate'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        item['creationDate'] as int)
                    : null,
                width: item['width'] as int?,
                height: item['height'] as int?,
                duration: item['duration'] as int?,
                mediumType: MediumType.values.firstWhere(
                  (e) => e.toString() == 'MediumType.${item['mediumType']}',
                  orElse: () => MediumType.image,
                ),
              ))
          .toList(),
      album: Album(
        id: json['album']['id'] as String,
        name: json['album']['name'] as String,
        count: json['album']['count'] as int?,
      ),
      nextCursor: json['nextCursor'] as String?,
    );
  }
}

class PhotoGallery {
  static Future<List<Album>> listAlbums({MediumType? mediumType}) async {
    final result = await const MethodChannel('photo_gallery')
        .invokeMethod<List<dynamic>>('listAlbums', {
      'mediumType': mediumType?.toString().split('.').last,
    });
    if (result == null) {
      throw Exception('Failed to list albums');
    }
    return result
        .map((album) => Album(
              id: album['id'] as String,
              name: album['name'] as String,
              count: album['count'] as int?,
            ))
        .toList();
  }
}

class ThumbnailProvider extends ImageProvider<ThumbnailProvider> {
  final String mediumId;
  final bool highQuality;
  final int? width;
  final int? height;
  final MediumType? mediumType;

  const ThumbnailProvider({
    required this.mediumId,
    this.highQuality = false,
    this.width,
    this.height,
    this.mediumType,
  });

  @override
  Future<ThumbnailProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ThumbnailProvider>(this);
  }

  @override
  ImageStreamCompleter loadBuffer(
      ThumbnailProvider key,
      Future<ui.Codec> Function(ImmutableBuffer,
              {bool allowUpscaling, int? cacheHeight, int? cacheWidth})
          decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(ThumbnailProvider key) async {
    final result =
        await const MethodChannel('photo_gallery').invokeMethod<Uint8List>(
      'getThumbnail',
      {
        'mediumId': key.mediumId,
        'highQuality': key.highQuality,
        'width': key.width,
        'height': key.height,
        'mediumType': key.mediumType?.toString().split('.').last,
      },
    );
    if (result == null) {
      throw Exception('Failed to load thumbnail');
    }
    final buffer = await ImmutableBuffer.fromUint8List(result);
    return await ui.instantiateImageCodecFromBuffer(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is ThumbnailProvider &&
        other.mediumId == mediumId &&
        other.highQuality == highQuality &&
        other.width == width &&
        other.height == height &&
        other.mediumType == mediumType;
  }

  @override
  int get hashCode =>
      Object.hash(mediumId, highQuality, width, height, mediumType);
}
