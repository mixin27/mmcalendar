import 'package:data/data.dart' as db;
import 'package:drift/drift.dart';

import '../../domain/entities/event_category.dart';

/// Data model for EventCategory entity
class EventCategoryModel extends EventCategory {
  const EventCategoryModel({
    super.id,
    required super.name,
    required super.iconName,
    required super.colorCode,
    super.isDefault,
    super.sortOrder,
    required super.createdAt,
  });

  /// Convert from domain entity to data model
  factory EventCategoryModel.fromEntity(EventCategory entity) {
    return EventCategoryModel(
      id: entity.id,
      name: entity.name,
      iconName: entity.iconName,
      colorCode: entity.colorCode,
      isDefault: entity.isDefault,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
    );
  }

  /// Convert from database EventCategory to EventCategoryModel
  factory EventCategoryModel.fromDatabaseEntity(db.EventCategory dbCategory) {
    return EventCategoryModel(
      id: dbCategory.id,
      name: dbCategory.name,
      iconName: dbCategory.iconName,
      colorCode: dbCategory.colorCode,
      isDefault: dbCategory.isDefault,
      sortOrder: dbCategory.sortOrder,
      createdAt: dbCategory.createdAt,
    );
  }

  /// Convert to database companion for insert/update
  db.EventCategoriesCompanion toDatabaseCompanion() {
    return db.EventCategoriesCompanion.insert(
      id: id != null ? Value(id!) : const Value.absent(),
      name: name,
      iconName: iconName,
      colorCode: colorCode,
      isDefault: Value(isDefault),
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }

  /// Convert to domain entity
  EventCategory toEntity() {
    return EventCategory(
      id: id,
      name: name,
      iconName: iconName,
      colorCode: colorCode,
      isDefault: isDefault,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }

  @override
  EventCategoryModel copyWith({
    int? id,
    String? name,
    String? iconName,
    int? colorCode,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return EventCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorCode: colorCode ?? this.colorCode,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
