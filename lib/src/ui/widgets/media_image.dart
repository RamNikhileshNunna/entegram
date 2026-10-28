import 'dart:typed_data';
import 'dart:ui' as ui;

/// Reject unsupported containers before replacing a usable thumbnail. Codec
/// support comes from the current device, not a brittle list of file suffixes.
Future<bool> canDisplayImage(Uint8List bytes) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    codec = await descriptor.instantiateCodec(targetWidth: 1, targetHeight: 1);
    final frame = await codec.getNextFrame();
    frame.image.dispose();
    return true;
  } catch (_) {
    return false;
  } finally {
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}
