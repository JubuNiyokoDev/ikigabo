import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/category_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../providers/category_provider.dart';
import 'add_category_screen.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: isDark ? AppColors.textDark : Colors.black87,
        elevation: 0,
        title: Text(l10n.category),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
            ),
            icon: const Icon(AppIcons.add),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.money,
                    size: 64,
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noData,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryDetailScreen(category: category),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(int.parse('0xFF${category.color}')).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getIconData(category.icon),
                              color: Color(int.parse('0xFF${category.color}')),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                Text(
                                  _getTypeLabel(category.type, l10n),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!category.isDefault)
                            IconButton(
                              onPressed: () => _deleteCategory(ref, category.id),
                              icon: const Icon(AppIcons.delete, color: AppColors.error),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('${l10n.error}: $e')),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'food': return AppIcons.food;
      case 'transport': return AppIcons.transport;
      case 'health': return AppIcons.health;
      case 'education': return AppIcons.education;
      case 'entertainment': return AppIcons.entertainment;
      case 'salary': return AppIcons.income;
      case 'sale': return AppIcons.money;
      case 'gift': return AppIcons.gift;
      default: return AppIcons.money;
    }
  }

  String _getTypeLabel(CategoryType type, AppLocalizations l10n) {
    switch (type) {
      case CategoryType.income: return l10n.income;
      case CategoryType.expense: return l10n.expense;
      case CategoryType.both: return '${l10n.income} & ${l10n.expense}';
    }
  }

  void _deleteCategory(WidgetRef ref, int categoryId) {
    ref.read(categoryControllerProvider.notifier).deleteCategory(categoryId);
  }
}