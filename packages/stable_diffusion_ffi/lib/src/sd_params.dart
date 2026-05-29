import 'ffi/sd_enums.dart';

class SdGenerateParams {
  const SdGenerateParams({
    required this.modelPath,
    this.dylibPath = '',

    required this.prompt,
    this.negativePrompt = '',
    this.vaePath = '',
    this.width = 512,
    this.height = 512,
    this.steps = 20,
    this.cfgScale = 7.0,
    this.seed = -1,
    this.sampleMethod = SdSampleMethod.eulerA,
    this.schedule = SdSchedule.default_,
    this.threads = -1,
    this.wtype = SdType.auto_,
  });

  final String modelPath;
  /// Path to the pre-compiled dylib. Leave empty to use the Native Assets
  /// bundled library (built from the submodule during `flutter build`).
  final String dylibPath;
  final String prompt;
  final String negativePrompt;
  final String vaePath;
  final int width;
  final int height;
  final int steps;
  final double cfgScale;
  /// Seed value. Use -1 for a random seed based on current time.
  final int seed;
  final int sampleMethod;
  final int schedule;
  /// Number of CPU threads. -1 = auto-detect.
  final int threads;
  final int wtype;
}
