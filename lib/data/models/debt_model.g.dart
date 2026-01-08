// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDebtModelCollection on Isar {
  IsarCollection<DebtModel> get debtModels => this.collection();
}

const DebtModelSchema = CollectionSchema(
  name: r'DebtModel',
  id: 7879871328374011369,
  properties: {
    r'collateral': PropertySchema(
      id: 0,
      name: r'collateral',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'currency': PropertySchema(
      id: 2,
      name: r'currency',
      type: IsarType.string,
    ),
    r'date': PropertySchema(
      id: 3,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'daysUntilDue': PropertySchema(
      id: 4,
      name: r'daysUntilDue',
      type: IsarType.long,
    ),
    r'description': PropertySchema(
      id: 5,
      name: r'description',
      type: IsarType.string,
    ),
    r'dueDate': PropertySchema(
      id: 6,
      name: r'dueDate',
      type: IsarType.dateTime,
    ),
    r'hasInterest': PropertySchema(
      id: 7,
      name: r'hasInterest',
      type: IsarType.bool,
    ),
    r'hasReminder': PropertySchema(
      id: 8,
      name: r'hasReminder',
      type: IsarType.bool,
    ),
    r'interestRate': PropertySchema(
      id: 9,
      name: r'interestRate',
      type: IsarType.double,
    ),
    r'isDeleted': PropertySchema(
      id: 10,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isOverdue': PropertySchema(
      id: 11,
      name: r'isOverdue',
      type: IsarType.bool,
    ),
    r'notes': PropertySchema(
      id: 12,
      name: r'notes',
      type: IsarType.string,
    ),
    r'paidAmount': PropertySchema(
      id: 13,
      name: r'paidAmount',
      type: IsarType.double,
    ),
    r'paymentProgress': PropertySchema(
      id: 14,
      name: r'paymentProgress',
      type: IsarType.double,
    ),
    r'paymentTransactionIds': PropertySchema(
      id: 15,
      name: r'paymentTransactionIds',
      type: IsarType.longList,
    ),
    r'personContact': PropertySchema(
      id: 16,
      name: r'personContact',
      type: IsarType.string,
    ),
    r'personName': PropertySchema(
      id: 17,
      name: r'personName',
      type: IsarType.string,
    ),
    r'relatedTransactionId': PropertySchema(
      id: 18,
      name: r'relatedTransactionId',
      type: IsarType.long,
    ),
    r'remainingAmount': PropertySchema(
      id: 19,
      name: r'remainingAmount',
      type: IsarType.double,
    ),
    r'reminderDateTime': PropertySchema(
      id: 20,
      name: r'reminderDateTime',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 21,
      name: r'status',
      type: IsarType.byte,
      enumMap: _DebtModelstatusEnumValueMap,
    ),
    r'totalAmount': PropertySchema(
      id: 22,
      name: r'totalAmount',
      type: IsarType.double,
    ),
    r'totalWithInterest': PropertySchema(
      id: 23,
      name: r'totalWithInterest',
      type: IsarType.double,
    ),
    r'type': PropertySchema(
      id: 24,
      name: r'type',
      type: IsarType.byte,
      enumMap: _DebtModeltypeEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 25,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _debtModelEstimateSize,
  serialize: _debtModelSerialize,
  deserialize: _debtModelDeserialize,
  deserializeProp: _debtModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'isDeleted': IndexSchema(
      id: -786475870904832312,
      name: r'isDeleted',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isDeleted',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _debtModelGetId,
  getLinks: _debtModelGetLinks,
  attach: _debtModelAttach,
  version: '3.1.0+1',
);

int _debtModelEstimateSize(
  DebtModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.collateral;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.currency.length * 3;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.paymentTransactionIds;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  {
    final value = object.personContact;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.personName.length * 3;
  return bytesCount;
}

void _debtModelSerialize(
  DebtModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.collateral);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.currency);
  writer.writeDateTime(offsets[3], object.date);
  writer.writeLong(offsets[4], object.daysUntilDue);
  writer.writeString(offsets[5], object.description);
  writer.writeDateTime(offsets[6], object.dueDate);
  writer.writeBool(offsets[7], object.hasInterest);
  writer.writeBool(offsets[8], object.hasReminder);
  writer.writeDouble(offsets[9], object.interestRate);
  writer.writeBool(offsets[10], object.isDeleted);
  writer.writeBool(offsets[11], object.isOverdue);
  writer.writeString(offsets[12], object.notes);
  writer.writeDouble(offsets[13], object.paidAmount);
  writer.writeDouble(offsets[14], object.paymentProgress);
  writer.writeLongList(offsets[15], object.paymentTransactionIds);
  writer.writeString(offsets[16], object.personContact);
  writer.writeString(offsets[17], object.personName);
  writer.writeLong(offsets[18], object.relatedTransactionId);
  writer.writeDouble(offsets[19], object.remainingAmount);
  writer.writeDateTime(offsets[20], object.reminderDateTime);
  writer.writeByte(offsets[21], object.status.index);
  writer.writeDouble(offsets[22], object.totalAmount);
  writer.writeDouble(offsets[23], object.totalWithInterest);
  writer.writeByte(offsets[24], object.type.index);
  writer.writeDateTime(offsets[25], object.updatedAt);
}

DebtModel _debtModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DebtModel(
    collateral: reader.readStringOrNull(offsets[0]),
    createdAt: reader.readDateTime(offsets[1]),
    currency: reader.readStringOrNull(offsets[2]) ?? 'FBU',
    date: reader.readDateTime(offsets[3]),
    description: reader.readStringOrNull(offsets[5]),
    dueDate: reader.readDateTimeOrNull(offsets[6]),
    hasInterest: reader.readBoolOrNull(offsets[7]) ?? false,
    hasReminder: reader.readBoolOrNull(offsets[8]) ?? false,
    id: id,
    interestRate: reader.readDoubleOrNull(offsets[9]),
    isDeleted: reader.readBoolOrNull(offsets[10]) ?? false,
    notes: reader.readStringOrNull(offsets[12]),
    paidAmount: reader.readDoubleOrNull(offsets[13]) ?? 0.0,
    paymentTransactionIds: reader.readLongList(offsets[15]),
    personContact: reader.readStringOrNull(offsets[16]),
    personName: reader.readString(offsets[17]),
    relatedTransactionId: reader.readLongOrNull(offsets[18]),
    reminderDateTime: reader.readDateTimeOrNull(offsets[20]),
    status: _DebtModelstatusValueEnumMap[reader.readByteOrNull(offsets[21])] ??
        DebtStatus.pending,
    totalAmount: reader.readDouble(offsets[22]),
    type: _DebtModeltypeValueEnumMap[reader.readByteOrNull(offsets[24])] ??
        DebtType.given,
    updatedAt: reader.readDateTimeOrNull(offsets[25]),
  );
  return object;
}

P _debtModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset) ?? 'FBU') as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 8:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 14:
      return (reader.readDouble(offset)) as P;
    case 15:
      return (reader.readLongList(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readLongOrNull(offset)) as P;
    case 19:
      return (reader.readDouble(offset)) as P;
    case 20:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 21:
      return (_DebtModelstatusValueEnumMap[reader.readByteOrNull(offset)] ??
          DebtStatus.pending) as P;
    case 22:
      return (reader.readDouble(offset)) as P;
    case 23:
      return (reader.readDouble(offset)) as P;
    case 24:
      return (_DebtModeltypeValueEnumMap[reader.readByteOrNull(offset)] ??
          DebtType.given) as P;
    case 25:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _DebtModelstatusEnumValueMap = {
  'pending': 0,
  'partiallyPaid': 1,
  'fullyPaid': 2,
  'cancelled': 3,
};
const _DebtModelstatusValueEnumMap = {
  0: DebtStatus.pending,
  1: DebtStatus.partiallyPaid,
  2: DebtStatus.fullyPaid,
  3: DebtStatus.cancelled,
};
const _DebtModeltypeEnumValueMap = {
  'given': 0,
  'received': 1,
};
const _DebtModeltypeValueEnumMap = {
  0: DebtType.given,
  1: DebtType.received,
};

Id _debtModelGetId(DebtModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _debtModelGetLinks(DebtModel object) {
  return [];
}

void _debtModelAttach(IsarCollection<dynamic> col, Id id, DebtModel object) {
  object.id = id;
}

extension DebtModelQueryWhereSort
    on QueryBuilder<DebtModel, DebtModel, QWhere> {
  QueryBuilder<DebtModel, DebtModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhere> anyIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isDeleted'),
      );
    });
  }
}

extension DebtModelQueryWhere
    on QueryBuilder<DebtModel, DebtModel, QWhereClause> {
  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> isDeletedEqualTo(
      bool isDeleted) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isDeleted',
        value: [isDeleted],
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> isDeletedNotEqualTo(
      bool isDeleted) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [],
              upper: [isDeleted],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [isDeleted],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [isDeleted],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [],
              upper: [isDeleted],
              includeUpper: false,
            ));
      }
    });
  }
}

extension DebtModelQueryFilter
    on QueryBuilder<DebtModel, DebtModel, QFilterCondition> {
  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> collateralIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'collateral',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      collateralIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'collateral',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> collateralEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'collateral',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      collateralGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'collateral',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> collateralLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'collateral',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> collateralBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'collateral',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      collateralStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'collateral',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> collateralEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'collateral',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> collateralContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'collateral',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> collateralMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'collateral',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      collateralIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'collateral',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      collateralIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'collateral',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> currencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> currencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> currencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> currencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> currencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> currencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> currencyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> currencyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> currencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      currencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dateGreaterThan(
    DateTime value, {
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dateLessThan(
    DateTime value, {
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> daysUntilDueEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'daysUntilDue',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      daysUntilDueGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'daysUntilDue',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      daysUntilDueLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'daysUntilDue',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> daysUntilDueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'daysUntilDue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> descriptionEqualTo(
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> descriptionLessThan(
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> descriptionBetween(
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> descriptionEndsWith(
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> descriptionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> descriptionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dueDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dueDate',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dueDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dueDate',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dueDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dueDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dueDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dueDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dueDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> hasInterestEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasInterest',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> hasReminderEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasReminder',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      interestRateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'interestRate',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      interestRateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'interestRate',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> interestRateEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'interestRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      interestRateGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'interestRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      interestRateLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'interestRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> interestRateBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'interestRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> isDeletedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> isOverdueEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isOverdue',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> notesContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> notesMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> paidAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paidAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paidAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paidAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> paidAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paidAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> paidAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paidAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentProgressEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentProgress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentProgressGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentProgress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentProgressLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentProgress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentProgressBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentProgress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentTransactionIdsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paymentTransactionIds',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentTransactionIdsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paymentTransactionIds',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentTransactionIdsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentTransactionIds',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentTransactionIdsElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentTransactionIds',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentTransactionIdsElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentTransactionIds',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentTransactionIdsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentTransactionIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentTransactionIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentTransactionIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentTransactionIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentTransactionIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentTransactionIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentTransactionIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentTransactionIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentTransactionIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentTransactionIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentTransactionIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      paymentTransactionIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentTransactionIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personContactIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'personContact',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personContactIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'personContact',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personContactEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personContact',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personContactGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'personContact',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personContactLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'personContact',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personContactBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'personContact',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personContactStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'personContact',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personContactEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'personContact',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personContactContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'personContact',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personContactMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'personContact',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personContactIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personContact',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personContactIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'personContact',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'personName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'personName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'personName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'personName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'personName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'personName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'personName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personName',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      personNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'personName',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      relatedTransactionIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'relatedTransactionId',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      relatedTransactionIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'relatedTransactionId',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      relatedTransactionIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relatedTransactionId',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      relatedTransactionIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'relatedTransactionId',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      relatedTransactionIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'relatedTransactionId',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      relatedTransactionIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'relatedTransactionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      remainingAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remainingAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      remainingAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remainingAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      remainingAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remainingAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      remainingAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remainingAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      reminderDateTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reminderDateTime',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      reminderDateTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reminderDateTime',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      reminderDateTimeEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reminderDateTime',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      reminderDateTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reminderDateTime',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      reminderDateTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reminderDateTime',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      reminderDateTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reminderDateTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> statusEqualTo(
      DebtStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> statusGreaterThan(
    DebtStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> statusLessThan(
    DebtStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> statusBetween(
    DebtStatus lower,
    DebtStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> totalAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      totalAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> totalAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> totalAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      totalWithInterestEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalWithInterest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      totalWithInterestGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalWithInterest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      totalWithInterestLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalWithInterest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      totalWithInterestBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalWithInterest',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> typeEqualTo(
      DebtType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> typeGreaterThan(
    DebtType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> typeLessThan(
    DebtType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> typeBetween(
    DebtType lower,
    DebtType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> updatedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> updatedAtBetween(
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

extension DebtModelQueryObject
    on QueryBuilder<DebtModel, DebtModel, QFilterCondition> {}

extension DebtModelQueryLinks
    on QueryBuilder<DebtModel, DebtModel, QFilterCondition> {}

extension DebtModelQuerySortBy on QueryBuilder<DebtModel, DebtModel, QSortBy> {
  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByCollateral() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collateral', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByCollateralDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collateral', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByDaysUntilDue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilDue', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByDaysUntilDueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilDue', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByHasInterest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasInterest', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByHasInterestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasInterest', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByHasReminder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasReminder', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByHasReminderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasReminder', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByInterestRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interestRate', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByInterestRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interestRate', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByIsOverdue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOverdue', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByIsOverdueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOverdue', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByPaidAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByPaidAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByPaymentProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentProgress', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByPaymentProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentProgress', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByPersonContact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personContact', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByPersonContactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personContact', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByPersonName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personName', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByPersonNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personName', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
      sortByRelatedTransactionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedTransactionId', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
      sortByRelatedTransactionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedTransactionId', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByRemainingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByRemainingAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByReminderDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderDateTime', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
      sortByReminderDateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderDateTime', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByTotalWithInterest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWithInterest', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
      sortByTotalWithInterestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWithInterest', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DebtModelQuerySortThenBy
    on QueryBuilder<DebtModel, DebtModel, QSortThenBy> {
  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByCollateral() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collateral', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByCollateralDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collateral', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByDaysUntilDue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilDue', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByDaysUntilDueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilDue', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByHasInterest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasInterest', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByHasInterestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasInterest', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByHasReminder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasReminder', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByHasReminderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasReminder', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByInterestRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interestRate', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByInterestRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interestRate', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByIsOverdue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOverdue', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByIsOverdueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOverdue', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByPaidAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByPaidAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByPaymentProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentProgress', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByPaymentProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentProgress', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByPersonContact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personContact', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByPersonContactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personContact', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByPersonName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personName', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByPersonNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personName', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
      thenByRelatedTransactionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedTransactionId', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
      thenByRelatedTransactionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedTransactionId', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByRemainingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByRemainingAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByReminderDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderDateTime', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
      thenByReminderDateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderDateTime', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByTotalWithInterest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWithInterest', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
      thenByTotalWithInterestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWithInterest', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DebtModelQueryWhereDistinct
    on QueryBuilder<DebtModel, DebtModel, QDistinct> {
  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByCollateral(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'collateral', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByCurrency(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByDaysUntilDue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'daysUntilDue');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dueDate');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByHasInterest() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasInterest');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByHasReminder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasReminder');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByInterestRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'interestRate');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByIsOverdue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isOverdue');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByPaidAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paidAmount');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByPaymentProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentProgress');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct>
      distinctByPaymentTransactionIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentTransactionIds');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByPersonContact(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personContact',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByPersonName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct>
      distinctByRelatedTransactionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relatedTransactionId');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByRemainingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainingAmount');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByReminderDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reminderDateTime');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalAmount');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByTotalWithInterest() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalWithInterest');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension DebtModelQueryProperty
    on QueryBuilder<DebtModel, DebtModel, QQueryProperty> {
  QueryBuilder<DebtModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DebtModel, String?, QQueryOperations> collateralProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'collateral');
    });
  }

  QueryBuilder<DebtModel, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<DebtModel, String, QQueryOperations> currencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currency');
    });
  }

  QueryBuilder<DebtModel, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<DebtModel, int, QQueryOperations> daysUntilDueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'daysUntilDue');
    });
  }

  QueryBuilder<DebtModel, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<DebtModel, DateTime?, QQueryOperations> dueDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dueDate');
    });
  }

  QueryBuilder<DebtModel, bool, QQueryOperations> hasInterestProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasInterest');
    });
  }

  QueryBuilder<DebtModel, bool, QQueryOperations> hasReminderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasReminder');
    });
  }

  QueryBuilder<DebtModel, double?, QQueryOperations> interestRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'interestRate');
    });
  }

  QueryBuilder<DebtModel, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<DebtModel, bool, QQueryOperations> isOverdueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isOverdue');
    });
  }

  QueryBuilder<DebtModel, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<DebtModel, double, QQueryOperations> paidAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paidAmount');
    });
  }

  QueryBuilder<DebtModel, double, QQueryOperations> paymentProgressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentProgress');
    });
  }

  QueryBuilder<DebtModel, List<int>?, QQueryOperations>
      paymentTransactionIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentTransactionIds');
    });
  }

  QueryBuilder<DebtModel, String?, QQueryOperations> personContactProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personContact');
    });
  }

  QueryBuilder<DebtModel, String, QQueryOperations> personNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personName');
    });
  }

  QueryBuilder<DebtModel, int?, QQueryOperations>
      relatedTransactionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relatedTransactionId');
    });
  }

  QueryBuilder<DebtModel, double, QQueryOperations> remainingAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainingAmount');
    });
  }

  QueryBuilder<DebtModel, DateTime?, QQueryOperations>
      reminderDateTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderDateTime');
    });
  }

  QueryBuilder<DebtModel, DebtStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<DebtModel, double, QQueryOperations> totalAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalAmount');
    });
  }

  QueryBuilder<DebtModel, double, QQueryOperations>
      totalWithInterestProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalWithInterest');
    });
  }

  QueryBuilder<DebtModel, DebtType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<DebtModel, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
