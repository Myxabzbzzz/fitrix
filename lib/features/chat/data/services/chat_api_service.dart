import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';

export 'package:fitrix/features/chat/data/models/chat_message.dart'
    show ChatFailure;

/// A reply that couldn't be produced, and why.
class ChatException implements Exception {
  final ChatFailure failure;

  /// What went wrong, for logs only (never shown: the chat shows [failure]).
  final String? detail;

  ChatException(this.failure, [this.detail]);

  @override
  String toString() =>
      'ChatException(${failure.name}${detail == null ? '' : ': $detail'})';
}

class ChatApiService {
  final Dio _dio;

  /// Returns the signed-in user's Supabase access token, or null when there
  /// is none. Sent as `Authorization: Bearer <token>`; the backend rejects
  /// chat requests without a valid one (unless its auth is turned off).
  final Future<String?> Function()? _accessToken;

  ChatApiService({
    String? baseUrl,
    Dio? dio,
    Future<String?> Function()? accessToken,
  })  : _accessToken = accessToken,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConstants.apiBaseUrl,
                connectTimeout: AppConstants.apiConnectTimeout,
                receiveTimeout: AppConstants.apiReceiveTimeout,
                contentType: Headers.jsonContentType,
              ),
            );

  /// Streams Felix's reply as text chunks as soon as the model produces them.
  ///
  /// Any failure (backend unreachable, Ollama down, stream cut off, ...)
  /// throws a [ChatException] so the chat can mark the question and offer a
  /// retry. Nothing is ever made up in Felix's place.
  ///
  /// Optional context for the backend:
  /// - [topic]: which Felix persona answers ("app", "gym", "running", ...).
  /// - [profile]: what Felix knows about the user (name, age, weightKg,
  ///   heightCm); omitted when empty.
  /// - [history]: recent `{role, content}` turns, oldest first, without
  ///   [message]. When sent, the backend uses it instead of its own memory,
  ///   so the chat stored on the device is the source of truth.
  /// - [language]: the app's language code; Felix uses it when the user's
  ///   own language isn't clear from the message.
  /// - [context]: what the app knows about the user's day (plan, check-in,
  ///   food, ...); omitted when empty.
  /// - [images]: at most one base64 JPEG (<= 1.5 MB decoded) for this turn
  ///   only; the backend then answers with its vision model.
  /// - [onAction]: called with the change Felix proposes (at most one per
  ///   reply, before the stream ends); invalid actions are ignored.
  Stream<String> streamMessage(
    String message,
    String conversationId, {
    String? topic,
    Map<String, Object>? profile,
    List<Map<String, String>>? history,
    String? language,
    Map<String, Object>? context,
    List<String>? images,
    void Function(ChatAction action)? onAction,
  }) async* {
    final token = await _currentToken();
    final Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        AppConstants.chatStreamEndpoint,
        data: {
          'message': message,
          'conversationId': conversationId,
          if (topic != null) 'topic': topic,
          if (profile != null && profile.isNotEmpty) 'profile': profile,
          if (history != null) 'history': history,
          if (language != null) 'language': language,
          if (context != null && context.isNotEmpty) 'context': context,
          if (images != null && images.isNotEmpty) 'images': images,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
          responseType: ResponseType.stream,
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      debugPrint(
        'FITRIX backend unreachable at ${_dio.options.baseUrl} '
        '(${e.type.name}).',
      );
      throw ChatException(ChatFailure.unavailable, e.type.name);
    }

    final lines = response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    if (response.statusCode != 200) {
      final body = await lines.join('\n');
      switch (response.statusCode) {
        case 401:
          throw ChatException(ChatFailure.signInAgain, body);
        case 413:
          // Only a photo makes a request that large.
          throw ChatException(ChatFailure.photoUnavailable, body);
        case 429:
          throw ChatException(ChatFailure.tooFast, body);
      }
      throw ChatException(ChatFailure.unavailable, _serverError(body));
    }

    var done = false;
    try {
      await for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final data = jsonDecode(line) as Map<String, dynamic>;
        final error = data['error'];
        if (error != null) {
          throw ChatException(ChatFailure.unavailable, error.toString());
        }
        final delta = data['delta'];
        if (delta is String && delta.isNotEmpty) yield delta;
        final action = ChatAction.tryParse(data['action']);
        if (action != null) onAction?.call(action);
        if (data['done'] == true) {
          done = true;
          break;
        }
      }
    } on DioException catch (e) {
      throw ChatException(ChatFailure.interrupted, e.type.name);
    } on FormatException catch (e) {
      throw ChatException(ChatFailure.unreadable, e.message);
    }

    if (!done) throw ChatException(ChatFailure.interrupted, 'no "done"');
  }

  Future<String?> _currentToken() async {
    final accessToken = _accessToken;
    if (accessToken == null) return null;
    try {
      final token = await accessToken();
      return (token == null || token.isEmpty) ? null : token;
    } catch (e) {
      // No token (e.g. a refresh failed offline): send the request anyway;
      // the backend answers 401 if it needs one.
      debugPrint('Could not get an access token for the chat: $e');
      return null;
    }
  }

  /// The backend's own error text, for logs.
  String _serverError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return (data['message'] ?? data['error'] ?? body).toString();
    } on FormatException {
      return body;
    }
  }
}
