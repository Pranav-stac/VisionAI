import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  // Compress image with quality parameter (0-100)
  static Future<File?> compressImage(File file, {int quality = 80}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      
      if (result == null) {
        if (kDebugMode) {
          print('Compression failed - returning original file');
        }
        return file;
      }
      
      if (kDebugMode) {
        final originalSize = await file.length();
        final compressedSize = await result.length();
        print('Original size: $originalSize bytes');
        print('Compressed size: $compressedSize bytes');
        print('Compression ratio: ${(compressedSize / originalSize * 100).toStringAsFixed(1)}%');
      }
      
      return File(result.path);
    } catch (e) {
      if (kDebugMode) {
        print('Error compressing image: $e');
      }
      // Return original file if compression fails
      return file;
    }
  }
  
  // Resize image to specific dimensions
  static Future<File?> resizeImage(File file, {int width = 800, int height = 600}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_resized.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        minWidth: width,
        minHeight: height,
        quality: 90,
        format: CompressFormat.jpeg,
      );
      
      return result != null ? File(result.path) : file;
    } catch (e) {
      if (kDebugMode) {
        print('Error resizing image: $e');
      }
      return file;
    }
  }
  
  // Adaptively compress image based on file size
  static Future<File> adaptiveCompress(File file) async {
    final fileSize = await file.length();
    final fileSizeKB = fileSize / 1024;
    
    // Different compression strategies based on file size
    if (fileSizeKB > 1000) {
      // Large image (>1MB): Aggressive compression
      return (await compressImage(file, quality: 60)) ?? file;
    } else if (fileSizeKB > 500) {
      // Medium image (500KB-1MB): Moderate compression
      return (await compressImage(file, quality: 75)) ?? file;
    } else if (fileSizeKB > 200) {
      // Small image (200KB-500KB): Light compression
      return (await compressImage(file, quality: 85)) ?? file;
    } else {
      // Very small image (<200KB): No compression needed
      return file;
    }
  }
} 