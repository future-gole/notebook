// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncLogCollection on Isar {
  IsarCollection<SyncLog> get syncLogs => this.collection();
}

const SyncLogSchema = CollectionSchema(
  name: r'SyncLog',
  id: 7389629408375913179,
  properties: {
    r'createdTime': PropertySchema(
      id: 0,
      name: r'createdTime',
      type: IsarType.dateTime,
    ),
    r'lastError': PropertySchema(
      id: 1,
      name: r'lastError',
      type: IsarType.string,
    ),
    r'lastSyncTime': PropertySchema(
      id: 2,
      name: r'lastSyncTime',
      type: IsarType.dateTime,
    ),
    r'lastSyncTimestamp': PropertySchema(
      id: 3,
      name: r'lastSyncTimestamp',
      type: IsarType.long,
    ),
    r'remoteDeviceId': PropertySchema(
      id: 4,
      name: r'remoteDeviceId',
      type: IsarType.string,
    ),
    r'remoteDeviceName': PropertySchema(
      id: 5,
      name: r'remoteDeviceName',
      type: IsarType.string,
    ),
    r'remoteIp': PropertySchema(
      id: 6,
      name: r'remoteIp',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 7,
      name: r'syncStatus',
      type: IsarType.long,
    ),
  },

  estimateSize: _syncLogEstimateSize,
  serialize: _syncLogSerialize,
  deserialize: _syncLogDeserialize,
  deserializeProp: _syncLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'remoteIp': IndexSchema(
      id: -7322182204781518405,
      name: r'remoteIp',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'remoteIp',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _syncLogGetId,
  getLinks: _syncLogGetLinks,
  attach: _syncLogAttach,
  version: '3.3.0-dev.3',
);

int _syncLogEstimateSize(
  SyncLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.lastError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.remoteDeviceId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.remoteDeviceName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.remoteIp.length * 3;
  return bytesCount;
}

void _syncLogSerialize(
  SyncLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdTime);
  writer.writeString(offsets[1], object.lastError);
  writer.writeDateTime(offsets[2], object.lastSyncTime);
  writer.writeLong(offsets[3], object.lastSyncTimestamp);
  writer.writeString(offsets[4], object.remoteDeviceId);
  writer.writeString(offsets[5], object.remoteDeviceName);
  writer.writeString(offsets[6], object.remoteIp);
  writer.writeLong(offsets[7], object.syncStatus);
}

SyncLog _syncLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncLog();
  object.createdTime = reader.readDateTimeOrNull(offsets[0]);
  object.id = id;
  object.lastError = reader.readStringOrNull(offsets[1]);
  object.lastSyncTime = reader.readDateTimeOrNull(offsets[2]);
  object.lastSyncTimestamp = reader.readLong(offsets[3]);
  object.remoteDeviceId = reader.readStringOrNull(offsets[4]);
  object.remoteDeviceName = reader.readStringOrNull(offsets[5]);
  object.remoteIp = reader.readString(offsets[6]);
  object.syncStatus = reader.readLong(offsets[7]);
  return object;
}

P _syncLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syncLogGetId(SyncLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syncLogGetLinks(SyncLog object) {
  return [];
}

void _syncLogAttach(IsarCollection<dynamic> col, Id id, SyncLog object) {
  object.id = id;
}

extension SyncLogByIndex on IsarCollection<SyncLog> {
  Future<SyncLog?> getByRemoteIp(String remoteIp) {
    return getByIndex(r'remoteIp', [remoteIp]);
  }

  SyncLog? getByRemoteIpSync(String remoteIp) {
    return getByIndexSync(r'remoteIp', [remoteIp]);
  }

  Future<bool> deleteByRemoteIp(String remoteIp) {
    return deleteByIndex(r'remoteIp', [remoteIp]);
  }

  bool deleteByRemoteIpSync(String remoteIp) {
    return deleteByIndexSync(r'remoteIp', [remoteIp]);
  }

  Future<List<SyncLog?>> getAllByRemoteIp(List<String> remoteIpValues) {
    final values = remoteIpValues.map((e) => [e]).toList();
    return getAllByIndex(r'remoteIp', values);
  }

  List<SyncLog?> getAllByRemoteIpSync(List<String> remoteIpValues) {
    final values = remoteIpValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'remoteIp', values);
  }

  Future<int> deleteAllByRemoteIp(List<String> remoteIpValues) {
    final values = remoteIpValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'remoteIp', values);
  }

  int deleteAllByRemoteIpSync(List<String> remoteIpValues) {
    final values = remoteIpValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'remoteIp', values);
  }

  Future<Id> putByRemoteIp(SyncLog object) {
    return putByIndex(r'remoteIp', object);
  }

  Id putByRemoteIpSync(SyncLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'remoteIp', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRemoteIp(List<SyncLog> objects) {
    return putAllByIndex(r'remoteIp', objects);
  }

  List<Id> putAllByRemoteIpSync(
    List<SyncLog> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'remoteIp', objects, saveLinks: saveLinks);
  }
}

extension SyncLogQueryWhereSort on QueryBuilder<SyncLog, SyncLog, QWhere> {
  QueryBuilder<SyncLog, SyncLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncLogQueryWhere on QueryBuilder<SyncLog, SyncLog, QWhereClause> {
  QueryBuilder<SyncLog, SyncLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterWhereClause> remoteIpEqualTo(
    String remoteIp,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'remoteIp', value: [remoteIp]),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterWhereClause> remoteIpNotEqualTo(
    String remoteIp,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteIp',
                lower: [],
                upper: [remoteIp],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteIp',
                lower: [remoteIp],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteIp',
                lower: [remoteIp],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteIp',
                lower: [],
                upper: [remoteIp],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension SyncLogQueryFilter
    on QueryBuilder<SyncLog, SyncLog, QFilterCondition> {
  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> createdTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'createdTime'),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> createdTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'createdTime'),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> createdTimeEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdTime', value: value),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> createdTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> createdTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> createdTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastError'),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastError'),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastErrorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastError',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastErrorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastErrorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastErrorContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastErrorMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastError',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastError', value: ''),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lastError', value: ''),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastSyncTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastSyncTime'),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  lastSyncTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastSyncTime'),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastSyncTimeEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastSyncTime', value: value),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastSyncTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastSyncTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastSyncTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastSyncTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> lastSyncTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastSyncTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  lastSyncTimestampEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastSyncTimestamp', value: value),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  lastSyncTimestampGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastSyncTimestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  lastSyncTimestampLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastSyncTimestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  lastSyncTimestampBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastSyncTimestamp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteDeviceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'remoteDeviceId'),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  remoteDeviceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'remoteDeviceId'),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteDeviceIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'remoteDeviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  remoteDeviceIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remoteDeviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteDeviceIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remoteDeviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteDeviceIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remoteDeviceId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  remoteDeviceIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'remoteDeviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteDeviceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'remoteDeviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteDeviceIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'remoteDeviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteDeviceIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'remoteDeviceId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  remoteDeviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remoteDeviceId', value: ''),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  remoteDeviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'remoteDeviceId', value: ''),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  remoteDeviceNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'remoteDeviceName'),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  remoteDeviceNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'remoteDeviceName'),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteDeviceNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'remoteDeviceName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  remoteDeviceNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remoteDeviceName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  remoteDeviceNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remoteDeviceName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteDeviceNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remoteDeviceName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  remoteDeviceNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'remoteDeviceName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  remoteDeviceNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'remoteDeviceName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  remoteDeviceNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'remoteDeviceName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteDeviceNameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'remoteDeviceName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  remoteDeviceNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remoteDeviceName', value: ''),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition>
  remoteDeviceNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'remoteDeviceName', value: ''),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteIpEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'remoteIp',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteIpGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remoteIp',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteIpLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remoteIp',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteIpBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remoteIp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteIpStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'remoteIp',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteIpEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'remoteIp',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteIpContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'remoteIp',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteIpMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'remoteIp',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteIpIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remoteIp', value: ''),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> remoteIpIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'remoteIp', value: ''),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> syncStatusEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> syncStatusGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'syncStatus',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> syncStatusLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'syncStatus',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterFilterCondition> syncStatusBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'syncStatus',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SyncLogQueryObject
    on QueryBuilder<SyncLog, SyncLog, QFilterCondition> {}

extension SyncLogQueryLinks
    on QueryBuilder<SyncLog, SyncLog, QFilterCondition> {}

extension SyncLogQuerySortBy on QueryBuilder<SyncLog, SyncLog, QSortBy> {
  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortByCreatedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdTime', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortByCreatedTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdTime', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortByLastSyncTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncTime', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortByLastSyncTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncTime', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortByLastSyncTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncTimestamp', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortByLastSyncTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncTimestamp', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortByRemoteDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteDeviceId', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortByRemoteDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteDeviceId', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortByRemoteDeviceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteDeviceName', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortByRemoteDeviceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteDeviceName', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortByRemoteIp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteIp', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortByRemoteIpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteIp', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }
}

extension SyncLogQuerySortThenBy
    on QueryBuilder<SyncLog, SyncLog, QSortThenBy> {
  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByCreatedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdTime', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByCreatedTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdTime', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByLastSyncTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncTime', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByLastSyncTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncTime', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByLastSyncTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncTimestamp', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByLastSyncTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncTimestamp', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByRemoteDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteDeviceId', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByRemoteDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteDeviceId', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByRemoteDeviceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteDeviceName', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByRemoteDeviceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteDeviceName', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByRemoteIp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteIp', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenByRemoteIpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteIp', Sort.desc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QAfterSortBy> thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }
}

extension SyncLogQueryWhereDistinct
    on QueryBuilder<SyncLog, SyncLog, QDistinct> {
  QueryBuilder<SyncLog, SyncLog, QDistinct> distinctByCreatedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdTime');
    });
  }

  QueryBuilder<SyncLog, SyncLog, QDistinct> distinctByLastError({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastError', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QDistinct> distinctByLastSyncTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncTime');
    });
  }

  QueryBuilder<SyncLog, SyncLog, QDistinct> distinctByLastSyncTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncTimestamp');
    });
  }

  QueryBuilder<SyncLog, SyncLog, QDistinct> distinctByRemoteDeviceId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'remoteDeviceId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QDistinct> distinctByRemoteDeviceName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'remoteDeviceName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<SyncLog, SyncLog, QDistinct> distinctByRemoteIp({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteIp', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncLog, SyncLog, QDistinct> distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }
}

extension SyncLogQueryProperty
    on QueryBuilder<SyncLog, SyncLog, QQueryProperty> {
  QueryBuilder<SyncLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyncLog, DateTime?, QQueryOperations> createdTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdTime');
    });
  }

  QueryBuilder<SyncLog, String?, QQueryOperations> lastErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastError');
    });
  }

  QueryBuilder<SyncLog, DateTime?, QQueryOperations> lastSyncTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncTime');
    });
  }

  QueryBuilder<SyncLog, int, QQueryOperations> lastSyncTimestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncTimestamp');
    });
  }

  QueryBuilder<SyncLog, String?, QQueryOperations> remoteDeviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteDeviceId');
    });
  }

  QueryBuilder<SyncLog, String?, QQueryOperations> remoteDeviceNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteDeviceName');
    });
  }

  QueryBuilder<SyncLog, String, QQueryOperations> remoteIpProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteIp');
    });
  }

  QueryBuilder<SyncLog, int, QQueryOperations> syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }
}
