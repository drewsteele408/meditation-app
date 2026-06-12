// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_generation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$geminiRepositoryHash() => r'0b30799cc135df1606818511748acf3323a797a3';

/// See also [geminiRepository].
@ProviderFor(geminiRepository)
final geminiRepositoryProvider = AutoDisposeProvider<GeminiRepository>.internal(
  geminiRepository,
  name: r'geminiRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$geminiRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GeminiRepositoryRef = AutoDisposeProviderRef<GeminiRepository>;
String _$scriptGenerationNotifierHash() =>
    r'655e371631b53fdf4544aa20ad8e3dfeb444f355';

/// See also [ScriptGenerationNotifier].
@ProviderFor(ScriptGenerationNotifier)
final scriptGenerationNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      ScriptGenerationNotifier,
      ScriptGenerationResult?
    >.internal(
      ScriptGenerationNotifier.new,
      name: r'scriptGenerationNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$scriptGenerationNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ScriptGenerationNotifier =
    AutoDisposeAsyncNotifier<ScriptGenerationResult?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
