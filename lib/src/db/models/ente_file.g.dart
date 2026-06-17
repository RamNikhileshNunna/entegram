// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ente_file.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEnteFileCollection on Isar {
  IsarCollection<EnteFile> get enteFiles => this.collection();
}

const EnteFileSchema = CollectionSchema(
  name: r'EnteFile',
  id: -4727976828947338192,
  properties: {
    r'collectionID': PropertySchema(
      id: 0,
      name: r'collectionID',
      type: IsarType.long,
    ),
    r'creationTime': PropertySchema(
      id: 1,
      name: r'creationTime',
      type: IsarType.long,
    ),
    r'encryptedKey': PropertySchema(
      id: 2,
      name: r'encryptedKey',
      type: IsarType.string,
    ),
    r'faceClusterIds': PropertySchema(
      id: 3,
      name: r'faceClusterIds',
      type: IsarType.stringList,
    ),
    r'fileDecryptionHeader': PropertySchema(
      id: 4,
      name: r'fileDecryptionHeader',
      type: IsarType.string,
    ),
    r'fileType': PropertySchema(id: 5, name: r'fileType', type: IsarType.long),
    r'hash': PropertySchema(id: 6, name: r'hash', type: IsarType.string),
    r'height': PropertySchema(id: 7, name: r'height', type: IsarType.long),
    r'isDeleted': PropertySchema(
      id: 8,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'keyDecryptionNonce': PropertySchema(
      id: 9,
      name: r'keyDecryptionNonce',
      type: IsarType.string,
    ),
    r'latitude': PropertySchema(
      id: 10,
      name: r'latitude',
      type: IsarType.double,
    ),
    r'longitude': PropertySchema(
      id: 11,
      name: r'longitude',
      type: IsarType.double,
    ),
    r'modificationTime': PropertySchema(
      id: 12,
      name: r'modificationTime',
      type: IsarType.long,
    ),
    r'ownerID': PropertySchema(id: 13, name: r'ownerID', type: IsarType.long),
    r'personIds': PropertySchema(
      id: 14,
      name: r'personIds',
      type: IsarType.stringList,
    ),
    r'thumbnailDecryptionHeader': PropertySchema(
      id: 15,
      name: r'thumbnailDecryptionHeader',
      type: IsarType.string,
    ),
    r'title': PropertySchema(id: 16, name: r'title', type: IsarType.string),
    r'updationTime': PropertySchema(
      id: 17,
      name: r'updationTime',
      type: IsarType.long,
    ),
    r'width': PropertySchema(id: 18, name: r'width', type: IsarType.long),
  },

  estimateSize: _enteFileEstimateSize,
  serialize: _enteFileSerialize,
  deserialize: _enteFileDeserialize,
  deserializeProp: _enteFileDeserializeProp,
  idName: r'id',
  indexes: {
    r'collectionID': IndexSchema(
      id: 5856867985300705204,
      name: r'collectionID',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'collectionID',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'creationTime': IndexSchema(
      id: 7992538883628812436,
      name: r'creationTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'creationTime',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _enteFileGetId,
  getLinks: _enteFileGetLinks,
  attach: _enteFileAttach,
  version: '3.3.2',
);

int _enteFileEstimateSize(
  EnteFile object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.encryptedKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.faceClusterIds.length * 3;
  {
    for (var i = 0; i < object.faceClusterIds.length; i++) {
      final value = object.faceClusterIds[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.fileDecryptionHeader;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.hash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.keyDecryptionNonce;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.personIds.length * 3;
  {
    for (var i = 0; i < object.personIds.length; i++) {
      final value = object.personIds[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.thumbnailDecryptionHeader;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.title;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _enteFileSerialize(
  EnteFile object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.collectionID);
  writer.writeLong(offsets[1], object.creationTime);
  writer.writeString(offsets[2], object.encryptedKey);
  writer.writeStringList(offsets[3], object.faceClusterIds);
  writer.writeString(offsets[4], object.fileDecryptionHeader);
  writer.writeLong(offsets[5], object.fileType);
  writer.writeString(offsets[6], object.hash);
  writer.writeLong(offsets[7], object.height);
  writer.writeBool(offsets[8], object.isDeleted);
  writer.writeString(offsets[9], object.keyDecryptionNonce);
  writer.writeDouble(offsets[10], object.latitude);
  writer.writeDouble(offsets[11], object.longitude);
  writer.writeLong(offsets[12], object.modificationTime);
  writer.writeLong(offsets[13], object.ownerID);
  writer.writeStringList(offsets[14], object.personIds);
  writer.writeString(offsets[15], object.thumbnailDecryptionHeader);
  writer.writeString(offsets[16], object.title);
  writer.writeLong(offsets[17], object.updationTime);
  writer.writeLong(offsets[18], object.width);
}

EnteFile _enteFileDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EnteFile();
  object.collectionID = reader.readLong(offsets[0]);
  object.creationTime = reader.readLong(offsets[1]);
  object.encryptedKey = reader.readStringOrNull(offsets[2]);
  object.faceClusterIds = reader.readStringList(offsets[3]) ?? [];
  object.fileDecryptionHeader = reader.readStringOrNull(offsets[4]);
  object.fileType = reader.readLong(offsets[5]);
  object.hash = reader.readStringOrNull(offsets[6]);
  object.height = reader.readLongOrNull(offsets[7]);
  object.id = id;
  object.isDeleted = reader.readBool(offsets[8]);
  object.keyDecryptionNonce = reader.readStringOrNull(offsets[9]);
  object.latitude = reader.readDoubleOrNull(offsets[10]);
  object.longitude = reader.readDoubleOrNull(offsets[11]);
  object.modificationTime = reader.readLong(offsets[12]);
  object.ownerID = reader.readLong(offsets[13]);
  object.personIds = reader.readStringList(offsets[14]) ?? [];
  object.thumbnailDecryptionHeader = reader.readStringOrNull(offsets[15]);
  object.title = reader.readStringOrNull(offsets[16]);
  object.updationTime = reader.readLong(offsets[17]);
  object.width = reader.readLongOrNull(offsets[18]);
  return object;
}

P _enteFileDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readDoubleOrNull(offset)) as P;
    case 11:
      return (reader.readDoubleOrNull(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readStringList(offset) ?? []) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    case 18:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _enteFileGetId(EnteFile object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _enteFileGetLinks(EnteFile object) {
  return [];
}

void _enteFileAttach(IsarCollection<dynamic> col, Id id, EnteFile object) {
  object.id = id;
}

extension EnteFileQueryWhereSort on QueryBuilder<EnteFile, EnteFile, QWhere> {
  QueryBuilder<EnteFile, EnteFile, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterWhere> anyCollectionID() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'collectionID'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterWhere> anyCreationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'creationTime'),
      );
    });
  }
}

extension EnteFileQueryWhere on QueryBuilder<EnteFile, EnteFile, QWhereClause> {
  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> idBetween(
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

  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> collectionIDEqualTo(
    int collectionID,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'collectionID',
          value: [collectionID],
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> collectionIDNotEqualTo(
    int collectionID,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'collectionID',
                lower: [],
                upper: [collectionID],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'collectionID',
                lower: [collectionID],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'collectionID',
                lower: [collectionID],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'collectionID',
                lower: [],
                upper: [collectionID],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> collectionIDGreaterThan(
    int collectionID, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'collectionID',
          lower: [collectionID],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> collectionIDLessThan(
    int collectionID, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'collectionID',
          lower: [],
          upper: [collectionID],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> collectionIDBetween(
    int lowerCollectionID,
    int upperCollectionID, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'collectionID',
          lower: [lowerCollectionID],
          includeLower: includeLower,
          upper: [upperCollectionID],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> creationTimeEqualTo(
    int creationTime,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'creationTime',
          value: [creationTime],
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> creationTimeNotEqualTo(
    int creationTime,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creationTime',
                lower: [],
                upper: [creationTime],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creationTime',
                lower: [creationTime],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creationTime',
                lower: [creationTime],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creationTime',
                lower: [],
                upper: [creationTime],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> creationTimeGreaterThan(
    int creationTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'creationTime',
          lower: [creationTime],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> creationTimeLessThan(
    int creationTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'creationTime',
          lower: [],
          upper: [creationTime],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterWhereClause> creationTimeBetween(
    int lowerCreationTime,
    int upperCreationTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'creationTime',
          lower: [lowerCreationTime],
          includeLower: includeLower,
          upper: [upperCreationTime],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension EnteFileQueryFilter
    on QueryBuilder<EnteFile, EnteFile, QFilterCondition> {
  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> collectionIDEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'collectionID', value: value),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  collectionIDGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'collectionID',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> collectionIDLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'collectionID',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> collectionIDBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'collectionID',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> creationTimeEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'creationTime', value: value),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  creationTimeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'creationTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> creationTimeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'creationTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> creationTimeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'creationTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> encryptedKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'encryptedKey'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  encryptedKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'encryptedKey'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> encryptedKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'encryptedKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  encryptedKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'encryptedKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> encryptedKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'encryptedKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> encryptedKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'encryptedKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  encryptedKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'encryptedKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> encryptedKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'encryptedKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> encryptedKeyContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'encryptedKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> encryptedKeyMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'encryptedKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  encryptedKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'encryptedKey', value: ''),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  encryptedKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'encryptedKey', value: ''),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'faceClusterIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'faceClusterIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'faceClusterIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'faceClusterIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'faceClusterIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'faceClusterIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'faceClusterIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'faceClusterIds',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'faceClusterIds', value: ''),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'faceClusterIds', value: ''),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'faceClusterIds', length, true, length, true);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'faceClusterIds', 0, true, 0, true);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'faceClusterIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'faceClusterIds', 0, true, length, include);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'faceClusterIds', length, include, 999999, true);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  faceClusterIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'faceClusterIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  fileDecryptionHeaderIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'fileDecryptionHeader'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  fileDecryptionHeaderIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'fileDecryptionHeader'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  fileDecryptionHeaderEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fileDecryptionHeader',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  fileDecryptionHeaderGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileDecryptionHeader',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  fileDecryptionHeaderLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileDecryptionHeader',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  fileDecryptionHeaderBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileDecryptionHeader',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  fileDecryptionHeaderStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fileDecryptionHeader',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  fileDecryptionHeaderEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fileDecryptionHeader',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  fileDecryptionHeaderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fileDecryptionHeader',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  fileDecryptionHeaderMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fileDecryptionHeader',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  fileDecryptionHeaderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileDecryptionHeader', value: ''),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  fileDecryptionHeaderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'fileDecryptionHeader',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> fileTypeEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileType', value: value),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> fileTypeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> fileTypeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> fileTypeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> hashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'hash'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> hashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'hash'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> hashEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'hash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> hashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'hash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> hashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'hash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> hashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'hash',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> hashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'hash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> hashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'hash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> hashContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'hash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> hashMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'hash',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> hashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hash', value: ''),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> hashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'hash', value: ''),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> heightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'height'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> heightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'height'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> heightEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'height', value: value),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> heightGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'height',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> heightLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'height',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> heightBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'height',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> idBetween(
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> isDeletedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDeleted', value: value),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  keyDecryptionNonceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'keyDecryptionNonce'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  keyDecryptionNonceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'keyDecryptionNonce'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  keyDecryptionNonceEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'keyDecryptionNonce',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  keyDecryptionNonceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'keyDecryptionNonce',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  keyDecryptionNonceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'keyDecryptionNonce',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  keyDecryptionNonceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'keyDecryptionNonce',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  keyDecryptionNonceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'keyDecryptionNonce',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  keyDecryptionNonceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'keyDecryptionNonce',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  keyDecryptionNonceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'keyDecryptionNonce',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  keyDecryptionNonceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'keyDecryptionNonce',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  keyDecryptionNonceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'keyDecryptionNonce', value: ''),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  keyDecryptionNonceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'keyDecryptionNonce', value: ''),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> latitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'latitude'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> latitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'latitude'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> latitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> latitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> latitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> latitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'latitude',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> longitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'longitude'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> longitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'longitude'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> longitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> longitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> longitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> longitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'longitude',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  modificationTimeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'modificationTime', value: value),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  modificationTimeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'modificationTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  modificationTimeLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'modificationTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  modificationTimeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'modificationTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> ownerIDEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ownerID', value: value),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> ownerIDGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ownerID',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> ownerIDLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ownerID',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> ownerIDBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ownerID',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  personIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'personIds', value: ''),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  personIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'personIds', value: ''),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  personIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'personIds', length, true, length, true);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> personIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'personIds', 0, true, 0, true);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  personIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'personIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  personIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'personIds', 0, true, length, include);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  personIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'personIds', length, include, 999999, true);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  thumbnailDecryptionHeaderIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'thumbnailDecryptionHeader'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  thumbnailDecryptionHeaderIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'thumbnailDecryptionHeader'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  thumbnailDecryptionHeaderEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'thumbnailDecryptionHeader',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  thumbnailDecryptionHeaderGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'thumbnailDecryptionHeader',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  thumbnailDecryptionHeaderLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'thumbnailDecryptionHeader',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  thumbnailDecryptionHeaderBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'thumbnailDecryptionHeader',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  thumbnailDecryptionHeaderStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'thumbnailDecryptionHeader',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  thumbnailDecryptionHeaderEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'thumbnailDecryptionHeader',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  thumbnailDecryptionHeaderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'thumbnailDecryptionHeader',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  thumbnailDecryptionHeaderMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'thumbnailDecryptionHeader',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  thumbnailDecryptionHeaderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'thumbnailDecryptionHeader',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  thumbnailDecryptionHeaderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'thumbnailDecryptionHeader',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'title'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'title'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> titleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> titleGreaterThan(
    String? value, {
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> titleLessThan(
    String? value, {
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> titleBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> titleContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> titleMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> updationTimeEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updationTime', value: value),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition>
  updationTimeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updationTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> updationTimeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updationTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> updationTimeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updationTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> widthIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'width'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> widthIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'width'),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> widthEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'width', value: value),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> widthGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'width',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> widthLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'width',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterFilterCondition> widthBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'width',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension EnteFileQueryObject
    on QueryBuilder<EnteFile, EnteFile, QFilterCondition> {}

extension EnteFileQueryLinks
    on QueryBuilder<EnteFile, EnteFile, QFilterCondition> {}

extension EnteFileQuerySortBy on QueryBuilder<EnteFile, EnteFile, QSortBy> {
  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByCollectionID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionID', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByCollectionIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionID', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByCreationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creationTime', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByCreationTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creationTime', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByEncryptedKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedKey', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByEncryptedKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedKey', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByFileDecryptionHeader() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileDecryptionHeader', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy>
  sortByFileDecryptionHeaderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileDecryptionHeader', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByFileType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileType', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByFileTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileType', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByKeyDecryptionNonce() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyDecryptionNonce', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy>
  sortByKeyDecryptionNonceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyDecryptionNonce', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByModificationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modificationTime', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByModificationTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modificationTime', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByOwnerID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerID', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByOwnerIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerID', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy>
  sortByThumbnailDecryptionHeader() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailDecryptionHeader', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy>
  sortByThumbnailDecryptionHeaderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailDecryptionHeader', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByUpdationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByUpdationTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> sortByWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.desc);
    });
  }
}

extension EnteFileQuerySortThenBy
    on QueryBuilder<EnteFile, EnteFile, QSortThenBy> {
  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByCollectionID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionID', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByCollectionIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionID', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByCreationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creationTime', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByCreationTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creationTime', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByEncryptedKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedKey', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByEncryptedKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedKey', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByFileDecryptionHeader() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileDecryptionHeader', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy>
  thenByFileDecryptionHeaderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileDecryptionHeader', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByFileType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileType', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByFileTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileType', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByKeyDecryptionNonce() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyDecryptionNonce', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy>
  thenByKeyDecryptionNonceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyDecryptionNonce', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByModificationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modificationTime', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByModificationTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modificationTime', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByOwnerID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerID', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByOwnerIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerID', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy>
  thenByThumbnailDecryptionHeader() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailDecryptionHeader', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy>
  thenByThumbnailDecryptionHeaderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailDecryptionHeader', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByUpdationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByUpdationTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.desc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.asc);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QAfterSortBy> thenByWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.desc);
    });
  }
}

extension EnteFileQueryWhereDistinct
    on QueryBuilder<EnteFile, EnteFile, QDistinct> {
  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByCollectionID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'collectionID');
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByCreationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'creationTime');
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByEncryptedKey({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'encryptedKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByFaceClusterIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'faceClusterIds');
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByFileDecryptionHeader({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'fileDecryptionHeader',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByFileType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileType');
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByHash({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'height');
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByKeyDecryptionNonce({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'keyDecryptionNonce',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitude');
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitude');
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByModificationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modificationTime');
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByOwnerID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerID');
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByPersonIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personIds');
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct>
  distinctByThumbnailDecryptionHeader({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'thumbnailDecryptionHeader',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByUpdationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updationTime');
    });
  }

  QueryBuilder<EnteFile, EnteFile, QDistinct> distinctByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'width');
    });
  }
}

extension EnteFileQueryProperty
    on QueryBuilder<EnteFile, EnteFile, QQueryProperty> {
  QueryBuilder<EnteFile, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EnteFile, int, QQueryOperations> collectionIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'collectionID');
    });
  }

  QueryBuilder<EnteFile, int, QQueryOperations> creationTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'creationTime');
    });
  }

  QueryBuilder<EnteFile, String?, QQueryOperations> encryptedKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'encryptedKey');
    });
  }

  QueryBuilder<EnteFile, List<String>, QQueryOperations>
  faceClusterIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'faceClusterIds');
    });
  }

  QueryBuilder<EnteFile, String?, QQueryOperations>
  fileDecryptionHeaderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileDecryptionHeader');
    });
  }

  QueryBuilder<EnteFile, int, QQueryOperations> fileTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileType');
    });
  }

  QueryBuilder<EnteFile, String?, QQueryOperations> hashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hash');
    });
  }

  QueryBuilder<EnteFile, int?, QQueryOperations> heightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'height');
    });
  }

  QueryBuilder<EnteFile, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<EnteFile, String?, QQueryOperations>
  keyDecryptionNonceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keyDecryptionNonce');
    });
  }

  QueryBuilder<EnteFile, double?, QQueryOperations> latitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitude');
    });
  }

  QueryBuilder<EnteFile, double?, QQueryOperations> longitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitude');
    });
  }

  QueryBuilder<EnteFile, int, QQueryOperations> modificationTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modificationTime');
    });
  }

  QueryBuilder<EnteFile, int, QQueryOperations> ownerIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerID');
    });
  }

  QueryBuilder<EnteFile, List<String>, QQueryOperations> personIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personIds');
    });
  }

  QueryBuilder<EnteFile, String?, QQueryOperations>
  thumbnailDecryptionHeaderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailDecryptionHeader');
    });
  }

  QueryBuilder<EnteFile, String?, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<EnteFile, int, QQueryOperations> updationTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updationTime');
    });
  }

  QueryBuilder<EnteFile, int?, QQueryOperations> widthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'width');
    });
  }
}
