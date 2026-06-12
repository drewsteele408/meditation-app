// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_generation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$elevenlabsRepositoryHash() =>
    r'00a9e48f88d371bd207d3b876b5ee496e89e24b1';

/// See also [elevenlabsRepository].
@ProviderFor(elevenlabsRepository)
final elevenlabsRepositoryProvider =
    AutoDisposeProvider<ElevenLabsRepository>.internal(
      elevenlabsRepository,
      name: r'elevenlabsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$elevenlabsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ElevenlabsRepositoryRef = AutoDisposeProviderRef<ElevenLabsRepository>;
String _$audioGenerationNotifierHash() =>
    r'fac33a3b29b582bbb78beccde4d400f1a4043c5e';

/// See also [AudioGenerationNotifier].
@ProviderFor(AudioGenerationNotifier)
final audioGenerationNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AudioGenerationNotifier, String?>.internal(
      AudioGenerationNotifier.new,
      name: r'audioGenerationNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$audioGenerationNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AudioGenerationNotifier = AutoDisposeAsyncNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
