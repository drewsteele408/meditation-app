import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audio_playback_provider.g.dart';

// ---------------------------------------------------------------------------
// Status enum
// ---------------------------------------------------------------------------

enum PlaybackStatus { idle, loading, playing, paused, stopped, error }

// ---------------------------------------------------------------------------
// State model
// ---------------------------------------------------------------------------

class AudioPlaybackState {
  const AudioPlaybackState({
    required this.status,
    required this.position,
    required this.duration,
    this.errorMessage,
  });

  final PlaybackStatus status;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  AudioPlaybackState copyWith({
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    String? errorMessage,
  }) {
    return AudioPlaybackState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

@riverpod
class AudioPlaybackNotifier extends _$AudioPlaybackNotifier {
  late final AudioPlayer _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  AudioPlaybackState build() {
    _player = AudioPlayer();

    _positionSub = _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _durationSub = _player.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    _playerStateSub = _player.playerStateStream.listen((playerState) {
      final mapped = _mapPlayerState(playerState);
      if (mapped != null) {
        state = state.copyWith(status: mapped);
        // When playback completes, reset position to zero.
        if (mapped == PlaybackStatus.stopped) {
          state = state.copyWith(position: Duration.zero);
        }
      }
    });

    ref.onDispose(() {
      _positionSub?.cancel();
      _durationSub?.cancel();
      _playerStateSub?.cancel();
      _player.dispose();
    });

    return const AudioPlaybackState(
      status: PlaybackStatus.idle,
      position: Duration.zero,
      duration: Duration.zero,
    );
  }

  // -------------------------------------------------------------------------
  // Public methods
  // -------------------------------------------------------------------------

  Future<void> load(String filePath) async {
    state = state.copyWith(status: PlaybackStatus.loading, errorMessage: null);
    try {
      await _player.setFilePath(filePath);
      state = state.copyWith(status: PlaybackStatus.playing);
      await _player.play();
    } catch (e) {
      state = state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void play() {
    _player.play();
    state = state.copyWith(status: PlaybackStatus.playing);
  }

  void pause() {
    _player.pause();
    state = state.copyWith(status: PlaybackStatus.paused);
  }

  void stop() {
    _player.stop();
    state = state.copyWith(
      status: PlaybackStatus.stopped,
      position: Duration.zero,
    );
  }

  void replay() {
    _player.seek(Duration.zero);
    _player.play();
    state = state.copyWith(status: PlaybackStatus.playing);
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  PlaybackStatus? _mapPlayerState(PlayerState playerState) {
    if (playerState.processingState == ProcessingState.completed) {
      return PlaybackStatus.stopped;
    }
    if (playerState.playing) {
      return PlaybackStatus.playing;
    }
    // Buffering / loading — only update if we are not already in a
    // terminal or intentional state that the user set explicitly.
    if (playerState.processingState == ProcessingState.buffering ||
        playerState.processingState == ProcessingState.loading) {
      return PlaybackStatus.loading;
    }
    // idle / ready but not playing maps to paused when audio is loaded,
    // otherwise we leave the status as-is so idle is preserved at startup.
    if (playerState.processingState == ProcessingState.ready) {
      return PlaybackStatus.paused;
    }
    // ProcessingState.idle — no audio loaded yet; keep current status.
    return null;
  }
}
