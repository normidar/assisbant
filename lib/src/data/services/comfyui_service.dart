import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ComfyUIResult {
  const ComfyUIResult({required this.bytes, required this.seed});
  final Uint8List bytes;
  final int seed;
}

class ComfyUIService {
  static Future<ComfyUIResult> generate({
    required String baseUrl,
    required String prompt,
    required String unetName,
    required String clipName,
    required String vaeName,
    int width = 1024,
    int height = 1024,
    int steps = 8,
    int seed = -1,
  }) async {
    final clientId = const Uuid().v4();
    final actualSeed = seed < 0 ? Random().nextInt(0x7fffffff) : seed;
    final base = _strip(baseUrl);

    final postResp = await http.post(
      Uri.parse('$base/prompt'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'client_id': clientId,
        'prompt': _buildWorkflow(
          prompt: prompt,
          unetName: unetName,
          clipName: clipName,
          vaeName: vaeName,
          width: width,
          height: height,
          steps: steps,
          seed: actualSeed,
        ),
      }),
    );

    if (postResp.statusCode != 200) {
      throw Exception(
          'ComfyUI /prompt HTTP ${postResp.statusCode}\n${postResp.body}');
    }

    final promptId =
        (jsonDecode(postResp.body) as Map<String, dynamic>)['prompt_id']
            as String;

    final wsBase = base.replaceFirst(RegExp(r'^http'), 'ws');
    final channel = WebSocketChannel.connect(
        Uri.parse('$wsBase/ws?client_id=$clientId'));

    String? filename;
    String? subfolder;

    try {
      await for (final raw in channel.stream) {
        final msg = jsonDecode(raw as String) as Map<String, dynamic>;
        final type = msg['type'] as String?;

        if (type == 'execution_error') {
          final data = msg['data'] as Map<String, dynamic>;
          if (data['prompt_id'] == promptId) {
            throw Exception(
                'ComfyUI error: ${data['exception_message']}');
          }
        }

        if (type == 'executed') {
          final data = msg['data'] as Map<String, dynamic>;
          if (data['prompt_id'] != promptId) continue;
          final output = data['output'] as Map<String, dynamic>?;
          final images = output?['images'] as List<dynamic>?;
          if (images != null && images.isNotEmpty) {
            final img = images.first as Map<String, dynamic>;
            filename = img['filename'] as String;
            subfolder = img['subfolder'] as String? ?? '';
            break;
          }
        }
      }
    } finally {
      await channel.sink.close();
    }

    if (filename == null) {
      throw Exception('ComfyUI: no image received');
    }

    final viewUrl = Uri.parse('$base/view').replace(queryParameters: {
      'filename': filename,
      'subfolder': subfolder ?? '',
      'type': 'output',
    });

    final imgResp = await http.get(viewUrl);
    if (imgResp.statusCode != 200) {
      throw Exception('ComfyUI /view HTTP ${imgResp.statusCode}');
    }

    return ComfyUIResult(bytes: imgResp.bodyBytes, seed: actualSeed);
  }

  static String _strip(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  static Map<String, dynamic> _buildWorkflow({
    required String prompt,
    required String unetName,
    required String clipName,
    required String vaeName,
    required int width,
    required int height,
    required int steps,
    required int seed,
  }) =>
      {
        '28': {
          'class_type': 'UNETLoader',
          'inputs': {'unet_name': unetName, 'weight_dtype': 'default'},
        },
        '30': {
          'class_type': 'CLIPLoader',
          'inputs': {
            'clip_name': clipName,
            'type': 'lumina2',
            'device': 'default',
          },
        },
        '29': {
          'class_type': 'VAELoader',
          'inputs': {'vae_name': vaeName},
        },
        '27': {
          'class_type': 'CLIPTextEncode',
          'inputs': {'text': prompt, 'clip': ['30', 0]},
        },
        '33': {
          'class_type': 'ConditioningZeroOut',
          'inputs': {'conditioning': ['27', 0]},
        },
        '11': {
          'class_type': 'ModelSamplingAuraFlow',
          'inputs': {'model': ['28', 0], 'shift': 3},
        },
        '13': {
          'class_type': 'EmptySD3LatentImage',
          'inputs': {'width': width, 'height': height, 'batch_size': 1},
        },
        '3': {
          'class_type': 'KSampler',
          'inputs': {
            'seed': seed,
            'steps': steps,
            'cfg': 1,
            'sampler_name': 'res_multistep',
            'scheduler': 'simple',
            'denoise': 1.0,
            'model': ['11', 0],
            'positive': ['27', 0],
            'negative': ['33', 0],
            'latent_image': ['13', 0],
          },
        },
        '8': {
          'class_type': 'VAEDecode',
          'inputs': {'samples': ['3', 0], 'vae': ['29', 0]},
        },
        '9': {
          'class_type': 'SaveImage',
          'inputs': {'images': ['8', 0], 'filename_prefix': 'assisbant'},
        },
      };
}
