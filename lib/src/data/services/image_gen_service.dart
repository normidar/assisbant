import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class ImageGenResult {
  const ImageGenResult({required this.bytes, this.seed});
  final Uint8List bytes;
  final int? seed;
}

class ImageGenService {
  static String _base(String apiUrl) {
    var url = apiUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static Future<ImageGenResult> generate({
    required String apiUrl,
    required String prompt,
    String negativePrompt = '',
    String model = '',
    int width = 512,
    int height = 512,
    int steps = 20,
  }) async {
    final uri = Uri.parse('${_base(apiUrl)}/sdapi/v1/txt2img');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'prompt': prompt,
        'negative_prompt': negativePrompt,
        'width': width,
        'height': height,
        'steps': steps,
        'sampler_name': 'DPM++ 2M Karras',
        if (model.isNotEmpty)
          'override_settings': {'sd_model_checkpoint': model},
      });
      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final images = (json['images'] as List<dynamic>).cast<String>();
      if (images.isEmpty) throw Exception('No images in response');
      int? seed;
      try {
        final info = jsonDecode(json['info'] as String) as Map<String, dynamic>;
        seed = info['seed'] as int?;
      } catch (_) {}
      return ImageGenResult(bytes: base64Decode(images.first), seed: seed);
    } finally {
      client.close();
    }
  }

  static Future<List<String>> getModels(String apiUrl) async {
    final uri = Uri.parse('${_base(apiUrl)}/sdapi/v1/sd-models');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) return [];
      final responseBody = await response.transform(utf8.decoder).join();
      final list = jsonDecode(responseBody) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map<String>(
            (m) => m['model_name'] as String? ?? m['title'] as String? ?? '',
          )
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }
}
