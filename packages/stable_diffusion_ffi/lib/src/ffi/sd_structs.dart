import 'dart:ffi';

/// Maps to sd_image_t in stable-diffusion.h
///
/// Dart FFI automatically inserts the 4-byte alignment pad before `data`
/// to satisfy the 8-byte pointer alignment requirement on 64-bit targets,
/// producing the same layout as the C struct.
final class SdImageT extends Struct {
  @Uint32()
  external int width;

  @Uint32()
  external int height;

  @Uint32()
  external int channel;

  external Pointer<Uint8> data;
}
