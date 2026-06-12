import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repositories/elevenlabs_repository.dart';
import '../audio_generation_provider.dart';
import '../audio_playback_provider.dart';
import '../script_generation_provider.dart';

class PlaybackScreen extends ConsumerStatefulWidget {
  const PlaybackScreen({super.key});

  @override
  ConsumerState<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends ConsumerState<PlaybackScreen> {
  /// Guards against calling prepareAudio more than once per screen visit.
  bool _audioPrepared = false;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _errorMessage(Object? error) {
    if (error is AudioSaveException) return error.message;
    if (error == null) return 'An unexpected error occurred.';
    final raw = error.toString();
    const prefix = 'Exception: ';
    if (raw.startsWith(prefix)) return raw.substring(prefix.length);
    return raw;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final scriptState = ref.watch(scriptGenerationNotifierProvider);
    final audioGenState = ref.watch(audioGenerationNotifierProvider);
    final playbackState = ref.watch(audioPlaybackNotifierProvider);

    final isAudioLoading = audioGenState is AsyncLoading;
    final isAudioError = audioGenState is AsyncError;
    final isPlaybackError = playbackState.status == PlaybackStatus.error;

    final isControlsDisabled = isAudioLoading ||
        playbackState.status == PlaybackStatus.loading ||
        playbackState.status == PlaybackStatus.idle;

    // -------------------------------------------------------------------------
    // Chain: script ready → prepare audio → load player
    // -------------------------------------------------------------------------

    ref.listen<AsyncValue<ScriptGenerationResult?>>(
      scriptGenerationNotifierProvider,
      (previous, next) {
        if (!mounted) return;
        next.whenOrNull(
          data: (result) {
            if (result != null && !_audioPrepared) {
              _audioPrepared = true;
              ref
                  .read(audioGenerationNotifierProvider.notifier)
                  .prepareAudio(result.audioBase64);
            }
          },
        );
      },
    );

    ref.listen<AsyncValue<String?>>(
      audioGenerationNotifierProvider,
      (previous, next) {
        if (!mounted) return;
        next.whenOrNull(
          data: (filePath) {
            if (filePath != null) {
              ref
                  .read(audioPlaybackNotifierProvider.notifier)
                  .load(filePath);
            }
          },
        );
      },
    );

    // -------------------------------------------------------------------------
    // Script text (may be null if somehow reached without script state)
    // -------------------------------------------------------------------------

    final script = scriptState.valueOrNull?.script ?? '';

    // -------------------------------------------------------------------------
    // Progress bar values
    // -------------------------------------------------------------------------

    final position = playbackState.position;
    final duration = playbackState.duration;
    final sliderMax = duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
    final sliderValue =
        (position.inSeconds / sliderMax).clamp(0.0, 1.0);
    final sliderEnabled = !isControlsDisabled &&
        playbackState.status != PlaybackStatus.stopped;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ref.read(audioPlaybackNotifierProvider.notifier).stop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your Meditation'),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------------------------------------------------------
              // Script display (scrollable, takes remaining space)
              // ---------------------------------------------------------------
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Text(
                    script,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16.0,
                      height: 1.6,
                    ),
                  ),
                ),
              ),

              // ---------------------------------------------------------------
              // Bottom controls panel
              // ---------------------------------------------------------------
              Container(
                color: colorScheme.surface,
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Error banner — audio generation failure
                    if (isAudioError) ...[
                      _ErrorBanner(
                        message: _errorMessage(
                          (audioGenState as AsyncError).error,
                        ),
                        onTryAgain: () {
                          final result = scriptState.valueOrNull;
                          if (result != null) {
                            _audioPrepared = false;
                            ref
                                .read(audioGenerationNotifierProvider.notifier)
                                .prepareAudio(result.audioBase64);
                            _audioPrepared = true;
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Error banner — playback failure
                    if (!isAudioError && isPlaybackError) ...[
                      _ErrorBanner(
                        message: playbackState.errorMessage ??
                            'Audio playback failed. Please try again.',
                        onTryAgain: () {
                          final result = scriptState.valueOrNull;
                          if (result != null) {
                            _audioPrepared = false;
                            ref
                                .read(audioGenerationNotifierProvider.notifier)
                                .prepareAudio(result.audioBase64);
                            _audioPrepared = true;
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Loading indicator
                    if (isAudioLoading) ...[
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          SizedBox(width: 12),
                          Text('Preparing audio...'),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Progress slider
                    Row(
                      children: [
                        Text(
                          _formatDuration(position),
                          style: theme.textTheme.bodySmall,
                        ),
                        Expanded(
                          child: Slider(
                            value: sliderValue,
                            onChanged: sliderEnabled ? null : null,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),

                    // Playback controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Semantics(
                          label: 'Replay from beginning',
                          child: IconButton(
                            icon: const Icon(Icons.replay),
                            iconSize: 32,
                            onPressed: isControlsDisabled
                                ? null
                                : () => ref
                                    .read(audioPlaybackNotifierProvider.notifier)
                                    .replay(),
                          ),
                        ),
                        Semantics(
                          label: playbackState.status == PlaybackStatus.playing
                              ? 'Pause'
                              : 'Play',
                          child: IconButton(
                            icon: Icon(
                              playbackState.status == PlaybackStatus.playing
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            iconSize: 48,
                            onPressed: isControlsDisabled
                                ? null
                                : () {
                                    final notifier = ref.read(
                                      audioPlaybackNotifierProvider.notifier,
                                    );
                                    if (playbackState.status ==
                                        PlaybackStatus.playing) {
                                      notifier.pause();
                                    } else {
                                      notifier.play();
                                    }
                                  },
                          ),
                        ),
                        Semantics(
                          label: 'Stop',
                          child: IconButton(
                            icon: const Icon(Icons.stop),
                            iconSize: 32,
                            onPressed: isControlsDisabled
                                ? null
                                : () => ref
                                    .read(audioPlaybackNotifierProvider.notifier)
                                    .stop(),
                          ),
                        ),
                      ],
                    ),
                  ],
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
    required this.onTryAgain,
  });

  final String message;
  final VoidCallback onTryAgain;

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
            onPressed: onTryAgain,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onErrorContainer,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
