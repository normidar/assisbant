import 'package:stable_diffusion_ffi/src/ffi/sd_enums.dart';

class SdGenerateParams {
  const SdGenerateParams({
    required this.modelPath,
    required this.prompt, this.dylibPath = '',
    this.negativePrompt = '',
    this.vaePath = '',
    this.width = 512,
    this.height = 512,
    this.steps = 20,
    this.seed = -1,
    this.sampleMethod = SdSampleMethod.useDefault,
    this.schedule = SdSchedule.useDefault,
    this.threads = -1,
    this.wtype = SdType.auto_,
  });

  final String modelPath;

  /// Path to a pre-compiled dylib. Leave empty to use the library bundled via
  /// Native Assets (compiled from the submodule during `flutter build`).
  final String dylibPath;

  final String prompt;
  final String negativePrompt;

  /// Optional external VAE path. Leave empty to use the VAE bundled in the model.
  final String vaePath;

  final int width;
  final int height;

  /// Denoising steps. 10–20 is typical; lower = faster.
  final int steps;

  /// Seed. -1 = random (current time-based).
  final int seed;

  /// sample_method_t value. -1 = library default.
  final int sampleMethod;

  /// scheduler_t value. -1 = library default.
  final int schedule;

  /// CPU thread count. -1 = auto.
  final int threads;

  /// sd_type_t quantisation. 42 (SD_TYPE_COUNT) = auto.
  final int wtype;
}
