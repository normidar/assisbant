import 'dart:typed_data';

class SdGenerationResult {
  const SdGenerationResult({
    required this.pngBytes,
    required this.seed,
    required this.width,
    required this.height,
  });

  final Uint8List pngBytes;
  final int seed;
  final int width;
  final int height;
}
