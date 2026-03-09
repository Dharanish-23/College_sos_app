/// web_camera_helper_stub.dart
/// Stub for non-web platforms. These functions should never be called on mobile
/// since we check kIsWeb before calling them.
import 'package:image_picker/image_picker.dart';

Future<XFile?> webCapturePhoto({bool frontCamera = false}) async => null;
Future<XFile?> webCaptureVideo() async => null;
Future<XFile?> webPickPhoto() async => null;
Future<XFile?> webPickVideo() async => null;
