/// sd_type_t — weight/quantization type
abstract final class SdType {
  static const int f32 = 0;
  static const int f16 = 1;
  static const int q4_0 = 2;
  static const int q4_1 = 3;
  static const int q5_0 = 6;
  static const int q5_1 = 7;
  static const int q8_0 = 8;
  static const int q8_1 = 9;
  static const int q8K = 15;

  /// SD_TYPE_COUNT (42) — let the library choose automatically
  static const int auto_ = 42;
}

/// rng_type_t
abstract final class SdRng {
  static const int stdDefault = 0;
  static const int cuda = 1;
  static const int cpu = 2;
}

/// scheduler_t  (from stable-diffusion.h, commit 0e4ee04+)
abstract final class SdSchedule {
  static const int discrete = 0;
  static const int karras = 1;
  static const int exponential = 2;
  static const int ays = 3;
  static const int gits = 4;
  static const int sgmUniform = 5;
  static const int simple = 6;
  static const int smoothstep = 7;
  static const int klOptimal = 8;
  static const int lcm = 9;

  /// Use library default (set by sd_img_gen_params_init)
  static const int useDefault = -1;
}

/// sample_method_t  (from stable-diffusion.h, commit 0e4ee04+)
abstract final class SdSampleMethod {
  static const int euler = 0;
  static const int eulerA = 1;
  static const int heun = 2;
  static const int dpm2 = 3;
  static const int dpmpp2sA = 4;
  static const int dpmpp2m = 5;
  static const int dpmpp2mv2 = 6;
  static const int ipndm = 7;
  static const int ipndmV = 8;
  static const int lcm = 9;
  static const int ddimTrailing = 10;
  static const int tcd = 11;

  /// Use library default (set by sd_img_gen_params_init)
  static const int useDefault = -1;
}
