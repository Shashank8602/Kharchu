import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/data/key_store.dart';
import 'package:kharchu/services/groq/groq_client.dart';
import 'package:kharchu/services/groq/groq_errors.dart';
import 'package:kharchu/services/groq/rate_limiter.dart';

import 'fake_http.dart';

void main() {
  late FakeAdapter adapter;
  late KeyStore keys;

  GroqClient make({KeyStore? keyStore, ModelConfig? cfg, RateLimiter? limiter}) {
    final dio = Dio(BaseOptions(baseUrl: GroqClient.baseUrl))
      ..httpClientAdapter = adapter;
    return GroqClient(
      dio: dio,
      keyStore: keyStore ?? keys,
      models: () =>
          cfg ??
          const ModelConfig(
            chatModel: 'openai/gpt-oss-120b',
            fallbackModel: 'openai/gpt-oss-20b',
            voiceModel: 'whisper-large-v3',
          ),
      limiter: limiter ?? RateLimiter(delay: (_) async {}),
    );
  }

  final msgs = [
    {'role': 'user', 'content': 'hi'}
  ];

  setUp(() {
    adapter = FakeAdapter([]);
    keys = MemoryKeyStore('gsk_test_key');
  });

  group('chat', () {
    test('plain answer is parsed and trimmed', () async {
      adapter.script.add((_) => json(chatCompletion(content: '  You spent ₹5,120.  ')));
      final r = await make().chat(messages: msgs);
      expect(r.content, 'You spent ₹5,120.');
      expect(r.toolCalls, isEmpty);
      expect(r.totalTokens, 263);
    });

    test('tool call is parsed, arguments kept as raw text', () async {
      adapter.script.add((_) => json(chatCompletion(calls: [
            {
              'id': 'fc_1',
              'type': 'function',
              'function': {
                'name': 'propose_add_expense',
                'arguments': '{"amount_rupees":1000,"item":"Chats"}',
              }
            }
          ])));
      final r = await make().chat(messages: msgs, tools: [
        {'type': 'function', 'function': {'name': 'propose_add_expense'}}
      ]);
      expect(r.content, isNull);
      expect(r.toolCalls.single.name, 'propose_add_expense');
      expect(r.toolCalls.single.arguments, '{"amount_rupees":1000,"item":"Chats"}');
    });

    test('malformed tool arguments are passed through, not crashed on', () async {
      adapter.script.add((_) => json(chatCompletion(calls: [
            {
              'id': 'fc_1',
              'type': 'function',
              'function': {'name': 'x', 'arguments': '{"amount": '},
            }
          ])));
      final r = await make().chat(messages: msgs);
      expect(r.toolCalls.single.arguments, '{"amount": ');
    });

    test('arguments sent as an object are re-encoded', () async {
      adapter.script.add((_) => json(chatCompletion(calls: [
            {
              'id': 'fc_1',
              'type': 'function',
              'function': {'name': 'x', 'arguments': {'a': 1}},
            }
          ])));
      final r = await make().chat(messages: msgs);
      expect(jsonDecode(r.toolCalls.single.arguments), {'a': 1});
    });

    test('empty content and no tool calls gives null content', () async {
      adapter.script.add((_) => json(chatCompletion(content: '   ')));
      final r = await make().chat(messages: msgs);
      expect(r.content, isNull);
      expect(r.toolCalls, isEmpty);
    });

    test('a response with no choices is a bad response', () async {
      adapter.script.add((_) => json({'choices': []}));
      expect(() => make().chat(messages: msgs), throwsA(isA<GroqBadResponse>()));
    });

    test('a response of the wrong shape is a bad response, not a crash', () async {
      adapter.script.add((_) => json({'oops': true}));
      expect(() => make().chat(messages: msgs), throwsA(isA<GroqBadResponse>()));
    });

    test('request carries key, model, reasoning_effort and tools', () async {
      adapter.script.add((_) => json(chatCompletion(content: 'ok')));
      await make().chat(messages: msgs, tools: [
        {'type': 'function', 'function': {'name': 't'}}
      ]);
      final req = adapter.requests.single;
      expect(req.headers['Authorization'], 'Bearer gsk_test_key');
      final body = req.data as Map;
      expect(body['model'], 'openai/gpt-oss-120b');
      expect(body['reasoning_effort'], 'low');
      expect(body['tool_choice'], 'auto');
      expect(body['max_completion_tokens'], 700);
    });

    test('non gpt-oss models get no reasoning_effort', () async {
      adapter.script.add((_) => json(chatCompletion(content: 'ok')));
      await make(
        cfg: const ModelConfig(
            chatModel: 'qwen/qwen3.8-27b', fallbackModel: '', voiceModel: 'w'),
      ).chat(messages: msgs);
      expect((adapter.requests.single.data as Map).containsKey('reasoning_effort'), isFalse);
    });

    test('tools are omitted when the list is empty', () async {
      adapter.script.add((_) => json(chatCompletion(content: 'ok')));
      await make().chat(messages: msgs, tools: []);
      final body = adapter.requests.single.data as Map;
      expect(body.containsKey('tools'), isFalse);
      expect(body.containsKey('tool_choice'), isFalse);
    });
  });

  group('errors', () {
    test('no key', () async {
      expect(() => make(keyStore: MemoryKeyStore()).chat(messages: msgs),
          throwsA(isA<GroqNoKey>()));
      expect(() => make(keyStore: MemoryKeyStore('   ')).chat(messages: msgs),
          throwsA(isA<GroqNoKey>()));
      expect(adapter.requests, isEmpty, reason: 'must not call the network');
    });

    test('401 and 403 mean the key was rejected', () async {
      adapter.script.add((_) => errorBody(401, 'Invalid API Key'));
      adapter.script.add((_) => errorBody(403, 'forbidden'));
      await expectLater(make().chat(messages: msgs), throwsA(isA<GroqUnauthorized>()));
      await expectLater(make().chat(messages: msgs), throwsA(isA<GroqUnauthorized>()));
    });

    test('429 on the main model falls back to the second model', () async {
      adapter.script.add((_) => errorBody(429, 'rate limit'));
      adapter.script.add((_) => json(chatCompletion(content: 'from fallback')));
      final r = await make().chat(messages: msgs);
      expect(r.content, 'from fallback');
      expect(r.model, 'openai/gpt-oss-20b');
      expect((adapter.requests[0].data as Map)['model'], 'openai/gpt-oss-120b');
      expect((adapter.requests[1].data as Map)['model'], 'openai/gpt-oss-20b');
    });

    test('429 on both models reports the wait time', () async {
      adapter.script.add((_) => errorBody(429, 'limit', headers: {'retry-after': ['7']}));
      adapter.script.add((_) => errorBody(429, 'limit', headers: {'retry-after': ['12']}));
      try {
        await make().chat(messages: msgs);
        fail('should throw');
      } on GroqRateLimited catch (e) {
        expect(e.retryAfterSeconds, 12);
        expect(e.userMessage, 'Busy right now. Try again in 12s.');
        expect(e.canRetry, isTrue);
      }
    });

    test('429 with no fallback configured rethrows without a second call', () async {
      adapter.script.add((_) => errorBody(429, 'limit'));
      await expectLater(
        make(
          cfg: const ModelConfig(
              chatModel: 'openai/gpt-oss-120b', fallbackModel: '', voiceModel: 'w'),
        ).chat(messages: msgs),
        throwsA(isA<GroqRateLimited>()),
      );
      expect(adapter.requests.length, 1);
    });

    test('429 when fallback equals the main model does not loop', () async {
      adapter.script.add((_) => errorBody(429, 'limit'));
      await expectLater(
        make(
          cfg: const ModelConfig(
              chatModel: 'm', fallbackModel: 'm', voiceModel: 'w'),
        ).chat(messages: msgs),
        throwsA(isA<GroqRateLimited>()),
      );
      expect(adapter.requests.length, 1);
    });

    test('retry-after that is junk or fractional is handled', () async {
      adapter.script.add((_) => errorBody(429, 'x', headers: {'retry-after': ['soon']}));
      adapter.script.add((_) => errorBody(429, 'x', headers: {'retry-after': ['2.3']}));
      try {
        await make().chat(messages: msgs);
      } on GroqRateLimited catch (e) {
        expect(e.retryAfterSeconds, 3);
      }
    });

    test('a network failure is reported as a network error', () async {
      adapter.script.add((o) => throw DioException.connectionError(
          requestOptions: o, reason: 'no internet'));
      expect(() => make().chat(messages: msgs), throwsA(isA<GroqNetworkError>()));
    });

    test('a timeout is reported as a network error', () async {
      adapter.script.add((o) => throw DioException.receiveTimeout(
          timeout: const Duration(seconds: 45), requestOptions: o));
      expect(() => make().chat(messages: msgs), throwsA(isA<GroqNetworkError>()));
    });

    test('5xx is a server error that can be retried', () async {
      adapter.script.add((_) => errorBody(503, 'unavailable'));
      try {
        await make().chat(messages: msgs);
        fail('should throw');
      } on GroqServerError catch (e) {
        expect(e.statusCode, 503);
        expect(e.canRetry, isTrue);
      }
    });

    test('404 and a retired-model 400 both say the model is unavailable', () async {
      adapter.script.add((_) => errorBody(404, 'not found'));
      adapter.script.add((_) => errorBody(
          400, 'The model `llama-3.3-70b-versatile` has been decommissioned'));
      await expectLater(make().chat(messages: msgs), throwsA(isA<GroqModelNotFound>()));
      try {
        await make().chat(messages: msgs);
      } on GroqModelNotFound catch (e) {
        expect(e.needsProfile, isTrue);
        expect(e.userMessage, contains('Profile'));
      }
    });

    test('other 400s are bad requests, never exposing technical detail', () async {
      adapter.script.add((_) => errorBody(400, 'tool call validation failed: ...'));
      try {
        await make().chat(messages: msgs);
        fail('should throw');
      } on GroqBadRequest catch (e) {
        expect(e.userMessage, "Couldn't understand that, try rephrasing.");
        expect(e.detail, contains('validation'));
      }
    });

    test('an error body that is not JSON does not crash mapping', () async {
      adapter.script.add((_) => ResponseBody.fromString('<html>bad gateway</html>', 502));
      expect(() => make().chat(messages: msgs), throwsA(isA<GroqServerError>()));
    });

    test('the key never appears in any error message', () async {
      adapter.script.add((_) => errorBody(401, 'Invalid API Key gsk_test_key'));
      try {
        await make().chat(messages: msgs);
      } on GroqException catch (e) {
        expect(e.userMessage, isNot(contains('gsk_')));
        expect(e.toString(), isNot(contains('gsk_')));
      }
    });
  });

  group('transcribe', () {
    test('returns the trimmed transcript and sends model, prompt and no language by default',
        () async {
      adapter.script.add((_) => json({'text': '  ನಿನ್ನೆ ಪೆಟ್ರೋಲ್‌ಗೆ 500 ರೂಪಾಯಿ  '}));
      final text = await make().transcribe(Uint8List.fromList([1, 2, 3]));
      expect(text, 'ನಿನ್ನೆ ಪೆಟ್ರೋಲ್‌ಗೆ 500 ರೂಪಾಯಿ');
      final form = adapter.requests.single.data as FormData;
      final fields = {for (final f in form.fields) f.key: f.value};
      expect(fields['model'], 'whisper-large-v3');
      expect(fields['temperature'], '0');
      expect(fields['prompt'], GroqClient.voicePrompt);
      expect(fields.containsKey('language'), isFalse);
      expect(form.files.single.key, 'file');
    });

    test('sends the language when one is chosen', () async {
      adapter.script.add((_) => json({'text': 'hello'}));
      await make(
        cfg: const ModelConfig(
            chatModel: 'a', fallbackModel: 'b', voiceModel: 'whisper-large-v3',
            voiceLanguage: 'kn'),
      ).transcribe(Uint8List(4));
      final form = adapter.requests.single.data as FormData;
      expect({for (final f in form.fields) f.key: f.value}['language'], 'kn');
    });

    test('silence gives an empty transcript, not an error', () async {
      adapter.script.add((_) => json({'text': ''}));
      expect(await make().transcribe(Uint8List(4)), '');
    });

    test('a response without text is a bad response', () async {
      adapter.script.add((_) => json({'nope': 1}));
      expect(() => make().transcribe(Uint8List(4)), throwsA(isA<GroqBadResponse>()));
    });

    test('errors map the same way as chat', () async {
      adapter.script.add((_) => errorBody(429, 'limit', headers: {'retry-after': ['5']}));
      adapter.script.add((_) => errorBody(401, 'bad'));
      await expectLater(make().transcribe(Uint8List(4)), throwsA(isA<GroqRateLimited>()));
      await expectLater(make().transcribe(Uint8List(4)), throwsA(isA<GroqUnauthorized>()));
    });

    test('no key means no network call', () async {
      expect(() => make(keyStore: MemoryKeyStore()).transcribe(Uint8List(4)),
          throwsA(isA<GroqNoKey>()));
      expect(adapter.requests, isEmpty);
    });
  });

  group('testKey', () {
    test('succeeds on 200', () async {
      adapter.script.add((_) => json({'data': []}));
      await make().testKey();
      expect(adapter.requests.single.path, '/models');
    });

    test('fails clearly on a bad key', () async {
      adapter.script.add((_) => errorBody(401, 'bad'));
      expect(() => make().testKey(), throwsA(isA<GroqUnauthorized>()));
    });

    test('fails clearly with no key', () async {
      expect(() => make(keyStore: MemoryKeyStore()).testKey(), throwsA(isA<GroqNoKey>()));
    });
  });

  group('RateLimiter', () {
    test('lets requests through under the cap without waiting', () async {
      var waited = 0;
      final l = RateLimiter(maxPerMinute: 3, delay: (d) async => waited++);
      for (var i = 0; i < 3; i++) {
        await l.acquire();
      }
      expect(waited, 0);
    });

    test('waits once the cap is reached, then proceeds when the window moves',
        () async {
      var t = DateTime(2026, 10, 24, 12, 0, 0);
      final waits = <Duration>[];
      final l = RateLimiter(
        maxPerMinute: 2,
        now: () => t,
        delay: (d) async {
          waits.add(d);
          t = t.add(d);
        },
      );
      await l.acquire();
      t = t.add(const Duration(seconds: 10));
      await l.acquire();
      await l.acquire(); // third: must wait for the first to age out
      expect(waits.length, 1);
      expect(waits.first.inSeconds, inInclusiveRange(50, 51));
    });
  });
}
