import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/category_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/category_provider.dart';
import '../../providers/theme_provider.dart';
import 'add_category_screen.dart';

class CategoriesManagementScreen extends ConsumerWidget {
  const CategoriesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      appBar: AppBar(
        title: Text('Catégories'),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: isDark ? AppColors.textDark : Colors.black87,
        elevation: 0,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return _buildEmptyState(context, isDark, l10n);
          }
          
          final incomeCategories = categories.where((c) => 
            c.type == CategoryType.income || c.type == CategoryType.both).toList();
          final expenseCategories = categories.where((c) => 
            c.type == CategoryType.expense || c.type == CategoryType.both).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                context, 
                ref,
                'Catégories Revenus', 
                incomeCategories, 
                AppColors.success,
                isDark,
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                ref, 
                'Catégories Dépenses', 
                expenseCategories, 
                AppColors.error,
                isDark,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('${l10n.error}: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(AppIcons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              AppIcons.filter,
              size: 40,
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune catégorie',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre première catégorie',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    WidgetRef ref,
    String title, 
    List<CategoryModel> categories, 
    Color color,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
            const Spacer(),
            Text(
              '${categories.length}',
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...categories.map((category) => _CategoryCard(
          category: category,
          onEdit: () => _editCategory(context, category),
          onDelete: () => _deleteCategory(context, ref, category),
        ).animate().fadeIn(delay: (categories.indexOf(category) * 50).ms)),
      ],
    );
  }

  void _editCategory(BuildContext context, CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCategoryScreen(category: category),
      ),
    );
  }

  void _deleteCategory(BuildContext context, WidgetRef ref, CategoryModel category) {
    final l10n = AppLocalizations.of(context)!;
    
    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de supprimer une catégorie par défaut'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer catégorie'),
        content: Text('Confirmer la suppression de "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(categoryControllerProvider.notifier).deleteCategory(category.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Catégorie supprimée'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final color = Color(int.parse('FF${category.color}', radix: 16));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconData(category.icon),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTypeLabel(category.type, context),
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!category.isDefault) ...[
            IconButton(
              onPressed: onEdit,
              icon: const Icon(AppIcons.edit, size: 18),
              color: AppColors.primary,
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(AppIcons.delete, size: 18),
              color: AppColors.error,
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Défaut',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'salary': return AppIcons.salary;
      case 'sale': return AppIcons.sale;
      case 'gift': return AppIcons.gift;
      case 'food': return AppIcons.food;
      case 'transport': return AppIcons.transport;
      case 'health': return AppIcons.health;
      case 'education': return AppIcons.education;
      case 'entertainment': return AppIcons.entertainment;
      default: return AppIcons.money;
    }
  }

  String _getTypeLabel(CategoryType type, BuildContext context) {
    switch (type) {
      case CategoryType.income: return 'Revenus';
      case CategoryType.expense: return 'Dépenses';
      case CategoryType.both: return 'Les deux';
    }
  }
}