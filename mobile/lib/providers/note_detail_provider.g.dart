// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NoteDetail)
const noteDetailProvider = NoteDetailFamily._();

final class NoteDetailProvider
    extends $NotifierProvider<NoteDetail, NoteDetailState> {
  const NoteDetailProvider._({
    required NoteDetailFamily super.from,
    required Note super.argument,
  }) : super(
         retry: null,
         name: r'noteDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noteDetailHash();

  @override
  String toString() {
    return r'noteDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NoteDetail create() => NoteDetail();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NoteDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noteDetailHash() => r'ba458c67bf978ff064bac214cbdac3a67b49d301';

final class NoteDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          NoteDetail,
          NoteDetailState,
          NoteDetailState,
          NoteDetailState,
          Note
        > {
  const NoteDetailFamily._()
    : super(
        retry: null,
        name: r'noteDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NoteDetailProvider call(Note initialNote) =>
      NoteDetailProvider._(argument: initialNote, from: this);

  @override
  String toString() => r'noteDetailProvider';
}

abstract class _$NoteDetail extends $Notifier<NoteDetailState> {
  late final _$args = ref.$arg as Note;
  Note get initialNote => _$args;

  NoteDetailState build(Note initialNote);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<NoteDetailState, NoteDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NoteDetailState, NoteDetailState>,
              NoteDetailState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
