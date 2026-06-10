import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meditation_prompt_provider.g.dart';

/// Immutable state for the meditation prompt form.
class MeditationPromptState {
  const MeditationPromptState({
    this.promptText = '',
    this.durationMinutes = 10,
  });

  final String promptText;
  final int durationMinutes;

  MeditationPromptState copyWith({
    String? promptText,
    int? durationMinutes,
  }) {
    return MeditationPromptState(
      promptText: promptText ?? this.promptText,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}

@riverpod
class MeditationPromptNotifier extends _$MeditationPromptNotifier {
  @override
  MeditationPromptState build() => const MeditationPromptState();

  void setPrompt(String text) {
    state = state.copyWith(promptText: text);
  }

  void setDuration(int minutes) {
    state = state.copyWith(durationMinutes: minutes);
  }

  void reset() {
    state = const MeditationPromptState();
  }
}
