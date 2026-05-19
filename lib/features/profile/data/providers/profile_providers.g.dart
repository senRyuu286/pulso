// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileRepository,
          ProfileRepository,
          ProfileRepository
        >
    with $Provider<ProfileRepository> {
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'94f0e5e8046b78d059fe8ecee1e7d33bb1c9f737';

@ProviderFor(fetchProfile)
final fetchProfileProvider = FetchProfileFamily._();

final class FetchProfileProvider
    extends $FunctionalProvider<AsyncValue<Profile>, Profile, FutureOr<Profile>>
    with $FutureModifier<Profile>, $FutureProvider<Profile> {
  FetchProfileProvider._({
    required FetchProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchProfileHash();

  @override
  String toString() {
    return r'fetchProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Profile> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Profile> create(Ref ref) {
    final argument = this.argument as String;
    return fetchProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchProfileHash() => r'2a18b495ff5e80c0a998fc13992cd5cb6201011a';

final class FetchProfileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Profile>, String> {
  FetchProfileFamily._()
    : super(
        retry: null,
        name: r'fetchProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FetchProfileProvider call(String userId) =>
      FetchProfileProvider._(argument: userId, from: this);

  @override
  String toString() => r'fetchProfileProvider';
}

@ProviderFor(watchProfile)
final watchProfileProvider = WatchProfileFamily._();

final class WatchProfileProvider
    extends $FunctionalProvider<AsyncValue<Profile>, Profile, Stream<Profile>>
    with $FutureModifier<Profile>, $StreamProvider<Profile> {
  WatchProfileProvider._({
    required WatchProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'watchProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchProfileHash();

  @override
  String toString() {
    return r'watchProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Profile> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Profile> create(Ref ref) {
    final argument = this.argument as String;
    return watchProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchProfileHash() => r'77d6e92efc7d02bf8b71a7f6dc782753ef7b6f6f';

final class WatchProfileFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Profile>, String> {
  WatchProfileFamily._()
    : super(
        retry: null,
        name: r'watchProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchProfileProvider call(String userId) =>
      WatchProfileProvider._(argument: userId, from: this);

  @override
  String toString() => r'watchProfileProvider';
}
