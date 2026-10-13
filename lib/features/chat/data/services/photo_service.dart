import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum PhotoSource { camera, library }

/// The photo can't be made small enough for the backend.
class PhotoTooLargeException implements Exception {
  const PhotoTooLargeException();
}

/// Picks a photo for Felix, behind a small interface so tests never reach
/// the platform channels.
abstract class PhotoService {
  /// Stored path (`chat_photos/<uuid>.jpg`, relative to the documents dir)
  /// of a ready-to-send JPEG (longest side <= 1280 px, <= 1.5 MB), or null
  /// when cancelled. Throws [PhotoTooLargeException] if it can't be shrunk.
  Future<String?> pick(PhotoSource source);
}

/// The backend's limit for one photo, decoded.
const maxChatPhotoBytes = 1500 * 1024;

const chatPhotosFolder = 'chat_photos';

/// Loads the app documents directory. Replaceable in tests.
@visibleForTesting
Future<String> Function() documentsDirLoader =
    () async => (await getApplicationDocumentsDirectory()).path;

Future<String>? _docsDir;

/// The documents directory, resolved once. The container path changes when
/// iOS updates or reinstalls the app, so photos are stored relative to it.
Future<String> chatDocsDir() => _docsDir ??= documentsDirLoader();

@visibleForTesting
void resetChatDocsDir() => _docsDir = null;

/// Where the photo stored as [stored] lives under [docs]. Understands the
/// relative form and legacy absolute paths (from an old container), which
/// resolve by file name.
String resolveChatPhoto(String docs, String stored) =>
    p.join(docs, chatPhotosFolder, p.basename(stored));

/// Base64 of the stored photo, or null if it is missing or too big.
Future<String?> encodeChatPhoto(String stored) async {
  final file = File(resolveChatPhoto(await chatDocsDir(), stored));
  if (!await file.exists()) return null;
  if (await file.length() > maxChatPhotoBytes) return null;
  return base64Encode(await file.readAsBytes());
}

/// Deletes the stored photo; never throws.
Future<void> deleteChatPhoto(String stored) async {
  try {
    File(resolveChatPhoto(await chatDocsDir(), stored)).deleteSync();
  } catch (_) {}
}

bool _isJpeg(Uint8List b) => b.length > 2 && b[0] == 0xFF && b[1] == 0xD8;

/// [bytes] as a JPEG that fits the backend: unchanged when it already is a
/// JPEG within the size limit, otherwise re-encoded (longest side <= 1280 px,
/// quality 80, then 65, then 50). Re-encoding also drops metadata such as
/// GPS. Null when even quality 50 is too big.
Future<Uint8List?> normalizeChatPhoto(Uint8List bytes) {
  if (_isJpeg(bytes) && bytes.length <= maxChatPhotoBytes) {
    return Future.value(bytes);
  }
  return Isolate.run(() {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    // Apply the EXIF rotation; the JPEG encoder drops EXIF.
    var image = img.bakeOrientation(decoded);
    final longest = image.width > image.height ? image.width : image.height;
    if (longest > 1280) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? 1280 : null,
        height: image.height > image.width ? 1280 : null,
      );
    }
    for (final quality in const [80, 65, 50]) {
      final out = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      if (out.length <= maxChatPhotoBytes) return out;
    }
    return null;
  });
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
      requestFullMetadata: false,
    );
    if (picked == null) return null;
    final docs = await chatDocsDir();
    final dir = Directory(p.join(docs, chatPhotosFolder));
    await dir.create(recursive: true);
    final name = '${const Uuid().v4()}.jpg';
    final target = p.join(dir.path, name);

    final bytes = await picked.readAsBytes();
    final normalized = await normalizeChatPhoto(bytes);
    if (normalized == null) throw const PhotoTooLargeException();
    if (identical(normalized, bytes)) {
      // Already a fine JPEG: move the picker's temp file instead of copying.
      final temp = File(picked.path);
      try {
        await temp.rename(target);
      } catch (_) {
        await temp.copy(target);
        try {
          await temp.delete();
        } catch (_) {}
      }
    } else {
      await File(target).writeAsBytes(normalized);
    }
    return '$chatPhotosFolder/$name';
  }
}

final photoServiceProvider =
    Provider<PhotoService>((ref) => PickerPhotoService());
