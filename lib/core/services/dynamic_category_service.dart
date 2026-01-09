import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../l10n/app_localizations.dart';

class CategoryMappingService {
  // Mapping dynamique basé sur les traductions
  static IncomeCategory mapToIncomeCategory(String categoryName, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = categoryName.toLowerCase().trim();
    
    // Vérifier contre les traductions actuelles
    if (name == l10n.salary.toLowerCase()) return IncomeCategory.salary;
    if (name == l10n.sale.toLowerCase()) return IncomeCategory.sale;
    if (name == l10n.gift.toLowerCase()) return IncomeCategory.gift;
    if (name == l10n.investment.toLowerCase()) return IncomeCategory.investment;
    if (name == l10n.debtReceived.toLowerCase()) return IncomeCategory.debtReceived;
    
    return IncomeCategory.other;
  }

  static ExpenseCategory mapToExpenseCategory(String categoryName, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = categoryName.toLowerCase().trim();
    
    // Vérifier contre les traductions actuelles
    if (name == l10n.food.toLowerCase()) return ExpenseCategory.food;
    if (name == l10n.transport.toLowerCase()) return ExpenseCategory.transport;
    if (name == l10n.health.toLowerCase()) return ExpenseCategory.health;
    if (name == l10n.education.toLowerCase()) return ExpenseCategory.education;
    if (name == l10n.entertainment.toLowerCase()) return ExpenseCategory.entertainment;
    if (name == l10n.purchase.toLowerCase()) return ExpenseCategory.purchase;
    if (name == l10n.utilities.toLowerCase()) return ExpenseCategory.utilities;
    if (name == 'retrait' || name == 'withdrawal') return ExpenseCategory.withdrawal;
    if (name == l10n.bankFees.toLowerCase()) return ExpenseCategory.bankFees;
    
    return ExpenseCategory.other;
  }

  // Obtenir la catégorie correcte selon le type et la sélection
  static dynamic getCategoryFromSelection(TransactionType type, String? categoryName, BuildContext context) {
    if (categoryName == null || categoryName.isEmpty) {
      return type == TransactionType.income ? IncomeCategory.other : ExpenseCategory.other;
    }
    
    if (type == TransactionType.income) {
      return mapToIncomeCategory(categoryName, context);
    } else {
      return mapToExpenseCategory(categoryName, context);
    }
  }

  // Mapper une catégorie personnalisée vers l'enum le plus proche
  static ExpenseCategory mapCustomExpenseCategory(CategoryModel category) {
    final icon = category.icon.toLowerCase();
    
    switch (icon) {
      case 'food': return ExpenseCategory.food;
      case 'transport': return ExpenseCategory.transport;
      case 'health': return ExpenseCategory.health;
      case 'education': return ExpenseCategory.education;
      case 'entertainment': return ExpenseCategory.entertainment;
      case 'shopping': return ExpenseCategory.purchase;
      case 'utilities': return ExpenseCategory.utilities;
      default: return ExpenseCategory.other;
    }
  }

  static IncomeCategory mapCustomIncomeCategory(CategoryModel category) {
    final icon = category.icon.toLowerCase();
    
    switch (icon) {
      case 'salary': return IncomeCategory.salary;
      case 'sale': return IncomeCategory.sale;
      case 'gift': return IncomeCategory.gift;
      case 'investment': return IncomeCategory.investment;
      default: return IncomeCategory.other;
    }
  }
}