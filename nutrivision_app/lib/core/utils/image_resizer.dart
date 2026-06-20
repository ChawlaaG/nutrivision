import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageResizer {
  /// Resizes an image to a maximum dimension (width or height) while maintaining aspect ratio.
  /// Returns the path to the resized image.
  static Future<String> resizeImage(String imagePath, {int maxDimension = 1024, int quality = 80}) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found at $imagePath');
      }

      // Read image bytes
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Check if resizing is needed
      if (image.width <= maxDimension && image.height <= maxDimension) {
        return imagePath; // No need to resize
      }

      // Resize
      final resizedImage = img.copyResize(
        image,
        width: image.width > image.height ? maxDimension : null,
        height: image.height > image.width ? maxDimension : null,
        interpolation: img.Interpolation.linear,
      );

      // Save resized image
      final newPath = '${imagePath}_resized.jpg';
      final resizedBytes = img.encodeJpg(resizedImage, quality: quality);
      await File(newPath).writeAsBytes(resizedBytes);

      return newPath;
    } catch (e) {
      debugPrint('Image Resize Error: $e');
      return imagePath; // Fallback to original if resize fails
    }
  }
}
