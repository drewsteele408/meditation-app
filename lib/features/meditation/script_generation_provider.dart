import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/supabase_provider.dart';
import '../../repositories/gemini_repository.dart';

part 'script_generation_provider.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

@riverpod
GeminiRepository geminiRepository(GeminiRepositoryRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return GeminiRepository(supabase);
}

// ---------------------------------------------------------------------------
// Result model
// ---------------------------------------------------------------------------

/// Immutable result returned after a successful meditation generation.
class ScriptGenerationResult {
  const ScriptGenerationResult({
    required this.script,
    required this.audioBase64,
  });

  final String script;
  final String audioBase64;

  ScriptGenerationResult copyWith({
    String? script,
    String? audioBase64,
  }) {
    return ScriptGenerationResult(
      script: script ?? this.script,
      audioBase64: audioBase64 ?? this.audioBase64,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

@riverpod
class ScriptGenerationNotifier extends _$ScriptGenerationNotifier {
  @override
  FutureOr<ScriptGenerationResult?> build() => null;

  /// Validates [prompt], calls the repository, and updates [state].
  ///
  /// Sets [state] to [AsyncLoading] while the request is in-flight.
  /// Sets [state] to [AsyncError] on validation failure or any exception.
  /// Sets [state] to [AsyncData] on success.
  Future<void> generate(String prompt, int durationMinutes) async {
    // Set loading state first so the spinner appears on the same frame as the
    // button tap, before any conditional or async operation executes.
    state = const AsyncLoading();

    // Client-side validation — no network call needed for these cases.
    if (prompt.trim().isEmpty) {
      state = AsyncError(
        Exception('Please enter a prompt before generating your meditation.'),
        StackTrace.current,
      );
      return;
    }
    if (prompt.length > 1000) {
      state = AsyncError(
        Exception('Your prompt is too long. Please shorten it to 1,000 characters or fewer.'),
        StackTrace.current,
      );
      return;
    }

    try {
      final result = await ref
          .read(geminiRepositoryProvider)
          .generateMeditation(prompt: prompt, durationMinutes: durationMinutes);

      state = AsyncData(
        ScriptGenerationResult(
          script: result.script,
          audioBase64: result.audioBase64,
        ),
      );
    } on MeditationGenerationException catch (e, st) {
      state = AsyncError(e, st);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
