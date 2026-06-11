import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isSignUp = false;

  /// Maps any thrown auth error to a plain-language sentence suitable for
  /// display in a SnackBar.  Never exposes a raw exception string to the user.
  String _authErrorMessage(Object? error) {
    if (error == null) return 'Something went wrong. Please try again.';
    final raw = error.toString().toLowerCase();
    if (raw.contains('invalid login credentials') ||
        raw.contains('invalid_credentials') ||
        raw.contains('400')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (raw.contains('email not confirmed') ||
        raw.contains('email_not_confirmed')) {
      return 'Please confirm your email address before logging in.';
    }
    if (raw.contains('user already registered') ||
        raw.contains('already_exists')) {
      return 'An account with this email already exists. Please log in instead.';
    }
    if (raw.contains('network') ||
        raw.contains('socketexception') ||
        raw.contains('connection')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (raw.contains('rate') || raw.contains('429')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      final displayName = _displayNameController.text.trim();
      ref.read(authNotifierProvider.notifier).signUp(email, password, displayName);
    } else {
      ref.read(authNotifierProvider.notifier).signIn(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use ref.listen to react to auth state changes — never navigate manually.
    // On error: show a SnackBar with a human-readable message.
    //
    // The mounted check prevents ScaffoldMessenger.of(context) from being
    // called after the widget is disposed — on Flutter web this causes a null
    // DOM node crash identical to the removeChild error.  The error is mapped
    // to a plain-language string rather than calling error.toString() directly,
    // which would expose raw Supabase AuthException internals to the user.
    ref.listen<AsyncValue<void>>(authNotifierProvider, (previous, next) {
      if (!mounted) return;
      next.whenOrNull(
        error: (error, _) {
          final message = _authErrorMessage(error);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: colorScheme.error,
            ),
          );
        },
      );
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AsyncLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    _isSignUp ? 'Create Account' : 'Log In',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Display Name field — only in sign-up mode
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (_isSignUp && (value == null || value.trim().isEmpty)) {
                          return 'Display name is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: isLoading ? null : (_) => _submit(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required.';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Primary action button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLoading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(_isSignUp ? 'Create Account' : 'Log In'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mode toggle button
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                            });
                            _formKey.currentState?.reset();
                          },
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Log In'
                          : 'No account yet? Create Account',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
