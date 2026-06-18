import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageExport {
  static Future<bool> _ensurePermission() async {
    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      if (photos.isGranted) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
    if (Platform.isIOS) {
      final photos = await Permission.photosAddOnly.request();
      if (photos.isGranted) return true;
      return (await Permission.photos.request()).isGranted;
    }
    return true;
  }

  static Future<void> saveToGallery(Uint8List bytes, {required String fileName}) async {
    final granted = await _ensurePermission();
    if (!granted) {
      throw Exception('Photo library permission denied');
    }
    await Gal.putImageBytes(bytes, name: fileName);
  }

  static Future<void> saveFileToGallery(String filePath, {required String fileName}) async {
    final bytes = await File(filePath).readAsBytes();
    await saveToGallery(bytes, fileName: fileName);
  }
}
