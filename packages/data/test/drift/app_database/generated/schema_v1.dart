// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class CalendarSettings extends Table
    with TableInfo<CalendarSettings, CalendarSettingsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CalendarSettings(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  late final GeneratedColumn<int> sasanaYearType = GeneratedColumn<int>(
    'sasana_year_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<int> calendarType = GeneratedColumn<int>(
    'calendar_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<int> gregorianStart = GeneratedColumn<int>(
    'gregorian_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('2361222'),
  );
  late final GeneratedColumn<double> timezoneOffset = GeneratedColumn<double>(
    'timezone_offset',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('6.5'),
  );
  late final GeneratedColumn<String> defaultLanguage = GeneratedColumn<String>(
    'default_language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('\'en\''),
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression(
      'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)',
    ),
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression(
      'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sasanaYearType,
    calendarType,
    gregorianStart,
    timezoneOffset,
    defaultLanguage,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_settings';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarSettingsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarSettingsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sasanaYearType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sasana_year_type'],
      )!,
      calendarType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calendar_type'],
      )!,
      gregorianStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gregorian_start'],
      )!,
      timezoneOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}timezone_offset'],
      )!,
      defaultLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_language'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  CalendarSettings createAlias(String alias) {
    return CalendarSettings(attachedDatabase, alias);
  }
}

class CalendarSettingsData extends DataClass
    implements Insertable<CalendarSettingsData> {
  final int id;
  final int sasanaYearType;
  final int calendarType;
  final int gregorianStart;
  final double timezoneOffset;
  final String defaultLanguage;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CalendarSettingsData({
    required this.id,
    required this.sasanaYearType,
    required this.calendarType,
    required this.gregorianStart,
    required this.timezoneOffset,
    required this.defaultLanguage,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sasana_year_type'] = Variable<int>(sasanaYearType);
    map['calendar_type'] = Variable<int>(calendarType);
    map['gregorian_start'] = Variable<int>(gregorianStart);
    map['timezone_offset'] = Variable<double>(timezoneOffset);
    map['default_language'] = Variable<String>(defaultLanguage);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CalendarSettingsCompanion toCompanion(bool nullToAbsent) {
    return CalendarSettingsCompanion(
      id: Value(id),
      sasanaYearType: Value(sasanaYearType),
      calendarType: Value(calendarType),
      gregorianStart: Value(gregorianStart),
      timezoneOffset: Value(timezoneOffset),
      defaultLanguage: Value(defaultLanguage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CalendarSettingsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarSettingsData(
      id: serializer.fromJson<int>(json['id']),
      sasanaYearType: serializer.fromJson<int>(json['sasanaYearType']),
      calendarType: serializer.fromJson<int>(json['calendarType']),
      gregorianStart: serializer.fromJson<int>(json['gregorianStart']),
      timezoneOffset: serializer.fromJson<double>(json['timezoneOffset']),
      defaultLanguage: serializer.fromJson<String>(json['defaultLanguage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sasanaYearType': serializer.toJson<int>(sasanaYearType),
      'calendarType': serializer.toJson<int>(calendarType),
      'gregorianStart': serializer.toJson<int>(gregorianStart),
      'timezoneOffset': serializer.toJson<double>(timezoneOffset),
      'defaultLanguage': serializer.toJson<String>(defaultLanguage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CalendarSettingsData copyWith({
    int? id,
    int? sasanaYearType,
    int? calendarType,
    int? gregorianStart,
    double? timezoneOffset,
    String? defaultLanguage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CalendarSettingsData(
    id: id ?? this.id,
    sasanaYearType: sasanaYearType ?? this.sasanaYearType,
    calendarType: calendarType ?? this.calendarType,
    gregorianStart: gregorianStart ?? this.gregorianStart,
    timezoneOffset: timezoneOffset ?? this.timezoneOffset,
    defaultLanguage: defaultLanguage ?? this.defaultLanguage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CalendarSettingsData copyWithCompanion(CalendarSettingsCompanion data) {
    return CalendarSettingsData(
      id: data.id.present ? data.id.value : this.id,
      sasanaYearType: data.sasanaYearType.present
          ? data.sasanaYearType.value
          : this.sasanaYearType,
      calendarType: data.calendarType.present
          ? data.calendarType.value
          : this.calendarType,
      gregorianStart: data.gregorianStart.present
          ? data.gregorianStart.value
          : this.gregorianStart,
      timezoneOffset: data.timezoneOffset.present
          ? data.timezoneOffset.value
          : this.timezoneOffset,
      defaultLanguage: data.defaultLanguage.present
          ? data.defaultLanguage.value
          : this.defaultLanguage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarSettingsData(')
          ..write('id: $id, ')
          ..write('sasanaYearType: $sasanaYearType, ')
          ..write('calendarType: $calendarType, ')
          ..write('gregorianStart: $gregorianStart, ')
          ..write('timezoneOffset: $timezoneOffset, ')
          ..write('defaultLanguage: $defaultLanguage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sasanaYearType,
    calendarType,
    gregorianStart,
    timezoneOffset,
    defaultLanguage,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarSettingsData &&
          other.id == this.id &&
          other.sasanaYearType == this.sasanaYearType &&
          other.calendarType == this.calendarType &&
          other.gregorianStart == this.gregorianStart &&
          other.timezoneOffset == this.timezoneOffset &&
          other.defaultLanguage == this.defaultLanguage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CalendarSettingsCompanion extends UpdateCompanion<CalendarSettingsData> {
  final Value<int> id;
  final Value<int> sasanaYearType;
  final Value<int> calendarType;
  final Value<int> gregorianStart;
  final Value<double> timezoneOffset;
  final Value<String> defaultLanguage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CalendarSettingsCompanion({
    this.id = const Value.absent(),
    this.sasanaYearType = const Value.absent(),
    this.calendarType = const Value.absent(),
    this.gregorianStart = const Value.absent(),
    this.timezoneOffset = const Value.absent(),
    this.defaultLanguage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CalendarSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.sasanaYearType = const Value.absent(),
    this.calendarType = const Value.absent(),
    this.gregorianStart = const Value.absent(),
    this.timezoneOffset = const Value.absent(),
    this.defaultLanguage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<CalendarSettingsData> custom({
    Expression<int>? id,
    Expression<int>? sasanaYearType,
    Expression<int>? calendarType,
    Expression<int>? gregorianStart,
    Expression<double>? timezoneOffset,
    Expression<String>? defaultLanguage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sasanaYearType != null) 'sasana_year_type': sasanaYearType,
      if (calendarType != null) 'calendar_type': calendarType,
      if (gregorianStart != null) 'gregorian_start': gregorianStart,
      if (timezoneOffset != null) 'timezone_offset': timezoneOffset,
      if (defaultLanguage != null) 'default_language': defaultLanguage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CalendarSettingsCompanion copyWith({
    Value<int>? id,
    Value<int>? sasanaYearType,
    Value<int>? calendarType,
    Value<int>? gregorianStart,
    Value<double>? timezoneOffset,
    Value<String>? defaultLanguage,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CalendarSettingsCompanion(
      id: id ?? this.id,
      sasanaYearType: sasanaYearType ?? this.sasanaYearType,
      calendarType: calendarType ?? this.calendarType,
      gregorianStart: gregorianStart ?? this.gregorianStart,
      timezoneOffset: timezoneOffset ?? this.timezoneOffset,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sasanaYearType.present) {
      map['sasana_year_type'] = Variable<int>(sasanaYearType.value);
    }
    if (calendarType.present) {
      map['calendar_type'] = Variable<int>(calendarType.value);
    }
    if (gregorianStart.present) {
      map['gregorian_start'] = Variable<int>(gregorianStart.value);
    }
    if (timezoneOffset.present) {
      map['timezone_offset'] = Variable<double>(timezoneOffset.value);
    }
    if (defaultLanguage.present) {
      map['default_language'] = Variable<String>(defaultLanguage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarSettingsCompanion(')
          ..write('id: $id, ')
          ..write('sasanaYearType: $sasanaYearType, ')
          ..write('calendarType: $calendarType, ')
          ..write('gregorianStart: $gregorianStart, ')
          ..write('timezoneOffset: $timezoneOffset, ')
          ..write('defaultLanguage: $defaultLanguage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class AppSettings extends Table with TableInfo<AppSettings, AppSettingsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AppSettings(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression(
      'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)',
    ),
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression(
      'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, key, value, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  AppSettings createAlias(String alias) {
    return AppSettings(attachedDatabase, alias);
  }
}

class AppSettingsData extends DataClass implements Insertable<AppSettingsData> {
  final int id;
  final String key;
  final String value;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AppSettingsData({
    required this.id,
    required this.key,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsData(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingsData copyWith({
    int? id,
    String? key,
    String? value,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AppSettingsData(
    id: id ?? this.id,
    key: key ?? this.key,
    value: value ?? this.value,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSettingsData copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingsData(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsData(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsData &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingsData> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String value,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingsData> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class CustomHolidays extends Table
    with TableInfo<CustomHolidays, CustomHolidaysData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CustomHolidays(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
    'is_recurring',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_recurring" IN (0, 1))',
    ),
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression(
      'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)',
    ),
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression(
      'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    date,
    type,
    description,
    isRecurring,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_holidays';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomHolidaysData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomHolidaysData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isRecurring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_recurring'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  CustomHolidays createAlias(String alias) {
    return CustomHolidays(attachedDatabase, alias);
  }
}

class CustomHolidaysData extends DataClass
    implements Insertable<CustomHolidaysData> {
  final int id;
  final String name;
  final DateTime date;
  final String type;
  final String? description;
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CustomHolidaysData({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    this.description,
    required this.isRecurring,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['date'] = Variable<DateTime>(date);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_recurring'] = Variable<bool>(isRecurring);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CustomHolidaysCompanion toCompanion(bool nullToAbsent) {
    return CustomHolidaysCompanion(
      id: Value(id),
      name: Value(name),
      date: Value(date),
      type: Value(type),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isRecurring: Value(isRecurring),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomHolidaysData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomHolidaysData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      date: serializer.fromJson<DateTime>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      description: serializer.fromJson<String?>(json['description']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'date': serializer.toJson<DateTime>(date),
      'type': serializer.toJson<String>(type),
      'description': serializer.toJson<String?>(description),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CustomHolidaysData copyWith({
    int? id,
    String? name,
    DateTime? date,
    String? type,
    Value<String?> description = const Value.absent(),
    bool? isRecurring,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CustomHolidaysData(
    id: id ?? this.id,
    name: name ?? this.name,
    date: date ?? this.date,
    type: type ?? this.type,
    description: description.present ? description.value : this.description,
    isRecurring: isRecurring ?? this.isRecurring,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomHolidaysData copyWithCompanion(CustomHolidaysCompanion data) {
    return CustomHolidaysData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      description: data.description.present
          ? data.description.value
          : this.description,
      isRecurring: data.isRecurring.present
          ? data.isRecurring.value
          : this.isRecurring,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomHolidaysData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    date,
    type,
    description,
    isRecurring,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomHolidaysData &&
          other.id == this.id &&
          other.name == this.name &&
          other.date == this.date &&
          other.type == this.type &&
          other.description == this.description &&
          other.isRecurring == this.isRecurring &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomHolidaysCompanion extends UpdateCompanion<CustomHolidaysData> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> date;
  final Value<String> type;
  final Value<String?> description;
  final Value<bool> isRecurring;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CustomHolidaysCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CustomHolidaysCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime date,
    required String type,
    this.description = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       date = Value(date),
       type = Value(type);
  static Insertable<CustomHolidaysData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? date,
    Expression<String>? type,
    Expression<String>? description,
    Expression<bool>? isRecurring,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CustomHolidaysCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? date,
    Value<String>? type,
    Value<String?>? description,
    Value<bool>? isRecurring,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CustomHolidaysCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      type: type ?? this.type,
      description: description ?? this.description,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomHolidaysCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class UserEvents extends Table with TableInfo<UserEvents, UserEventsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  UserEvents(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<DateTime> eventDate = GeneratedColumn<DateTime>(
    'event_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<DateTime> eventTime = GeneratedColumn<DateTime>(
    'event_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
    'is_all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_all_day" IN (0, 1))',
    ),
    defaultValue: const CustomExpression('1'),
  );
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> colorCode = GeneratedColumn<int>(
    'color_code',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> recurrenceType = GeneratedColumn<String>(
    'recurrence_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> recurrenceInterval = GeneratedColumn<int>(
    'recurrence_interval',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> recurrenceDays = GeneratedColumn<String>(
    'recurrence_days',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<DateTime> recurrenceEndDate =
      GeneratedColumn<DateTime>(
        'recurrence_end_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  late final GeneratedColumn<int> recurrenceCount = GeneratedColumn<int>(
    'recurrence_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<bool> hasNotification = GeneratedColumn<bool>(
    'has_notification',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_notification" IN (0, 1))',
    ),
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<String> notificationTimes =
      GeneratedColumn<String>(
        'notification_times',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('1761915241'),
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('1761915241'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    eventDate,
    eventTime,
    isAllDay,
    category,
    categoryId,
    colorCode,
    recurrenceType,
    recurrenceInterval,
    recurrenceDays,
    recurrenceEndDate,
    recurrenceCount,
    hasNotification,
    notificationTimes,
    location,
    isCompleted,
    completedAt,
    priority,
    tags,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_events';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserEventsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserEventsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      eventDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}event_date'],
      )!,
      eventTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}event_time'],
      ),
      isAllDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_all_day'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      colorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_code'],
      ),
      recurrenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_type'],
      ),
      recurrenceInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_interval'],
      ),
      recurrenceDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_days'],
      ),
      recurrenceEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recurrence_end_date'],
      ),
      recurrenceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_count'],
      ),
      hasNotification: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_notification'],
      )!,
      notificationTimes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notification_times'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  UserEvents createAlias(String alias) {
    return UserEvents(attachedDatabase, alias);
  }
}

class UserEventsData extends DataClass implements Insertable<UserEventsData> {
  final int id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final DateTime? eventTime;
  final bool isAllDay;
  final String category;
  final int? categoryId;
  final int? colorCode;
  final String? recurrenceType;
  final int? recurrenceInterval;
  final String? recurrenceDays;
  final DateTime? recurrenceEndDate;
  final int? recurrenceCount;
  final bool hasNotification;
  final String? notificationTimes;
  final String? location;
  final bool isCompleted;
  final DateTime? completedAt;
  final int priority;
  final String? tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserEventsData({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.eventTime,
    required this.isAllDay,
    required this.category,
    this.categoryId,
    this.colorCode,
    this.recurrenceType,
    this.recurrenceInterval,
    this.recurrenceDays,
    this.recurrenceEndDate,
    this.recurrenceCount,
    required this.hasNotification,
    this.notificationTimes,
    this.location,
    required this.isCompleted,
    this.completedAt,
    required this.priority,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['event_date'] = Variable<DateTime>(eventDate);
    if (!nullToAbsent || eventTime != null) {
      map['event_time'] = Variable<DateTime>(eventTime);
    }
    map['is_all_day'] = Variable<bool>(isAllDay);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || colorCode != null) {
      map['color_code'] = Variable<int>(colorCode);
    }
    if (!nullToAbsent || recurrenceType != null) {
      map['recurrence_type'] = Variable<String>(recurrenceType);
    }
    if (!nullToAbsent || recurrenceInterval != null) {
      map['recurrence_interval'] = Variable<int>(recurrenceInterval);
    }
    if (!nullToAbsent || recurrenceDays != null) {
      map['recurrence_days'] = Variable<String>(recurrenceDays);
    }
    if (!nullToAbsent || recurrenceEndDate != null) {
      map['recurrence_end_date'] = Variable<DateTime>(recurrenceEndDate);
    }
    if (!nullToAbsent || recurrenceCount != null) {
      map['recurrence_count'] = Variable<int>(recurrenceCount);
    }
    map['has_notification'] = Variable<bool>(hasNotification);
    if (!nullToAbsent || notificationTimes != null) {
      map['notification_times'] = Variable<String>(notificationTimes);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserEventsCompanion toCompanion(bool nullToAbsent) {
    return UserEventsCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      eventDate: Value(eventDate),
      eventTime: eventTime == null && nullToAbsent
          ? const Value.absent()
          : Value(eventTime),
      isAllDay: Value(isAllDay),
      category: Value(category),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      colorCode: colorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(colorCode),
      recurrenceType: recurrenceType == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceType),
      recurrenceInterval: recurrenceInterval == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceInterval),
      recurrenceDays: recurrenceDays == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceDays),
      recurrenceEndDate: recurrenceEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceEndDate),
      recurrenceCount: recurrenceCount == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceCount),
      hasNotification: Value(hasNotification),
      notificationTimes: notificationTimes == null && nullToAbsent
          ? const Value.absent()
          : Value(notificationTimes),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      isCompleted: Value(isCompleted),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      priority: Value(priority),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserEventsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserEventsData(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      eventDate: serializer.fromJson<DateTime>(json['eventDate']),
      eventTime: serializer.fromJson<DateTime?>(json['eventTime']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
      category: serializer.fromJson<String>(json['category']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      colorCode: serializer.fromJson<int?>(json['colorCode']),
      recurrenceType: serializer.fromJson<String?>(json['recurrenceType']),
      recurrenceInterval: serializer.fromJson<int?>(json['recurrenceInterval']),
      recurrenceDays: serializer.fromJson<String?>(json['recurrenceDays']),
      recurrenceEndDate: serializer.fromJson<DateTime?>(
        json['recurrenceEndDate'],
      ),
      recurrenceCount: serializer.fromJson<int?>(json['recurrenceCount']),
      hasNotification: serializer.fromJson<bool>(json['hasNotification']),
      notificationTimes: serializer.fromJson<String?>(
        json['notificationTimes'],
      ),
      location: serializer.fromJson<String?>(json['location']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      priority: serializer.fromJson<int>(json['priority']),
      tags: serializer.fromJson<String?>(json['tags']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'eventDate': serializer.toJson<DateTime>(eventDate),
      'eventTime': serializer.toJson<DateTime?>(eventTime),
      'isAllDay': serializer.toJson<bool>(isAllDay),
      'category': serializer.toJson<String>(category),
      'categoryId': serializer.toJson<int?>(categoryId),
      'colorCode': serializer.toJson<int?>(colorCode),
      'recurrenceType': serializer.toJson<String?>(recurrenceType),
      'recurrenceInterval': serializer.toJson<int?>(recurrenceInterval),
      'recurrenceDays': serializer.toJson<String?>(recurrenceDays),
      'recurrenceEndDate': serializer.toJson<DateTime?>(recurrenceEndDate),
      'recurrenceCount': serializer.toJson<int?>(recurrenceCount),
      'hasNotification': serializer.toJson<bool>(hasNotification),
      'notificationTimes': serializer.toJson<String?>(notificationTimes),
      'location': serializer.toJson<String?>(location),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'priority': serializer.toJson<int>(priority),
      'tags': serializer.toJson<String?>(tags),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserEventsData copyWith({
    int? id,
    String? title,
    Value<String?> description = const Value.absent(),
    DateTime? eventDate,
    Value<DateTime?> eventTime = const Value.absent(),
    bool? isAllDay,
    String? category,
    Value<int?> categoryId = const Value.absent(),
    Value<int?> colorCode = const Value.absent(),
    Value<String?> recurrenceType = const Value.absent(),
    Value<int?> recurrenceInterval = const Value.absent(),
    Value<String?> recurrenceDays = const Value.absent(),
    Value<DateTime?> recurrenceEndDate = const Value.absent(),
    Value<int?> recurrenceCount = const Value.absent(),
    bool? hasNotification,
    Value<String?> notificationTimes = const Value.absent(),
    Value<String?> location = const Value.absent(),
    bool? isCompleted,
    Value<DateTime?> completedAt = const Value.absent(),
    int? priority,
    Value<String?> tags = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserEventsData(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    eventDate: eventDate ?? this.eventDate,
    eventTime: eventTime.present ? eventTime.value : this.eventTime,
    isAllDay: isAllDay ?? this.isAllDay,
    category: category ?? this.category,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    colorCode: colorCode.present ? colorCode.value : this.colorCode,
    recurrenceType: recurrenceType.present
        ? recurrenceType.value
        : this.recurrenceType,
    recurrenceInterval: recurrenceInterval.present
        ? recurrenceInterval.value
        : this.recurrenceInterval,
    recurrenceDays: recurrenceDays.present
        ? recurrenceDays.value
        : this.recurrenceDays,
    recurrenceEndDate: recurrenceEndDate.present
        ? recurrenceEndDate.value
        : this.recurrenceEndDate,
    recurrenceCount: recurrenceCount.present
        ? recurrenceCount.value
        : this.recurrenceCount,
    hasNotification: hasNotification ?? this.hasNotification,
    notificationTimes: notificationTimes.present
        ? notificationTimes.value
        : this.notificationTimes,
    location: location.present ? location.value : this.location,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    priority: priority ?? this.priority,
    tags: tags.present ? tags.value : this.tags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserEventsData copyWithCompanion(UserEventsCompanion data) {
    return UserEventsData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      eventDate: data.eventDate.present ? data.eventDate.value : this.eventDate,
      eventTime: data.eventTime.present ? data.eventTime.value : this.eventTime,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      category: data.category.present ? data.category.value : this.category,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      colorCode: data.colorCode.present ? data.colorCode.value : this.colorCode,
      recurrenceType: data.recurrenceType.present
          ? data.recurrenceType.value
          : this.recurrenceType,
      recurrenceInterval: data.recurrenceInterval.present
          ? data.recurrenceInterval.value
          : this.recurrenceInterval,
      recurrenceDays: data.recurrenceDays.present
          ? data.recurrenceDays.value
          : this.recurrenceDays,
      recurrenceEndDate: data.recurrenceEndDate.present
          ? data.recurrenceEndDate.value
          : this.recurrenceEndDate,
      recurrenceCount: data.recurrenceCount.present
          ? data.recurrenceCount.value
          : this.recurrenceCount,
      hasNotification: data.hasNotification.present
          ? data.hasNotification.value
          : this.hasNotification,
      notificationTimes: data.notificationTimes.present
          ? data.notificationTimes.value
          : this.notificationTimes,
      location: data.location.present ? data.location.value : this.location,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      priority: data.priority.present ? data.priority.value : this.priority,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserEventsData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('eventDate: $eventDate, ')
          ..write('eventTime: $eventTime, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('category: $category, ')
          ..write('categoryId: $categoryId, ')
          ..write('colorCode: $colorCode, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('recurrenceInterval: $recurrenceInterval, ')
          ..write('recurrenceDays: $recurrenceDays, ')
          ..write('recurrenceEndDate: $recurrenceEndDate, ')
          ..write('recurrenceCount: $recurrenceCount, ')
          ..write('hasNotification: $hasNotification, ')
          ..write('notificationTimes: $notificationTimes, ')
          ..write('location: $location, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('priority: $priority, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    description,
    eventDate,
    eventTime,
    isAllDay,
    category,
    categoryId,
    colorCode,
    recurrenceType,
    recurrenceInterval,
    recurrenceDays,
    recurrenceEndDate,
    recurrenceCount,
    hasNotification,
    notificationTimes,
    location,
    isCompleted,
    completedAt,
    priority,
    tags,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserEventsData &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.eventDate == this.eventDate &&
          other.eventTime == this.eventTime &&
          other.isAllDay == this.isAllDay &&
          other.category == this.category &&
          other.categoryId == this.categoryId &&
          other.colorCode == this.colorCode &&
          other.recurrenceType == this.recurrenceType &&
          other.recurrenceInterval == this.recurrenceInterval &&
          other.recurrenceDays == this.recurrenceDays &&
          other.recurrenceEndDate == this.recurrenceEndDate &&
          other.recurrenceCount == this.recurrenceCount &&
          other.hasNotification == this.hasNotification &&
          other.notificationTimes == this.notificationTimes &&
          other.location == this.location &&
          other.isCompleted == this.isCompleted &&
          other.completedAt == this.completedAt &&
          other.priority == this.priority &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserEventsCompanion extends UpdateCompanion<UserEventsData> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> eventDate;
  final Value<DateTime?> eventTime;
  final Value<bool> isAllDay;
  final Value<String> category;
  final Value<int?> categoryId;
  final Value<int?> colorCode;
  final Value<String?> recurrenceType;
  final Value<int?> recurrenceInterval;
  final Value<String?> recurrenceDays;
  final Value<DateTime?> recurrenceEndDate;
  final Value<int?> recurrenceCount;
  final Value<bool> hasNotification;
  final Value<String?> notificationTimes;
  final Value<String?> location;
  final Value<bool> isCompleted;
  final Value<DateTime?> completedAt;
  final Value<int> priority;
  final Value<String?> tags;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const UserEventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.eventTime = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.category = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.colorCode = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.recurrenceInterval = const Value.absent(),
    this.recurrenceDays = const Value.absent(),
    this.recurrenceEndDate = const Value.absent(),
    this.recurrenceCount = const Value.absent(),
    this.hasNotification = const Value.absent(),
    this.notificationTimes = const Value.absent(),
    this.location = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UserEventsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required DateTime eventDate,
    this.eventTime = const Value.absent(),
    this.isAllDay = const Value.absent(),
    required String category,
    this.categoryId = const Value.absent(),
    this.colorCode = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.recurrenceInterval = const Value.absent(),
    this.recurrenceDays = const Value.absent(),
    this.recurrenceEndDate = const Value.absent(),
    this.recurrenceCount = const Value.absent(),
    this.hasNotification = const Value.absent(),
    this.notificationTimes = const Value.absent(),
    this.location = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title),
       eventDate = Value(eventDate),
       category = Value(category);
  static Insertable<UserEventsData> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? eventDate,
    Expression<DateTime>? eventTime,
    Expression<bool>? isAllDay,
    Expression<String>? category,
    Expression<int>? categoryId,
    Expression<int>? colorCode,
    Expression<String>? recurrenceType,
    Expression<int>? recurrenceInterval,
    Expression<String>? recurrenceDays,
    Expression<DateTime>? recurrenceEndDate,
    Expression<int>? recurrenceCount,
    Expression<bool>? hasNotification,
    Expression<String>? notificationTimes,
    Expression<String>? location,
    Expression<bool>? isCompleted,
    Expression<DateTime>? completedAt,
    Expression<int>? priority,
    Expression<String>? tags,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (eventDate != null) 'event_date': eventDate,
      if (eventTime != null) 'event_time': eventTime,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (category != null) 'category': category,
      if (categoryId != null) 'category_id': categoryId,
      if (colorCode != null) 'color_code': colorCode,
      if (recurrenceType != null) 'recurrence_type': recurrenceType,
      if (recurrenceInterval != null) 'recurrence_interval': recurrenceInterval,
      if (recurrenceDays != null) 'recurrence_days': recurrenceDays,
      if (recurrenceEndDate != null) 'recurrence_end_date': recurrenceEndDate,
      if (recurrenceCount != null) 'recurrence_count': recurrenceCount,
      if (hasNotification != null) 'has_notification': hasNotification,
      if (notificationTimes != null) 'notification_times': notificationTimes,
      if (location != null) 'location': location,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt,
      if (priority != null) 'priority': priority,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UserEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<DateTime>? eventDate,
    Value<DateTime?>? eventTime,
    Value<bool>? isAllDay,
    Value<String>? category,
    Value<int?>? categoryId,
    Value<int?>? colorCode,
    Value<String?>? recurrenceType,
    Value<int?>? recurrenceInterval,
    Value<String?>? recurrenceDays,
    Value<DateTime?>? recurrenceEndDate,
    Value<int?>? recurrenceCount,
    Value<bool>? hasNotification,
    Value<String?>? notificationTimes,
    Value<String?>? location,
    Value<bool>? isCompleted,
    Value<DateTime?>? completedAt,
    Value<int>? priority,
    Value<String?>? tags,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return UserEventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      isAllDay: isAllDay ?? this.isAllDay,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      colorCode: colorCode ?? this.colorCode,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrenceCount: recurrenceCount ?? this.recurrenceCount,
      hasNotification: hasNotification ?? this.hasNotification,
      notificationTimes: notificationTimes ?? this.notificationTimes,
      location: location ?? this.location,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (eventDate.present) {
      map['event_date'] = Variable<DateTime>(eventDate.value);
    }
    if (eventTime.present) {
      map['event_time'] = Variable<DateTime>(eventTime.value);
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (colorCode.present) {
      map['color_code'] = Variable<int>(colorCode.value);
    }
    if (recurrenceType.present) {
      map['recurrence_type'] = Variable<String>(recurrenceType.value);
    }
    if (recurrenceInterval.present) {
      map['recurrence_interval'] = Variable<int>(recurrenceInterval.value);
    }
    if (recurrenceDays.present) {
      map['recurrence_days'] = Variable<String>(recurrenceDays.value);
    }
    if (recurrenceEndDate.present) {
      map['recurrence_end_date'] = Variable<DateTime>(recurrenceEndDate.value);
    }
    if (recurrenceCount.present) {
      map['recurrence_count'] = Variable<int>(recurrenceCount.value);
    }
    if (hasNotification.present) {
      map['has_notification'] = Variable<bool>(hasNotification.value);
    }
    if (notificationTimes.present) {
      map['notification_times'] = Variable<String>(notificationTimes.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserEventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('eventDate: $eventDate, ')
          ..write('eventTime: $eventTime, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('category: $category, ')
          ..write('categoryId: $categoryId, ')
          ..write('colorCode: $colorCode, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('recurrenceInterval: $recurrenceInterval, ')
          ..write('recurrenceDays: $recurrenceDays, ')
          ..write('recurrenceEndDate: $recurrenceEndDate, ')
          ..write('recurrenceCount: $recurrenceCount, ')
          ..write('hasNotification: $hasNotification, ')
          ..write('notificationTimes: $notificationTimes, ')
          ..write('location: $location, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('priority: $priority, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class EventCategories extends Table
    with TableInfo<EventCategories, EventCategoriesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  EventCategories(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
    'icon_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> colorCode = GeneratedColumn<int>(
    'color_code',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    iconName,
    colorCode,
    isDefault,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_categories';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventCategoriesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventCategoriesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_name'],
      )!,
      colorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_code'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  EventCategories createAlias(String alias) {
    return EventCategories(attachedDatabase, alias);
  }
}

class EventCategoriesData extends DataClass
    implements Insertable<EventCategoriesData> {
  final int id;
  final String name;
  final String iconName;
  final int colorCode;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;
  const EventCategoriesData({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorCode,
    required this.isDefault,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon_name'] = Variable<String>(iconName);
    map['color_code'] = Variable<int>(colorCode);
    map['is_default'] = Variable<bool>(isDefault);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EventCategoriesCompanion toCompanion(bool nullToAbsent) {
    return EventCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      iconName: Value(iconName),
      colorCode: Value(colorCode),
      isDefault: Value(isDefault),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory EventCategoriesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventCategoriesData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconName: serializer.fromJson<String>(json['iconName']),
      colorCode: serializer.fromJson<int>(json['colorCode']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'iconName': serializer.toJson<String>(iconName),
      'colorCode': serializer.toJson<int>(colorCode),
      'isDefault': serializer.toJson<bool>(isDefault),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EventCategoriesData copyWith({
    int? id,
    String? name,
    String? iconName,
    int? colorCode,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
  }) => EventCategoriesData(
    id: id ?? this.id,
    name: name ?? this.name,
    iconName: iconName ?? this.iconName,
    colorCode: colorCode ?? this.colorCode,
    isDefault: isDefault ?? this.isDefault,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  EventCategoriesData copyWithCompanion(EventCategoriesCompanion data) {
    return EventCategoriesData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      colorCode: data.colorCode.present ? data.colorCode.value : this.colorCode,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventCategoriesData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconName: $iconName, ')
          ..write('colorCode: $colorCode, ')
          ..write('isDefault: $isDefault, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    iconName,
    colorCode,
    isDefault,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventCategoriesData &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconName == this.iconName &&
          other.colorCode == this.colorCode &&
          other.isDefault == this.isDefault &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class EventCategoriesCompanion extends UpdateCompanion<EventCategoriesData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> iconName;
  final Value<int> colorCode;
  final Value<bool> isDefault;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const EventCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconName = const Value.absent(),
    this.colorCode = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EventCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String iconName,
    required int colorCode,
    this.isDefault = const Value.absent(),
    required int sortOrder,
    required DateTime createdAt,
  }) : name = Value(name),
       iconName = Value(iconName),
       colorCode = Value(colorCode),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt);
  static Insertable<EventCategoriesData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? iconName,
    Expression<int>? colorCode,
    Expression<bool>? isDefault,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconName != null) 'icon_name': iconName,
      if (colorCode != null) 'color_code': colorCode,
      if (isDefault != null) 'is_default': isDefault,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EventCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? iconName,
    Value<int>? colorCode,
    Value<bool>? isDefault,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return EventCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorCode: colorCode ?? this.colorCode,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (colorCode.present) {
      map['color_code'] = Variable<int>(colorCode.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconName: $iconName, ')
          ..write('colorCode: $colorCode, ')
          ..write('isDefault: $isDefault, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV1 extends GeneratedDatabase {
  DatabaseAtV1(QueryExecutor e) : super(e);
  late final CalendarSettings calendarSettings = CalendarSettings(this);
  late final AppSettings appSettings = AppSettings(this);
  late final CustomHolidays customHolidays = CustomHolidays(this);
  late final UserEvents userEvents = UserEvents(this);
  late final EventCategories eventCategories = EventCategories(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    calendarSettings,
    appSettings,
    customHolidays,
    userEvents,
    eventCategories,
  ];
  @override
  int get schemaVersion => 1;
}
