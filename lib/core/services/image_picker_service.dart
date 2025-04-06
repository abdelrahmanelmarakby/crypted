import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exif/exif.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the specified source (gallery or camera).
  /// [source] - ImageSource.gallery or ImageSource.camera
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
    }
    return null;
  }

  Future<List<File?>?> pickMultiImage() async {
    try {
      List<XFile>? pickedFile = await _picker.pickMultiImage(
        imageQuality: 100,
        limit: 10,
      );
      if (pickedFile.isNotEmpty) {
        return pickedFile.map((e) => File(e.path)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
    }
    return null;
  }

  /// Picks a panorama image (from gallery) based on aspect ratio.
  Future<File?> pickPanoramaImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        bool isPanorama = await _isPanoramaImage(imageFile);
        return isPanorama ? imageFile : null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking panorama image: $e');
      }
    }
    return null;
  }

  /// Checks if the image is a panorama based on its aspect ratio.
  Future<bool> _isPanoramaImage(File imageFile) async {
    try {
      final data = await readExifFromBytes(await imageFile.readAsBytes());
      if (data.isEmpty) return false;

      if (data.containsKey('ImageWidth') && data.containsKey('ImageLength')) {
        final width = int.tryParse(data['ImageWidth']?.printable ?? '0') ?? 0;
        final height = int.tryParse(data['ImageLength']?.printable ?? '0') ?? 0;

        // Panorama aspect ratio threshold (e.g., width is >2.5x height)
        return width / height > 2.5;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reading EXIF data: $e');
      }
    }
    return false;
  }
}
