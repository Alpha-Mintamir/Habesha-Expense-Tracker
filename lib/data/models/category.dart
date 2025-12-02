import '../../core/constants/db_constants.dart';

class Category {
  final int? id;
  final String name;
  final bool isDefault;
  final String createdAt; // ISO 8601

  Category({
    this.id,
    required this.name,
    this.isDefault = false,
    required this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map[DbConstants.colId] as int?,
      name: map[DbConstants.colName] as String,
      isDefault: (map[DbConstants.colIsDefault] as int) == 1,
      createdAt: map[DbConstants.colCreatedAt] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.colId: id,
      DbConstants.colName: name,
      DbConstants.colIsDefault: isDefault ? 1 : 0,
      DbConstants.colCreatedAt: createdAt,
    };
  }

  Category copyWith({
    int? id,
    String? name,
    bool? isDefault,
    String? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

