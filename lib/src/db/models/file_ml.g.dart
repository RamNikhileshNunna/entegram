// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_ml.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFileMlCollection on Isar {
  IsarCollection<FileMl> get fileMls => this.collection();
}

const FileMlSchema = CollectionSchema(
  name: r'FileMl',
  id: -8506685462301823053,
  properties: {
    r'creationTime': PropertySchema(
      id: 0,
      name: r'creationTime',
      type: IsarType.long,
    ),
    r'hasFile': PropertySchema(id: 1, name: r'hasFile', type: IsarType.bool),
    r'issue': PropertySchema(id: 2, name: r'issue', type: IsarType.string),
    r'pending': PropertySchema(id: 3, name: r'pending', type: IsarType.bool),
    r'promptRevision': PropertySchema(
      id: 4,
      name: r'promptRevision',
      type: IsarType.long,
    ),
    r'retryAt': PropertySchema(id: 5, name: r'retryAt', type: IsarType.long),
    r'scores': PropertySchema(
      id: 6,
      name: r'scores',
      type: IsarType.doubleList,
    ),
    r'updatedAt': PropertySchema(
      id: 7,
      name: r'updatedAt',
      type: IsarType.long,
    ),
  },

  estimateSize: _fileMlEstimateSize,
  serialize: _fileMlSerialize,
  deserialize: _fileMlDeserialize,
  deserializeProp: _fileMlDeserializeProp,
  idName: r'id',
  indexes: {
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
    r'hasFile': IndexSchema(
      id: -5430474558544470644,
      name: r'hasFile',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'hasFile',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'pending': IndexSchema(
      id: 8530226530755963391,
      name: r'pending',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'pending',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'retryAt': IndexSchema(
      id: 4032742812960899578,
      name: r'retryAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'retryAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _fileMlGetId,
  getLinks: _fileMlGetLinks,
  attach: _fileMlAttach,
  version: '3.3.2',
);

int _fileMlEstimateSize(
  FileMl object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.issue;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.scores.length * 8;
  return bytesCount;
}

void _fileMlSerialize(
  FileMl object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.creationTime);
  writer.writeBool(offsets[1], object.hasFile);
  writer.writeString(offsets[2], object.issue);
  writer.writeBool(offsets[3], object.pending);
  writer.writeLong(offsets[4], object.promptRevision);
  writer.writeLong(offsets[5], object.retryAt);
  writer.writeDoubleList(offsets[6], object.scores);
  writer.writeLong(offsets[7], object.updatedAt);
}

FileMl _fileMlDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FileMl();
  object.creationTime = reader.readLong(offsets[0]);
  object.hasFile = reader.readBool(offsets[1]);
  object.id = id;
  object.issue = reader.readStringOrNull(offsets[2]);
  object.pending = reader.readBool(offsets[3]);
  object.promptRevision = reader.readLong(offsets[4]);
  object.retryAt = reader.readLong(offsets[5]);
  object.scores = reader.readDoubleList(offsets[6]) ?? [];
  object.updatedAt = reader.readLong(offsets[7]);
  return object;
}

P _fileMlDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDoubleList(offset) ?? []) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _fileMlGetId(FileMl object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _fileMlGetLinks(FileMl object) {
  return [];
}

void _fileMlAttach(IsarCollection<dynamic> col, Id id, FileMl object) {
  object.id = id;
}

extension FileMlQueryWhereSort on QueryBuilder<FileMl, FileMl, QWhere> {
  QueryBuilder<FileMl, FileMl, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhere> anyCreationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'creationTime'),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhere> anyHasFile() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'hasFile'),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhere> anyPending() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'pending'),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhere> anyRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'retryAt'),
      );
    });
  }
}

extension FileMlQueryWhere on QueryBuilder<FileMl, FileMl, QWhereClause> {
  QueryBuilder<FileMl, FileMl, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> idBetween(
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

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> creationTimeEqualTo(
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

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> creationTimeNotEqualTo(
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

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> creationTimeGreaterThan(
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

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> creationTimeLessThan(
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

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> creationTimeBetween(
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

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> hasFileEqualTo(bool hasFile) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'hasFile', value: [hasFile]),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> hasFileNotEqualTo(
    bool hasFile,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'hasFile',
                lower: [],
                upper: [hasFile],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'hasFile',
                lower: [hasFile],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'hasFile',
                lower: [hasFile],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'hasFile',
                lower: [],
                upper: [hasFile],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> pendingEqualTo(bool pending) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'pending', value: [pending]),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> pendingNotEqualTo(
    bool pending,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pending',
                lower: [],
                upper: [pending],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pending',
                lower: [pending],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pending',
                lower: [pending],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pending',
                lower: [],
                upper: [pending],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> retryAtEqualTo(int retryAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'retryAt', value: [retryAt]),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> retryAtNotEqualTo(
    int retryAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'retryAt',
                lower: [],
                upper: [retryAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'retryAt',
                lower: [retryAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'retryAt',
                lower: [retryAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'retryAt',
                lower: [],
                upper: [retryAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> retryAtGreaterThan(
    int retryAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'retryAt',
          lower: [retryAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> retryAtLessThan(
    int retryAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'retryAt',
          lower: [],
          upper: [retryAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterWhereClause> retryAtBetween(
    int lowerRetryAt,
    int upperRetryAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'retryAt',
          lower: [lowerRetryAt],
          includeLower: includeLower,
          upper: [upperRetryAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension FileMlQueryFilter on QueryBuilder<FileMl, FileMl, QFilterCondition> {
  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> creationTimeEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'creationTime', value: value),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> creationTimeGreaterThan(
    int value, {
    bool include = false,
  }) {
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

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> creationTimeLessThan(
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

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> creationTimeBetween(
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

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> hasFileEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasFile', value: value),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> idBetween(
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

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> issueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'issue'),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> issueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'issue'),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> issueEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'issue',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> issueGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'issue',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> issueLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'issue',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> issueBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'issue',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> issueStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'issue',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> issueEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'issue',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> issueContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'issue',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> issueMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'issue',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> issueIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'issue', value: ''),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> issueIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'issue', value: ''),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> pendingEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pending', value: value),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> promptRevisionEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'promptRevision', value: value),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> promptRevisionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'promptRevision',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> promptRevisionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'promptRevision',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> promptRevisionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'promptRevision',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> retryAtEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'retryAt', value: value),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> retryAtGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'retryAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> retryAtLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'retryAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> retryAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'retryAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> scoresElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'scores',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> scoresElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'scores',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> scoresElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'scores',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> scoresElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'scores',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> scoresLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'scores', length, true, length, true);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> scoresIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'scores', 0, true, 0, true);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> scoresIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'scores', 0, false, 999999, true);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> scoresLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'scores', 0, true, length, include);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> scoresLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'scores', length, include, 999999, true);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> scoresLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'scores',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> updatedAtEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> updatedAtGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> updatedAtLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterFilterCondition> updatedAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension FileMlQueryObject on QueryBuilder<FileMl, FileMl, QFilterCondition> {}

extension FileMlQueryLinks on QueryBuilder<FileMl, FileMl, QFilterCondition> {}

extension FileMlQuerySortBy on QueryBuilder<FileMl, FileMl, QSortBy> {
  QueryBuilder<FileMl, FileMl, QAfterSortBy> sortByCreationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creationTime', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> sortByCreationTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creationTime', Sort.desc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> sortByHasFile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasFile', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> sortByHasFileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasFile', Sort.desc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> sortByIssue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'issue', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> sortByIssueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'issue', Sort.desc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> sortByPending() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pending', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> sortByPendingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pending', Sort.desc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> sortByPromptRevision() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptRevision', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> sortByPromptRevisionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptRevision', Sort.desc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> sortByRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryAt', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> sortByRetryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryAt', Sort.desc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension FileMlQuerySortThenBy on QueryBuilder<FileMl, FileMl, QSortThenBy> {
  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByCreationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creationTime', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByCreationTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creationTime', Sort.desc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByHasFile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasFile', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByHasFileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasFile', Sort.desc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByIssue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'issue', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByIssueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'issue', Sort.desc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByPending() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pending', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByPendingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pending', Sort.desc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByPromptRevision() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptRevision', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByPromptRevisionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptRevision', Sort.desc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryAt', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByRetryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryAt', Sort.desc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<FileMl, FileMl, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension FileMlQueryWhereDistinct on QueryBuilder<FileMl, FileMl, QDistinct> {
  QueryBuilder<FileMl, FileMl, QDistinct> distinctByCreationTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'creationTime');
    });
  }

  QueryBuilder<FileMl, FileMl, QDistinct> distinctByHasFile() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasFile');
    });
  }

  QueryBuilder<FileMl, FileMl, QDistinct> distinctByIssue({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'issue', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FileMl, FileMl, QDistinct> distinctByPending() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pending');
    });
  }

  QueryBuilder<FileMl, FileMl, QDistinct> distinctByPromptRevision() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'promptRevision');
    });
  }

  QueryBuilder<FileMl, FileMl, QDistinct> distinctByRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'retryAt');
    });
  }

  QueryBuilder<FileMl, FileMl, QDistinct> distinctByScores() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scores');
    });
  }

  QueryBuilder<FileMl, FileMl, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension FileMlQueryProperty on QueryBuilder<FileMl, FileMl, QQueryProperty> {
  QueryBuilder<FileMl, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FileMl, int, QQueryOperations> creationTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'creationTime');
    });
  }

  QueryBuilder<FileMl, bool, QQueryOperations> hasFileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasFile');
    });
  }

  QueryBuilder<FileMl, String?, QQueryOperations> issueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'issue');
    });
  }

  QueryBuilder<FileMl, bool, QQueryOperations> pendingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pending');
    });
  }

  QueryBuilder<FileMl, int, QQueryOperations> promptRevisionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'promptRevision');
    });
  }

  QueryBuilder<FileMl, int, QQueryOperations> retryAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'retryAt');
    });
  }

  QueryBuilder<FileMl, List<double>, QQueryOperations> scoresProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scores');
    });
  }

  QueryBuilder<FileMl, int, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
