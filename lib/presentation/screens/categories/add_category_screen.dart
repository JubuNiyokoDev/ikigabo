import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/category_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/category_provider.dart';
import '../../providers/theme_provider.dart';

class AddCategoryScreen extends ConsumerStatefulWidget {
  final CategoryModel? category;

  const AddCategoryScreen({super.key, this.category});

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  CategoryType _selectedType = CategoryType.expense;
  String _selectedIcon = 'money';
  String _selectedColor = '4CAF50';

  final List<String> _availableIcons = [
    'money',
    'salary',
    'sale',
    'gift',
    'investment',
    'food',
    'transport',
    'health',
    'education',
    'entertainment',
    'shopping',
    'utilities',
    'asset',
    'debt',
  ];

  final List<String> _availableColors = [
    '4CAF50',
    'F44336',
    '2196F3',
    'FF9800',
    '9C27B0',
    'E91E63',
    '3F51B5',
    'FF5722',
    '607D8B',
    '795548',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedType = widget.category!.type;
      _selectedIcon = widget.category!.icon;
      _selectedColor = widget.category!.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final isEditing = widget.category != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? l10n.editSource : l10n.newSource),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: isDark ? AppColors.textDark : Colors.black87,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPreview(isDark),
            const SizedBox(height: 24),
            _buildNameField(l10n, isDark),
            const SizedBox(height: 24),
            _buildTypeSelector(l10n, isDark),
            const SizedBox(height: 24),
            _buildIconSelector(isDark),
            const SizedBox(height: 24),
            _buildColorSelector(isDark),
            const SizedBox(height: 32),
            _buildSaveButton(l10n, isEditing),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(bool isDark) {
    final color = Color(int.parse('FF$_selectedColor', radix: 16));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Aperçu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(_getIconData(_selectedIcon), color: color, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            _nameController.text.isEmpty
                ? 'Nom de la catégorie'
                : _nameController.text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getTypeLabel(_selectedType),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nom de la catégorie',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Ex: Restaurant, Essence...',
              prefixIcon: Icon(AppIcons.edit),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.nameRequired;
              }
              return null;
            },
            onChanged: (value) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.type,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTypeOption(
                  CategoryType.income,
                  l10n.income,
                  AppColors.success,
                  AppIcons.income,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeOption(
                  CategoryType.expense,
                  l10n.expense,
                  AppColors.error,
                  AppIcons.expense,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeOption(
                  CategoryType.both,
                  'Les deux',
                  AppColors.primary,
                  AppIcons.money,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(
    CategoryType type,
    String label,
    Color color,
    IconData icon,
  ) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.borderDark,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondaryDark,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Icône',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableIcons.map((iconName) {
              final isSelected = _selectedIcon == iconName;
              final color = Color(int.parse('FF$_selectedColor', radix: 16));

              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = iconName),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.2)
                        : AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : AppColors.borderDark,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    _getIconData(iconName),
                    color: isSelected ? color : AppColors.textSecondaryDark,
                    size: 24,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Couleur',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableColors.map((colorHex) {
              final color = Color(int.parse('FF$colorHex', radix: 16));
              final isSelected = _selectedColor == colorHex;

              return GestureDetector(
                onTap: () => setState(() => _selectedColor = colorHex),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n, bool isEditing) {
    return ElevatedButton(
      onPressed: _saveCategory,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        isEditing ? l10n.editSource : l10n.save,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final category = CategoryModel(
      id: widget.category?.id ?? Isar.autoIncrement,
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
      type: _selectedType,
      isDefault: widget.category?.isDefault ?? false,
      createdAt: widget.category?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.category != null) {
        await ref
            .read(categoryControllerProvider.notifier)
            .updateCategory(category);
      } else {
        await ref
            .read(categoryControllerProvider.notifier)
            .createCategory(category);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.category != null ? 'Catégorie modifiée' : 'Catégorie créée',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'salary':
        return AppIcons.salary;
      case 'sale':
        return AppIcons.sale;
      case 'gift':
        return AppIcons.gift;
      case 'investment':
        return AppIcons.investment;
      case 'food':
        return AppIcons.food;
      case 'transport':
        return AppIcons.transport;
      case 'health':
        return AppIcons.health;
      case 'education':
        return AppIcons.education;
      case 'entertainment':
        return AppIcons.entertainment;
      case 'shopping':
        return AppIcons.shopping;
      case 'utilities':
        return AppIcons.utilities;
      case 'asset':
        return AppIcons.asset;
      case 'debt':
        return AppIcons.debt;
      default:
        return AppIcons.money;
    }
  }

  String _getTypeLabel(CategoryType type) {
    switch (type) {
      case CategoryType.income:
        return 'Revenus';
      case CategoryType.expense:
        return 'Dépenses';
      case CategoryType.both:
        return 'Revenus & Dépenses';
    }
  }
}
