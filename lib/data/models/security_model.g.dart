// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSecurityModelCollection on Isar {
  IsarCollection<SecurityModel> get securityModels => this.collection();
}

const SecurityModelSchema = CollectionSchema(
  name: r'SecurityModel',
  id: -6992770786191867215,
  properties: {
    r'biometricEnabled': PropertySchema(
      id: 0,
      name: r'biometricEnabled',
      type: IsarType.bool,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'failedAttempts': PropertySchema(
      id: 2,
      name: r'failedAttempts',
      type: IsarType.long,
    ),
    r'isLocked': PropertySchema(
      id: 3,
      name: r'isLocked',
      type: IsarType.bool,
    ),
    r'lastFailedLogin': PropertySchema(
      id: 4,
      name: r'lastFailedLogin',
      type: IsarType.dateTime,
    ),
    r'lastSuccessfulLogin': PropertySchema(
      id: 5,
      name: r'lastSuccessfulLogin',
      type: IsarType.dateTime,
    ),
    r'lockedUntil': PropertySchema(
      id: 6,
      name: r'lockedUntil',
      type: IsarType.dateTime,
    ),
    r'maxFailedAttempts': PropertySchema(
      id: 7,
      name: r'maxFailedAttempts',
      type: IsarType.long,
    ),
    r'passwordHash': PropertySchema(
      id: 8,
      name: r'passwordHash',
      type: IsarType.string,
    ),
    r'pinHash': PropertySchema(
      id: 9,
      name: r'pinHash',
      type: IsarType.string,
    ),
    r'remainingLockMinutes': PropertySchema(
      id: 10,
      name: r'remainingLockMinutes',
      type: IsarType.long,
    ),
    r'requireSecurityOnStart': PropertySchema(
      id: 11,
      name: r'requireSecurityOnStart',
      type: IsarType.bool,
    ),
    r'requireSecurityOnTransaction': PropertySchema(
      id: 12,
      name: r'requireSecurityOnTransaction',
      type: IsarType.bool,
    ),
    r'salt': PropertySchema(
      id: 13,
      name: r'salt',
      type: IsarType.string,
    ),
    r'securityType': PropertySchema(
      id: 14,
      name: r'securityType',
      type: IsarType.byte,
      enumMap: _SecurityModelsecurityTypeEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 15,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _securityModelEstimateSize,
  serialize: _securityModelSerialize,
  deserialize: _securityModelDeserialize,
  deserializeProp: _securityModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _securityModelGetId,
  getLinks: _securityModelGetLinks,
  attach: _securityModelAttach,
  version: '3.1.0+1',
);

int _securityModelEstimateSize(
  SecurityModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.passwordHash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.pinHash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.salt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _securityModelSerialize(
  SecurityModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.biometricEnabled);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeLong(offsets[2], object.failedAttempts);
  writer.writeBool(offsets[3], object.isLocked);
  writer.writeDateTime(offsets[4], object.lastFailedLogin);
  writer.writeDateTime(offsets[5], object.lastSuccessfulLogin);
  writer.writeDateTime(offsets[6], object.lockedUntil);
  writer.writeLong(offsets[7], object.maxFailedAttempts);
  writer.writeString(offsets[8], object.passwordHash);
  writer.writeString(offsets[9], object.pinHash);
  writer.writeLong(offsets[10], object.remainingLockMinutes);
  writer.writeBool(offsets[11], object.requireSecurityOnStart);
  writer.writeBool(offsets[12], object.requireSecurityOnTransaction);
  writer.writeString(offsets[13], object.salt);
  writer.writeByte(offsets[14], object.securityType.index);
  writer.writeDateTime(offsets[15], object.updatedAt);
}

SecurityModel _securityModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SecurityModel(
    biometricEnabled: reader.readBoolOrNull(offsets[0]) ?? false,
    createdAt: reader.readDateTime(offsets[1]),
    failedAttempts: reader.readLongOrNull(offsets[2]) ?? 0,
    id: id,
    lastFailedLogin: reader.readDateTimeOrNull(offsets[4]),
    lastSuccessfulLogin: reader.readDateTimeOrNull(offsets[5]),
    lockedUntil: reader.readDateTimeOrNull(offsets[6]),
    maxFailedAttempts: reader.readLongOrNull(offsets[7]) ?? 5,
    passwordHash: reader.readStringOrNull(offsets[8]),
    pinHash: reader.readStringOrNull(offsets[9]),
    requireSecurityOnStart: reader.readBoolOrNull(offsets[11]) ?? true,
    requireSecurityOnTransaction: reader.readBoolOrNull(offsets[12]) ?? false,
    salt: reader.readStringOrNull(offsets[13]),
    securityType: _SecurityModelsecurityTypeValueEnumMap[
            reader.readByteOrNull(offsets[14])] ??
        SecurityType.none,
    updatedAt: reader.readDateTimeOrNull(offsets[15]),
  );
  return object;
}

P _securityModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset) ?? 5) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 12:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (_SecurityModelsecurityTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SecurityType.none) as P;
    case 15:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _SecurityModelsecurityTypeEnumValueMap = {
  'pin': 0,
  'password': 1,
  'biometric': 2,
  'none': 3,
};
const _SecurityModelsecurityTypeValueEnumMap = {
  0: SecurityType.pin,
  1: SecurityType.password,
  2: SecurityType.biometric,
  3: SecurityType.none,
};

Id _securityModelGetId(SecurityModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _securityModelGetLinks(SecurityModel object) {
  return [];
}

void _securityModelAttach(
    IsarCollection<dynamic> col, Id id, SecurityModel object) {
  object.id = id;
}

extension SecurityModelQueryWhereSort
    on QueryBuilder<SecurityModel, SecurityModel, QWhere> {
  QueryBuilder<SecurityModel, SecurityModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SecurityModelQueryWhere
    on QueryBuilder<SecurityModel, SecurityModel, QWhereClause> {
  QueryBuilder<SecurityModel, SecurityModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<SecurityModel, SecurityModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SecurityModelQueryFilter
    on QueryBuilder<SecurityModel, SecurityModel, QFilterCondition> {
  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      biometricEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'biometricEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      failedAttemptsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'failedAttempts',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      failedAttemptsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'failedAttempts',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      failedAttemptsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'failedAttempts',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      failedAttemptsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'failedAttempts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
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

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition> idLessThan(
    Id value, {
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

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
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

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      isLockedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLocked',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lastFailedLoginIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastFailedLogin',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lastFailedLoginIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastFailedLogin',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lastFailedLoginEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastFailedLogin',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lastFailedLoginGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastFailedLogin',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lastFailedLoginLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastFailedLogin',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lastFailedLoginBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastFailedLogin',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lastSuccessfulLoginIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSuccessfulLogin',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lastSuccessfulLoginIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSuccessfulLogin',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lastSuccessfulLoginEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSuccessfulLogin',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lastSuccessfulLoginGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSuccessfulLogin',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lastSuccessfulLoginLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSuccessfulLogin',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lastSuccessfulLoginBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSuccessfulLogin',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lockedUntilIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lockedUntil',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lockedUntilIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lockedUntil',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lockedUntilEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lockedUntil',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lockedUntilGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lockedUntil',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lockedUntilLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lockedUntil',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      lockedUntilBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lockedUntil',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      maxFailedAttemptsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxFailedAttempts',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      maxFailedAttemptsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxFailedAttempts',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      maxFailedAttemptsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxFailedAttempts',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      maxFailedAttemptsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxFailedAttempts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      passwordHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'passwordHash',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      passwordHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'passwordHash',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      passwordHashEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'passwordHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      passwordHashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'passwordHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      passwordHashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'passwordHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      passwordHashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'passwordHash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      passwordHashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'passwordHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      passwordHashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'passwordHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      passwordHashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'passwordHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      passwordHashMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'passwordHash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      passwordHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'passwordHash',
        value: '',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      passwordHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'passwordHash',
        value: '',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      pinHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pinHash',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      pinHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pinHash',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      pinHashEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pinHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      pinHashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pinHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      pinHashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pinHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      pinHashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pinHash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      pinHashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pinHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      pinHashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pinHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      pinHashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pinHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      pinHashMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pinHash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      pinHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pinHash',
        value: '',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      pinHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pinHash',
        value: '',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      remainingLockMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remainingLockMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      remainingLockMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remainingLockMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      remainingLockMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remainingLockMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      remainingLockMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remainingLockMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      requireSecurityOnStartEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requireSecurityOnStart',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      requireSecurityOnTransactionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requireSecurityOnTransaction',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      saltIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'salt',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      saltIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'salt',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition> saltEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'salt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      saltGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'salt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      saltLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'salt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition> saltBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'salt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      saltStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'salt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      saltEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'salt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      saltContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'salt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition> saltMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'salt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      saltIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'salt',
        value: '',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      saltIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'salt',
        value: '',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      securityTypeEqualTo(SecurityType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'securityType',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      securityTypeGreaterThan(
    SecurityType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'securityType',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      securityTypeLessThan(
    SecurityType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'securityType',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      securityTypeBetween(
    SecurityType lower,
    SecurityType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'securityType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterFilterCondition>
      updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SecurityModelQueryObject
    on QueryBuilder<SecurityModel, SecurityModel, QFilterCondition> {}

extension SecurityModelQueryLinks
    on QueryBuilder<SecurityModel, SecurityModel, QFilterCondition> {}

extension SecurityModelQuerySortBy
    on QueryBuilder<SecurityModel, SecurityModel, QSortBy> {
  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByBiometricEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'biometricEnabled', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByBiometricEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'biometricEnabled', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByFailedAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedAttempts', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByFailedAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedAttempts', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> sortByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByIsLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByLastFailedLogin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFailedLogin', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByLastFailedLoginDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFailedLogin', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByLastSuccessfulLogin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessfulLogin', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByLastSuccessfulLoginDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessfulLogin', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> sortByLockedUntil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockedUntil', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByLockedUntilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockedUntil', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByMaxFailedAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxFailedAttempts', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByMaxFailedAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxFailedAttempts', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByPasswordHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passwordHash', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByPasswordHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passwordHash', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> sortByPinHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinHash', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> sortByPinHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinHash', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByRemainingLockMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingLockMinutes', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByRemainingLockMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingLockMinutes', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByRequireSecurityOnStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requireSecurityOnStart', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByRequireSecurityOnStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requireSecurityOnStart', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByRequireSecurityOnTransaction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requireSecurityOnTransaction', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByRequireSecurityOnTransactionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requireSecurityOnTransaction', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> sortBySalt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salt', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> sortBySaltDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salt', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortBySecurityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityType', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortBySecurityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityType', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SecurityModelQuerySortThenBy
    on QueryBuilder<SecurityModel, SecurityModel, QSortThenBy> {
  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByBiometricEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'biometricEnabled', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByBiometricEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'biometricEnabled', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByFailedAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedAttempts', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByFailedAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedAttempts', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> thenByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByIsLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByLastFailedLogin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFailedLogin', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByLastFailedLoginDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFailedLogin', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByLastSuccessfulLogin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessfulLogin', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByLastSuccessfulLoginDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessfulLogin', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> thenByLockedUntil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockedUntil', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByLockedUntilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockedUntil', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByMaxFailedAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxFailedAttempts', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByMaxFailedAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxFailedAttempts', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByPasswordHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passwordHash', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByPasswordHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passwordHash', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> thenByPinHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinHash', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> thenByPinHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinHash', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByRemainingLockMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingLockMinutes', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByRemainingLockMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingLockMinutes', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByRequireSecurityOnStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requireSecurityOnStart', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByRequireSecurityOnStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requireSecurityOnStart', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByRequireSecurityOnTransaction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requireSecurityOnTransaction', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByRequireSecurityOnTransactionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requireSecurityOnTransaction', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> thenBySalt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salt', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> thenBySaltDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salt', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenBySecurityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityType', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenBySecurityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityType', Sort.desc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SecurityModelQueryWhereDistinct
    on QueryBuilder<SecurityModel, SecurityModel, QDistinct> {
  QueryBuilder<SecurityModel, SecurityModel, QDistinct>
      distinctByBiometricEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'biometricEnabled');
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct>
      distinctByFailedAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'failedAttempts');
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct> distinctByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLocked');
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct>
      distinctByLastFailedLogin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastFailedLogin');
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct>
      distinctByLastSuccessfulLogin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSuccessfulLogin');
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct>
      distinctByLockedUntil() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lockedUntil');
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct>
      distinctByMaxFailedAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxFailedAttempts');
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct> distinctByPasswordHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'passwordHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct> distinctByPinHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pinHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct>
      distinctByRemainingLockMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainingLockMinutes');
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct>
      distinctByRequireSecurityOnStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'requireSecurityOnStart');
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct>
      distinctByRequireSecurityOnTransaction() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'requireSecurityOnTransaction');
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct> distinctBySalt(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'salt', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct>
      distinctBySecurityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'securityType');
    });
  }

  QueryBuilder<SecurityModel, SecurityModel, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension SecurityModelQueryProperty
    on QueryBuilder<SecurityModel, SecurityModel, QQueryProperty> {
  QueryBuilder<SecurityModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SecurityModel, bool, QQueryOperations>
      biometricEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'biometricEnabled');
    });
  }

  QueryBuilder<SecurityModel, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<SecurityModel, int, QQueryOperations> failedAttemptsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failedAttempts');
    });
  }

  QueryBuilder<SecurityModel, bool, QQueryOperations> isLockedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLocked');
    });
  }

  QueryBuilder<SecurityModel, DateTime?, QQueryOperations>
      lastFailedLoginProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastFailedLogin');
    });
  }

  QueryBuilder<SecurityModel, DateTime?, QQueryOperations>
      lastSuccessfulLoginProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSuccessfulLogin');
    });
  }

  QueryBuilder<SecurityModel, DateTime?, QQueryOperations>
      lockedUntilProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lockedUntil');
    });
  }

  QueryBuilder<SecurityModel, int, QQueryOperations>
      maxFailedAttemptsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxFailedAttempts');
    });
  }

  QueryBuilder<SecurityModel, String?, QQueryOperations>
      passwordHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'passwordHash');
    });
  }

  QueryBuilder<SecurityModel, String?, QQueryOperations> pinHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pinHash');
    });
  }

  QueryBuilder<SecurityModel, int, QQueryOperations>
      remainingLockMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainingLockMinutes');
    });
  }

  QueryBuilder<SecurityModel, bool, QQueryOperations>
      requireSecurityOnStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'requireSecurityOnStart');
    });
  }

  QueryBuilder<SecurityModel, bool, QQueryOperations>
      requireSecurityOnTransactionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'requireSecurityOnTransaction');
    });
  }

  QueryBuilder<SecurityModel, String?, QQueryOperations> saltProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'salt');
    });
  }

  QueryBuilder<SecurityModel, SecurityType, QQueryOperations>
      securityTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'securityType');
    });
  }

  QueryBuilder<SecurityModel, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
