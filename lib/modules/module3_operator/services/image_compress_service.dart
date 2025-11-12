import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class OperatorImageCompressService {
  static Future<File> compress(
    File file, {
    int quality = 60,
    int minWidth = 800,
    int minHeight = 600,
  }) async {
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

      return File(result?.path ?? file.path);
    } catch (e) {
      // Keep the original if compression fails; caller expects a valid file.
      return file;
    }
  }
}
