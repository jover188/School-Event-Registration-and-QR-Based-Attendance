import 'package:flutter/widgets.dart';

class AppDestination {
  const AppDestination({
    required this.id,
    required this.label,
    required this.icon,
    this.compactPrimary = true,
    this.essential = false,
    this.category,
  });
  final String id;
  final String label;
  final IconData icon;
  final bool compactPrimary;
  final bool essential;
  final String? category;
}
