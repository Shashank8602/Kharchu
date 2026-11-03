import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Scripted HTTP responses: each request pops the next one.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.script);
  final List<FutureOr<ResponseBody> Function(RequestOptions)> script;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (script.isEmpty) throw StateError('unexpected request to ${options.path}');
    return script.removeAt(0)(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(Object body, {int status = 200, Map<String, List<String>>? headers}) =>
    ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...?headers,
    });

ResponseBody errorBody(int status, String message,
        {Map<String, List<String>>? headers}) =>
    json({'error': {'message': message}}, status: status, headers: headers);


Map<String, dynamic> chatCompletion({String? content, List<Map<String, dynamic>>? calls}) => {
      'choices': [
        {
          'message': {
            'role': 'assistant',
            'content': content,
            'tool_calls': ?calls,
          }
        }
      ],
      'usage': {'total_tokens': 263},
    };

/// Builds the exception Dio raises when the device is offline.
class DioExceptionShim {
  static DioException offline(RequestOptions o) =>
      DioException.connectionError(requestOptions: o, reason: 'no internet');
}
