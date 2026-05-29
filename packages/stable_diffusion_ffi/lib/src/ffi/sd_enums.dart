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
  /// SD_TYPE_COUNT — let the library choose automatically
  static const int auto_ = 26;
}

/// rng_type_t
abstract final class SdRng {
  static const int stdDefault = 0;
  static const int cuda = 1;
}

/// schedule_t
abstract final class SdSchedule {
  static const int default_ = 0;
  static const int discrete = 1;
  static const int karras = 2;
  static const int exponential = 3;
  static const int aya = 4;
}

/// sample_method_t
abstract final class SdSampleMethod {
  static const int eulerA = 0;
  static const int euler = 1;
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
}
