// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_cluster.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMemoryClusterCollection on Isar {
  IsarCollection<MemoryCluster> get memoryClusters => this.collection();
}

const MemoryClusterSchema = CollectionSchema(
  name: r'MemoryCluster',
  id: 6016391400559658201,
  properties: {
    r'coverFileId': PropertySchema(
      id: 0,
      name: r'coverFileId',
      type: IsarType.long,
    ),
    r'endTime': PropertySchema(id: 1, name: r'endTime', type: IsarType.long),
    r'fileIds': PropertySchema(
      id: 2,
      name: r'fileIds',
      type: IsarType.longList,
    ),
    r'generatedAt': PropertySchema(
      id: 3,
      name: r'generatedAt',
      type: IsarType.long,
    ),
    r'kind': PropertySchema(
      id: 4,
      name: r'kind',
      type: IsarType.byte,
      enumMap: _MemoryClusterkindEnumValueMap,
    ),
    r'personIds': PropertySchema(
      id: 5,
      name: r'personIds',
      type: IsarType.stringList,
    ),
    r'signature': PropertySchema(
      id: 6,
      name: r'signature',
      type: IsarType.string,
    ),
    r'startTime': PropertySchema(
      id: 7,
      name: r'startTime',
      type: IsarType.long,
    ),
    r'title': PropertySchema(id: 8, name: r'title', type: IsarType.string),
  },

  estimateSize: _memoryClusterEstimateSize,
  serialize: _memoryClusterSerialize,
  deserialize: _memoryClusterDeserialize,
  deserializeProp: _memoryClusterDeserializeProp,
  idName: r'id',
  indexes: {
    r'signature': IndexSchema(
      id: 4701578645143940109,
      name: r'signature',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'signature',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'startTime': IndexSchema(
      id: -3870335341264752872,
      name: r'startTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'startTime',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _memoryClusterGetId,
  getLinks: _memoryClusterGetLinks,
  attach: _memoryClusterAttach,
  version: '3.3.2',
);

int _memoryClusterEstimateSize(
  MemoryCluster object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.fileIds.length * 8;
  bytesCount += 3 + object.personIds.length * 3;
  {
    for (var i = 0; i < object.personIds.length; i++) {
      final value = object.personIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.signature.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _memoryClusterSerialize(
  MemoryCluster object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.coverFileId);
  writer.writeLong(offsets[1], object.endTime);
  writer.writeLongList(offsets[2], object.fileIds);
  writer.writeLong(offsets[3], object.generatedAt);
  writer.writeByte(offsets[4], object.kind.index);
  writer.writeStringList(offsets[5], object.personIds);
  writer.writeString(offsets[6], object.signature);
  writer.writeLong(offsets[7], object.startTime);
  writer.writeString(offsets[8], object.title);
}

MemoryCluster _memoryClusterDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MemoryCluster();
  object.coverFileId = reader.readLongOrNull(offsets[0]);
  object.endTime = reader.readLong(offsets[1]);
  object.fileIds = reader.readLongList(offsets[2]) ?? [];
  object.generatedAt = reader.readLong(offsets[3]);
  object.id = id;
  object.kind =
      _MemoryClusterkindValueEnumMap[reader.readByteOrNull(offsets[4])] ??
      MemoryKind.people;
  object.personIds = reader.readStringList(offsets[5]) ?? [];
  object.signature = reader.readString(offsets[6]);
  object.startTime = reader.readLong(offsets[7]);
  object.title = reader.readString(offsets[8]);
  return object;
}

P _memoryClusterDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLongList(offset) ?? []) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (_MemoryClusterkindValueEnumMap[reader.readByteOrNull(offset)] ??
              MemoryKind.people)
          as P;
    case 5:
      return (reader.readStringList(offset) ?? []) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _MemoryClusterkindEnumValueMap = {'people': 0, 'trip': 1, 'onThisDay': 2};
const _MemoryClusterkindValueEnumMap = {
  0: MemoryKind.people,
  1: MemoryKind.trip,
  2: MemoryKind.onThisDay,
};

Id _memoryClusterGetId(MemoryCluster object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _memoryClusterGetLinks(MemoryCluster object) {
  return [];
}

void _memoryClusterAttach(
  IsarCollection<dynamic> col,
  Id id,
  MemoryCluster object,
) {
  object.id = id;
}

extension MemoryClusterByIndex on IsarCollection<MemoryCluster> {
  Future<MemoryCluster?> getBySignature(String signature) {
    return getByIndex(r'signature', [signature]);
  }

  MemoryCluster? getBySignatureSync(String signature) {
    return getByIndexSync(r'signature', [signature]);
  }

  Future<bool> deleteBySignature(String signature) {
    return deleteByIndex(r'signature', [signature]);
  }

  bool deleteBySignatureSync(String signature) {
    return deleteByIndexSync(r'signature', [signature]);
  }

  Future<List<MemoryCluster?>> getAllBySignature(List<String> signatureValues) {
    final values = signatureValues.map((e) => [e]).toList();
    return getAllByIndex(r'signature', values);
  }

  List<MemoryCluster?> getAllBySignatureSync(List<String> signatureValues) {
    final values = signatureValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'signature', values);
  }

  Future<int> deleteAllBySignature(List<String> signatureValues) {
    final values = signatureValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'signature', values);
  }

  int deleteAllBySignatureSync(List<String> signatureValues) {
    final values = signatureValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'signature', values);
  }

  Future<Id> putBySignature(MemoryCluster object) {
    return putByIndex(r'signature', object);
  }

  Id putBySignatureSync(MemoryCluster object, {bool saveLinks = true}) {
    return putByIndexSync(r'signature', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySignature(List<MemoryCluster> objects) {
    return putAllByIndex(r'signature', objects);
  }

  List<Id> putAllBySignatureSync(
    List<MemoryCluster> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'signature', objects, saveLinks: saveLinks);
  }
}

extension MemoryClusterQueryWhereSort
    on QueryBuilder<MemoryCluster, MemoryCluster, QWhere> {
  QueryBuilder<MemoryCluster, MemoryCluster, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterWhere> anyStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'startTime'),
      );
    });
  }
}

extension MemoryClusterQueryWhere
    on QueryBuilder<MemoryCluster, MemoryCluster, QWhereClause> {
  QueryBuilder<MemoryCluster, MemoryCluster, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterWhereClause> idBetween(
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

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterWhereClause>
  signatureEqualTo(String signature) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'signature', value: [signature]),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterWhereClause>
  signatureNotEqualTo(String signature) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'signature',
                lower: [],
                upper: [signature],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'signature',
                lower: [signature],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'signature',
                lower: [signature],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'signature',
                lower: [],
                upper: [signature],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterWhereClause>
  startTimeEqualTo(int startTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'startTime', value: [startTime]),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterWhereClause>
  startTimeNotEqualTo(int startTime) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startTime',
                lower: [],
                upper: [startTime],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startTime',
                lower: [startTime],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startTime',
                lower: [startTime],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startTime',
                lower: [],
                upper: [startTime],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterWhereClause>
  startTimeGreaterThan(int startTime, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'startTime',
          lower: [startTime],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterWhereClause>
  startTimeLessThan(int startTime, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'startTime',
          lower: [],
          upper: [startTime],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterWhereClause>
  startTimeBetween(
    int lowerStartTime,
    int upperStartTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'startTime',
          lower: [lowerStartTime],
          includeLower: includeLower,
          upper: [upperStartTime],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension MemoryClusterQueryFilter
    on QueryBuilder<MemoryCluster, MemoryCluster, QFilterCondition> {
  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  coverFileIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'coverFileId'),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  coverFileIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'coverFileId'),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  coverFileIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'coverFileId', value: value),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  coverFileIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'coverFileId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  coverFileIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'coverFileId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  coverFileIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'coverFileId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  endTimeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'endTime', value: value),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  endTimeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'endTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  endTimeLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'endTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  endTimeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'endTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  fileIdsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileIds', value: value),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  fileIdsElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileIds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  fileIdsElementLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileIds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  fileIdsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  fileIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fileIds', length, true, length, true);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  fileIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fileIds', 0, true, 0, true);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  fileIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fileIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  fileIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fileIds', 0, true, length, include);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  fileIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fileIds', length, include, 999999, true);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  fileIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fileIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  generatedAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'generatedAt', value: value),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  generatedAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'generatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  generatedAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'generatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  generatedAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'generatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
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

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition> idBetween(
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

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition> kindEqualTo(
    MemoryKind value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'kind', value: value),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  kindGreaterThan(MemoryKind value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'kind',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  kindLessThan(MemoryKind value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'kind',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition> kindBetween(
    MemoryKind lower,
    MemoryKind upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'kind',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'personIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'personIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'personIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'personIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'personIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'personIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'personIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'personIds',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'personIds', value: ''),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'personIds', value: ''),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'personIds', length, true, length, true);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'personIds', 0, true, 0, true);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'personIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'personIds', 0, true, length, include);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'personIds', length, include, 999999, true);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  personIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'personIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  signatureEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'signature',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  signatureGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'signature',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  signatureLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'signature',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  signatureBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'signature',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  signatureStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'signature',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  signatureEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'signature',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  signatureContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'signature',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  signatureMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'signature',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  signatureIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'signature', value: ''),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  signatureIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'signature', value: ''),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  startTimeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startTime', value: value),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  startTimeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  startTimeLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  startTimeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }
}

extension MemoryClusterQueryObject
    on QueryBuilder<MemoryCluster, MemoryCluster, QFilterCondition> {}

extension MemoryClusterQueryLinks
    on QueryBuilder<MemoryCluster, MemoryCluster, QFilterCondition> {}

extension MemoryClusterQuerySortBy
    on QueryBuilder<MemoryCluster, MemoryCluster, QSortBy> {
  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> sortByCoverFileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverFileId', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy>
  sortByCoverFileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverFileId', Sort.desc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> sortByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> sortByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> sortByGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy>
  sortByGeneratedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.desc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> sortByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> sortByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> sortBySignature() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy>
  sortBySignatureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.desc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> sortByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy>
  sortByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension MemoryClusterQuerySortThenBy
    on QueryBuilder<MemoryCluster, MemoryCluster, QSortThenBy> {
  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> thenByCoverFileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverFileId', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy>
  thenByCoverFileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverFileId', Sort.desc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> thenByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> thenByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> thenByGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy>
  thenByGeneratedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.desc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> thenByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> thenByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> thenBySignature() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy>
  thenBySignatureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.desc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> thenByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy>
  thenByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension MemoryClusterQueryWhereDistinct
    on QueryBuilder<MemoryCluster, MemoryCluster, QDistinct> {
  QueryBuilder<MemoryCluster, MemoryCluster, QDistinct>
  distinctByCoverFileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'coverFileId');
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QDistinct> distinctByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endTime');
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QDistinct> distinctByFileIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileIds');
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QDistinct>
  distinctByGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'generatedAt');
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QDistinct> distinctByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kind');
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QDistinct> distinctByPersonIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personIds');
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QDistinct> distinctBySignature({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'signature', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QDistinct> distinctByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startTime');
    });
  }

  QueryBuilder<MemoryCluster, MemoryCluster, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension MemoryClusterQueryProperty
    on QueryBuilder<MemoryCluster, MemoryCluster, QQueryProperty> {
  QueryBuilder<MemoryCluster, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MemoryCluster, int?, QQueryOperations> coverFileIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'coverFileId');
    });
  }

  QueryBuilder<MemoryCluster, int, QQueryOperations> endTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endTime');
    });
  }

  QueryBuilder<MemoryCluster, List<int>, QQueryOperations> fileIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileIds');
    });
  }

  QueryBuilder<MemoryCluster, int, QQueryOperations> generatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'generatedAt');
    });
  }

  QueryBuilder<MemoryCluster, MemoryKind, QQueryOperations> kindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kind');
    });
  }

  QueryBuilder<MemoryCluster, List<String>, QQueryOperations>
  personIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personIds');
    });
  }

  QueryBuilder<MemoryCluster, String, QQueryOperations> signatureProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'signature');
    });
  }

  QueryBuilder<MemoryCluster, int, QQueryOperations> startTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startTime');
    });
  }

  QueryBuilder<MemoryCluster, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}
