import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../repositories/elevenlabs_repository.dart';

part 'audio_generation_provider.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

@riverpod
ElevenLabsRepository elevenlabsRepository(Ref ref) {
  return const ElevenLabsRepository();
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

@riverpod
class AudioGenerationNotifier extends _$AudioGenerationNotifier {
  @override
  FutureOr<String?> build() => null;

  /// Decodes [audioBase64] and saves the resulting MP3 to a temporary file.
  ///
  /// Sets [state] to [AsyncLoading] while the file-I/O is in progress.
  /// Sets [state] to [AsyncData] with the local file path on success.
  /// Sets [state] to [AsyncError] on [AudioSaveException] or any other error.
  Future<void> prepareAudio(String audioBase64) async {
    state = const AsyncLoading();

    try {
      final filePath = await ref
          .read(elevenlabsRepositoryProvider)
          .saveAudioToTempFile(audioBase64);

      state = AsyncData(filePath);
    } on AudioSaveException catch (e, st) {
      state = AsyncError(e, st);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
