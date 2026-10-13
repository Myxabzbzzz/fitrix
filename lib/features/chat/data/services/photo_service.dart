import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum PhotoSource { camera, library }

/// Picks a photo for Felix, behind a small interface so tests never reach
/// the platform channels.
abstract class PhotoService {
  /// Path of a ready-to-send JPEG (longest side <= 1280 px, quality 80)
  /// kept in the app's documents directory, or null when cancelled.
  Future<String?> pick(PhotoSource source);
}

/// The backend's limit for one photo, decoded.
const maxChatPhotoBytes = 1500 * 1024;

/// Base64 of the photo at [path], or null if it is missing or too big.
Future<String?> encodeChatPhoto(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  if (await file.length() > maxChatPhotoBytes) return null;
  return base64Encode(await file.readAsBytes());
}

class PickerPhotoService implements PhotoService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> pick(PhotoSource source) async {
    final picked = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (picked == null) return null;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/chat_photos');
    await dir.create(recursive: true);
    final target = '${dir.path}/${const Uuid().v4()}.jpg';
    await File(picked.path).copy(target);
    return target;
  }
}

final photoServiceProvider =
    Provider<PhotoService>((ref) => PickerPhotoService());
