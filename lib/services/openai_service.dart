import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class OpenAIService {
  static bool _isInitialized = false;
  static String? _apiKey;
  static const String _defaultModel = 'gpt-3.5-turbo';
  static const String _apiEndpoint =
      'https://api.openai.com/v1/chat/completions';

  /// Initialize with API key from .env file
  static void initialize() {
    if (!_isInitialized) {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        _apiKey = apiKey;
        _isInitialized = true;
        debugPrint('OpenAI service initialized with API key from .env');
      } else {
        debugPrint('Warning: OpenAI API key not found in .env file');
      }
    }
  }

  static bool get isInitialized => _isInitialized;

  /// Create a system prompt that includes movie context
  static String _createSystemPrompt(Movie movie) {
    return '''
You are MovieVerse AI, a helpful assistant with deep knowledge about movies, actors, directors, and cinema.
You're currently discussing the movie "${movie.title}" (${movie.releaseYear}).

Movie details:
${movie.overview ?? 'No overview available.'}

Answer questions about this movie, provide interesting facts, analyses, or recommendations based on this movie.
Keep your responses concise, informative, and engaging. If you don't know specific information about this movie,
you can make educated guesses based on your knowledge of cinema, but clearly indicate when you're speculating.
''';
  }

  /// Send a message to OpenAI and get a response
  static Future<String> sendMessage({
    required String message,
    required Movie movie,
    required List<Map<String, String>> chatHistory,
    String model = _defaultModel,
  }) async {
    if (!_isInitialized || _apiKey == null) {
      return 'Movie chat is currently unavailable. Please make sure the OPENAI_API_KEY is set in the .env file.';
    }

    try {
      // Prepare the messages for the API call
      final messages = [
        // System message with movie context
        {
          'role': 'system',
          'content': _createSystemPrompt(movie),
        },
      ];

      // Add chat history
      for (final chat in chatHistory) {
        if (chat.containsKey('user')) {
          messages.add({
            'role': 'user',
            'content': chat['user'] ?? '',
          });
        }
        if (chat.containsKey('assistant')) {
          messages.add({
            'role': 'assistant',
            'content': chat['assistant'] ?? '',
          });
        }
      }

      // Add the current user message
      messages.add({
        'role': 'user',
        'content': message,
      });

      // Prepare the request body
      final requestBody = jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.7,
      });

      // Make the API call
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ??
            'Sorry, I couldn\'t generate a response.';
      } else {
        debugPrint('Error from OpenAI API: ${response.body}');
        return 'Sorry, I encountered an error (${response.statusCode}) while processing your request.';
      }
    } catch (e) {
      debugPrint('Error calling OpenAI API: $e');
      return 'Sorry, I encountered an error while processing your request. Please try again later.';
    }
  }
}
