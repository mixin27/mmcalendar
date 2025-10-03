import 'package:equatable/equatable.dart';

/// Base class for all data models
abstract class BaseModel extends Equatable {
  const BaseModel();

  /// Convert to Map for serialization
  Map<String, dynamic> toMap();

  /// Create from Map for deserialization
  // Implement in subclasses
  // factory BaseModel.fromMap(Map<String, dynamic> map);
}
