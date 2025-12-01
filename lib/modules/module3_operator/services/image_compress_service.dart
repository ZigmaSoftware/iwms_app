import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageCompressService {
  static Future<File> compress(File file,
      {int quality = 60, int minWidth = 800, int minHeight = 600}) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          p.join(dir.path, 'cmp_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );

      // ✅ Always return a File
      return File(result?.path ?? file.path);
    } catch (e) {
      print('⚠️ Compression error: $e');
      return file; // fallback to original
    }
  }
}
