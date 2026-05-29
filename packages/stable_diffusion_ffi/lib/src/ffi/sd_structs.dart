import 'dart:ffi';

/// Maps to sd_image_t in stable-diffusion.h
final class SdImageT extends Struct {
  @Uint32()
  external int width;

  @Uint32()
  external int height;

  @Uint32()
  external int channel;

  external Pointer<Uint8> data;
}
