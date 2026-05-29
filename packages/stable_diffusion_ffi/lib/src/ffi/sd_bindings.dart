import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'sd_structs.dart';

// ─── new_sd_ctx ────────────────────────────────────────────────────────────────

typedef _NewSdCtxC = Pointer<Void> Function(
  Pointer<Utf8> modelPath,
  Pointer<Utf8> clipLPath,
  Pointer<Utf8> clipGPath,
  Pointer<Utf8> t5xxlPath,
  Pointer<Utf8> diffusionModelPath,
  Pointer<Utf8> vaePath,
  Pointer<Utf8> taesdPath,
  Pointer<Utf8> controlNetPath,
  Pointer<Utf8> loraModelDir,
  Pointer<Utf8> embedDir,
  Pointer<Utf8> stackedIdEmbedDir,
  Bool vaeDecodeOnly,
  Bool vaeTiling,
  Bool freeParamsImmediately,
  Int32 nThreads,
  Int32 wtype,
  Int32 rngType,
  Int32 schedule,
  Bool keepClipOnCpu,
  Bool keepControlNetCpu,
  Bool keepVaeOnCpu,
  Bool diffusionFlashAttn,
);

typedef _NewSdCtxDart = Pointer<Void> Function(
  Pointer<Utf8> modelPath,
  Pointer<Utf8> clipLPath,
  Pointer<Utf8> clipGPath,
  Pointer<Utf8> t5xxlPath,
  Pointer<Utf8> diffusionModelPath,
  Pointer<Utf8> vaePath,
  Pointer<Utf8> taesdPath,
  Pointer<Utf8> controlNetPath,
  Pointer<Utf8> loraModelDir,
  Pointer<Utf8> embedDir,
  Pointer<Utf8> stackedIdEmbedDir,
  bool vaeDecodeOnly,
  bool vaeTiling,
  bool freeParamsImmediately,
  int nThreads,
  int wtype,
  int rngType,
  int schedule,
  bool keepClipOnCpu,
  bool keepControlNetCpu,
  bool keepVaeOnCpu,
  bool diffusionFlashAttn,
);

// ─── free_sd_ctx ───────────────────────────────────────────────────────────────

typedef _FreeSdCtxC = Void Function(Pointer<Void> sdCtx);
typedef _FreeSdCtxDart = void Function(Pointer<Void> sdCtx);

// ─── txt2img ───────────────────────────────────────────────────────────────────
//
// Returns sd_image_t* (array of batch_count images, caller must free each
// .data with free() and then free() the array itself).

typedef _Txt2ImgC = Pointer<SdImageT> Function(
  Pointer<Void> sdCtx,
  Pointer<Utf8> prompt,
  Pointer<Utf8> negativePrompt,
  Int32 clipSkip,
  Float cfgScale,
  Float guidance,
  Int32 width,
  Int32 height,
  Int32 sampleMethod,
  Int32 sampleSteps,
  Int64 seed,
  Int32 batchCount,
  Pointer<SdImageT> controlCond,
  Float controlStrength,
  Float styleStrength,
  Bool normalizeInput,
  Pointer<Utf8> inputIdImagesPath,
);

typedef _Txt2ImgDart = Pointer<SdImageT> Function(
  Pointer<Void> sdCtx,
  Pointer<Utf8> prompt,
  Pointer<Utf8> negativePrompt,
  int clipSkip,
  double cfgScale,
  double guidance,
  int width,
  int height,
  int sampleMethod,
  int sampleSteps,
  int seed,
  int batchCount,
  Pointer<SdImageT> controlCond,
  double controlStrength,
  double styleStrength,
  bool normalizeInput,
  Pointer<Utf8> inputIdImagesPath,
);

// ─── SdBindings ────────────────────────────────────────────────────────────────

class SdBindings {
  SdBindings(DynamicLibrary lib)
      : newSdCtx =
            lib.lookupFunction<_NewSdCtxC, _NewSdCtxDart>('new_sd_ctx'),
        freeSdCtx =
            lib.lookupFunction<_FreeSdCtxC, _FreeSdCtxDart>('free_sd_ctx'),
        txt2img = lib.lookupFunction<_Txt2ImgC, _Txt2ImgDart>('txt2img');

  final _NewSdCtxDart newSdCtx;
  final _FreeSdCtxDart freeSdCtx;
  final _Txt2ImgDart txt2img;
}
