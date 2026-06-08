import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'generate_params.dart';

/// Flutter ↔ Swift channel for on-device MLX LLM inference.
///
/// macOS専用（Apple Silicon + macOS 14+が必要）。
/// 他のプラットフォームでは [isSupported] が false を返し、
/// 呼び出しはすべてno-opになります。
class MlxLlm {
  MlxLlm._();

  static const _channel = MethodChannel('dev.normidar.assisbant/mlx_llm');
  static const _tokenChannel =
      EventChannel('dev.normidar.assisbant/mlx_llm/tokens');

  /// true if this platform can run MLX inference (macOS only).
  static bool get isSupported => !kIsWeb && Platform.isMacOS;

  /// Load an MLX model from [directoryPath].
  ///
  /// [directoryPath] must point to a directory containing
  /// `config.json`, `tokenizer.json`, and `*.safetensors` weights
  /// as produced by `mlx_lm.convert` (or the `gguf_to_mlx.py` tool).
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> loadModel(String directoryPath) async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('loadModel', {'path': directoryPath});
  }

  /// Stream generated text tokens for [prompt].
  ///
  /// Each yielded [String] is a decoded text chunk (one or more characters).
  /// The stream closes when generation completes or is cancelled.
  ///
  /// Example:
  /// ```dart
  /// final buf = StringBuffer();
  /// await for (final token in MlxLlm.generate('Hello!')) {
  ///   buf.write(token);
  ///   setState(() => _output = buf.toString());
  /// }
  /// ```
  static Stream<String> generate(
    String prompt, {
    GenerateParams params = const GenerateParams(),
  }) async* {
    if (!isSupported) {
      throw UnsupportedError('MLX inference is only supported on macOS.');
    }
    // Store the pending request on the native side before subscribing to the
    // token stream.  onListen in Swift checks for a pending request and starts
    // generation immediately when the stream is first listened to.
    await _channel.invokeMethod<void>('setGenerateRequest', {
      'prompt': prompt,
      ...params.toMap(),
    });
    yield* _tokenChannel.receiveBroadcastStream().cast<String>();
  }

  /// Cancel an in-progress generation.
  static Future<void> cancelGeneration() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('cancelGeneration');
  }

  /// Unload the current model and free memory.
  static Future<void> disposeModel() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('disposeModel');
  }
}
