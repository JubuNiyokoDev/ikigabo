import 'package:isar_community/isar.dart';

part 'category_model.g.dart';

enum CategoryType {
  income,
  expense,
  both,
}

@collection
class CategoryModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String name;

  late String icon;

  late String color;

  @enumerated
  late CategoryType type;

  late bool isDefault;

  late DateTime createdAt;

  DateTime? updatedAt;

  @Index()
  late bool isDeleted;

  CategoryModel({
    this.id = Isar.autoIncrement,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });
}