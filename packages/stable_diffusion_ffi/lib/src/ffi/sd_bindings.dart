import 'dart:ffi';

import 'package:stable_diffusion_ffi/src/ffi/sd_structs.dart';

// stable-diffusion.cpp >= commit 0e4ee04 uses a struct-based API:
//
//   sd_ctx_t* new_sd_ctx(const sd_ctx_params_t* params)
//   void      free_sd_ctx(sd_ctx_t* ctx)
//   sd_image_t* generate_image(sd_ctx_t* ctx, const sd_img_gen_params_t* params)
//
// Both param structs are large and have many nested types, so we interact with
// them through init helpers + raw byte-offset writes rather than mirroring the
// full C layout in Dart.

typedef _VoidPtrFromPtrUint8Dart = Pointer<Void> Function(Pointer<Uint8>);

typedef _VoidVoidPtrDart = void Function(Pointer<Void>);

typedef _VoidPtrUint8C = Void Function(Pointer<Uint8>);
typedef _VoidPtrUint8Dart = void Function(Pointer<Uint8>);

typedef _SdImagePtrDart = Pointer<SdImageT> Function(Pointer<Void>, Pointer<Uint8>);

class SdBindings {
  SdBindings(DynamicLibrary lib)
      : sdCtxParamsInit =
            lib.lookupFunction<_VoidPtrUint8C, _VoidPtrUint8Dart>('sd_ctx_params_init'),
        newSdCtx =
            lib.lookupFunction<Pointer<Void> Function(Pointer<Uint8>), _VoidPtrFromPtrUint8Dart>('new_sd_ctx'),
        freeSdCtx =
            lib.lookupFunction<Void Function(Pointer<Void>), _VoidVoidPtrDart>('free_sd_ctx'),
        sdImgGenParamsInit =
            lib.lookupFunction<_VoidPtrUint8C, _VoidPtrUint8Dart>('sd_img_gen_params_init'),
        generateImage =
            lib.lookupFunction<Pointer<SdImageT> Function(Pointer<Void>, Pointer<Uint8>), _SdImagePtrDart>('generate_image');

  /// void sd_ctx_params_init(sd_ctx_params_t*)
  final _VoidPtrUint8Dart sdCtxParamsInit;

  /// sd_ctx_t* new_sd_ctx(const sd_ctx_params_t*)
  final _VoidPtrFromPtrUint8Dart newSdCtx;

  /// void free_sd_ctx(sd_ctx_t*)
  final _VoidVoidPtrDart freeSdCtx;

  /// void sd_img_gen_params_init(sd_img_gen_params_t*)
  final _VoidPtrUint8Dart sdImgGenParamsInit;

  /// sd_image_t* generate_image(sd_ctx_t*, const sd_img_gen_params_t*)
  final _SdImagePtrDart generateImage;
}

// ── Byte offsets in sd_ctx_params_t ─────────────────────────────────────────
// Layout (64-bit, little-endian):
//   14 pointer fields × 8 = 112, then embedding_count(4)+pad(4),
//   2 pointer fields × 8 = 16 → total 132, then vae_decode_only(1)+
//   free_params_immediately(1)+pad(2)+n_threads(4) → at 148.
const int sdCtxModelPath = 0;   // const char*
const int sdCtxNThreads  = 148; // int32  (-1 = auto)
const int sdCtxWtype     = 152; // sd_type_t  (42 = SD_TYPE_COUNT = auto)

// ── Byte offsets in sd_img_gen_params_t ─────────────────────────────────────
// loras(8)+lora_count(4)+pad(4)=16; then prompt/neg at 16/24; clip_skip(4)+
// pad(4)=8 at 32; 2×sd_image_t(24) at 40..88; ref_images(8)+count(4)+2bool+
// pad(2) at 64..80; mask_image(24) at 80..104; width/height at 104/108.
// sample_params(96) at 112; sample_steps at +56=168. strength(4)+pad(4) then
// seed(int64) at 216.
const int sdGenPrompt         = 16;  // const char*
const int sdGenNegativePrompt = 24;  // const char*
const int sdGenWidth          = 104; // int32
const int sdGenHeight         = 108; // int32
const int sdGenScheduler      = 160; // scheduler_t int32  (at 112+48)
const int sdGenSampleMethod   = 164; // sample_method_t int32  (at 112+52)
const int sdGenSampleSteps    = 168; // int32  (at 112+56)
const int sdGenSeed           = 216; // int64
const int sdGenBatchCount     = 224; // int32
