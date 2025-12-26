// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pm_service_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authPmService)
const authPmServiceProvider = AuthPmServiceProvider._();

final class AuthPmServiceProvider
    extends $FunctionalProvider<AuthPmService, AuthPmService, AuthPmService>
    with $Provider<AuthPmService> {
  const AuthPmServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authPmServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authPmServiceHash();

  @$internal
  @override
  $ProviderElement<AuthPmService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthPmService create(Ref ref) {
    return authPmService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthPmService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthPmService>(value),
    );
  }
}

String _$authPmServiceHash() => r'57e4d0c58920f35c272fae8bf4885ce4202cefe5';

@ProviderFor(resourcePmService)
const resourcePmServiceProvider = ResourcePmServiceProvider._();

final class ResourcePmServiceProvider
    extends
        $FunctionalProvider<
          ResourcePmService,
          ResourcePmService,
          ResourcePmService
        >
    with $Provider<ResourcePmService> {
  const ResourcePmServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resourcePmServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resourcePmServiceHash();

  @$internal
  @override
  $ProviderElement<ResourcePmService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResourcePmService create(Ref ref) {
    return resourcePmService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResourcePmService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResourcePmService>(value),
    );
  }
}

String _$resourcePmServiceHash() => r'5dc6c653ab49edac12100a5d0ca7896f2d9f6814';
