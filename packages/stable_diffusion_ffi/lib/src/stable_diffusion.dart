import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:image/image.dart' as img;
import 'package:stable_diffusion_ffi/src/ffi/sd_bindings.dart';
import 'package:stable_diffusion_ffi/src/ffi/sd_structs.dart';
import 'package:stable_diffusion_ffi/src/sd_params.dart';
import 'package:stable_diffusion_ffi/src/sd_result.dart';

export 'ffi/sd_enums.dart';
export 'sd_params.dart';
export 'sd_result.dart';

// Sizes of the two C parameter structs (generous upper bounds).
const int _kCtxParamsSize    = 1024;
const int _kImgGenParamsSize = 4096;

class StableDiffusionFfi {
  /// Generates an image using stable-diffusion.cpp via Dart FFI.
  ///
  /// If [SdGenerateParams.dylibPath] is empty the library bundled through
  /// Native Assets (compiled from the submodule during `flutter build`) is
  /// loaded by platform-specific name. Set it explicitly only when using a
  /// pre-compiled dylib outside the app bundle.
  ///
  /// Runs in a background [Isolate] to keep the UI thread unblocked.
  static Future<SdGenerationResult> generate(SdGenerateParams params) =>
      Isolate.run(() => _generateSync(params));

  static DynamicLibrary _openLibrary(String dylibPath) {
    if (dylibPath.isNotEmpty) return DynamicLibrary.open(dylibPath);
    if (Platform.isMacOS) return DynamicLibrary.open('libstable-diffusion.dylib');
    if (Platform.isLinux) return DynamicLibrary.open('libstable-diffusion.so');
    if (Platform.isWindows) return DynamicLibrary.open('stable-diffusion.dll');
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  static SdGenerationResult _generateSync(SdGenerateParams params) {
    final dylib    = _openLibrary(params.dylibPath);
    final bindings = SdBindings(dylib);

    Pointer<Void>     ctx    = nullptr;
    Pointer<SdImageT> images = nullptr;
    Pointer<Uint8>?   ctxBuf;
    Pointer<Uint8>?   genBuf;
    Pointer<Utf8>?    modelPathStr;
    Pointer<Utf8>?    vaePathStr;
    Pointer<Utf8>?    promptStr;
    Pointer<Utf8>?    negPromptStr;

    try {
      // ── Context params ───────────────────────────────────────────────────
      ctxBuf = calloc<Uint8>(_kCtxParamsSize);
      bindings.sdCtxParamsInit(ctxBuf);

      modelPathStr = params.modelPath.toNativeUtf8();
      (ctxBuf + sdCtxModelPath).cast<Pointer<Utf8>>().value = modelPathStr;
      (ctxBuf + sdCtxNThreads).cast<Int32>().value          = params.threads;
      (ctxBuf + sdCtxWtype).cast<Int32>().value             = params.wtype;

      if (params.vaePath.isNotEmpty) {
        // vae_path is the 11th pointer field in sd_ctx_params_t (offset 80)
        vaePathStr = params.vaePath.toNativeUtf8();
        (ctxBuf + 80).cast<Pointer<Utf8>>().value = vaePathStr;
      }

      ctx = bindings.newSdCtx(ctxBuf);
      if (ctx == nullptr) {
        throw StateError('Failed to load model: ${params.modelPath}');
      }

      // ── Image gen params ─────────────────────────────────────────────────
      genBuf = calloc<Uint8>(_kImgGenParamsSize);
      bindings.sdImgGenParamsInit(genBuf);

      promptStr    = params.prompt.toNativeUtf8();
      negPromptStr = params.negativePrompt.toNativeUtf8();

      (genBuf + sdGenPrompt).cast<Pointer<Utf8>>().value         = promptStr;
      (genBuf + sdGenNegativePrompt).cast<Pointer<Utf8>>().value = negPromptStr;
      (genBuf + sdGenWidth).cast<Int32>().value       = params.width;
      (genBuf + sdGenHeight).cast<Int32>().value      = params.height;
      (genBuf + sdGenSampleSteps).cast<Int32>().value = params.steps;
      (genBuf + sdGenBatchCount).cast<Int32>().value  = 1;

      if (params.sampleMethod >= 0) {
        (genBuf + sdGenSampleMethod).cast<Int32>().value = params.sampleMethod;
      }
      if (params.schedule >= 0) {
        (genBuf + sdGenScheduler).cast<Int32>().value = params.schedule;
      }

      final effectiveSeed = params.seed < 0
          ? DateTime.now().millisecondsSinceEpoch % 0xFFFFFFFF
          : params.seed;
      (genBuf + sdGenSeed).cast<Int64>().value = effectiveSeed;

      images = bindings.generateImage(ctx, genBuf);
      if (images == nullptr) {
        throw StateError('generate_image returned null — generation failed');
      }

      final sdImage = images.ref;
      final w  = sdImage.width;
      final h  = sdImage.height;
      final ch = sdImage.channel;

      final rawPixels = Uint8List.fromList(
        sdImage.data.asTypedList(w * h * ch),
      );

      final image = img.Image.fromBytes(
        width: w,
        height: h,
        bytes: rawPixels.buffer,
        numChannels: ch,
      );

      return SdGenerationResult(
        pngBytes: Uint8List.fromList(img.encodePng(image)),
        seed: effectiveSeed,
        width: w,
        height: h,
      );
    } finally {
      if (images != nullptr) {
        calloc.free(images.ref.data);
        calloc.free(images);
      }
      if (ctx != nullptr) bindings.freeSdCtx(ctx);
      if (ctxBuf != null) calloc.free(ctxBuf);
      if (genBuf != null) calloc.free(genBuf);
      if (modelPathStr != null) calloc.free(modelPathStr);
      if (vaePathStr != null) calloc.free(vaePathStr);
      if (promptStr != null) calloc.free(promptStr);
      if (negPromptStr != null) calloc.free(negPromptStr);
    }
  }
}
