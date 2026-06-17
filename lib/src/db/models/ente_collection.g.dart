// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ente_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEnteCollectionCollection on Isar {
  IsarCollection<EnteCollection> get enteCollections => this.collection();
}

const EnteCollectionSchema = CollectionSchema(
  name: r'EnteCollection',
  id: 5711469949736624564,
  properties: {
    r'collectionID': PropertySchema(
      id: 0,
      name: r'collectionID',
      type: IsarType.long,
    ),
    r'encryptedKey': PropertySchema(
      id: 1,
      name: r'encryptedKey',
      type: IsarType.string,
    ),
    r'isDeleted': PropertySchema(
      id: 2,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isOwned': PropertySchema(id: 3, name: r'isOwned', type: IsarType.bool),
    r'keyDecryptionNonce': PropertySchema(
      id: 4,
      name: r'keyDecryptionNonce',
      type: IsarType.string,
    ),
    r'name': PropertySchema(id: 5, name: r'name', type: IsarType.string),
    r'ownerID': PropertySchema(id: 6, name: r'ownerID', type: IsarType.long),
    r'type': PropertySchema(id: 7, name: r'type', type: IsarType.string),
    r'updationTime': PropertySchema(
      id: 8,
      name: r'updationTime',
      type: IsarType.long,
    ),
  },

  estimateSize: _enteCollectionEstimateSize,
  serialize: _enteCollectionSerialize,
  deserialize: _enteCollectionDeserialize,
  deserializeProp: _enteCollectionDeserializeProp,
  idName: r'id',
  indexes: {
    r'isOwned': IndexSchema(
      id: -8062236361993569491,
      name: r'isOwned',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isOwned',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _enteCollectionGetId,
  getLinks: _enteCollectionGetLinks,
  attach: _enteCollectionAttach,
  version: '3.3.2',
);

int _enteCollectionEstimateSize(
  EnteCollection object,
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
  {
    final value = object.keyDecryptionNonce;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.type;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _enteCollectionSerialize(
  EnteCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.collectionID);
  writer.writeString(offsets[1], object.encryptedKey);
  writer.writeBool(offsets[2], object.isDeleted);
  writer.writeBool(offsets[3], object.isOwned);
  writer.writeString(offsets[4], object.keyDecryptionNonce);
  writer.writeString(offsets[5], object.name);
  writer.writeLong(offsets[6], object.ownerID);
  writer.writeString(offsets[7], object.type);
  writer.writeLong(offsets[8], object.updationTime);
}

EnteCollection _enteCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EnteCollection();
  object.collectionID = reader.readLong(offsets[0]);
  object.encryptedKey = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.isDeleted = reader.readBool(offsets[2]);
  object.isOwned = reader.readBool(offsets[3]);
  object.keyDecryptionNonce = reader.readStringOrNull(offsets[4]);
  object.name = reader.readStringOrNull(offsets[5]);
  object.ownerID = reader.readLong(offsets[6]);
  object.type = reader.readStringOrNull(offsets[7]);
  object.updationTime = reader.readLong(offsets[8]);
  return object;
}

P _enteCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _enteCollectionGetId(EnteCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _enteCollectionGetLinks(EnteCollection object) {
  return [];
}

void _enteCollectionAttach(
  IsarCollection<dynamic> col,
  Id id,
  EnteCollection object,
) {
  object.id = id;
}

extension EnteCollectionQueryWhereSort
    on QueryBuilder<EnteCollection, EnteCollection, QWhere> {
  QueryBuilder<EnteCollection, EnteCollection, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterWhere> anyIsOwned() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isOwned'),
      );
    });
  }
}

extension EnteCollectionQueryWhere
    on QueryBuilder<EnteCollection, EnteCollection, QWhereClause> {
  QueryBuilder<EnteCollection, EnteCollection, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterWhereClause> idBetween(
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterWhereClause>
  isOwnedEqualTo(bool isOwned) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isOwned', value: [isOwned]),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterWhereClause>
  isOwnedNotEqualTo(bool isOwned) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isOwned',
                lower: [],
                upper: [isOwned],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isOwned',
                lower: [isOwned],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isOwned',
                lower: [isOwned],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isOwned',
                lower: [],
                upper: [isOwned],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension EnteCollectionQueryFilter
    on QueryBuilder<EnteCollection, EnteCollection, QFilterCondition> {
  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  collectionIDEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'collectionID', value: value),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  collectionIDLessThan(int value, {bool include = false}) {
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  collectionIDBetween(
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  encryptedKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'encryptedKey'),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  encryptedKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'encryptedKey'),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  encryptedKeyEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  encryptedKeyLessThan(
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  encryptedKeyBetween(
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  encryptedKeyEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  encryptedKeyContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  encryptedKeyMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  encryptedKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'encryptedKey', value: ''),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  encryptedKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'encryptedKey', value: ''),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition> idBetween(
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDeleted', value: value),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  isOwnedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isOwned', value: value),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  keyDecryptionNonceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'keyDecryptionNonce'),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  keyDecryptionNonceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'keyDecryptionNonce'),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  keyDecryptionNonceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'keyDecryptionNonce', value: ''),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  keyDecryptionNonceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'keyDecryptionNonce', value: ''),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'name'),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'name'),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  nameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  nameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  nameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  ownerIDEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ownerID', value: value),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  ownerIDGreaterThan(int value, {bool include = false}) {
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  ownerIDLessThan(int value, {bool include = false}) {
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  ownerIDBetween(
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  typeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'type'),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  typeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'type'),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  typeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  typeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  typeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  typeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  typeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  typeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'type',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  updationTimeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updationTime', value: value),
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  updationTimeLessThan(int value, {bool include = false}) {
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

  QueryBuilder<EnteCollection, EnteCollection, QAfterFilterCondition>
  updationTimeBetween(
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
}

extension EnteCollectionQueryObject
    on QueryBuilder<EnteCollection, EnteCollection, QFilterCondition> {}

extension EnteCollectionQueryLinks
    on QueryBuilder<EnteCollection, EnteCollection, QFilterCondition> {}

extension EnteCollectionQuerySortBy
    on QueryBuilder<EnteCollection, EnteCollection, QSortBy> {
  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  sortByCollectionID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionID', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  sortByCollectionIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionID', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  sortByEncryptedKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedKey', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  sortByEncryptedKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedKey', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> sortByIsOwned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOwned', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  sortByIsOwnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOwned', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  sortByKeyDecryptionNonce() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyDecryptionNonce', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  sortByKeyDecryptionNonceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyDecryptionNonce', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> sortByOwnerID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerID', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  sortByOwnerIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerID', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  sortByUpdationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  sortByUpdationTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.desc);
    });
  }
}

extension EnteCollectionQuerySortThenBy
    on QueryBuilder<EnteCollection, EnteCollection, QSortThenBy> {
  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  thenByCollectionID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionID', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  thenByCollectionIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collectionID', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  thenByEncryptedKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedKey', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  thenByEncryptedKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedKey', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> thenByIsOwned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOwned', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  thenByIsOwnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOwned', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  thenByKeyDecryptionNonce() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyDecryptionNonce', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  thenByKeyDecryptionNonceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyDecryptionNonce', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> thenByOwnerID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerID', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  thenByOwnerIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerID', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  thenByUpdationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.asc);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QAfterSortBy>
  thenByUpdationTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.desc);
    });
  }
}

extension EnteCollectionQueryWhereDistinct
    on QueryBuilder<EnteCollection, EnteCollection, QDistinct> {
  QueryBuilder<EnteCollection, EnteCollection, QDistinct>
  distinctByCollectionID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'collectionID');
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QDistinct>
  distinctByEncryptedKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'encryptedKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QDistinct>
  distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QDistinct> distinctByIsOwned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isOwned');
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QDistinct>
  distinctByKeyDecryptionNonce({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'keyDecryptionNonce',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QDistinct> distinctByOwnerID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerID');
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QDistinct> distinctByType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EnteCollection, EnteCollection, QDistinct>
  distinctByUpdationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updationTime');
    });
  }
}

extension EnteCollectionQueryProperty
    on QueryBuilder<EnteCollection, EnteCollection, QQueryProperty> {
  QueryBuilder<EnteCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EnteCollection, int, QQueryOperations> collectionIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'collectionID');
    });
  }

  QueryBuilder<EnteCollection, String?, QQueryOperations>
  encryptedKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'encryptedKey');
    });
  }

  QueryBuilder<EnteCollection, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<EnteCollection, bool, QQueryOperations> isOwnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isOwned');
    });
  }

  QueryBuilder<EnteCollection, String?, QQueryOperations>
  keyDecryptionNonceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keyDecryptionNonce');
    });
  }

  QueryBuilder<EnteCollection, String?, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<EnteCollection, int, QQueryOperations> ownerIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerID');
    });
  }

  QueryBuilder<EnteCollection, String?, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<EnteCollection, int, QQueryOperations> updationTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updationTime');
    });
  }
}
