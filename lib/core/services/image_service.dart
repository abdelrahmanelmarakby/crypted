import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

Future<bool> isImageBrightFromNetwork(String imageUrl) async {
  try {
    // Fetch the image data from the network
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      return true; // Default to bright if failed to load
    }

    // Decode image from network response
    Uint8List bytes = response.bodyBytes;
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return true;

    int totalLuminance = 0;
    int pixelCount = image.width * image.height;

    // Loop over the pixels and calculate luminance
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final img.Pixel pixel = image.getPixel(x, y);
        int luminance =
            (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).toInt();
        totalLuminance += luminance;
      }
    }

    // Calculate the average brightness
    double averageLuminance = totalLuminance / pixelCount;
    return averageLuminance >
        128; // If average luminance > 128, consider it bright
  } catch (e) {
    debugPrint("Error analyzing image brightness: $e");
    return true; // Default to bright in case of an error
  }
}

Future<bool> isImageBright(String imagePath) async {
  // Load image from assets
  final ByteData data = await rootBundle.load(imagePath);
  final List<int> bytes = data.buffer.asUint8List();

  // Decode image to get pixel data
  img.Image? image = img.decodeImage(Uint8List.fromList(bytes));
  if (image == null) return true; // Default to bright if failed to decode

  int totalLuminance = 0;
  int pixelCount = image.width * image.height;

  // Loop over the pixels and calculate luminance
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final img.Pixel pixel = image.getPixel(x, y);
      int luminance =
          (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).toInt();
      totalLuminance += luminance;
    }
  }

  // Calculate the average brightness
  double averageLuminance = totalLuminance / pixelCount;
  return averageLuminance >
      128; // If average luminance > 128, consider it bright
}
