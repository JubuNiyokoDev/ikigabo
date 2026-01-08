import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import 'isar_provider.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return CategoryRepository(isarService);
});

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategories();
});

final incomeCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategoriesByType(CategoryType.income);
});

final expenseCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategoriesByType(CategoryType.expense);
});

final categoryControllerProvider = StateNotifierProvider<CategoryController, AsyncValue<void>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryController(repository);
});

class CategoryController extends StateNotifier<AsyncValue<void>> {
  final CategoryRepository _repository;

  CategoryController(this._repository) : super(const AsyncValue.data(null));

  Future<void> createCategory(CategoryModel category) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createCategory(category);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateCategory(category);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteCategory(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCategory(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> initializeDefaultCategories() async {
    try {
      await _repository.initializeDefaultCategories();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}