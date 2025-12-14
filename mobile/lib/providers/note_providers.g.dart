// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// NoteRepository Provider - 数据层
/// 提供 Isar 的具体实现

@ProviderFor(noteRepository)
const noteRepositoryProvider = NoteRepositoryProvider._();

/// NoteRepository Provider - 数据层
/// 提供 Isar 的具体实现

final class NoteRepositoryProvider
    extends $FunctionalProvider<NoteRepository, NoteRepository, NoteRepository>
    with $Provider<NoteRepository> {
  /// NoteRepository Provider - 数据层
  /// 提供 Isar 的具体实现
  const NoteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteRepositoryHash();

  @$internal
  @override
  $ProviderElement<NoteRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NoteRepository create(Ref ref) {
    return noteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteRepository>(value),
    );
  }
}

String _$noteRepositoryHash() => r'5fa35dc47447d083b69833aae1f1e66d66cef073';

/// NoteService Provider - 业务层
/// 现在依赖抽象的 Repository 接口

@ProviderFor(noteService)
const noteServiceProvider = NoteServiceProvider._();

/// NoteService Provider - 业务层
/// 现在依赖抽象的 Repository 接口

final class NoteServiceProvider
    extends $FunctionalProvider<NoteService, NoteService, NoteService>
    with $Provider<NoteService> {
  /// NoteService Provider - 业务层
  /// 现在依赖抽象的 Repository 接口
  const NoteServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteServiceHash();

  @$internal
  @override
  $ProviderElement<NoteService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NoteService create(Ref ref) {
    return noteService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteService>(value),
    );
  }
}

String _$noteServiceHash() => r'e1d56e60271e48942a7f4d8ca94518e4a3e430a6';

/// 搜索查询 Provider - 用于管理当前搜索关键词

@ProviderFor(SearchQuery)
const searchQueryProvider = SearchQueryProvider._();

/// 搜索查询 Provider - 用于管理当前搜索关键词
final class SearchQueryProvider
    extends $NotifierProvider<SearchQuery, String?> {
  /// 搜索查询 Provider - 用于管理当前搜索关键词
  const SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$searchQueryHash() => r'682eaf558bae7ed6cf1fb423cb5832de0a760e2d';

/// 搜索查询 Provider - 用于管理当前搜索关键词

abstract class _$SearchQuery extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 搜索结果 Provider - 根据搜索查询返回结果

@ProviderFor(searchResults)
const searchResultsProvider = SearchResultsProvider._();

/// 搜索结果 Provider - 根据搜索查询返回结果

final class SearchResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NoteEntity>>,
          List<NoteEntity>,
          Stream<List<NoteEntity>>
        >
    with $FutureModifier<List<NoteEntity>>, $StreamProvider<List<NoteEntity>> {
  /// 搜索结果 Provider - 根据搜索查询返回结果
  const SearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @$internal
  @override
  $StreamProviderElement<List<NoteEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<NoteEntity>> create(Ref ref) {
    return searchResults(ref);
  }
}

String _$searchResultsHash() => r'ebcc6e9ea28e1d9a8bfa0964af302821321c4567';

/// 所有笔记的 Stream Provider

@ProviderFor(allNotes)
const allNotesProvider = AllNotesProvider._();

/// 所有笔记的 Stream Provider

final class AllNotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NoteEntity>>,
          List<NoteEntity>,
          Stream<List<NoteEntity>>
        >
    with $FutureModifier<List<NoteEntity>>, $StreamProvider<List<NoteEntity>> {
  /// 所有笔记的 Stream Provider
  const AllNotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allNotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allNotesHash();

  @$internal
  @override
  $StreamProviderElement<List<NoteEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<NoteEntity>> create(Ref ref) {
    return allNotes(ref);
  }
}

String _$allNotesHash() => r'2a341e98bfdc03cc4f5ce2acee5d414fd436d640';

/// 根据 ID 获取笔记的 Provider

@ProviderFor(noteById)
const noteByIdProvider = NoteByIdFamily._();

/// 根据 ID 获取笔记的 Provider

final class NoteByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<NoteEntity?>,
          NoteEntity?,
          FutureOr<NoteEntity?>
        >
    with $FutureModifier<NoteEntity?>, $FutureProvider<NoteEntity?> {
  /// 根据 ID 获取笔记的 Provider
  const NoteByIdProvider._({
    required NoteByIdFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'noteByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noteByIdHash();

  @override
  String toString() {
    return r'noteByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<NoteEntity?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NoteEntity?> create(Ref ref) {
    final argument = this.argument as int;
    return noteById(ref, id: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noteByIdHash() => r'd8b9b6defd5b01092d5417052bf27381a4bd04f3';

/// 根据 ID 获取笔记的 Provider

final class NoteByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<NoteEntity?>, int> {
  const NoteByIdFamily._()
    : super(
        retry: null,
        name: r'noteByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 根据 ID 获取笔记的 Provider

  NoteByIdProvider call({required int id}) =>
      NoteByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'noteByIdProvider';
}

/// 桌面端当前选中的笔记 Provider
/// 用于桌面端详情面板显示

@ProviderFor(SelectedNote)
const selectedNoteProvider = SelectedNoteProvider._();

/// 桌面端当前选中的笔记 Provider
/// 用于桌面端详情面板显示
final class SelectedNoteProvider
    extends $NotifierProvider<SelectedNote, NoteEntity?> {
  /// 桌面端当前选中的笔记 Provider
  /// 用于桌面端详情面板显示
  const SelectedNoteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedNoteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedNoteHash();

  @$internal
  @override
  SelectedNote create() => SelectedNote();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteEntity? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteEntity?>(value),
    );
  }
}

String _$selectedNoteHash() => r'9d71b3044da7c044a9a9bdc0b61dbf0c95427cd8';

/// 桌面端当前选中的笔记 Provider
/// 用于桌面端详情面板显示

abstract class _$SelectedNote extends $Notifier<NoteEntity?> {
  NoteEntity? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<NoteEntity?, NoteEntity?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NoteEntity?, NoteEntity?>,
              NoteEntity?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 根据分类获取笔记的 StreamNotifier

@ProviderFor(NoteByCategory)
const noteByCategoryProvider = NoteByCategoryProvider._();

/// 根据分类获取笔记的 StreamNotifier
final class NoteByCategoryProvider
    extends $StreamNotifierProvider<NoteByCategory, List<NoteEntity>> {
  /// 根据分类获取笔记的 StreamNotifier
  const NoteByCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteByCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteByCategoryHash();

  @$internal
  @override
  NoteByCategory create() => NoteByCategory();
}

String _$noteByCategoryHash() => r'507e4ade80ea909ab7053e7bece8469728fbdc7d';

/// 根据分类获取笔记的 StreamNotifier

abstract class _$NoteByCategory extends $StreamNotifier<List<NoteEntity>> {
  Stream<List<NoteEntity>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<NoteEntity>>, List<NoteEntity>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<NoteEntity>>, List<NoteEntity>>,
              AsyncValue<List<NoteEntity>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
