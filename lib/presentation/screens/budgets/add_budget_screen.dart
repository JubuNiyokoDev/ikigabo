import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isar/isar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/currencies.dart';
import '../../../data/models/budget_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/budget_provider.dart';
import '../../providers/theme_provider.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  final BudgetModel? budget;

  const AddBudgetScreen({super.key, this.budget});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();

  BudgetType _selectedType = BudgetType.expense;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  String _selectedCurrency = 'BIF';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _notificationsEnabled = true;
  double _warningThreshold = 80.0;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      final budget = widget.budget!;
      _nameController.text = budget.name;
      _descriptionController.text = budget.description ?? '';
      _targetAmountController.text = budget.targetAmount.toString();
      _selectedType = budget.type;
      _selectedPeriod = budget.period;
      _selectedCurrency = budget.currency;
      _startDate = budget.startDate;
      _endDate = budget.endDate;
      _notificationsEnabled = budget.notificationsEnabled;
      _warningThreshold = budget.warningThreshold ?? 80.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final isEditing = widget.budget != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier Budget' : 'Nouveau Budget'),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: isDark ? AppColors.textDark : Colors.black87,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfo(isDark, l10n),
            const SizedBox(height: 24),
            _buildTypeSelector(isDark),
            const SizedBox(height: 24),
            _buildAmountAndCurrency(isDark, l10n),
            const SizedBox(height: 24),
            _buildPeriodSelector(isDark),
            const SizedBox(height: 24),
            _buildDateRange(isDark, l10n),
            const SizedBox(height: 24),
            _buildNotificationSettings(isDark, l10n),
            const SizedBox(height: 32),
            _buildSaveButton(l10n, isEditing),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo(bool isDark, AppLocalizations l10n) {
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
            'Informations de base',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom du budget',
              hintText: 'Ex: Budget Nourriture, Objectif Épargne...',
              prefixIcon: Icon(AppIcons.edit),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le nom est obligatoire';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optionnel)',
              hintText: 'Décrivez votre objectif...',
              prefixIcon: Icon(AppIcons.note),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
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
            'Type de budget',
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
                  BudgetType.expense,
                  'Dépenses',
                  'Limiter les dépenses',
                  AppColors.error,
                  AppIcons.expense,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeOption(
                  BudgetType.income,
                  'Revenus',
                  'Objectif de revenus',
                  AppColors.success,
                  AppIcons.income,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeOption(
                  BudgetType.saving,
                  'Épargne',
                  'Objectif d\'épargne',
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
    BudgetType type,
    String title,
    String subtitle,
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
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? color : AppColors.textSecondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountAndCurrency(bool isDark, AppLocalizations l10n) {
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
            'Montant et devise',
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
                flex: 2,
                child: TextFormField(
                  controller: _targetAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Montant objectif',
                    hintText: '0.00',
                    prefixIcon: Icon(AppIcons.money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le montant est obligatoire';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Montant invalide';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Devise',
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                  isExpanded: true,
                  items: AppCurrencies.all.map((currency) {
                    return DropdownMenuItem(
                      value: currency.code,
                      child: Text(
                        currency.code,
                        style: TextStyle(fontSize: 11.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCurrency = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
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
            'Période',
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
            children: BudgetPeriod.values.map((period) {
              final isSelected = _selectedPeriod == period;
              final label = _getPeriodLabel(period);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPeriod = period;
                    _updateEndDateBasedOnPeriod();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.borderDark,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRange(bool isDark, AppLocalizations l10n) {
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
            'Période personnalisée',
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
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderDark),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date de début',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textDark : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderDark),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date de fin',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textDark : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(bool isDark, AppLocalizations l10n) {
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
            'Notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Activer les notifications'),
            subtitle: const Text('Recevoir des alertes sur ce budget'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            activeThumbColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          if (_notificationsEnabled) ...[
            const SizedBox(height: 16),
            Text(
              'Seuil d\'alerte: ${_warningThreshold.toInt()}%',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
            Slider(
              value: _warningThreshold,
              min: 50,
              max: 95,
              divisions: 9,
              label: '${_warningThreshold.toInt()}%',
              onChanged: (value) => setState(() => _warningThreshold = value),
              activeColor: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n, bool isEditing) {
    return ElevatedButton(
      onPressed: _saveBudget,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        isEditing ? 'Modifier' : 'Créer Budget',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _updateEndDateBasedOnPeriod() {
    switch (_selectedPeriod) {
      case BudgetPeriod.weekly:
        _endDate = _startDate.add(const Duration(days: 7));
        break;
      case BudgetPeriod.monthly:
        _endDate = DateTime(
          _startDate.year,
          _startDate.month + 1,
          _startDate.day,
        );
        break;
      case BudgetPeriod.quarterly:
        _endDate = DateTime(
          _startDate.year,
          _startDate.month + 3,
          _startDate.day,
        );
        break;
      case BudgetPeriod.yearly:
        _endDate = DateTime(
          _startDate.year + 1,
          _startDate.month,
          _startDate.day,
        );
        break;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _updateEndDateBasedOnPeriod();
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  void _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final budget = BudgetModel(
      id: widget.budget?.id ?? Isar.autoIncrement,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      type: _selectedType,
      period: _selectedPeriod,
      targetAmount: double.parse(_targetAmountController.text),
      currentAmount: widget.budget?.currentAmount ?? 0.0,
      currency: _selectedCurrency,
      startDate: _startDate,
      endDate: _endDate,
      status: widget.budget?.status ?? BudgetStatus.active,
      createdAt: widget.budget?.createdAt ?? DateTime.now(),
      notificationsEnabled: _notificationsEnabled,
      warningThreshold: _warningThreshold,
    );

    try {
      if (widget.budget != null) {
        await ref.read(budgetControllerProvider.notifier).updateBudget(budget);
      } else {
        await ref.read(budgetControllerProvider.notifier).createBudget(budget);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.budget != null ? 'Budget modifié' : 'Budget créé',
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

  String _getPeriodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'Hebdomadaire';
      case BudgetPeriod.monthly:
        return 'Mensuel';
      case BudgetPeriod.quarterly:
        return 'Trimestriel';
      case BudgetPeriod.yearly:
        return 'Annuel';
    }
  }
}
