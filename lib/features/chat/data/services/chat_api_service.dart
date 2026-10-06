import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fitrix/core/constants/app_constants.dart';

/// A reply that couldn't be produced; [message] is shown in the chat.
class ChatException implements Exception {
  final String message;

  ChatException(this.message);

  @override
  String toString() => message;
}

class ChatApiService {
  final Dio _dio;

  ChatApiService({String baseUrl = AppConstants.apiBaseUrl, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: AppConstants.apiConnectTimeout,
                receiveTimeout: AppConstants.apiReceiveTimeout,
                contentType: Headers.jsonContentType,
              ),
            );

  /// Streams Felix's reply as text chunks as soon as the model produces them.
  ///
  /// If the backend can't be reached at all (not running, wrong address) this
  /// falls back to a canned offline reply so onboarding still works. Errors
  /// from a reachable backend (Ollama down, model missing, stream cut off)
  /// throw [ChatException] so the chat can offer a retry.
  ///
  /// Optional context for the backend:
  /// - [topic]: which Felix persona answers ("app", "gym", "running", ...).
  /// - [profile]: what Felix knows about the user (name, age, weightKg,
  ///   heightCm); omitted when empty.
  /// - [history]: recent `{role, content}` turns, oldest first, without
  ///   [message]. When sent, the backend uses it instead of its own memory,
  ///   so the chat stored on the device is the source of truth.
  Stream<String> streamMessage(
    String message,
    String conversationId, {
    String? topic,
    Map<String, Object>? profile,
    List<Map<String, String>>? history,
  }) async* {
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
        },
        options: Options(
          responseType: ResponseType.stream,
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        debugPrint(
          'FITRIX backend unreachable at ${_dio.options.baseUrl} '
          '(${e.type.name}); using offline reply.',
        );
        yield _getMockResponse(message);
        return;
      }
      throw ChatException('Felix is unavailable right now.');
    }

    final lines = response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    if (response.statusCode != 200) {
      final body = await lines.join('\n');
      throw ChatException(_serverError(body));
    }

    var done = false;
    try {
      await for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final data = jsonDecode(line) as Map<String, dynamic>;
        final error = data['error'];
        if (error != null) throw ChatException(error.toString());
        final delta = data['delta'];
        if (delta is String && delta.isNotEmpty) yield delta;
        if (data['done'] == true) {
          done = true;
          break;
        }
      }
    } on DioException {
      throw ChatException('Connection lost while Felix was replying.');
    } on FormatException {
      throw ChatException('Felix sent an unreadable reply.');
    }

    if (!done) {
      throw ChatException('Connection lost while Felix was replying.');
    }
  }

  String _serverError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return (data['message'] ?? data['error'] ?? 'Felix is unavailable.')
          .toString();
    } on FormatException {
      return 'Felix is unavailable right now.';
    }
  }

  String _getMockResponse(String message) {
    // Offline replies so the onboarding flow works without the backend
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('muscle') || lowerMessage.contains('strength')) {
      return 'Nice choice! I like that.\n\nWhich sports or activities do you enjoy (or plan to do)?\nYou can pick more than one 👇';
    } else if (lowerMessage.contains('endurance') || lowerMessage.contains('stamina')) {
      return 'Great goal! Building endurance is key to overall fitness.\n\nWhich sports or activities do you enjoy (or plan to do)?';
    } else if (lowerMessage.contains('weight') || lowerMessage.contains('toned')) {
      return 'Excellent! Let\'s work on getting you toned.\n\nWhich sports or activities do you enjoy (or plan to do)?';
    } else if (lowerMessage.contains('gym')) {
      return 'I see you\'ve chosen Gym, Running, and Skiing — nice combo! Let\'s fine-tune your plan a bit.\n\nHow often do you usually hit the gym?';
    } else if (lowerMessage.contains('week')) {
      return 'Nice! And how would you describe your experience level?';
    } else if (lowerMessage.contains('intermediate') || lowerMessage.contains('beginner')) {
      return 'Got it. Are you focusing more on strength, muscle growth, fat loss, or just general fitness?';
    } else {
      return 'Thanks for sharing! I\'ll help you create a personalized plan based on your goals.';
    }
  }
}
