import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fitrix/core/constants/app_constants.dart';

class ChatApiService {
  final String baseUrl;

  ChatApiService({
    this.baseUrl = AppConstants.apiBaseUrl,
  });

  Future<String> sendMessage(String message, String conversationId) async {
    try {
      final url = Uri.parse('$baseUrl${AppConstants.chatEndpoint}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'message': message,
              'conversationId': conversationId,
            }),
          )
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'Sorry, I could not process your request.';
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback for when backend is not available
      return _getMockResponse(message);
    }
  }

  String _getMockResponse(String message) {
    // Mock responses for testing without backend
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
