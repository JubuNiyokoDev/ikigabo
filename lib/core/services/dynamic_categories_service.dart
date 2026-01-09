import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';
import '../../l10n/app_localizations.dart';

class DynamicCategoriesService {
  // Générer les catégories d'entrée selon la langue actuelle
  static List<CategoryModel> getIncomeCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return [
      CategoryModel(
        name: l10n.salary,
        type: CategoryType.income,
        icon: 'salary',
        color: '4CAF50',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      CategoryModel(
        name: l10n.sale,
        type: CategoryType.income,
        icon: 'sale',
        color: '2196F3',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      CategoryModel(
        name: l10n.gift,
        type: CategoryType.income,
        icon: 'gift',
        color: 'FF9800',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      CategoryModel(
        name: l10n.investment,
        type: CategoryType.income,
        icon: 'investment',
        color: '9C27B0',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Générer les catégories de sortie selon la langue actuelle
  static List<CategoryModel> getExpenseCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return [
      CategoryModel(
        name: l10n.food,
        type: CategoryType.expense,
        icon: 'food',
        color: 'FF5722',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      CategoryModel(
        name: l10n.transport,
        type: CategoryType.expense,
        icon: 'transport',
        color: '607D8B',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      CategoryModel(
        name: l10n.health,
        type: CategoryType.expense,
        icon: 'health',
        color: 'E91E63',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      CategoryModel(
        name: l10n.education,
        type: CategoryType.expense,
        icon: 'education',
        color: '3F51B5',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      CategoryModel(
        name: l10n.entertainment,
        type: CategoryType.expense,
        icon: 'entertainment',
        color: 'FF9800',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      CategoryModel(
        name: l10n.purchase,
        type: CategoryType.expense,
        icon: 'shopping',
        color: 'E91E63',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      CategoryModel(
        name: l10n.utilities,
        type: CategoryType.expense,
        icon: 'utilities',
        color: '795548',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Catégorie "Autre" selon la langue
  static List<CategoryModel> getOtherCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return [
      CategoryModel(
        name: l10n.other,
        type: CategoryType.both,
        icon: 'money',
        color: '9E9E9E',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Obtenir toutes les catégories par défaut selon la langue
  static List<CategoryModel> getAllDefaultCategories(BuildContext context) {
    return [
      ...getIncomeCategories(context),
      ...getExpenseCategories(context),
      ...getOtherCategories(context),
    ];
  }
}