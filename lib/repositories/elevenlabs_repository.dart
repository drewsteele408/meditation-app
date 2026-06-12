import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Thrown when saving the decoded audio bytes to a temporary file fails.
class AudioSaveException implements Exception {
  const AudioSaveException({required this.message});

  final String message;

  @override
  String toString() => 'AudioSaveException: $message';
}

/// Handles decoding the Base64 audio returned by the Supabase Edge Function
/// and persisting it to a temporary file that [just_audio] can play.
///
/// This repository makes NO network calls. All ElevenLabs TTS processing
/// happens server-side inside the `generate-meditation` Edge Function. This
/// class is responsible solely for the local file-I/O step.
class ElevenLabsRepository {
  const ElevenLabsRepository();

  /// Decodes [audioBase64] and writes the resulting MP3 bytes to a unique
  /// temporary file.
  ///
  /// Returns the absolute path of the written file.
  ///
  /// Throws [AudioSaveException] if:
  /// - [audioBase64] is empty or cannot be decoded,
  /// - or writing to the temporary directory fails.
  Future<String> saveAudioToTempFile(String audioBase64) async {
    if (audioBase64.isEmpty) {
      throw const AudioSaveException(
        message: 'Audio data is empty — nothing to save.',
      );
    }

    final List<int> bytes;
    try {
      bytes = base64Decode(audioBase64);
    } catch (e) {
      throw AudioSaveException(
        message: 'Failed to decode audio data: ${e.toString()}',
      );
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/meditation_$timestamp.mp3';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      return filePath;
    } catch (e) {
      throw AudioSaveException(
        message: 'Failed to write audio to temporary file: ${e.toString()}',
      );
    }
  }
}
