import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/meditation/screens/playback_screen.dart';
import 'features/meditation/screens/prompt_screen.dart';
import 'features/settings/screens/settings_screen.dart';

part 'router.g.dart';

// ---------------------------------------------------------------------------
// RouterNotifier
// ---------------------------------------------------------------------------
// A Riverpod Notifier that also implements Listenable so GoRouter can use it
// as a refreshListenable.  It watches authStateProvider so that every auth
// state change triggers a GoRouter rebuild + redirect evaluation.
// ---------------------------------------------------------------------------

class RouterNotifier extends Notifier<void> with ChangeNotifier {
  @override
  void build() {
    // Watch auth state so this notifier rebuilds (and calls notifyListeners)
    // whenever the stream emits a new value.
    ref.watch(authStateProvider);

    // Tell GoRouter to re-evaluate its redirect callback.
    // We call this in a post-frame callback to avoid triggering GoRouter
    // during the current Riverpod build cycle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}

/// A keepAlive provider so GoRouter holds a stable reference to the notifier.
final routerNotifierProvider =
    NotifierProvider<RouterNotifier, void>(RouterNotifier.new);

// ---------------------------------------------------------------------------
// Route paths
// ---------------------------------------------------------------------------

const _splash = '/';
const _auth = '/auth';
const _home = '/home';
const _prompt = '/prompt';
const _playback = '/playback';
const _settings = '/settings';

// ---------------------------------------------------------------------------
// GoRouter provider
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);

  return GoRouter(
    initialLocation: _splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final location = state.uri.toString();

      // Auth state is still loading — don't redirect yet.
      if (authAsync is AsyncLoading || authAsync is AsyncError) {
        return null;
      }

      // Pull the Supabase session out of the AsyncData value.
      final authState = authAsync.valueOrNull;
      final isAuthenticated = authState?.session != null;

      if (!isAuthenticated) {
        // Allow the user to stay on the splash screen or auth screen.
        if (location == _splash || location == _auth) return null;
        return _auth;
      }

      // Authenticated users should not linger on splash or auth.
      if (location == _splash || location == _auth) return _home;

      return null;
    },
    routes: [
      GoRoute(
        path: _splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: _auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: _home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: _prompt,
        builder: (context, state) => const PromptScreen(),
      ),
      GoRoute(
        path: _playback,
        redirect: (context, state) {
          // Redirect to /prompt if no ScriptGenerationResult extra is present.
          if (state.extra == null) return _prompt;
          return null;
        },
        builder: (context, state) => const PlaybackScreen(),
      ),
      GoRoute(
        path: _settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
