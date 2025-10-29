import 'package:equatable/equatable.dart';

/// Event category entity
class EventCategory extends Equatable {
  final int? id;
  final String name;
  final String iconName;
  final int colorCode;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;

  const EventCategory({
    this.id,
    required this.name,
    required this.iconName,
    required this.colorCode,
    this.isDefault = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  /// Predefined categories
  static EventCategory get personal => EventCategory(
    id: 1,
    name: 'Personal',
    iconName: 'person',
    colorCode: 0xFF2196F3,
    isDefault: true,
    sortOrder: 1,
    createdAt: DateTime.now(),
  );

  static EventCategory get work => EventCategory(
    id: 2,
    name: 'Work',
    iconName: 'work',
    colorCode: 0xFF4CAF50,
    isDefault: true,
    sortOrder: 2,
    createdAt: DateTime.now(),
  );

  static EventCategory get religious => EventCategory(
    id: 3,
    name: 'Religious',
    iconName: 'auto_awesome',
    colorCode: 0xFFFF9800,
    isDefault: true,
    sortOrder: 3,
    createdAt: DateTime.now(),
  );

  static EventCategory get family => EventCategory(
    id: 4,
    name: 'Family',
    iconName: 'family_restroom',
    colorCode: 0xFFE91E63,
    isDefault: true,
    sortOrder: 4,
    createdAt: DateTime.now(),
  );

  static EventCategory get health => EventCategory(
    id: 5,
    name: 'Health',
    iconName: 'favorite',
    colorCode: 0xFFF44336,
    isDefault: true,
    sortOrder: 5,
    createdAt: DateTime.now(),
  );

  static List<EventCategory> get defaultCategories => [
    personal,
    work,
    religious,
    family,
    health,
  ];

  EventCategory copyWith({
    int? id,
    String? name,
    String? iconName,
    int? colorCode,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return EventCategory(
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
  List<Object?> get props => [
    id,
    name,
    iconName,
    colorCode,
    isDefault,
    sortOrder,
    createdAt,
  ];
}
