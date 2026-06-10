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
      throw const MeditationGenerationException(
        message: 'No active session. Please sign in before generating a meditation.',
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
      throw MeditationGenerationException(
        message: e.details?.toString() ?? 'Edge Function invocation failed.',
        statusCode: e.status,
      );
    } catch (e) {
      throw MeditationGenerationException(
        message: 'Unexpected error calling generate-meditation: $e',
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
