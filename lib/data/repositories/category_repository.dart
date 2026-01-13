import 'package:isar_community/isar.dart';
import '../models/category_model.dart';
import '../services/isar_service.dart';

class CategoryRepository {
  final IsarService _isarService;

  CategoryRepository(this._isarService);

  Future<List<CategoryModel>> getAllCategories() async {
    final isar = await _isarService.isar;
    return await isar.categoryModels
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .sortByName()
        .findAll();
  }

  Future<List<CategoryModel>> getCategoriesByType(CategoryType type) async {
    final isar = await _isarService.isar;
    return await isar.categoryModels
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q
            .typeEqualTo(type)
            .or()
            .typeEqualTo(CategoryType.both))
        .sortByName()
        .findAll();
  }

  Future<CategoryModel?> getCategoryById(int id) async {
    final isar = await _isarService.isar;
    return await isar.categoryModels.get(id);
  }

  Future<CategoryModel> createCategory(CategoryModel category) async {
    final isar = await _isarService.isar;
    await isar.writeTxn(() async {
      await isar.categoryModels.put(category);
    });
    return category;
  }

  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final isar = await _isarService.isar;
    category.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.categoryModels.put(category);
    });
    return category;
  }

  Future<void> deleteCategory(int id) async {
    final isar = await _isarService.isar;
    await isar.writeTxn(() async {
      final category = await isar.categoryModels.get(id);
      if (category != null && !category.isDefault) {
        category.isDeleted = true;
        category.updatedAt = DateTime.now();
        await isar.categoryModels.put(category);
      }
    });
  }

  Future<void> initializeDefaultCategories() async {
    final isar = await _isarService.isar;
    final existingCategories = await getAllCategories();
    
    if (existingCategories.isEmpty) {
      final defaultCategories = [
        // Income categories
        CategoryModel(
          name: 'Salaire',
          icon: 'salary',
          color: '4CAF50',
          type: CategoryType.income,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          name: 'Vente',
          icon: 'sale',
          color: '2196F3',
          type: CategoryType.income,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          name: 'Cadeau',
          icon: 'gift',
          color: 'FF9800',
          type: CategoryType.income,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        
        // Expense categories
        CategoryModel(
          name: 'Nourriture',
          icon: 'food',
          color: 'F44336',
          type: CategoryType.expense,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          name: 'Transport',
          icon: 'transport',
          color: '9C27B0',
          type: CategoryType.expense,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          name: 'Santé',
          icon: 'health',
          color: 'E91E63',
          type: CategoryType.expense,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          name: 'Éducation',
          icon: 'education',
          color: '3F51B5',
          type: CategoryType.expense,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          name: 'Loisirs',
          icon: 'entertainment',
          color: 'FF5722',
          type: CategoryType.expense,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      ];

      await isar.writeTxn(() async {
        await isar.categoryModels.putAll(defaultCategories);
      });
    }
  }

  Stream<List<CategoryModel>> watchCategories() async* {
    final isar = await _isarService.isar;
    yield* isar.categoryModels
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);
  }

  Stream<List<CategoryModel>> watchCategoriesByType(CategoryType type) async* {
    final isar = await _isarService.isar;
    yield* isar.categoryModels
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q
            .typeEqualTo(type)
            .or()
            .typeEqualTo(CategoryType.both))
        .watch(fireImmediately: true);
  }
}