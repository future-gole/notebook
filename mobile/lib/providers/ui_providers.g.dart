// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 是否正在添加笔记（桌面端使用）

@ProviderFor(IsAddingNote)
const isAddingNoteProvider = IsAddingNoteProvider._();

/// 是否正在添加笔记（桌面端使用）
final class IsAddingNoteProvider extends $NotifierProvider<IsAddingNote, bool> {
  /// 是否正在添加笔记（桌面端使用）
  const IsAddingNoteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isAddingNoteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isAddingNoteHash();

  @$internal
  @override
  IsAddingNote create() => IsAddingNote();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isAddingNoteHash() => r'4ba61879b557d630b91b749a86901abbd7fde289';

/// 是否正在添加笔记（桌面端使用）

abstract class _$IsAddingNote extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
