import 'package:ikigabo/data/models/category_model.dart';

class DefaultCategories {
  static List<CategoryModel> get incomeCategories => [
    CategoryModel(
      name: 'Salaire',
      type: CategoryType.income,
      icon: 'salary',
      color: '4CAF50',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    CategoryModel(
      name: 'Vente',
      type: CategoryType.income,
      icon: 'sale',
      color: '2196F3',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    CategoryModel(
      name: 'Cadeau',
      type: CategoryType.income,
      icon: 'gift',
      color: 'FF9800',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    CategoryModel(
      name: 'Investissement',
      type: CategoryType.income,
      icon: 'investment',
      color: '9C27B0',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
  ];

  static List<CategoryModel> get expenseCategories => [
    CategoryModel(
      name: 'Alimentation',
      type: CategoryType.expense,
      icon: 'food',
      color: 'FF5722',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    CategoryModel(
      name: 'Transport',
      type: CategoryType.expense,
      icon: 'transport',
      color: '607D8B',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    CategoryModel(
      name: 'Santé',
      type: CategoryType.expense,
      icon: 'health',
      color: 'E91E63',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    CategoryModel(
      name: 'Éducation',
      type: CategoryType.expense,
      icon: 'education',
      color: '3F51B5',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    CategoryModel(
      name: 'Divertissement',
      type: CategoryType.expense,
      icon: 'entertainment',
      color: 'FF9800',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    CategoryModel(
      name: 'Shopping',
      type: CategoryType.expense,
      icon: 'shopping',
      color: 'E91E63',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    CategoryModel(
      name: 'Services',
      type: CategoryType.expense,
      icon: 'utilities',
      color: '795548',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
  ];

  static List<CategoryModel> get bothCategories => [
    CategoryModel(
      name: 'Autre',
      type: CategoryType.both,
      icon: 'money',
      color: '9E9E9E',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
  ];

  static List<CategoryModel> get all => [
    ...incomeCategories,
    ...expenseCategories,
    ...bothCategories,
  ];
}
