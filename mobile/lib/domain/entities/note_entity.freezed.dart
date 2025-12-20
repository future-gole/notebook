// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NoteEntity {

/// 笔记ID，null 表示尚未持久化的新笔记
 int? get id;/// 笔记标题，可为空
 String? get title;/// 笔记内容
 String? get content;/// url
 String? get url;/// 创建/修改时间
 DateTime? get time;/// 分类ID，用于关联到 CategoryEntity
 int get categoryId;/// 标签
 String? get tag;/// 链接预览图片URL（网络链接笔记用）
 String? get previewImageUrl;/// 链接预览标题（网络链接笔记用）
 String? get previewTitle;/// 链接预览描述（网络链接笔记用）
 String? get previewDescription;
/// Create a copy of NoteEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteEntityCopyWith<NoteEntity> get copyWith => _$NoteEntityCopyWithImpl<NoteEntity>(this as NoteEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.url, url) || other.url == url)&&(identical(other.time, time) || other.time == time)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.tag, tag) || other.tag == tag)&&(identical(other.previewImageUrl, previewImageUrl) || other.previewImageUrl == previewImageUrl)&&(identical(other.previewTitle, previewTitle) || other.previewTitle == previewTitle)&&(identical(other.previewDescription, previewDescription) || other.previewDescription == previewDescription));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,content,url,time,categoryId,tag,previewImageUrl,previewTitle,previewDescription);

@override
String toString() {
  return 'NoteEntity(id: $id, title: $title, content: $content, url: $url, time: $time, categoryId: $categoryId, tag: $tag, previewImageUrl: $previewImageUrl, previewTitle: $previewTitle, previewDescription: $previewDescription)';
}


}

/// @nodoc
abstract mixin class $NoteEntityCopyWith<$Res>  {
  factory $NoteEntityCopyWith(NoteEntity value, $Res Function(NoteEntity) _then) = _$NoteEntityCopyWithImpl;
@useResult
$Res call({
 int? id, String? title, String? content, String? url, DateTime? time, int categoryId, String? tag, String? previewImageUrl, String? previewTitle, String? previewDescription
});




}
/// @nodoc
class _$NoteEntityCopyWithImpl<$Res>
    implements $NoteEntityCopyWith<$Res> {
  _$NoteEntityCopyWithImpl(this._self, this._then);

  final NoteEntity _self;
  final $Res Function(NoteEntity) _then;

/// Create a copy of NoteEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? title = freezed,Object? content = freezed,Object? url = freezed,Object? time = freezed,Object? categoryId = null,Object? tag = freezed,Object? previewImageUrl = freezed,Object? previewTitle = freezed,Object? previewDescription = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,time: freezed == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,tag: freezed == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String?,previewImageUrl: freezed == previewImageUrl ? _self.previewImageUrl : previewImageUrl // ignore: cast_nullable_to_non_nullable
as String?,previewTitle: freezed == previewTitle ? _self.previewTitle : previewTitle // ignore: cast_nullable_to_non_nullable
as String?,previewDescription: freezed == previewDescription ? _self.previewDescription : previewDescription // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NoteEntity].
extension NoteEntityPatterns on NoteEntity {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NoteEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NoteEntity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NoteEntity value)  $default,){
final _that = this;
switch (_that) {
case _NoteEntity():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NoteEntity value)?  $default,){
final _that = this;
switch (_that) {
case _NoteEntity() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? title,  String? content,  String? url,  DateTime? time,  int categoryId,  String? tag,  String? previewImageUrl,  String? previewTitle,  String? previewDescription)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NoteEntity() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.url,_that.time,_that.categoryId,_that.tag,_that.previewImageUrl,_that.previewTitle,_that.previewDescription);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? title,  String? content,  String? url,  DateTime? time,  int categoryId,  String? tag,  String? previewImageUrl,  String? previewTitle,  String? previewDescription)  $default,) {final _that = this;
switch (_that) {
case _NoteEntity():
return $default(_that.id,_that.title,_that.content,_that.url,_that.time,_that.categoryId,_that.tag,_that.previewImageUrl,_that.previewTitle,_that.previewDescription);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? title,  String? content,  String? url,  DateTime? time,  int categoryId,  String? tag,  String? previewImageUrl,  String? previewTitle,  String? previewDescription)?  $default,) {final _that = this;
switch (_that) {
case _NoteEntity() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.url,_that.time,_that.categoryId,_that.tag,_that.previewImageUrl,_that.previewTitle,_that.previewDescription);case _:
  return null;

}
}

}

/// @nodoc


class _NoteEntity implements NoteEntity {
  const _NoteEntity({this.id, this.title, this.content, this.url, this.time, this.categoryId = AppConstants.homeCategoryId, this.tag, this.previewImageUrl, this.previewTitle, this.previewDescription});
  

/// 笔记ID，null 表示尚未持久化的新笔记
@override final  int? id;
/// 笔记标题，可为空
@override final  String? title;
/// 笔记内容
@override final  String? content;
/// url
@override final  String? url;
/// 创建/修改时间
@override final  DateTime? time;
/// 分类ID，用于关联到 CategoryEntity
@override@JsonKey() final  int categoryId;
/// 标签
@override final  String? tag;
/// 链接预览图片URL（网络链接笔记用）
@override final  String? previewImageUrl;
/// 链接预览标题（网络链接笔记用）
@override final  String? previewTitle;
/// 链接预览描述（网络链接笔记用）
@override final  String? previewDescription;

/// Create a copy of NoteEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteEntityCopyWith<_NoteEntity> get copyWith => __$NoteEntityCopyWithImpl<_NoteEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.url, url) || other.url == url)&&(identical(other.time, time) || other.time == time)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.tag, tag) || other.tag == tag)&&(identical(other.previewImageUrl, previewImageUrl) || other.previewImageUrl == previewImageUrl)&&(identical(other.previewTitle, previewTitle) || other.previewTitle == previewTitle)&&(identical(other.previewDescription, previewDescription) || other.previewDescription == previewDescription));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,content,url,time,categoryId,tag,previewImageUrl,previewTitle,previewDescription);

@override
String toString() {
  return 'NoteEntity(id: $id, title: $title, content: $content, url: $url, time: $time, categoryId: $categoryId, tag: $tag, previewImageUrl: $previewImageUrl, previewTitle: $previewTitle, previewDescription: $previewDescription)';
}


}

/// @nodoc
abstract mixin class _$NoteEntityCopyWith<$Res> implements $NoteEntityCopyWith<$Res> {
  factory _$NoteEntityCopyWith(_NoteEntity value, $Res Function(_NoteEntity) _then) = __$NoteEntityCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? title, String? content, String? url, DateTime? time, int categoryId, String? tag, String? previewImageUrl, String? previewTitle, String? previewDescription
});




}
/// @nodoc
class __$NoteEntityCopyWithImpl<$Res>
    implements _$NoteEntityCopyWith<$Res> {
  __$NoteEntityCopyWithImpl(this._self, this._then);

  final _NoteEntity _self;
  final $Res Function(_NoteEntity) _then;

/// Create a copy of NoteEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? title = freezed,Object? content = freezed,Object? url = freezed,Object? time = freezed,Object? categoryId = null,Object? tag = freezed,Object? previewImageUrl = freezed,Object? previewTitle = freezed,Object? previewDescription = freezed,}) {
  return _then(_NoteEntity(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,time: freezed == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,tag: freezed == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String?,previewImageUrl: freezed == previewImageUrl ? _self.previewImageUrl : previewImageUrl // ignore: cast_nullable_to_non_nullable
as String?,previewTitle: freezed == previewTitle ? _self.previewTitle : previewTitle // ignore: cast_nullable_to_non_nullable
as String?,previewDescription: freezed == previewDescription ? _self.previewDescription : previewDescription // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
