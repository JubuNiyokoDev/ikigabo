import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/currencies.dart';
import '../../../data/models/source_model.dart';
import '../../../data/models/transaction_model.dart' as tx;
import '../../../l10n/app_localizations.dart';
import '../../providers/source_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/loading_button.dart';
import '../../../core/services/ad_manager.dart';

class AddSourceScreen extends ConsumerStatefulWidget {
  final SourceModel? source;

  const AddSourceScreen({super.key, this.source});

  @override
  ConsumerState<AddSourceScreen> createState() => _AddSourceScreenState();
}

class _AddSourceScreenState extends ConsumerState<AddSourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  SourceType _selectedType = SourceType.pocket;
  String _currency = AppCurrencies.defaultCurrency.code;
  bool _isActive = true;
  SourceModel? _selectedSource;
  bool _showSourceSelector = false;
  bool _skipSourceSelection = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.source != null) {
      _nameController.text = widget.source!.name;
      _amountController.text = widget.source!.amount.toString();
      _descriptionController.text = widget.source!.description ?? '';
      _selectedType = widget.source!.type;
      _currency = widget.source!.currency;
      _isActive = widget.source!.isActive;
    } else {
      // Pour une nouvelle source, utiliser la devise par défaut de l'utilisateur
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final displayCurrencyAsync = ref.read(displayCurrencyProvider);
        final currentCurrency = displayCurrencyAsync.when(
          data: (curr) => curr,
          loading: () => AppCurrencies.bif,
          error: (_, __) => AppCurrencies.bif,
        );
        setState(() {
          _currency = currentCurrency.code;
        });
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    final amount = double.tryParse(value) ?? 0;
    setState(() {
      _showSourceSelector =
          amount > 0 && widget.source == null && !_skipSourceSelection;
      if (!_showSourceSelector) {
        _selectedSource = null;
      }
    });
  }

  Future<void> _saveSource() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final controller = ref.read(sourceControllerProvider.notifier);

        if (widget.source == null) {
          // Nouvelle source - vérifier d'où vient l'argent si montant > 0
          final amount = double.tryParse(_amountController.text) ?? 0.0;

          if (amount > 0 && !_skipSourceSelection) {
            if (_selectedSource == null) {
              final l10n = AppLocalizations.of(context)!;
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.pleaseSelectSource),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }

            // Vérifier si la source a assez d'argent
            if (_selectedSource!.amount < amount) {
              final l10n = AppLocalizations.of(context)!;
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${l10n.insufficientBalance} ${_selectedSource!.name}',
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }
          }

          final newSource = SourceModel(
            name: _nameController.text.trim(),
            type: _selectedType,
            amount: amount,
            currency: _currency,
            isActive: _isActive,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            createdAt: DateTime.now(),
          );

          if (amount > 0 && _selectedSource != null && !_skipSourceSelection) {
            // Créer avec transfert depuis une autre source
            final isBank =
                _selectedSource!.id < 0 && _selectedSource!.iconName == 'bank';
            final realSourceId = isBank
                ? -_selectedSource!.id
                : _selectedSource!.id;
            final sourceType = isBank
                ? tx.SourceType.bank
                : tx.SourceType.source;

            await controller.addSourceWithTransfer(
              source: newSource,
              fromSourceId: realSourceId,
              fromSourceType: sourceType,
              fromSourceName: _selectedSource!.name,
            );
          } else if (amount > 0) {
            // Créer avec entrée externe (salaire, cadeau, etc.)
            await controller.addSourceFromIncome(
              source: newSource,
              category: tx.IncomeCategory.other,
            );
          } else {
            // Créer source vide
            await controller.addSource(newSource);
          }
        } else {
          // Édition
          final updatedSource = SourceModel(
            name: _nameController.text.trim(),
            type: _selectedType,
            amount: double.tryParse(_amountController.text) ?? 0.0,
            currency: _currency,
            isActive: _isActive,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            createdAt: widget.source!.createdAt,
          );
          updatedSource.id = widget.source!.id;
          updatedSource.updatedAt = DateTime.now();
          await controller.updateSource(updatedSource);
        }

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pop(context);
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.source == null
                    ? l10n.sourceAddedSuccess
                    : l10n.sourceUpdatedSuccess,
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
          
          // Pub après action source
          AdManager.showSourceAd();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            AppIcons.back,
            color: isDark ? AppColors.textDark : Colors.black87,
          ),
        ),
        title: Text(
          widget.source == null ? l10n.newSource : l10n.editSource,
          style: TextStyle(
            color: isDark ? AppColors.textDark : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              _buildNameField(isDark, l10n).animate().fadeIn(delay: 100.ms),
              SizedBox(height: 12.h),
              _buildTypeSelector(isDark, l10n).animate().fadeIn(delay: 200.ms),
              SizedBox(height: 12.h),
              _buildAmountField(isDark, l10n).animate().fadeIn(delay: 300.ms),
              SizedBox(height: 12.h),
              if (_showSourceSelector)
                _buildSourceSelector(
                  isDark,
                  l10n,
                ).animate().fadeIn(delay: 350.ms),
              if (_showSourceSelector) SizedBox(height: 12.h),
              if (double.tryParse(_amountController.text) != null &&
                  double.parse(_amountController.text) > 0 &&
                  widget.source == null)
                _buildSkipSourceOption(
                  isDark,
                  l10n,
                ).animate().fadeIn(delay: 375.ms),
              if (double.tryParse(_amountController.text) != null &&
                  double.parse(_amountController.text) > 0 &&
                  widget.source == null)
                SizedBox(height: 12.h),
              _buildCurrencySelector(
                isDark,
                l10n,
              ).animate().fadeIn(delay: 400.ms),
              SizedBox(height: 12.h),
              _buildDescriptionField(
                isDark,
                l10n,
              ).animate().fadeIn(delay: 500.ms),
              SizedBox(height: 12.h),
              _buildActiveSwitch(isDark, l10n).animate().fadeIn(delay: 600.ms),
              SizedBox(height: 12.h),
              _buildSaveButton(l10n).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(bool isDark, AppLocalizations l10n) {
    return TextFormField(
      controller: _nameController,
      style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
      decoration: InputDecoration(
        labelText: l10n.sourceName,
        hintText: l10n.sourceNameHint,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(AppIcons.edit, color: AppColors.primary),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.sourceNameRequired;
        }
        return null;
      },
    );
  }

  Widget _buildTypeSelector(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sourceType,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDark : Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          children: SourceType.values.map((type) {
            final isSelected = _selectedType == type;
            return FilterChip(
              label: Text(_getTypeLabel(type, l10n)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedType = type);
              },
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              selectedColor: AppColors.primary.withValues(alpha: 0.3),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.textDark : Colors.black87),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 10.sp,
              ),
            );
          }).toList(),
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
      onChanged: _onAmountChanged,
      decoration: InputDecoration(
        labelText: l10n.amount,
        hintText: '0.00',
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(AppIcons.money, color: AppColors.primary),
        suffixText: _currency,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.amountRequired;
        }
        if (double.tryParse(value) == null) {
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
          l10n.currency,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDark : Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: AppCurrencies.all.map((currency) {
            final isSelected = _currency == currency.code;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: InkWell(
                  onTap: () => setState(() => _currency = currency.code),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
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
                    child: Text(
                      currency.code,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textDark : Colors.black87),
                        fontWeight: FontWeight.w600,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(bool isDark, AppLocalizations l10n) {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 2,
      style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
      decoration: InputDecoration(
        labelText: l10n.description,
        hintText: l10n.descriptionHint,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(AppIcons.note, color: AppColors.primary),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildActiveSwitch(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.activeSource,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                l10n.includeInCalculations,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                ),
              ),
            ],
          ),
          Switch(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    return LoadingButton(
      text: widget.source == null ? l10n.newSource : l10n.save,
      onPressed: _saveSource,
      isLoading: _isLoading,
    );
  }

  String _getTypeLabel(SourceType type, AppLocalizations l10n) {
    switch (type) {
      case SourceType.pocket:
        return l10n.pocket;
      case SourceType.safe:
        return l10n.safe;
      case SourceType.cash:
        return l10n.cash;
      case SourceType.custom:
        return l10n.custom;
    }
  }

  Widget _buildSourceSelector(bool isDark, AppLocalizations l10n) {
    final sourcesAsync = ref.watch(originalUnifiedSourcesProvider);

    return sourcesAsync.when(
      data: (sources) {
        final sourceCurrency = _currency;
        final availableSources = sources
            .where(
              (s) =>
                  s.amount > 0 &&
                  s.isActive &&
                  !s.isDeleted &&
                  s.currency == sourceCurrency,
            )
            .toList();

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
                const Icon(AppIcons.warning, color: AppColors.warning, size: 20),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: Text(
                    '${l10n.noMoneySourceAvailable} ${l10n.createSourceFirst}',
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
              l10n.selectMoneySource,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
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
                  final sourceKey =
                      '${source.id}_${source.iconName ?? 'source'}';
                  final selectedKey = _selectedSource != null
                      ? '${_selectedSource!.id}_${_selectedSource!.iconName ?? 'source'}'
                      : null;
                  final isSelected = selectedKey == sourceKey;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedSource = isSelected ? null : source;
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
                              _getSourceIcon(source.iconName ?? 'money'),
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 8.w),
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
                                    fontSize: 10.sp,
                                    color: AppColors.success,
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
      error: (e, s) => Container(
        padding: EdgeInsets.all(12.w),
        child: Text(
          l10n.loadingError,
          style: TextStyle(color: AppColors.error, fontSize: 10.sp),
        ),
      ),
    );
  }

  IconData _getSourceIcon(String iconName) {
    switch (iconName) {
      case 'bank':
        return AppIcons.bank;
      case 'assets':
        return AppIcons.assets;
      case 'debt_given':
        return AppIcons.debtGiven;
      case 'debt_received':
        return AppIcons.debtReceived;
      default:
        return AppIcons.money;
    }
  }

  Widget _buildSkipSourceOption(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _skipSourceSelection
              ? AppColors.primary
              : (isDark ? AppColors.borderDark : Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _skipSourceSelection,
            onChanged: (value) {
              setState(() {
                _skipSourceSelection = value ?? false;
                _showSourceSelector =
                    !_skipSourceSelection &&
                    (double.tryParse(_amountController.text) ?? 0) > 0 &&
                    widget.source == null;
                if (_skipSourceSelection) {
                  _selectedSource = null;
                }
              });
            },
            activeColor: AppColors.primary,
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.moneyAlreadyInAccount,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  l10n.moneyExistsInRealBank,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
