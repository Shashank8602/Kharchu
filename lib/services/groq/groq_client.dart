import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../data/key_store.dart';
import 'groq_errors.dart';
import 'rate_limiter.dart';

class ToolCall {
  const ToolCall({required this.id, required this.name, required this.arguments});
  final String id;
  final String name;

  /// Raw JSON text exactly as the model produced it. The agent parses and
  /// validates it, because models sometimes return malformed JSON.
  final String arguments;
}

class ChatResult {
  const ChatResult({
    this.content,
    this.toolCalls = const [],
    this.totalTokens = 0,
    this.model,
  });
  final String? content;
  final List<ToolCall> toolCalls;
  final int totalTokens;

  /// The model that actually answered (the fallback, if the first was limited).
  final String? model;
}

class ModelConfig {
  const ModelConfig({
    required this.chatModel,
    required this.fallbackModel,
    required this.voiceModel,
    this.voiceLanguage = 'auto',
  });
  final String chatModel;
  final String fallbackModel;
  final String voiceModel;
  final String voiceLanguage;
}

/// The only network code in the app. No third-party AI package: two endpoints.
class GroqClient {
  GroqClient({
    required this.dio,
    required this.keyStore,
    required this.models,
    RateLimiter? limiter,
  }) : _limiter = limiter ?? RateLimiter();

  static const baseUrl = 'https://api.groq.com/openai/v1';

  /// Hint that helps Whisper with the words this app hears.
  static const voicePrompt =
      'Expense or lending note in English or Kannada. Rupees, UPI, GPay, '
      'PhonePe, lent, borrowed, Bengaluru.';

  final Dio dio;
  final KeyStore keyStore;
  final ModelConfig Function() models;
  final RateLimiter _limiter;

  static Dio buildDio() => Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 45),
      ));

  Future<String> _requireKey() async {
    final k = await keyStore.read();
    if (k == null || k.isEmpty) throw const GroqNoKey();
    return k;
  }

  /// One chat completion. If the main model is rate limited, the fallback
  /// model (its own separate quota) is tried once.
  Future<ChatResult> chat({
    required List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
    int maxTokens = 700,
  }) async {
    final key = await _requireKey();
    final cfg = models();
    try {
      return await _chatWith(cfg.chatModel, key, messages, tools, maxTokens);
    } on GroqRateLimited {
      final fb = cfg.fallbackModel.trim();
      if (fb.isEmpty || fb == cfg.chatModel) rethrow;
      return _chatWith(fb, key, messages, tools, maxTokens);
    }
  }

  Future<ChatResult> _chatWith(
    String model,
    String key,
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
    int maxTokens,
  ) async {
    await _limiter.acquire();
    final body = <String, dynamic>{
      'model': model,
      'temperature': 0.1,
      'max_completion_tokens': maxTokens,
      // a copy, so later changes to the caller's list never alter this request
      'messages': List<Map<String, dynamic>>.of(messages),
      if (model.startsWith('openai/gpt-oss')) 'reasoning_effort': 'low',
      if (tools != null && tools.isNotEmpty) ...{
        'tools': tools,
        'tool_choice': 'auto',
      },
    };
    final data = await _send(
      () => dio.post<dynamic>(
        '/chat/completions',
        data: body,
        options: Options(headers: _headers(key)),
      ),
      model,
    );
    return _parseChat(data, model);
  }

  ChatResult _parseChat(dynamic data, String model) {
    try {
      final map = data as Map;
      final choices = map['choices'] as List;
      if (choices.isEmpty) throw const GroqBadResponse('no choices');
      final message = (choices.first as Map)['message'] as Map;
      final content = message['content'] as String?;
      final calls = <ToolCall>[];
      final raw = message['tool_calls'];
      if (raw is List) {
        for (final c in raw) {
          final m = c as Map;
          final fn = m['function'] as Map;
          final args = fn['arguments'];
          calls.add(ToolCall(
            id: (m['id'] ?? '').toString(),
            name: fn['name'] as String,
            arguments: args is String ? args : jsonEncode(args ?? {}),
          ));
        }
      }
      final usage = map['usage'];
      return ChatResult(
        content: (content == null || content.trim().isEmpty) ? null : content.trim(),
        toolCalls: calls,
        totalTokens: usage is Map ? (usage['total_tokens'] as num?)?.toInt() ?? 0 : 0,
        model: model,
      );
    } on GroqException {
      rethrow;
    } catch (e) {
      throw GroqBadResponse('unexpected shape: $e');
    }
  }

  /// Speech to text. Returns the transcript (possibly empty if nothing was
  /// heard).
  Future<String> transcribe(Uint8List audio, {String fileName = 'audio.m4a'}) async {
    final key = await _requireKey();
    final cfg = models();
    await _limiter.acquire();
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(audio, filename: fileName),
      'model': cfg.voiceModel,
      'response_format': 'json',
      'temperature': '0',
      'prompt': voicePrompt,
      if (cfg.voiceLanguage != 'auto') 'language': cfg.voiceLanguage,
    });
    final data = await _send(
      () => dio.post<dynamic>(
        '/audio/transcriptions',
        data: form,
        options: Options(headers: _headers(key)),
      ),
      cfg.voiceModel,
    );
    if (data is Map && data['text'] is String) {
      return (data['text'] as String).trim();
    }
    throw const GroqBadResponse('no transcript');
  }

  /// Checks that the key works. Throws a [GroqException] if not.
  Future<void> testKey() async {
    final key = await _requireKey();
    await _send(
      () => dio.get<dynamic>('/models', options: Options(headers: _headers(key))),
      '',
    );
  }

  Map<String, String> _headers(String key) => {'Authorization': 'Bearer $key'};

  Future<dynamic> _send(Future<Response<dynamic>> Function() call, String model) async {
    try {
      final res = await call();
      return res.data;
    } on DioException catch (e) {
      throw _map(e, model);
    }
  }

  GroqException _map(DioException e, String model) {
    final res = e.response;
    if (res == null) return const GroqNetworkError();
    final status = res.statusCode ?? 0;
    final detail = _errorMessage(res.data);
    if (status == 401 || status == 403) return const GroqUnauthorized();
    if (status == 404) return GroqModelNotFound(model);
    if (status == 429) {
      return GroqRateLimited(retryAfterSeconds: _retryAfter(res.headers));
    }
    if (status == 400 || status == 422) {
      // Groq reports a retired or unknown model as a 400 with a message.
      final lower = detail.toLowerCase();
      if (lower.contains('model') &&
          (lower.contains('not found') ||
              lower.contains('does not exist') ||
              lower.contains('decommissioned') ||
              lower.contains('not supported'))) {
        return GroqModelNotFound(model);
      }
      return GroqBadRequest(detail);
    }
    if (status >= 500) return GroqServerError(status);
    return GroqBadRequest('HTTP $status: $detail');
  }

  static int? _retryAfter(Headers headers) {
    final v = headers.value('retry-after');
    if (v == null) return null;
    final n = double.tryParse(v.trim());
    if (n == null) return null;
    return n.ceil().clamp(1, 3600);
  }

  static String _errorMessage(dynamic data) {
    try {
      if (data is Map && data['error'] is Map) {
        return ((data['error'] as Map)['message'] ?? '').toString();
      }
    } catch (_) {}
    return '';
  }
}
