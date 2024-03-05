// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlists.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDBPlaylistCollection on Isar {
  IsarCollection<DBPlaylist> get dBPlaylists => this.collection();
}

const DBPlaylistSchema = CollectionSchema(
  name: r'DBPlaylist',
  id: 6620789938256199997,
  properties: {
    r'accessKey': PropertySchema(
      id: 0,
      name: r'accessKey',
      type: IsarType.string,
    ),
    r'audios': PropertySchema(
      id: 1,
      name: r'audios',
      type: IsarType.objectList,
      target: r'DBAudio',
    ),
    r'color': PropertySchema(
      id: 2,
      name: r'color',
      type: IsarType.string,
    ),
    r'count': PropertySchema(
      id: 3,
      name: r'count',
      type: IsarType.long,
    ),
    r'createTime': PropertySchema(
      id: 4,
      name: r'createTime',
      type: IsarType.long,
    ),
    r'description': PropertySchema(
      id: 5,
      name: r'description',
      type: IsarType.string,
    ),
    r'followers': PropertySchema(
      id: 6,
      name: r'followers',
      type: IsarType.long,
    ),
    r'hashCode': PropertySchema(
      id: 7,
      name: r'hashCode',
      type: IsarType.long,
    ),
    r'id': PropertySchema(
      id: 8,
      name: r'id',
      type: IsarType.long,
    ),
    r'isCachingAllowed': PropertySchema(
      id: 9,
      name: r'isCachingAllowed',
      type: IsarType.bool,
    ),
    r'isFollowing': PropertySchema(
      id: 10,
      name: r'isFollowing',
      type: IsarType.bool,
    ),
    r'knownTracks': PropertySchema(
      id: 11,
      name: r'knownTracks',
      type: IsarType.objectList,
      target: r'DBAudio',
    ),
    r'ownerID': PropertySchema(
      id: 12,
      name: r'ownerID',
      type: IsarType.long,
    ),
    r'photo': PropertySchema(
      id: 13,
      name: r'photo',
      type: IsarType.object,
      target: r'DBThumbnails',
    ),
    r'plays': PropertySchema(
      id: 14,
      name: r'plays',
      type: IsarType.long,
    ),
    r'simillarity': PropertySchema(
      id: 15,
      name: r'simillarity',
      type: IsarType.double,
    ),
    r'subtitle': PropertySchema(
      id: 16,
      name: r'subtitle',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 17,
      name: r'title',
      type: IsarType.string,
    ),
    r'updateTime': PropertySchema(
      id: 18,
      name: r'updateTime',
      type: IsarType.long,
    )
  },
  estimateSize: _dBPlaylistEstimateSize,
  serialize: _dBPlaylistSerialize,
  deserialize: _dBPlaylistDeserialize,
  deserializeProp: _dBPlaylistDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {},
  embeddedSchemas: {
    r'DBThumbnails': DBThumbnailsSchema,
    r'DBAudio': DBAudioSchema,
    r'DBAlbum': DBAlbumSchema,
    r'DBLyrics': DBLyricsSchema,
    r'DBLyricTimestamp': DBLyricTimestampSchema
  },
  getId: _dBPlaylistGetId,
  getLinks: _dBPlaylistGetLinks,
  attach: _dBPlaylistAttach,
  version: '3.1.0+1',
);

int _dBPlaylistEstimateSize(
  DBPlaylist object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.accessKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.audios;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[DBAudio]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += DBAudioSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final value = object.color;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.knownTracks;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[DBAudio]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += DBAudioSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final value = object.photo;
    if (value != null) {
      bytesCount += 3 +
          DBThumbnailsSchema.estimateSize(
              value, allOffsets[DBThumbnails]!, allOffsets);
    }
  }
  {
    final value = object.subtitle;
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

void _dBPlaylistSerialize(
  DBPlaylist object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accessKey);
  writer.writeObjectList<DBAudio>(
    offsets[1],
    allOffsets,
    DBAudioSchema.serialize,
    object.audios,
  );
  writer.writeString(offsets[2], object.color);
  writer.writeLong(offsets[3], object.count);
  writer.writeLong(offsets[4], object.createTime);
  writer.writeString(offsets[5], object.description);
  writer.writeLong(offsets[6], object.followers);
  writer.writeLong(offsets[7], object.hashCode);
  writer.writeLong(offsets[8], object.id);
  writer.writeBool(offsets[9], object.isCachingAllowed);
  writer.writeBool(offsets[10], object.isFollowing);
  writer.writeObjectList<DBAudio>(
    offsets[11],
    allOffsets,
    DBAudioSchema.serialize,
    object.knownTracks,
  );
  writer.writeLong(offsets[12], object.ownerID);
  writer.writeObject<DBThumbnails>(
    offsets[13],
    allOffsets,
    DBThumbnailsSchema.serialize,
    object.photo,
  );
  writer.writeLong(offsets[14], object.plays);
  writer.writeDouble(offsets[15], object.simillarity);
  writer.writeString(offsets[16], object.subtitle);
  writer.writeString(offsets[17], object.title);
  writer.writeLong(offsets[18], object.updateTime);
}

DBPlaylist _dBPlaylistDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DBPlaylist(
    accessKey: reader.readStringOrNull(offsets[0]),
    audios: reader.readObjectList<DBAudio>(
      offsets[1],
      DBAudioSchema.deserialize,
      allOffsets,
      DBAudio(),
    ),
    color: reader.readStringOrNull(offsets[2]),
    count: reader.readLong(offsets[3]),
    createTime: reader.readLongOrNull(offsets[4]),
    description: reader.readStringOrNull(offsets[5]),
    followers: reader.readLongOrNull(offsets[6]) ?? 0,
    id: reader.readLong(offsets[8]),
    isCachingAllowed: reader.readBool(offsets[9]),
    isFollowing: reader.readBoolOrNull(offsets[10]),
    knownTracks: reader.readObjectList<DBAudio>(
      offsets[11],
      DBAudioSchema.deserialize,
      allOffsets,
      DBAudio(),
    ),
    ownerID: reader.readLong(offsets[12]),
    photo: reader.readObjectOrNull<DBThumbnails>(
      offsets[13],
      DBThumbnailsSchema.deserialize,
      allOffsets,
    ),
    plays: reader.readLongOrNull(offsets[14]) ?? 0,
    simillarity: reader.readDoubleOrNull(offsets[15]),
    subtitle: reader.readStringOrNull(offsets[16]),
    title: reader.readStringOrNull(offsets[17]),
    updateTime: reader.readLongOrNull(offsets[18]),
  );
  return object;
}

P _dBPlaylistDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readObjectList<DBAudio>(
        offset,
        DBAudioSchema.deserialize,
        allOffsets,
        DBAudio(),
      )) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBoolOrNull(offset)) as P;
    case 11:
      return (reader.readObjectList<DBAudio>(
        offset,
        DBAudioSchema.deserialize,
        allOffsets,
        DBAudio(),
      )) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readObjectOrNull<DBThumbnails>(
        offset,
        DBThumbnailsSchema.deserialize,
        allOffsets,
      )) as P;
    case 14:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 15:
      return (reader.readDoubleOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dBPlaylistGetId(DBPlaylist object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _dBPlaylistGetLinks(DBPlaylist object) {
  return [];
}

void _dBPlaylistAttach(IsarCollection<dynamic> col, Id id, DBPlaylist object) {}

extension DBPlaylistQueryWhereSort
    on QueryBuilder<DBPlaylist, DBPlaylist, QWhere> {
  QueryBuilder<DBPlaylist, DBPlaylist, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DBPlaylistQueryWhere
    on QueryBuilder<DBPlaylist, DBPlaylist, QWhereClause> {
  QueryBuilder<DBPlaylist, DBPlaylist, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterWhereClause> isarIdNotEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DBPlaylistQueryFilter
    on QueryBuilder<DBPlaylist, DBPlaylist, QFilterCondition> {
  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      accessKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accessKey',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      accessKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accessKey',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> accessKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      accessKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> accessKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> accessKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accessKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      accessKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> accessKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> accessKeyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> accessKeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'accessKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      accessKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accessKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      accessKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'accessKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> audiosIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'audios',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      audiosIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'audios',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      audiosLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'audios',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> audiosIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'audios',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      audiosIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'audios',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      audiosLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'audios',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      audiosLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'audios',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      audiosLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'audios',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> colorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'color',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> colorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'color',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> colorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> colorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> colorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> colorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'color',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> colorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> colorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> colorContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> colorMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'color',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> colorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'color',
        value: '',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      colorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'color',
        value: '',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> countEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'count',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> countGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'count',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> countLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'count',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> countBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'count',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      createTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createTime',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      createTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createTime',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> createTimeEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createTime',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      createTimeGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createTime',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      createTimeLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createTime',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> createTimeBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> followersEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followers',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      followersGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'followers',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> followersLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'followers',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> followersBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'followers',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> hashCodeEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      hashCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> hashCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> hashCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hashCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> idEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> idGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> idLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> idBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      isCachingAllowedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCachingAllowed',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      isFollowingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isFollowing',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      isFollowingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isFollowing',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      isFollowingEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFollowing',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> isarIdEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      knownTracksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'knownTracks',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      knownTracksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'knownTracks',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      knownTracksLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'knownTracks',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      knownTracksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'knownTracks',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      knownTracksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'knownTracks',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      knownTracksLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'knownTracks',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      knownTracksLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'knownTracks',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      knownTracksLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'knownTracks',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> ownerIDEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerID',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      ownerIDGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerID',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> ownerIDLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerID',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> ownerIDBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> photoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photo',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> photoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photo',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> playsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plays',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> playsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'plays',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> playsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'plays',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> playsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'plays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      simillarityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'simillarity',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      simillarityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'simillarity',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      simillarityEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'simillarity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      simillarityGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'simillarity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      simillarityLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'simillarity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      simillarityBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'simillarity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> subtitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subtitle',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      subtitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subtitle',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> subtitleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subtitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      subtitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subtitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> subtitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subtitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> subtitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subtitle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      subtitleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subtitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> subtitleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subtitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> subtitleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subtitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> subtitleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subtitle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      subtitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subtitle',
        value: '',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      subtitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subtitle',
        value: '',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> titleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> titleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> titleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> titleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      updateTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updateTime',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      updateTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updateTime',
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> updateTimeEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updateTime',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      updateTimeGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updateTime',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      updateTimeLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updateTime',
        value: value,
      ));
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> updateTimeBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updateTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DBPlaylistQueryObject
    on QueryBuilder<DBPlaylist, DBPlaylist, QFilterCondition> {
  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> audiosElement(
      FilterQuery<DBAudio> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'audios');
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition>
      knownTracksElement(FilterQuery<DBAudio> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'knownTracks');
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterFilterCondition> photo(
      FilterQuery<DBThumbnails> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'photo');
    });
  }
}

extension DBPlaylistQueryLinks
    on QueryBuilder<DBPlaylist, DBPlaylist, QFilterCondition> {}

extension DBPlaylistQuerySortBy
    on QueryBuilder<DBPlaylist, DBPlaylist, QSortBy> {
  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByAccessKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessKey', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByAccessKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessKey', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'count', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'count', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByCreateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createTime', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByCreateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createTime', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByFollowers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followers', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByFollowersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followers', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByIsCachingAllowed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCachingAllowed', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy>
      sortByIsCachingAllowedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCachingAllowed', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByIsFollowing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFollowing', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByIsFollowingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFollowing', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByOwnerID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerID', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByOwnerIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerID', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByPlays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plays', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByPlaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plays', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortBySimillarity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'simillarity', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortBySimillarityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'simillarity', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortBySubtitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitle', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortBySubtitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitle', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByUpdateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updateTime', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> sortByUpdateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updateTime', Sort.desc);
    });
  }
}

extension DBPlaylistQuerySortThenBy
    on QueryBuilder<DBPlaylist, DBPlaylist, QSortThenBy> {
  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByAccessKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessKey', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByAccessKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessKey', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'count', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'count', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByCreateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createTime', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByCreateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createTime', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByFollowers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followers', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByFollowersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followers', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByIsCachingAllowed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCachingAllowed', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy>
      thenByIsCachingAllowedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCachingAllowed', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByIsFollowing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFollowing', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByIsFollowingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFollowing', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByOwnerID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerID', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByOwnerIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerID', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByPlays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plays', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByPlaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plays', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenBySimillarity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'simillarity', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenBySimillarityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'simillarity', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenBySubtitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitle', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenBySubtitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitle', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByUpdateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updateTime', Sort.asc);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QAfterSortBy> thenByUpdateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updateTime', Sort.desc);
    });
  }
}

extension DBPlaylistQueryWhereDistinct
    on QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> {
  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctByAccessKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accessKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctByColor(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'color', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctByCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'count');
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctByCreateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createTime');
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctByFollowers() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followers');
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hashCode');
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctById() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id');
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctByIsCachingAllowed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCachingAllowed');
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctByIsFollowing() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFollowing');
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctByOwnerID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerID');
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctByPlays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'plays');
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctBySimillarity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'simillarity');
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctBySubtitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DBPlaylist, DBPlaylist, QDistinct> distinctByUpdateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updateTime');
    });
  }
}

extension DBPlaylistQueryProperty
    on QueryBuilder<DBPlaylist, DBPlaylist, QQueryProperty> {
  QueryBuilder<DBPlaylist, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<DBPlaylist, String?, QQueryOperations> accessKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accessKey');
    });
  }

  QueryBuilder<DBPlaylist, List<DBAudio>?, QQueryOperations> audiosProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audios');
    });
  }

  QueryBuilder<DBPlaylist, String?, QQueryOperations> colorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'color');
    });
  }

  QueryBuilder<DBPlaylist, int, QQueryOperations> countProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'count');
    });
  }

  QueryBuilder<DBPlaylist, int?, QQueryOperations> createTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createTime');
    });
  }

  QueryBuilder<DBPlaylist, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<DBPlaylist, int, QQueryOperations> followersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followers');
    });
  }

  QueryBuilder<DBPlaylist, int, QQueryOperations> hashCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hashCode');
    });
  }

  QueryBuilder<DBPlaylist, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DBPlaylist, bool, QQueryOperations> isCachingAllowedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCachingAllowed');
    });
  }

  QueryBuilder<DBPlaylist, bool?, QQueryOperations> isFollowingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFollowing');
    });
  }

  QueryBuilder<DBPlaylist, List<DBAudio>?, QQueryOperations>
      knownTracksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'knownTracks');
    });
  }

  QueryBuilder<DBPlaylist, int, QQueryOperations> ownerIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerID');
    });
  }

  QueryBuilder<DBPlaylist, DBThumbnails?, QQueryOperations> photoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'photo');
    });
  }

  QueryBuilder<DBPlaylist, int, QQueryOperations> playsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'plays');
    });
  }

  QueryBuilder<DBPlaylist, double?, QQueryOperations> simillarityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'simillarity');
    });
  }

  QueryBuilder<DBPlaylist, String?, QQueryOperations> subtitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtitle');
    });
  }

  QueryBuilder<DBPlaylist, String?, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<DBPlaylist, int?, QQueryOperations> updateTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updateTime');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const DBThumbnailsSchema = Schema(
  name: r'DBThumbnails',
  id: 4257073658254520342,
  properties: {
    r'height': PropertySchema(
      id: 0,
      name: r'height',
      type: IsarType.long,
    ),
    r'photo1200': PropertySchema(
      id: 1,
      name: r'photo1200',
      type: IsarType.string,
    ),
    r'photo135': PropertySchema(
      id: 2,
      name: r'photo135',
      type: IsarType.string,
    ),
    r'photo270': PropertySchema(
      id: 3,
      name: r'photo270',
      type: IsarType.string,
    ),
    r'photo300': PropertySchema(
      id: 4,
      name: r'photo300',
      type: IsarType.string,
    ),
    r'photo34': PropertySchema(
      id: 5,
      name: r'photo34',
      type: IsarType.string,
    ),
    r'photo600': PropertySchema(
      id: 6,
      name: r'photo600',
      type: IsarType.string,
    ),
    r'photo68': PropertySchema(
      id: 7,
      name: r'photo68',
      type: IsarType.string,
    ),
    r'width': PropertySchema(
      id: 8,
      name: r'width',
      type: IsarType.long,
    )
  },
  estimateSize: _dBThumbnailsEstimateSize,
  serialize: _dBThumbnailsSerialize,
  deserialize: _dBThumbnailsDeserialize,
  deserializeProp: _dBThumbnailsDeserializeProp,
);

int _dBThumbnailsEstimateSize(
  DBThumbnails object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.photo1200;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.photo135;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.photo270;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.photo300;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.photo34;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.photo600;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.photo68;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dBThumbnailsSerialize(
  DBThumbnails object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.height);
  writer.writeString(offsets[1], object.photo1200);
  writer.writeString(offsets[2], object.photo135);
  writer.writeString(offsets[3], object.photo270);
  writer.writeString(offsets[4], object.photo300);
  writer.writeString(offsets[5], object.photo34);
  writer.writeString(offsets[6], object.photo600);
  writer.writeString(offsets[7], object.photo68);
  writer.writeLong(offsets[8], object.width);
}

DBThumbnails _dBThumbnailsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DBThumbnails(
    height: reader.readLongOrNull(offsets[0]),
    photo1200: reader.readStringOrNull(offsets[1]),
    photo135: reader.readStringOrNull(offsets[2]),
    photo270: reader.readStringOrNull(offsets[3]),
    photo300: reader.readStringOrNull(offsets[4]),
    photo34: reader.readStringOrNull(offsets[5]),
    photo600: reader.readStringOrNull(offsets[6]),
    photo68: reader.readStringOrNull(offsets[7]),
    width: reader.readLongOrNull(offsets[8]),
  );
  return object;
}

P _dBThumbnailsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension DBThumbnailsQueryFilter
    on QueryBuilder<DBThumbnails, DBThumbnails, QFilterCondition> {
  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      heightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      heightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition> heightEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'height',
        value: value,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      heightGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'height',
        value: value,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      heightLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'height',
        value: value,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition> heightBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'height',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo1200IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photo1200',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo1200IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photo1200',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo1200EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photo1200',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo1200GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photo1200',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo1200LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photo1200',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo1200Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photo1200',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo1200StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photo1200',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo1200EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photo1200',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo1200Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photo1200',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo1200Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photo1200',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo1200IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photo1200',
        value: '',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo1200IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photo1200',
        value: '',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo135IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photo135',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo135IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photo135',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo135EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photo135',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo135GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photo135',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo135LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photo135',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo135Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photo135',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo135StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photo135',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo135EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photo135',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo135Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photo135',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo135Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photo135',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo135IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photo135',
        value: '',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo135IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photo135',
        value: '',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo270IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photo270',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo270IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photo270',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo270EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photo270',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo270GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photo270',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo270LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photo270',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo270Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photo270',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo270StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photo270',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo270EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photo270',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo270Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photo270',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo270Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photo270',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo270IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photo270',
        value: '',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo270IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photo270',
        value: '',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo300IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photo300',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo300IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photo300',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo300EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photo300',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo300GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photo300',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo300LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photo300',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo300Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photo300',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo300StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photo300',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo300EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photo300',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo300Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photo300',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo300Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photo300',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo300IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photo300',
        value: '',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo300IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photo300',
        value: '',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo34IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photo34',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo34IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photo34',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo34EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photo34',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo34GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photo34',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo34LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photo34',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo34Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photo34',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo34StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photo34',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo34EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photo34',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo34Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photo34',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo34Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photo34',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo34IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photo34',
        value: '',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo34IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photo34',
        value: '',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo600IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photo600',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo600IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photo600',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo600EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photo600',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo600GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photo600',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo600LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photo600',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo600Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photo600',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo600StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photo600',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo600EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photo600',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo600Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photo600',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo600Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photo600',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo600IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photo600',
        value: '',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo600IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photo600',
        value: '',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo68IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photo68',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo68IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photo68',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo68EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photo68',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo68GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photo68',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo68LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photo68',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo68Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photo68',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo68StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photo68',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo68EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photo68',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo68Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photo68',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo68Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photo68',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo68IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photo68',
        value: '',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      photo68IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photo68',
        value: '',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      widthIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'width',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      widthIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'width',
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition> widthEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'width',
        value: value,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition>
      widthGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'width',
        value: value,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition> widthLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'width',
        value: value,
      ));
    });
  }

  QueryBuilder<DBThumbnails, DBThumbnails, QAfterFilterCondition> widthBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'width',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DBThumbnailsQueryObject
    on QueryBuilder<DBThumbnails, DBThumbnails, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const DBLyricTimestampSchema = Schema(
  name: r'DBLyricTimestamp',
  id: 7786905163396428728,
  properties: {
    r'begin': PropertySchema(
      id: 0,
      name: r'begin',
      type: IsarType.long,
    ),
    r'end': PropertySchema(
      id: 1,
      name: r'end',
      type: IsarType.long,
    ),
    r'interlude': PropertySchema(
      id: 2,
      name: r'interlude',
      type: IsarType.bool,
    ),
    r'line': PropertySchema(
      id: 3,
      name: r'line',
      type: IsarType.string,
    )
  },
  estimateSize: _dBLyricTimestampEstimateSize,
  serialize: _dBLyricTimestampSerialize,
  deserialize: _dBLyricTimestampDeserialize,
  deserializeProp: _dBLyricTimestampDeserializeProp,
);

int _dBLyricTimestampEstimateSize(
  DBLyricTimestamp object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.line;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dBLyricTimestampSerialize(
  DBLyricTimestamp object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.begin);
  writer.writeLong(offsets[1], object.end);
  writer.writeBool(offsets[2], object.interlude);
  writer.writeString(offsets[3], object.line);
}

DBLyricTimestamp _dBLyricTimestampDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DBLyricTimestamp(
    begin: reader.readLongOrNull(offsets[0]),
    end: reader.readLongOrNull(offsets[1]),
    interlude: reader.readBoolOrNull(offsets[2]) ?? false,
    line: reader.readStringOrNull(offsets[3]),
  );
  return object;
}

P _dBLyricTimestampDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension DBLyricTimestampQueryFilter
    on QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QFilterCondition> {
  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      beginIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'begin',
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      beginIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'begin',
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      beginEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'begin',
        value: value,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      beginGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'begin',
        value: value,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      beginLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'begin',
        value: value,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      beginBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'begin',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      endIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'end',
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      endIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'end',
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      endEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      endGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      endLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      endBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'end',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      interludeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'interlude',
        value: value,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      lineIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'line',
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      lineIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'line',
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      lineEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'line',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      lineGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'line',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      lineLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'line',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      lineBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'line',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      lineStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'line',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      lineEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'line',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      lineContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'line',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      lineMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'line',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      lineIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'line',
        value: '',
      ));
    });
  }

  QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QAfterFilterCondition>
      lineIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'line',
        value: '',
      ));
    });
  }
}

extension DBLyricTimestampQueryObject
    on QueryBuilder<DBLyricTimestamp, DBLyricTimestamp, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const DBLyricsSchema = Schema(
  name: r'DBLyrics',
  id: 3860351152522208472,
  properties: {
    r'language': PropertySchema(
      id: 0,
      name: r'language',
      type: IsarType.string,
    ),
    r'text': PropertySchema(
      id: 1,
      name: r'text',
      type: IsarType.stringList,
    ),
    r'timestamps': PropertySchema(
      id: 2,
      name: r'timestamps',
      type: IsarType.objectList,
      target: r'DBLyricTimestamp',
    )
  },
  estimateSize: _dBLyricsEstimateSize,
  serialize: _dBLyricsSerialize,
  deserialize: _dBLyricsDeserialize,
  deserializeProp: _dBLyricsDeserializeProp,
);

int _dBLyricsEstimateSize(
  DBLyrics object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.language;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.text;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  {
    final list = object.timestamps;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[DBLyricTimestamp]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              DBLyricTimestampSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  return bytesCount;
}

void _dBLyricsSerialize(
  DBLyrics object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.language);
  writer.writeStringList(offsets[1], object.text);
  writer.writeObjectList<DBLyricTimestamp>(
    offsets[2],
    allOffsets,
    DBLyricTimestampSchema.serialize,
    object.timestamps,
  );
}

DBLyrics _dBLyricsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DBLyrics(
    language: reader.readStringOrNull(offsets[0]),
    text: reader.readStringList(offsets[1]),
    timestamps: reader.readObjectList<DBLyricTimestamp>(
      offsets[2],
      DBLyricTimestampSchema.deserialize,
      allOffsets,
      DBLyricTimestamp(),
    ),
  );
  return object;
}

P _dBLyricsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringList(offset)) as P;
    case 2:
      return (reader.readObjectList<DBLyricTimestamp>(
        offset,
        DBLyricTimestampSchema.deserialize,
        allOffsets,
        DBLyricTimestamp(),
      )) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension DBLyricsQueryFilter
    on QueryBuilder<DBLyrics, DBLyrics, QFilterCondition> {
  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> languageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'language',
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> languageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'language',
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> languageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> languageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> languageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> languageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'language',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> languageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> languageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> languageContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> languageMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'language',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> languageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'language',
        value: '',
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> languageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'language',
        value: '',
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'text',
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'text',
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition>
      textElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'text',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'text',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition>
      textElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'text',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'text',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'text',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'text',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'text',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> textLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'text',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> timestampsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'timestamps',
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition>
      timestampsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'timestamps',
      ));
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition>
      timestampsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timestamps',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> timestampsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timestamps',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition>
      timestampsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timestamps',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition>
      timestampsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timestamps',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition>
      timestampsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timestamps',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition>
      timestampsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'timestamps',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension DBLyricsQueryObject
    on QueryBuilder<DBLyrics, DBLyrics, QFilterCondition> {
  QueryBuilder<DBLyrics, DBLyrics, QAfterFilterCondition> timestampsElement(
      FilterQuery<DBLyricTimestamp> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'timestamps');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const DBAlbumSchema = Schema(
  name: r'DBAlbum',
  id: 393687043260479091,
  properties: {
    r'accessKey': PropertySchema(
      id: 0,
      name: r'accessKey',
      type: IsarType.string,
    ),
    r'hashCode': PropertySchema(
      id: 1,
      name: r'hashCode',
      type: IsarType.long,
    ),
    r'id': PropertySchema(
      id: 2,
      name: r'id',
      type: IsarType.long,
    ),
    r'mediaKey': PropertySchema(
      id: 3,
      name: r'mediaKey',
      type: IsarType.string,
    ),
    r'ownerID': PropertySchema(
      id: 4,
      name: r'ownerID',
      type: IsarType.long,
    ),
    r'thumb': PropertySchema(
      id: 5,
      name: r'thumb',
      type: IsarType.object,
      target: r'DBThumbnails',
    ),
    r'title': PropertySchema(
      id: 6,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _dBAlbumEstimateSize,
  serialize: _dBAlbumSerialize,
  deserialize: _dBAlbumDeserialize,
  deserializeProp: _dBAlbumDeserializeProp,
);

int _dBAlbumEstimateSize(
  DBAlbum object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.accessKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.mediaKey.length * 3;
  {
    final value = object.thumb;
    if (value != null) {
      bytesCount += 3 +
          DBThumbnailsSchema.estimateSize(
              value, allOffsets[DBThumbnails]!, allOffsets);
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

void _dBAlbumSerialize(
  DBAlbum object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accessKey);
  writer.writeLong(offsets[1], object.hashCode);
  writer.writeLong(offsets[2], object.id);
  writer.writeString(offsets[3], object.mediaKey);
  writer.writeLong(offsets[4], object.ownerID);
  writer.writeObject<DBThumbnails>(
    offsets[5],
    allOffsets,
    DBThumbnailsSchema.serialize,
    object.thumb,
  );
  writer.writeString(offsets[6], object.title);
}

DBAlbum _dBAlbumDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DBAlbum(
    accessKey: reader.readStringOrNull(offsets[0]),
    id: reader.readLongOrNull(offsets[2]),
    ownerID: reader.readLongOrNull(offsets[4]),
    thumb: reader.readObjectOrNull<DBThumbnails>(
      offsets[5],
      DBThumbnailsSchema.deserialize,
      allOffsets,
    ),
    title: reader.readStringOrNull(offsets[6]),
  );
  return object;
}

P _dBAlbumDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readObjectOrNull<DBThumbnails>(
        offset,
        DBThumbnailsSchema.deserialize,
        allOffsets,
      )) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension DBAlbumQueryFilter
    on QueryBuilder<DBAlbum, DBAlbum, QFilterCondition> {
  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> accessKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accessKey',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> accessKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accessKey',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> accessKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> accessKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> accessKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> accessKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accessKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> accessKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> accessKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> accessKeyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> accessKeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'accessKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> accessKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accessKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> accessKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'accessKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> hashCodeEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> hashCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> hashCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> hashCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hashCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> idEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> idGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> idLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> idBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> mediaKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> mediaKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> mediaKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> mediaKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> mediaKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mediaKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> mediaKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mediaKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> mediaKeyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mediaKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> mediaKeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mediaKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> mediaKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> mediaKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mediaKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> ownerIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ownerID',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> ownerIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ownerID',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> ownerIDEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerID',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> ownerIDGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerID',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> ownerIDLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerID',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> ownerIDBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> thumbIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'thumb',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> thumbIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'thumb',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> titleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> titleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> titleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> titleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension DBAlbumQueryObject
    on QueryBuilder<DBAlbum, DBAlbum, QFilterCondition> {
  QueryBuilder<DBAlbum, DBAlbum, QAfterFilterCondition> thumb(
      FilterQuery<DBThumbnails> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'thumb');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const DBAudioSchema = Schema(
  name: r'DBAudio',
  id: 3548579242968797800,
  properties: {
    r'accessKey': PropertySchema(
      id: 0,
      name: r'accessKey',
      type: IsarType.string,
    ),
    r'album': PropertySchema(
      id: 1,
      name: r'album',
      type: IsarType.object,
      target: r'DBAlbum',
    ),
    r'artist': PropertySchema(
      id: 2,
      name: r'artist',
      type: IsarType.string,
    ),
    r'date': PropertySchema(
      id: 3,
      name: r'date',
      type: IsarType.long,
    ),
    r'duration': PropertySchema(
      id: 4,
      name: r'duration',
      type: IsarType.long,
    ),
    r'genreID': PropertySchema(
      id: 5,
      name: r'genreID',
      type: IsarType.long,
    ),
    r'hasLyrics': PropertySchema(
      id: 6,
      name: r'hasLyrics',
      type: IsarType.bool,
    ),
    r'hashCode': PropertySchema(
      id: 7,
      name: r'hashCode',
      type: IsarType.long,
    ),
    r'id': PropertySchema(
      id: 8,
      name: r'id',
      type: IsarType.long,
    ),
    r'isCached': PropertySchema(
      id: 9,
      name: r'isCached',
      type: IsarType.bool,
    ),
    r'isExplicit': PropertySchema(
      id: 10,
      name: r'isExplicit',
      type: IsarType.bool,
    ),
    r'isRestricted': PropertySchema(
      id: 11,
      name: r'isRestricted',
      type: IsarType.bool,
    ),
    r'lyrics': PropertySchema(
      id: 12,
      name: r'lyrics',
      type: IsarType.object,
      target: r'DBLyrics',
    ),
    r'ownerID': PropertySchema(
      id: 13,
      name: r'ownerID',
      type: IsarType.long,
    ),
    r'subtitle': PropertySchema(
      id: 14,
      name: r'subtitle',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 15,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _dBAudioEstimateSize,
  serialize: _dBAudioSerialize,
  deserialize: _dBAudioDeserialize,
  deserializeProp: _dBAudioDeserializeProp,
);

int _dBAudioEstimateSize(
  DBAudio object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.accessKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.album;
    if (value != null) {
      bytesCount += 3 +
          DBAlbumSchema.estimateSize(value, allOffsets[DBAlbum]!, allOffsets);
    }
  }
  {
    final value = object.artist;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lyrics;
    if (value != null) {
      bytesCount += 3 +
          DBLyricsSchema.estimateSize(value, allOffsets[DBLyrics]!, allOffsets);
    }
  }
  {
    final value = object.subtitle;
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

void _dBAudioSerialize(
  DBAudio object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accessKey);
  writer.writeObject<DBAlbum>(
    offsets[1],
    allOffsets,
    DBAlbumSchema.serialize,
    object.album,
  );
  writer.writeString(offsets[2], object.artist);
  writer.writeLong(offsets[3], object.date);
  writer.writeLong(offsets[4], object.duration);
  writer.writeLong(offsets[5], object.genreID);
  writer.writeBool(offsets[6], object.hasLyrics);
  writer.writeLong(offsets[7], object.hashCode);
  writer.writeLong(offsets[8], object.id);
  writer.writeBool(offsets[9], object.isCached);
  writer.writeBool(offsets[10], object.isExplicit);
  writer.writeBool(offsets[11], object.isRestricted);
  writer.writeObject<DBLyrics>(
    offsets[12],
    allOffsets,
    DBLyricsSchema.serialize,
    object.lyrics,
  );
  writer.writeLong(offsets[13], object.ownerID);
  writer.writeString(offsets[14], object.subtitle);
  writer.writeString(offsets[15], object.title);
}

DBAudio _dBAudioDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DBAudio(
    accessKey: reader.readStringOrNull(offsets[0]),
    album: reader.readObjectOrNull<DBAlbum>(
      offsets[1],
      DBAlbumSchema.deserialize,
      allOffsets,
    ),
    artist: reader.readStringOrNull(offsets[2]),
    date: reader.readLongOrNull(offsets[3]),
    duration: reader.readLongOrNull(offsets[4]),
    genreID: reader.readLongOrNull(offsets[5]),
    hasLyrics: reader.readBoolOrNull(offsets[6]),
    id: reader.readLongOrNull(offsets[8]),
    isCached: reader.readBoolOrNull(offsets[9]),
    isExplicit: reader.readBoolOrNull(offsets[10]),
    isRestricted: reader.readBoolOrNull(offsets[11]),
    lyrics: reader.readObjectOrNull<DBLyrics>(
      offsets[12],
      DBLyricsSchema.deserialize,
      allOffsets,
    ),
    ownerID: reader.readLongOrNull(offsets[13]),
    subtitle: reader.readStringOrNull(offsets[14]),
    title: reader.readStringOrNull(offsets[15]),
  );
  return object;
}

P _dBAudioDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readObjectOrNull<DBAlbum>(
        offset,
        DBAlbumSchema.deserialize,
        allOffsets,
      )) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readBoolOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readBoolOrNull(offset)) as P;
    case 10:
      return (reader.readBoolOrNull(offset)) as P;
    case 11:
      return (reader.readBoolOrNull(offset)) as P;
    case 12:
      return (reader.readObjectOrNull<DBLyrics>(
        offset,
        DBLyricsSchema.deserialize,
        allOffsets,
      )) as P;
    case 13:
      return (reader.readLongOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension DBAudioQueryFilter
    on QueryBuilder<DBAudio, DBAudio, QFilterCondition> {
  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> accessKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accessKey',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> accessKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accessKey',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> accessKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> accessKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> accessKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> accessKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accessKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> accessKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> accessKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> accessKeyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'accessKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> accessKeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'accessKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> accessKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accessKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> accessKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'accessKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> albumIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'album',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> albumIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'album',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> artistIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'artist',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> artistIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'artist',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> artistEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> artistGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> artistLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> artistBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'artist',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> artistStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> artistEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> artistContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> artistMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'artist',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> artistIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'artist',
        value: '',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> artistIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'artist',
        value: '',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> dateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'date',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> dateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'date',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> dateEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> dateGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> dateLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> dateBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> durationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'duration',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> durationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'duration',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> durationEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'duration',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> durationGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'duration',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> durationLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'duration',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> durationBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'duration',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> genreIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'genreID',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> genreIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'genreID',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> genreIDEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'genreID',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> genreIDGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'genreID',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> genreIDLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'genreID',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> genreIDBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'genreID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> hasLyricsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hasLyrics',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> hasLyricsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hasLyrics',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> hasLyricsEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasLyrics',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> hashCodeEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> hashCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> hashCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> hashCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hashCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> idEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> idGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> idLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> idBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> isCachedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isCached',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> isCachedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isCached',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> isCachedEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCached',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> isExplicitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isExplicit',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> isExplicitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isExplicit',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> isExplicitEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isExplicit',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> isRestrictedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isRestricted',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition>
      isRestrictedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isRestricted',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> isRestrictedEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isRestricted',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> lyricsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lyrics',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> lyricsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lyrics',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> ownerIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ownerID',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> ownerIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ownerID',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> ownerIDEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerID',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> ownerIDGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerID',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> ownerIDLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerID',
        value: value,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> ownerIDBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> subtitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subtitle',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> subtitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subtitle',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> subtitleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subtitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> subtitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subtitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> subtitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subtitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> subtitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subtitle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> subtitleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subtitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> subtitleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subtitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> subtitleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subtitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> subtitleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subtitle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> subtitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subtitle',
        value: '',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> subtitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subtitle',
        value: '',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> titleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> titleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> titleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> titleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension DBAudioQueryObject
    on QueryBuilder<DBAudio, DBAudio, QFilterCondition> {
  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> album(
      FilterQuery<DBAlbum> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'album');
    });
  }

  QueryBuilder<DBAudio, DBAudio, QAfterFilterCondition> lyrics(
      FilterQuery<DBLyrics> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'lyrics');
    });
  }
}