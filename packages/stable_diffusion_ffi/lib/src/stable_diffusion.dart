import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:image/image.dart' as img;

import 'ffi/sd_bindings.dart';
import 'ffi/sd_enums.dart';
import 'ffi/sd_structs.dart';
import 'sd_params.dart';
import 'sd_result.dart';

export 'sd_params.dart';
export 'sd_result.dart';
export 'ffi/sd_enums.dart';

class StableDiffusionFfi {
  /// Generates an image using a stable-diffusion.cpp dylib.
  ///
  /// Loads the model, runs inference, returns PNG bytes, then frees all
  /// resources — all inside a background [Isolate] so the UI stays responsive.
  ///
  /// Model loading (especially for large .safetensors files) can take tens of
  /// seconds. Consider showing a progress indicator while awaiting.
  static Future<SdGenerationResult> generate(SdGenerateParams params) =>
      Isolate.run(() => _generateSync(params));

  static SdGenerationResult _generateSync(SdGenerateParams params) {
    final dylib = DynamicLibrary.open(params.dylibPath);
    final bindings = SdBindings(dylib);

    final allocs = <Pointer<Utf8>>[];
    Pointer<Utf8> s(String v) {
      final p = v.toNativeUtf8();
      allocs.add(p);
      return p;
    }

    Pointer<Void> ctx = nullptr;
    Pointer<SdImageT> images = nullptr;

    try {
      ctx = bindings.newSdCtx(
        s(params.modelPath),
        s(''), // clip_l (bundled in model)
        s(''), // clip_g
        s(''), // t5xxl
        s(''), // diffusion_model (standalone flux)
        s(params.vaePath), // empty = use model's built-in VAE
        s(''), // taesd
        s(''), // control_net
        s(''), // lora_dir
        s(''), // embed_dir
        s(''), // stacked_id_embed_dir
        true,  // vae_decode_only
        false, // vae_tiling
        false, // free_params_immediately
        params.threads,
        params.wtype,
        SdRng.stdDefault,
        params.schedule,
        false, // keep_clip_on_cpu
        false, // keep_control_net_cpu
        false, // keep_vae_on_cpu
        false, // diffusion_flash_attn
      );

      if (ctx == nullptr) {
        throw StateError('Failed to load model: ${params.modelPath}');
      }

      final effectiveSeed = params.seed < 0
          ? DateTime.now().millisecondsSinceEpoch % 0xFFFFFFFF
          : params.seed;

      images = bindings.txt2img(
        ctx,
        s(params.prompt),
        s(params.negativePrompt),
        -1,   // clip_skip (-1 = use model default)
        params.cfgScale,
        1.0,  // guidance
        params.width,
        params.height,
        params.sampleMethod,
        params.steps,
        effectiveSeed,
        1,    // batch_count
        nullptr, // no ControlNet
        0.9,  // control_strength
        1.0,  // style_strength
        false, // normalize_input
        s(''), // input_id_images_path
      );

      if (images == nullptr) {
        throw StateError('txt2img returned null — generation failed');
      }

      final sdImage = images.ref;
      final w = sdImage.width;
      final h = sdImage.height;
      final ch = sdImage.channel;
      final rawPixels = Uint8List.fromList(
        sdImage.data.asTypedList(w * h * ch),
      );

      final image = img.Image.fromBytes(
        width: w,
        height: h,
        bytes: rawPixels.buffer,
        numChannels: ch,
        format: img.Format.uint8,
      );

      return SdGenerationResult(
        pngBytes: Uint8List.fromList(img.encodePng(image)),
        seed: effectiveSeed,
        width: w,
        height: h,
      );
    } finally {
      // Free image data returned by txt2img (caller-owned malloc memory)
      if (images != nullptr) {
        calloc.free(images.ref.data);
        calloc.free(images);
      }
      if (ctx != nullptr) bindings.freeSdCtx(ctx);
      for (final p in allocs) calloc.free(p);
    }
  }
}
