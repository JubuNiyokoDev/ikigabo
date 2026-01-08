import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/category_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/category_provider.dart';
import '../../providers/theme_provider.dart';
import 'add_category_screen.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final CategoryModel category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final color = Color(int.parse('0xFF${category.color}'));

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: isDark ? AppColors.textDark : Colors.black87,
        elevation: 0,
        title: Text(category.name),
        actions: [
          if (!category.isDefault) ...[
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCategoryScreen(category: category),
                ),
              ),
              icon: const Icon(AppIcons.edit),
            ),
            IconButton(
              onPressed: () => _showDeleteDialog(context, ref),
              icon: const Icon(AppIcons.delete, color: AppColors.error),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildPreviewCard(isDark, color),
            SizedBox(height: 16.h),
            _buildDetailsCard(isDark, l10n),
            SizedBox(height: 16.h),
            _buildUsageCard(isDark, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(bool isDark, Color color) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              _getIconData(category.icon),
              color: color,
              size: 40.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            category.name,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              _getTypeLabel(category.type),
              style: TextStyle(
                fontSize: 12.sp,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          _buildDetailRow('Type', _getTypeLabel(category.type), isDark),
          _buildDetailRow('Icône', category.icon, isDark),
          _buildDetailRow('Couleur', '#${category.color}', isDark),
          _buildDetailRow('Statut', category.isDefault ? 'Catégorie par défaut' : 'Catégorie personnalisée', isDark),
          _buildDetailRow('Créée le', _formatDate(category.createdAt), isDark),
          if (category.updatedAt != null)
            _buildDetailRow('Modifiée le', _formatDate(category.updatedAt!), isDark),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? AppColors.textSecondaryDark : Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageCard(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.chart,
                color: AppColors.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Utilisation',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  AppIcons.info,
                  color: AppColors.info,
                  size: 16.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Cette catégorie peut être utilisée pour classer vos transactions.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
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
      case 'investment': return AppIcons.investment;
      case 'food': return AppIcons.food;
      case 'transport': return AppIcons.transport;
      case 'health': return AppIcons.health;
      case 'education': return AppIcons.education;
      case 'entertainment': return AppIcons.entertainment;
      case 'shopping': return AppIcons.shopping;
      case 'utilities': return AppIcons.utilities;
      case 'asset': return AppIcons.asset;
      case 'debt': return AppIcons.debt;
      default: return AppIcons.money;
    }
  }

  String _getTypeLabel(CategoryType type) {
    switch (type) {
      case CategoryType.income: return 'Revenus';
      case CategoryType.expense: return 'Dépenses';
      case CategoryType.both: return 'Revenus & Dépenses';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${category.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(categoryControllerProvider.notifier).deleteCategory(category.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}