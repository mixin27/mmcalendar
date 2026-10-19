import 'package:flutter/material.dart';

/// The icon for a category's stored icon name.
IconData categoryIcon(String iconName) => switch (iconName) {
  'person' => Icons.person,
  'work' => Icons.work,
  'auto_awesome' => Icons.auto_awesome,
  'family_restroom' => Icons.family_restroom,
  'favorite' => Icons.favorite,
  'school' => Icons.school,
  'sports' => Icons.sports,
  'restaurant' => Icons.restaurant,
  'flight' => Icons.flight,
  'shopping_cart' => Icons.shopping_cart,
  _ => Icons.event,
};
