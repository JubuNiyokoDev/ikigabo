import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ikigabo/core/services/ad_manager.dart';
import 'package:ikigabo/data/models/category_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/services/dynamic_categories_service.dart';
import '../../../data/models/transaction_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/source_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/category_provider.dart';
import '../../../core/services/ads_service.dart';
import '../../../core/services/dynamic_category_service.dart';

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  const AddTransactionBottomSheet({super.key});

  @override
  ConsumerState<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState
    extends ConsumerState<AddTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  int? _selectedSourceId;
  SourceType? _selectedSourceType;
  String _selectedCurrency = 'BIF';
  String? _selectedCategoryKey; // Changé de int? à String?
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryKey == null) {
        _showError('Veuillez sélectionner une catégorie');
        return;
      }

      if (_selectedSourceId == null) {
        _showError('Veuillez sélectionner une source');
        return;
      }

      final amount = double.parse(_amountController.text);

      // Pub récompensée pour transactions importantes (> 50000)
      if (amount > 50000) {
        final rewardGranted = await AdManager.showRewardedForLargeTransaction();
        if (!rewardGranted) {
          _showError('Regardez la pub pour cette transaction importante');
          return;
        }
      }

      // Convertir l'ID négatif en ID positif pour les banques/assets/dettes
      int actualSourceId = _selectedSourceId!;
      if (_selectedSourceId! < 0) {
        actualSourceId = -_selectedSourceId!; // Convertir en positif pour les banques
      }

      // Déterminer les catégories selon la sélection
      final selectedCategory = CategoryMappingService.getCategoryFromSelection(
        _type, 
        _selectedCategoryKey, 
        context
      );

      final transaction = TransactionModel(
        type: _type,
        incomeCategory: _type == TransactionType.income 
            ? selectedCategory as IncomeCategory 
            : IncomeCategory.other,
        expenseCategory: _type == TransactionType.expense 
            ? selectedCategory as ExpenseCategory 
            : ExpenseCategory.other,
        amount: double.parse(_amountController.text),
        currency: _selectedCurrency,
        // Pour les entrées, la destination est targetSourceId
        sourceId: _type == TransactionType.income ? 0 : actualSourceId,
        sourceType: _type == TransactionType.income
            ? SourceType.external
            : (_selectedSourceType ?? SourceType.source),
        sourceName: _type == TransactionType.income ? 'Externe' : null,
        targetSourceId: _type == TransactionType.income ? actualSourceId : null,
        targetSourceType: _type == TransactionType.income
            ? (_selectedSourceType ?? SourceType.source)
            : null,
        targetSourceName: _type == TransactionType.income ? null : null,
        date: _selectedDate,
        createdAt: DateTime.now(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      try {
        final controller = ref.read(transactionControllerProvider.notifier);
        await controller.addTransaction(transaction);

        if (mounted) {
          Navigator.pop(context);
          _showSuccess(l10n.transactionAddedSuccess);

          // Pub discrète après 2ème transaction
          _showAdIfNeeded();
        }
      } catch (e) {
        _showError('${l10n.error}: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showAdIfNeeded() async {
    // Compteur simple pour afficher pub tous les 2 transactions
    final prefs = await SharedPreferences.getInstance();
    final transactionCount = (prefs.getInt('transaction_count') ?? 0) + 1;
    await prefs.setInt('transaction_count', transactionCount);

    if (transactionCount % 2 == 0) {
      await AdsService.showInterstitial();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final maxHeight = screenHeight - safeAreaTop - 80; // Laisser 80px en haut

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.grey[50],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(isDark),
          Flexible(
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(AppSizes.spacing12),
                children: [
                  _buildTypeSelector(isDark, l10n),
                  const SizedBox(height: AppSizes.spacing12),
                  _buildAmountField(isDark, l10n),
                  const SizedBox(height: AppSizes.spacing12),
                  _buildCurrencySelector(isDark, l10n),
                  const SizedBox(height: AppSizes.spacing12),
                  _buildCategorySelector(isDark, l10n),
                  const SizedBox(height: AppSizes.spacing12),
                  _buildSourceSelector(isDark, l10n),
                  const SizedBox(height: AppSizes.spacing12),
                  _buildDatePicker(isDark, l10n),
                  const SizedBox(height: AppSizes.spacing12),
                  _buildDescriptionField(isDark, l10n),
                  const SizedBox(height: AppSizes.spacing12),
                  _buildSaveButton(l10n),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(AppIcons.add, color: AppColors.primary, size: 18.sp),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.newTransaction,
                  style: TextStyle(
                    fontSize: AppSizes.textMedium,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
                Text(
                  l10n.addIncomeOrExpense,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              AppIcons.close,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.2, duration: 300.ms);
  }

  Widget _buildTypeSelector(bool isDark, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _TypeButton(
            label: l10n.income,
            icon: AppIcons.income,
            color: AppColors.success,
            isSelected: _type == TransactionType.income,
            onTap: () => setState(() {
              _type = TransactionType.income;
              _selectedCategoryKey = null; // Reset category selection
            }),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSizes.spacing8),
        Expanded(
          child: _TypeButton(
            label: l10n.expense,
            icon: AppIcons.expense,
            color: AppColors.error,
            isSelected: _type == TransactionType.expense,
            onTap: () => setState(() {
              _type = TransactionType.expense;
              _selectedCategoryKey = null; // Reset category selection
            }),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField(bool isDark, AppLocalizations l10n) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: isDark ? AppColors.textDark : Colors.black87,
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: l10n.amount,
        hintText: '0',
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(
          AppIcons.money,
          color: _type == TransactionType.income
              ? AppColors.success
              : AppColors.error,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.amountRequired;
        }
        if (double.tryParse(value) == null || double.parse(value) <= 0) {
          return l10n.invalidAmount;
        }
        return null;
      },
    );
  }

  Widget _buildCurrencySelector(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Devise',
          style: TextStyle(
            fontSize: AppSizes.textSmall,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDark : Colors.black87,
          ),
        ),
        const SizedBox(height: AppSizes.spacing12),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: AppCurrencies.all.map((currency) {
            final isSelected = _selectedCurrency == currency.code;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedCurrency = currency.code;
                // Reset source selection quand la devise change
                _selectedSourceId = null;
                _selectedSourceType = null;
              }),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.borderDark
                              : Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currency.flag, style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 6.w),
                    Text(
                      currency.code,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textDark : Colors.black87),
                        fontWeight: FontWeight.w600,
                        fontSize: AppSizes.textSmall,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(bool isDark, AppLocalizations l10n) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return categoriesAsync.when(
      data: (allCategories) {
        // Filtrer les catégories selon le type de transaction
        final filteredCategories = allCategories.where((cat) {
          if (_type == TransactionType.income) {
            return cat.type == CategoryType.income ||
                cat.type == CategoryType.both;
          } else {
            return cat.type == CategoryType.expense ||
                cat.type == CategoryType.both;
          }
        }).toList();

        // Si aucune catégorie en DB, utiliser les catégories par défaut
        if (filteredCategories.isEmpty) {
          final defaultCategories = _getDefaultCategories();
          return _buildCategoryList(defaultCategories, isDark, l10n, true);
        }

        return _buildCategoryList(filteredCategories, isDark, l10n, false);
      },
      loading: () => SizedBox(
        height: 60.h,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Text('Erreur: $e'),
    );
  }

  Widget _buildSourceSelector(bool isDark, AppLocalizations l10n) {
    final sourcesAsync = ref.watch(originalUnifiedSourcesProvider);

    return sourcesAsync.when(
      data: (sources) {
        // Filtrer les sources selon la devise sélectionnée et le type de transaction
        final availableSources = sources.where((s) {
          // Vérifications de base
          if (!s.isActive || s.isDeleted || s.currency != _selectedCurrency) {
            return false;
          }

          // Pour les entrées (income): toutes les sources actives
          if (_type == TransactionType.income) {
            return true;
          }

          // Pour les sorties (expense): sources avec solde > 0
          return s.amount > 0;
        }).toList();

        if (availableSources.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSizes.spacing12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  AppIcons.warning,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: Text(
                    _type == TransactionType.income
                        ? 'Aucune source disponible pour $_selectedCurrency'
                        : 'Aucune source avec solde disponible pour $_selectedCurrency',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: AppSizes.textSmall,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.source,
              style: TextStyle(
                fontSize: AppSizes.textSmall,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
            const SizedBox(height: AppSizes.spacing12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: availableSources.map((source) {
                  final isSelected = _selectedSourceId == source.id;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedSourceId = isSelected ? null : source.id;
                      _selectedSourceType = isSelected
                          ? null
                          : _detectSourceType(source);
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.spacing12),
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12.r),
                        border: isSelected
                            ? Border.all(color: AppColors.primary)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getSourceIcon(source),
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppSizes.spacing12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  source.name,
                                  style: TextStyle(
                                    fontSize: AppSizes.textMedium,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textDark
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${source.amount.toStringAsFixed(0)} ${source.currency}',
                                  style: TextStyle(
                                    fontSize: AppSizes.textSmall,
                                    color: source.amount > 0
                                        ? AppColors.success
                                        : AppColors.textSecondaryDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              AppIcons.success,
                              color: AppColors.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text(l10n.loadingError),
    );
  }

  // Helper pour détecter le type de source
  SourceType _detectSourceType(source) {
    if (source.id < 0) {
      if (source.id <= -3000000) {
        return SourceType.debt; // Dette reçue
      } else if (source.id <= -2000000) {
        return SourceType.debt; // Dette donnée
      } else if (source.id <= -1000000) {
        return SourceType.asset; // Asset
      } else {
        return SourceType.bank; // Banque
      }
    }
    return SourceType.source; // Source normale
  }

  // Helper pour obtenir l'icône de la source
  IconData _getSourceIcon(source) {
    if (source.iconName == 'bank') return AppIcons.bank;
    if (source.iconName == 'assets') return AppIcons.assets;
    if (source.iconName == 'debt_given') return AppIcons.debt;
    if (source.iconName == 'debt_received') return AppIcons.debt;
    return AppIcons.wallet;
  }

  // Helper pour obtenir la couleur de la source
  Color _getSourceColor(source) {
    if (source.iconName == 'bank') return Colors.blue;
    if (source.iconName == 'assets') return Colors.orange;
    if (source.iconName == 'debt_given') return Colors.green;
    if (source.iconName == 'debt_received') return Colors.red;
    return AppColors.primary;
  }

  Widget _buildDatePicker(bool isDark, AppLocalizations l10n) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? ColorScheme.dark(
                        primary: AppColors.primary,
                        surface: AppColors.surfaceDark,
                        onSurface: AppColors.textDark,
                      )
                    : ColorScheme.light(
                        primary: AppColors.primary,
                        surface: Colors.white,
                        onSurface: Colors.black87,
                      ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.date,
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(AppIcons.calendar, color: AppColors.primary),
        ),
        child: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildDescriptionField(bool isDark, AppLocalizations l10n) {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 2,
      style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
      decoration: InputDecoration(
        labelText: l10n.description,
        hintText: l10n.addNote,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(AppIcons.note, color: AppColors.primary),
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 48.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _type == TransactionType.income
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
              : [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color:
                (_type == TransactionType.income
                        ? AppColors.success
                        : AppColors.error)
                    .withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Text(
          l10n.save,
          style: const TextStyle(
            fontSize: AppSizes.textMedium,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getIncomeCategoryLabel(IncomeCategory cat, AppLocalizations l10n) {
    switch (cat) {
      case IncomeCategory.salary:
        return l10n.salary;
      case IncomeCategory.sale:
        return l10n.sale;
      case IncomeCategory.gift:
        return l10n.gift;
      case IncomeCategory.debtReceived:
        return l10n.debtReceived;
      case IncomeCategory.investment:
        return l10n.investment;
      case IncomeCategory.other:
        return l10n.other;
    }
  }

  IconData _getCategoryIcon(String iconName) {
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
      default:
        return AppIcons.money;
    }
  }

  List<CategoryModel> _getDefaultCategories() {
    if (_type == TransactionType.income) {
      return [
        ...DynamicCategoriesService.getIncomeCategories(context),
        ...DynamicCategoriesService.getOtherCategories(context),
      ];
    } else {
      return [
        ...DynamicCategoriesService.getExpenseCategories(context),
        ...DynamicCategoriesService.getOtherCategories(context),
      ];
    }
  }

  Widget _buildCategoryList(
    List<CategoryModel> categories,
    bool isDark,
    AppLocalizations l10n,
    bool isDefault,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.category,
          style: TextStyle(
            fontSize: AppSizes.textSmall,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDark : Colors.black87,
          ),
        ),
        const SizedBox(height: AppSizes.spacing12),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: categories.map((category) {
            final categoryKey = isDefault
                ? category.name
                : category.id.toString();
            final isSelected = _selectedCategoryKey == categoryKey;
            final color = Color(int.parse('0xFF${category.color}'));

            return GestureDetector(
              onTap: () => setState(() {
                _selectedCategoryKey = isSelected ? null : categoryKey;
              }),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? color : AppColors.borderDark,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(category.icon),
                      color: isSelected ? color : AppColors.textSecondaryDark,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      category.name,
                      style: TextStyle(
                        color: isSelected
                            ? color
                            : (isDark ? AppColors.textDark : Colors.black87),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: AppSizes.textSmall,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IncomeCategory _mapToIncomeCategory(String categoryKey) {
    switch (categoryKey.toLowerCase()) {
      // Salaire / Salary
      case 'salaire':
      case 'salary':
      case 'umushahara':
      case 'mshahara':
        return IncomeCategory.salary;
      // Vente / Sale
      case 'vente':
      case 'sale':
      case 'kugurisha':
      case 'mauzo':
        return IncomeCategory.sale;
      // Cadeau / Gift
      case 'cadeau':
      case 'gift':
      case 'impano':
      case 'zawadi':
        return IncomeCategory.gift;
      // Investissement / Investment
      case 'investissement':
      case 'investment':
      case 'ishoramari':
      case 'uwekezaji':
        return IncomeCategory.investment;
      // Dette reçue
      case 'dette reçue':
      case 'debt received':
      case 'ideni ryakiriwe':
      case 'deni lililopokelewa':
        return IncomeCategory.debtReceived;
      // Autre / Other
      case 'autre':
      case 'other':
      case 'ikindi':
      case 'nyingine':
        return IncomeCategory.other;
      default:
        return IncomeCategory.other;
    }
  }

  ExpenseCategory _mapToExpenseCategory(String categoryKey) {
    switch (categoryKey.toLowerCase()) {
      // Alimentation / Food
      case 'alimentation':
      case 'food':
      case 'ibiryo':
      case 'chakula':
        return ExpenseCategory.food;
      // Transport
      case 'transport':
      case 'ubwikorezi':
      case 'usafiri':
        return ExpenseCategory.transport;
      // Santé / Health
      case 'santé':
      case 'health':
      case 'ubuzima':
      case 'afya':
        return ExpenseCategory.health;
      // Éducation / Education
      case 'éducation':
      case 'education':
      case 'uburezi':
      case 'elimu':
        return ExpenseCategory.education;
      // Divertissement / Entertainment
      case 'divertissement':
      case 'entertainment':
      case 'imyidagaduro':
      case 'burudani':
        return ExpenseCategory.entertainment;
      // Shopping / Achat
      case 'shopping':
      case 'achat':
      case 'purchase':
      case 'kugura':
      case 'ununuzi':
        return ExpenseCategory.purchase;
      // Services / Utilities
      case 'services':
      case 'utilities':
      case 'serivisi':
      case 'huduma':
        return ExpenseCategory.utilities;
      // Retrait / Withdrawal
      case 'retrait':
      case 'withdrawal':
      case 'gukura':
      case 'kutoa':
        return ExpenseCategory.withdrawal;
      // Autre / Other
      case 'autre':
      case 'other':
      case 'ikindi':
      case 'nyingine':
        return ExpenseCategory.other;
      default:
        return ExpenseCategory.other;
    }
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacing8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.borderDark : Colors.grey.shade300),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : (isDark
                          ? AppColors.cardBackgroundDark
                          : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? color
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : Colors.grey.shade600),
                size: 14.sp,
              ),
            ),
            const SizedBox(height: AppSizes.spacing4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? color
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : Colors.grey.shade600),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: AppSizes.textSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
