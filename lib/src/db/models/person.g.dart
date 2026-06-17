// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPersonCollection on Isar {
  IsarCollection<Person> get persons => this.collection();
}

const PersonSchema = CollectionSchema(
  name: r'Person',
  id: 7854610480646705599,
  properties: {
    r'avatarFaceID': PropertySchema(
      id: 0,
      name: r'avatarFaceID',
      type: IsarType.string,
    ),
    r'birthDate': PropertySchema(
      id: 1,
      name: r'birthDate',
      type: IsarType.string,
    ),
    r'clusterIds': PropertySchema(
      id: 2,
      name: r'clusterIds',
      type: IsarType.stringList,
    ),
    r'fileIds': PropertySchema(
      id: 3,
      name: r'fileIds',
      type: IsarType.longList,
    ),
    r'isDeleted': PropertySchema(
      id: 4,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isHidden': PropertySchema(id: 5, name: r'isHidden', type: IsarType.bool),
    r'name': PropertySchema(id: 6, name: r'name', type: IsarType.string),
    r'remoteID': PropertySchema(
      id: 7,
      name: r'remoteID',
      type: IsarType.string,
    ),
    r'updationTime': PropertySchema(
      id: 8,
      name: r'updationTime',
      type: IsarType.long,
    ),
  },

  estimateSize: _personEstimateSize,
  serialize: _personSerialize,
  deserialize: _personDeserialize,
  deserializeProp: _personDeserializeProp,
  idName: r'id',
  indexes: {
    r'remoteID': IndexSchema(
      id: 8280972950722306723,
      name: r'remoteID',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'remoteID',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _personGetId,
  getLinks: _personGetLinks,
  attach: _personAttach,
  version: '3.3.2',
);

int _personEstimateSize(
  Person object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.avatarFaceID;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.birthDate;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.clusterIds.length * 3;
  {
    for (var i = 0; i < object.clusterIds.length; i++) {
      final value = object.clusterIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.fileIds.length * 8;
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.remoteID.length * 3;
  return bytesCount;
}

void _personSerialize(
  Person object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.avatarFaceID);
  writer.writeString(offsets[1], object.birthDate);
  writer.writeStringList(offsets[2], object.clusterIds);
  writer.writeLongList(offsets[3], object.fileIds);
  writer.writeBool(offsets[4], object.isDeleted);
  writer.writeBool(offsets[5], object.isHidden);
  writer.writeString(offsets[6], object.name);
  writer.writeString(offsets[7], object.remoteID);
  writer.writeLong(offsets[8], object.updationTime);
}

Person _personDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Person();
  object.avatarFaceID = reader.readStringOrNull(offsets[0]);
  object.birthDate = reader.readStringOrNull(offsets[1]);
  object.clusterIds = reader.readStringList(offsets[2]) ?? [];
  object.fileIds = reader.readLongList(offsets[3]) ?? [];
  object.id = id;
  object.isDeleted = reader.readBool(offsets[4]);
  object.isHidden = reader.readBool(offsets[5]);
  object.name = reader.readStringOrNull(offsets[6]);
  object.remoteID = reader.readString(offsets[7]);
  object.updationTime = reader.readLong(offsets[8]);
  return object;
}

P _personDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringList(offset) ?? []) as P;
    case 3:
      return (reader.readLongList(offset) ?? []) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _personGetId(Person object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _personGetLinks(Person object) {
  return [];
}

void _personAttach(IsarCollection<dynamic> col, Id id, Person object) {
  object.id = id;
}

extension PersonByIndex on IsarCollection<Person> {
  Future<Person?> getByRemoteID(String remoteID) {
    return getByIndex(r'remoteID', [remoteID]);
  }

  Person? getByRemoteIDSync(String remoteID) {
    return getByIndexSync(r'remoteID', [remoteID]);
  }

  Future<bool> deleteByRemoteID(String remoteID) {
    return deleteByIndex(r'remoteID', [remoteID]);
  }

  bool deleteByRemoteIDSync(String remoteID) {
    return deleteByIndexSync(r'remoteID', [remoteID]);
  }

  Future<List<Person?>> getAllByRemoteID(List<String> remoteIDValues) {
    final values = remoteIDValues.map((e) => [e]).toList();
    return getAllByIndex(r'remoteID', values);
  }

  List<Person?> getAllByRemoteIDSync(List<String> remoteIDValues) {
    final values = remoteIDValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'remoteID', values);
  }

  Future<int> deleteAllByRemoteID(List<String> remoteIDValues) {
    final values = remoteIDValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'remoteID', values);
  }

  int deleteAllByRemoteIDSync(List<String> remoteIDValues) {
    final values = remoteIDValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'remoteID', values);
  }

  Future<Id> putByRemoteID(Person object) {
    return putByIndex(r'remoteID', object);
  }

  Id putByRemoteIDSync(Person object, {bool saveLinks = true}) {
    return putByIndexSync(r'remoteID', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRemoteID(List<Person> objects) {
    return putAllByIndex(r'remoteID', objects);
  }

  List<Id> putAllByRemoteIDSync(List<Person> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'remoteID', objects, saveLinks: saveLinks);
  }
}

extension PersonQueryWhereSort on QueryBuilder<Person, Person, QWhere> {
  QueryBuilder<Person, Person, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PersonQueryWhere on QueryBuilder<Person, Person, QWhereClause> {
  QueryBuilder<Person, Person, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Person, Person, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Person, Person, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterWhereClause> idBetween(
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

  QueryBuilder<Person, Person, QAfterWhereClause> remoteIDEqualTo(
    String remoteID,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'remoteID', value: [remoteID]),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterWhereClause> remoteIDNotEqualTo(
    String remoteID,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteID',
                lower: [],
                upper: [remoteID],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteID',
                lower: [remoteID],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteID',
                lower: [remoteID],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteID',
                lower: [],
                upper: [remoteID],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension PersonQueryFilter on QueryBuilder<Person, Person, QFilterCondition> {
  QueryBuilder<Person, Person, QAfterFilterCondition> avatarFaceIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'avatarFaceID'),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> avatarFaceIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'avatarFaceID'),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> avatarFaceIDEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'avatarFaceID',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> avatarFaceIDGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'avatarFaceID',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> avatarFaceIDLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'avatarFaceID',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> avatarFaceIDBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'avatarFaceID',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> avatarFaceIDStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'avatarFaceID',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> avatarFaceIDEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'avatarFaceID',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> avatarFaceIDContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'avatarFaceID',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> avatarFaceIDMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'avatarFaceID',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> avatarFaceIDIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'avatarFaceID', value: ''),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> avatarFaceIDIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'avatarFaceID', value: ''),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> birthDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'birthDate'),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> birthDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'birthDate'),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> birthDateEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'birthDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> birthDateGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'birthDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> birthDateLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'birthDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> birthDateBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'birthDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> birthDateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'birthDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> birthDateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'birthDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> birthDateContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'birthDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> birthDateMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'birthDate',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> birthDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'birthDate', value: ''),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> birthDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'birthDate', value: ''),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> clusterIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'clusterIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition>
  clusterIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'clusterIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> clusterIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'clusterIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> clusterIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'clusterIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition>
  clusterIdsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'clusterIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> clusterIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'clusterIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> clusterIdsElementContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'clusterIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> clusterIdsElementMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'clusterIds',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition>
  clusterIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'clusterIds', value: ''),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition>
  clusterIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'clusterIds', value: ''),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> clusterIdsLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'clusterIds', length, true, length, true);
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> clusterIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'clusterIds', 0, true, 0, true);
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> clusterIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'clusterIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> clusterIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'clusterIds', 0, true, length, include);
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition>
  clusterIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'clusterIds', length, include, 999999, true);
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> clusterIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clusterIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> fileIdsElementEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileIds', value: value),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> fileIdsElementGreaterThan(
    int value, {
    bool include = false,
  }) {
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

  QueryBuilder<Person, Person, QAfterFilterCondition> fileIdsElementLessThan(
    int value, {
    bool include = false,
  }) {
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

  QueryBuilder<Person, Person, QAfterFilterCondition> fileIdsElementBetween(
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

  QueryBuilder<Person, Person, QAfterFilterCondition> fileIdsLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fileIds', length, true, length, true);
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> fileIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fileIds', 0, true, 0, true);
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> fileIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fileIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> fileIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fileIds', 0, true, length, include);
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> fileIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fileIds', length, include, 999999, true);
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> fileIdsLengthBetween(
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

  QueryBuilder<Person, Person, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Person, Person, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Person, Person, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Person, Person, QAfterFilterCondition> isDeletedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDeleted', value: value),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> isHiddenEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isHidden', value: value),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'name'),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'name'),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Person, Person, QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<Person, Person, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<Person, Person, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<Person, Person, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Person, Person, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Person, Person, QAfterFilterCondition> nameContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Person, Person, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Person, Person, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> remoteIDEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'remoteID',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> remoteIDGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remoteID',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> remoteIDLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remoteID',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> remoteIDBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remoteID',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> remoteIDStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'remoteID',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> remoteIDEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'remoteID',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> remoteIDContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'remoteID',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> remoteIDMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'remoteID',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> remoteIDIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remoteID', value: ''),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> remoteIDIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'remoteID', value: ''),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> updationTimeEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updationTime', value: value),
      );
    });
  }

  QueryBuilder<Person, Person, QAfterFilterCondition> updationTimeGreaterThan(
    int value, {
    bool include = false,
  }) {
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

  QueryBuilder<Person, Person, QAfterFilterCondition> updationTimeLessThan(
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

  QueryBuilder<Person, Person, QAfterFilterCondition> updationTimeBetween(
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

extension PersonQueryObject on QueryBuilder<Person, Person, QFilterCondition> {}

extension PersonQueryLinks on QueryBuilder<Person, Person, QFilterCondition> {}

extension PersonQuerySortBy on QueryBuilder<Person, Person, QSortBy> {
  QueryBuilder<Person, Person, QAfterSortBy> sortByAvatarFaceID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarFaceID', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> sortByAvatarFaceIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarFaceID', Sort.desc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> sortByBirthDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'birthDate', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> sortByBirthDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'birthDate', Sort.desc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> sortByIsHidden() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> sortByIsHiddenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.desc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> sortByRemoteID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteID', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> sortByRemoteIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteID', Sort.desc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> sortByUpdationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> sortByUpdationTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.desc);
    });
  }
}

extension PersonQuerySortThenBy on QueryBuilder<Person, Person, QSortThenBy> {
  QueryBuilder<Person, Person, QAfterSortBy> thenByAvatarFaceID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarFaceID', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenByAvatarFaceIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarFaceID', Sort.desc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenByBirthDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'birthDate', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenByBirthDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'birthDate', Sort.desc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenByIsHidden() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenByIsHiddenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.desc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenByRemoteID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteID', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenByRemoteIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteID', Sort.desc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenByUpdationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.asc);
    });
  }

  QueryBuilder<Person, Person, QAfterSortBy> thenByUpdationTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updationTime', Sort.desc);
    });
  }
}

extension PersonQueryWhereDistinct on QueryBuilder<Person, Person, QDistinct> {
  QueryBuilder<Person, Person, QDistinct> distinctByAvatarFaceID({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avatarFaceID', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Person, Person, QDistinct> distinctByBirthDate({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'birthDate', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Person, Person, QDistinct> distinctByClusterIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clusterIds');
    });
  }

  QueryBuilder<Person, Person, QDistinct> distinctByFileIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileIds');
    });
  }

  QueryBuilder<Person, Person, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<Person, Person, QDistinct> distinctByIsHidden() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isHidden');
    });
  }

  QueryBuilder<Person, Person, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Person, Person, QDistinct> distinctByRemoteID({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteID', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Person, Person, QDistinct> distinctByUpdationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updationTime');
    });
  }
}

extension PersonQueryProperty on QueryBuilder<Person, Person, QQueryProperty> {
  QueryBuilder<Person, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Person, String?, QQueryOperations> avatarFaceIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatarFaceID');
    });
  }

  QueryBuilder<Person, String?, QQueryOperations> birthDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'birthDate');
    });
  }

  QueryBuilder<Person, List<String>, QQueryOperations> clusterIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clusterIds');
    });
  }

  QueryBuilder<Person, List<int>, QQueryOperations> fileIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileIds');
    });
  }

  QueryBuilder<Person, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<Person, bool, QQueryOperations> isHiddenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isHidden');
    });
  }

  QueryBuilder<Person, String?, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Person, String, QQueryOperations> remoteIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteID');
    });
  }

  QueryBuilder<Person, int, QQueryOperations> updationTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updationTime');
    });
  }
}
