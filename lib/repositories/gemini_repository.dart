import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when meditation generation fails, either due to a missing auth
/// session or a non-200 response from the Edge Function.
class MeditationGenerationException implements Exception {
  const MeditationGenerationException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode != null) {
      return 'MeditationGenerationException($statusCode): $message';
    }
    return 'MeditationGenerationException: $message';
  }
}

class GeminiRepository {
  GeminiRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Calls the `generate-meditation` Supabase Edge Function and returns the
  /// generated script and base-64 encoded audio as a named record.
  ///
  /// Throws [MeditationGenerationException] if:
  /// - there is no active session (unauthenticated),
  /// - the Edge Function returns a non-200 status code,
  /// - or the response body cannot be parsed.
  Future<({String script, String audioBase64})> generateMeditation({
    required String prompt,
    int durationMinutes = 10,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      // Session is missing — map to the standard session-expired message so
      // the router redirect and the error banner both display the same string.
      throw const MeditationGenerationException(
        message: 'Your session has expired. Please log in again.',
      );
    }

    final FunctionResponse response;
    try {
      response = await _supabase.functions.invoke(
        'generate-meditation',
        body: {'prompt': prompt, 'durationMinutes': durationMinutes},
        headers: {'Authorization': 'Bearer $token'},
      );
    } on FunctionException catch (e) {
      // Map well-known HTTP status codes to plain-language messages so that the
      // UI never receives a raw Supabase error string.  A null details value
      // (common when the function is not yet deployed or the host is
      // unreachable) previously produced the string "null" as the message.
      final String message;
      switch (e.status) {
        case 401:
          message = 'Your session has expired. Please log in again.';
        case 429:
          message = 'You have reached the daily limit. Please try again tomorrow.';
        case 503:
        case 502:
        case 504:
          message = 'Something went wrong. Please try again.';
        default:
          // Use details only when it is a non-empty, non-null string.
          final details = e.details;
          message = (details != null &&
                  details.toString().isNotEmpty &&
                  details.toString() != 'null')
              ? details.toString()
              : 'Something went wrong. Please try again.';
      }
      throw MeditationGenerationException(
        message: message,
        statusCode: e.status,
      );
    } catch (e) {
      // Catch-all for network errors (SocketException, TimeoutException, etc.)
      final raw = e.toString().toLowerCase();
      final isNetwork = raw.contains('socket') ||
          raw.contains('network') ||
          raw.contains('connection') ||
          raw.contains('timeout');
      throw MeditationGenerationException(
        message: isNetwork
            ? 'No internet connection. Please check your network and try again.'
            : 'Something went wrong. Please try again.',
      );
    }

    if (response.status != 200) {
      final errorMessage = (response.data is Map)
          ? (response.data as Map)['error']?.toString() ??
              'Edge Function returned status ${response.status}.'
          : 'Edge Function returned status ${response.status}.';
      throw MeditationGenerationException(
        message: errorMessage,
        statusCode: response.status,
      );
    }

    final data = response.data;
    if (data is! Map) {
      throw MeditationGenerationException(
        message: 'Unexpected response format from generate-meditation.',
        statusCode: response.status,
      );
    }

    final script = data['script'];
    final audioBase64 = data['audioBase64'];

    if (script is! String) {
      throw const MeditationGenerationException(
        message: 'Response is missing a valid "script" field.',
      );
    }
    if (audioBase64 is! String) {
      throw const MeditationGenerationException(
        message: 'Response is missing a valid "audioBase64" field.',
      );
    }

    return (script: script, audioBase64: audioBase64);
  }
}
