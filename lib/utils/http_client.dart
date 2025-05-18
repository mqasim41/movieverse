import 'dart:async';
import 'package:http/http.dart' as http;

/// A utility for making HTTP requests with longer timeouts
class HttpUtil {
  /// Default timeout duration
  static const Duration defaultTimeout = Duration(seconds: 60);

  /// Make a GET request with a longer timeout
  static Future<http.Response> getWithTimeout(
    String url, {
    Map<String, String>? headers,
    Duration timeout = defaultTimeout,
  }) async {
    try {
      final uri = Uri.parse(url);
      final client = http.Client();

      try {
        final response =
            await client.get(uri, headers: headers).timeout(timeout);
        return response;
      } finally {
        client.close();
      }
    } catch (e) {
      print('HTTP request timeout or error: $e for URL: $url');
      rethrow;
    }
  }
}
