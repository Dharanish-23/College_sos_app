/// web_camera_helper.dart
/// Uses dart:html to trigger the browser's native camera capture.
/// On mobile web: opens camera directly.
/// On desktop web: opens camera or file picker depending on browser support.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Captures a photo using the browser's camera (capture="user" for front, "environment" for back).
Future<XFile?> webCapturePhoto({bool frontCamera = false}) async {
  final completer = Completer<XFile?>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..setAttribute('capture', frontCamera ? 'user' : 'environment');

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files[0];
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    reader.onLoad.listen((_) {
      completer.complete(XFile.fromData(
        Uint8List.fromList(_dataUrlToBytes(reader.result as String)),
        name: file.name,
        mimeType: file.type,
      ));
    });
    reader.onError.listen((_) => completer.complete(null));
  });

  // If user dismisses without selecting
  html.document.body?.append(input);
  input.click();
  // Clean up after a delay
  Future.delayed(const Duration(minutes: 2), () {
    input.remove();
    if (!completer.isCompleted) completer.complete(null);
  });

  return completer.future;
}

/// Captures a video using the browser's camera.
Future<XFile?> webCaptureVideo() async {
  final completer = Completer<XFile?>();
  final input = html.FileUploadInputElement()
    ..accept = 'video/*'
    ..setAttribute('capture', 'environment');

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files[0];
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoad.listen((_) {
      final bytes = reader.result as dynamic;
      completer.complete(XFile.fromData(
        bytes is Uint8List ? bytes : Uint8List.fromList((bytes as List<int>)),
        name: file.name,
        mimeType: file.type,
      ));
    });
    reader.onError.listen((_) => completer.complete(null));
  });

  html.document.body?.append(input);
  input.click();
  Future.delayed(const Duration(minutes: 10), () {
    input.remove();
    if (!completer.isCompleted) completer.complete(null);
  });

  return completer.future;
}

/// Picks a photo from gallery (no capture attribute).
Future<XFile?> webPickPhoto() async {
  final completer = Completer<XFile?>();
  final input = html.FileUploadInputElement()..accept = 'image/*';

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) { completer.complete(null); return; }
    final file = files[0];
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    reader.onLoad.listen((_) {
      completer.complete(XFile.fromData(
        Uint8List.fromList(_dataUrlToBytes(reader.result as String)),
        name: file.name,
        mimeType: file.type,
      ));
    });
    reader.onError.listen((_) => completer.complete(null));
  });

  html.document.body?.append(input);
  input.click();
  Future.delayed(const Duration(minutes: 2), () {
    input.remove();
    if (!completer.isCompleted) completer.complete(null);
  });
  return completer.future;
}

/// Picks a video from gallery (no capture attribute).
Future<XFile?> webPickVideo() async {
  final completer = Completer<XFile?>();
  final input = html.FileUploadInputElement()..accept = 'video/*';

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) { completer.complete(null); return; }
    final file = files[0];
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoad.listen((_) {
      final bytes = reader.result as dynamic;
      completer.complete(XFile.fromData(
        bytes is Uint8List ? bytes : Uint8List.fromList((bytes as List<int>)),
        name: file.name,
        mimeType: file.type,
      ));
    });
    reader.onError.listen((_) => completer.complete(null));
  });

  html.document.body?.append(input);
  input.click();
  Future.delayed(const Duration(minutes: 10), () {
    input.remove();
    if (!completer.isCompleted) completer.complete(null);
  });
  return completer.future;
}

List<int> _dataUrlToBytes(String dataUrl) {
  final base64 = dataUrl.split(',').last;
  // ignore: avoid_web_libraries_in_flutter
  return html.window.atob(base64).codeUnits;
}
