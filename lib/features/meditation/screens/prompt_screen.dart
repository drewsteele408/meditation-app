import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../repositories/gemini_repository.dart';
import '../meditation_prompt_provider.dart';
import '../script_generation_provider.dart';

class PromptScreen extends ConsumerStatefulWidget {
  const PromptScreen({super.key});

  @override
  ConsumerState<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends ConsumerState<PromptScreen> {
  final _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Sync the controller with any existing provider state (e.g. after hot
    // reload or returning to this screen without a full reset).
    final initialText =
        ref.read(meditationPromptNotifierProvider).promptText;
    _promptController.text = initialText;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  /// Extracts a human-readable message from any exception type.
  String _errorMessage(Object? error) {
    if (error is MeditationGenerationException) {
      return error.message;
    }
    if (error == null) return 'An unexpected error occurred.';
    // Strip the "Exception: " prefix that Dart adds to Exception.toString().
    final raw = error.toString();
    const prefix = 'Exception: ';
    if (raw.startsWith(prefix)) return raw.substring(prefix.length);
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final promptState = ref.watch(meditationPromptNotifierProvider);
    final generationState = ref.watch(scriptGenerationNotifierProvider);

    final isLoading = generationState is AsyncLoading;
    final promptText = promptState.promptText;
    final durationMinutes = promptState.durationMinutes;

    // Navigate to /playback when generation succeeds — never navigate manually
    // inside the button callback.
    ref.listen<AsyncValue<ScriptGenerationResult?>>(
      scriptGenerationNotifierProvider,
      (previous, next) {
        next.whenOrNull(
          data: (result) {
            if (result != null) {
              context.go('/playback', extra: result);
            }
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Meditation'),
        leading: Semantics(
          label: 'Back',
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ----------------------------------------------------------------
              // Section label
              // ----------------------------------------------------------------
              Text(
                'What would you like to meditate on?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // ----------------------------------------------------------------
              // Prompt text field
              // ----------------------------------------------------------------
              TextField(
                controller: _promptController,
                enabled: !isLoading,
                maxLength: 1000,
                maxLines: 6,
                minLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText:
                      'e.g. Help me relax after a stressful day at work...',
                  border: const OutlineInputBorder(),
                  // Hide the built-in counter — we render our own below.
                  counterText: '',
                  filled: isLoading,
                  fillColor: isLoading
                      ? colorScheme.surfaceContainerHighest
                      : null,
                ),
                onChanged: (value) {
                  ref
                      .read(meditationPromptNotifierProvider.notifier)
                      .setPrompt(value);
                },
              ),
              const SizedBox(height: 4),

              // Character counter
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${promptText.length}/1000',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: promptText.length >= 1000
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ----------------------------------------------------------------
              // Duration selector
              // ----------------------------------------------------------------
              Text(
                'Duration',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                children: [
                  for (final minutes in [5, 10, 15])
                    ChoiceChip(
                      label: Text('$minutes min'),
                      selected: durationMinutes == minutes,
                      onSelected: isLoading
                          ? null
                          : (_) {
                              ref
                                  .read(meditationPromptNotifierProvider
                                      .notifier)
                                  .setDuration(minutes);
                            },
                    ),
                ],
              ),
              const SizedBox(height: 32),

              // ----------------------------------------------------------------
              // Error banner
              // ----------------------------------------------------------------
              if (generationState is AsyncError<ScriptGenerationResult?>) ...[
                _ErrorBanner(
                  message: _errorMessage(generationState.error),
                  onDismiss: () =>
                      ref.invalidate(scriptGenerationNotifierProvider),
                ),
                const SizedBox(height: 16),
              ],

              // ----------------------------------------------------------------
              // Loading indicator
              // ----------------------------------------------------------------
              if (isLoading) ...[
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Crafting your meditation...'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ----------------------------------------------------------------
              // Generate button
              // ----------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (isLoading || promptText.trim().isEmpty)
                      ? null
                      : () {
                          ref
                              .read(scriptGenerationNotifierProvider.notifier)
                              .generate(promptText, durationMinutes);
                        },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Text('Generate Meditation'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error banner widget
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onErrorContainer,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}
