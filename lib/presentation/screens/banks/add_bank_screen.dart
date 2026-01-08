import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isar/isar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/currencies.dart';
import '../../../data/models/bank_model.dart';
import '../../../data/models/source_model.dart';
import '../../../data/models/transaction_model.dart' as tx;
import '../../../l10n/app_localizations.dart';
import '../../providers/bank_provider.dart';
import '../../providers/source_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/dashboard_provider.dart' as dashboard;
import '../../../core/services/ad_manager.dart';

class AddBankScreen extends ConsumerStatefulWidget {
  final BankModel? bank;

  const AddBankScreen({super.key, this.bank});

  @override
  ConsumerState<AddBankScreen> createState() => _AddBankScreenState();
}

class _AddBankScreenState extends ConsumerState<AddBankScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _interestValueController = TextEditingController();
  final _descriptionController = TextEditingController();

  BankType _bankType = BankType.free;
  InterestType _interestType = InterestType.monthly;
  InterestCalculation _interestCalculation = InterestCalculation.fixedAmount;
  String? _currency;
  bool _isActive = true;
  SourceModel? _selectedSource;
  bool _showSourceSelector = false;
  bool _skipSourceSelection = false;

  @override
  void initState() {
    super.initState();
    if (widget.bank != null) {
      _nameController.text = widget.bank!.name;
      _balanceController.text = widget.bank!.balance.toString();
      _accountNumberController.text = widget.bank!.accountNumber ?? '';
      _interestValueController.text =
          widget.bank!.interestValue?.toString() ?? '';
      _descriptionController.text = widget.bank!.description ?? '';
      _bankType = widget.bank!.bankType;
      _interestType = widget.bank!.interestType;
      _interestCalculation = widget.bank!.interestCalculation;
      _currency = widget.bank!.currency;
      _isActive = widget.bank!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _accountNumberController.dispose();
    _interestValueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onBalanceChanged(String value) {
    final amount = double.tryParse(value) ?? 0;
    setState(() {
      _showSourceSelector =
          amount > 0 && widget.bank == null && !_skipSourceSelection;
      if (!_showSourceSelector) {
        _selectedSource = null;
      }
    });
  }

  Future<void> _saveBank() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      // Pub récompensée pour création banque (fonctionnalité importante)
      if (widget.bank == null) {
        final rewardGranted = await AdManager.showRewardedForBankCreation();
        if (!rewardGranted) {
          _showError('Regardez la pub pour créer votre banque');
          return;
        }
      }
      
      final amount = double.parse(_balanceController.text);

      // Vérifier la source si montant initial > 0
      if (amount > 0 && widget.bank == null && !_skipSourceSelection) {
        if (_selectedSource == null) {
          _showError(l10n.pleaseSelectSource);
          return;
        }

        // Vérifier si la source a assez d'argent
        if (_selectedSource!.amount < amount) {
          _showError('${l10n.insufficientBalance} ${_selectedSource!.name}');
          return;
        }

        // Vérifier la compatibilité des devises
        final bankCurrency = _currency ?? 'BIF';
        if (_selectedSource!.currency != bankCurrency) {
          _showError(
            '${l10n.currencyMismatch}: ${_selectedSource!.currency} ≠ $bankCurrency',
          );
          return;
        }
      }

      final displayCurrencyAsync = ref.read(displayCurrencyProvider);
      final currency = displayCurrencyAsync.when(
        data: (curr) => curr,
        loading: () => AppCurrencies.bif,
        error: (_, __) => AppCurrencies.bif,
      );

      final bank = BankModel(
        id: widget.bank?.id ?? Isar.autoIncrement,
        name: _nameController.text.trim(),
        balance: amount,
        currency: _currency ?? currency.code,
        bankType: _bankType,
        interestType: _interestType,
        interestCalculation: _interestCalculation,
        interestValue: _interestValueController.text.trim().isEmpty
            ? null
            : double.parse(_interestValueController.text),
        accountNumber: _accountNumberController.text.trim().isEmpty
            ? null
            : _accountNumberController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isActive: _isActive,
        createdAt: widget.bank?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        nextDeductionDate:
            _bankType == BankType.paid &&
                _interestValueController.text.trim().isNotEmpty
            ? BankModel(
                name: '',
                createdAt: DateTime.now(),
              ).calculateNextDeductionDate()
            : null,
      );

      try {
        final controller = ref.read(bankControllerProvider.notifier);

        if (widget.bank == null) {
          // Nouvelle banque
          if (amount > 0 && _skipSourceSelection) {
            // Banque avec solde existant (sans transfert)
            final repository = ref.read(bankRepositoryProvider);
            await repository.addBankWithExistingBalance(bank);

            // Invalider tous les providers nécessaires
            ref.invalidate(banksStreamProvider);
            ref.invalidate(unifiedSourcesProvider);
            ref.invalidate(transactionsStreamProvider);
            ref.invalidate(dashboard.totalWealthProvider);
            ref.invalidate(dashboard.thisMonthIncomeProvider);
            ref.invalidate(dashboard.thisMonthExpenseProvider);
          } else if (amount > 0 &&
              _selectedSource != null &&
              !_skipSourceSelection) {
            // Banque avec transfert depuis une source
            final repository = ref.read(bankRepositoryProvider);

            // Déterminer le type de source et l'ID réel
            final isBank =
                _selectedSource!.id < 0 && _selectedSource!.iconName == 'bank';
            final realSourceId = isBank
                ? -_selectedSource!.id
                : _selectedSource!.id;
            final sourceType = isBank
                ? tx.SourceType.bank
                : tx.SourceType.source;

            await repository.addBankWithTransfer(
              bank: bank,
              sourceId: realSourceId,
              sourceType: sourceType,
              sourceName: _selectedSource!.name,
            );

            // Invalider tous les providers nécessaires
            ref.invalidate(banksStreamProvider);
            ref.invalidate(sourcesStreamProvider);
            ref.invalidate(unifiedSourcesProvider);
            ref.invalidate(totalBalanceProvider);
            ref.invalidate(transactionsStreamProvider);
            ref.invalidate(dashboard.totalWealthProvider);
            ref.invalidate(dashboard.thisMonthIncomeProvider);
            ref.invalidate(dashboard.thisMonthExpenseProvider);
          } else {
            // Banque sans solde initial
            await controller.addBank(bank);
          }
        } else {
          await controller.updateBank(bank);
        }

        if (mounted) {
          Navigator.pop(context);
          final l10n = AppLocalizations.of(context)!;
          _showSuccess(
            widget.bank == null
                ? l10n.bankAddedSuccess
                : l10n.bankUpdatedSuccess,
          );
          
          // Pub après action banque
          AdManager.showBankAd();
        }
      } catch (e) {
        final l10n = AppLocalizations.of(context)!;
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
          widget.bank == null ? l10n.newBank : l10n.editBank,
          style: TextStyle(
            color: isDark ? AppColors.textDark : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: AppSizes.textLarge,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.spacing12),
            children: [
              _buildNameField(isDark, l10n).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildAccountNumberField(
                isDark,
                l10n,
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildBalanceField(isDark, l10n).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: AppSizes.spacing12),
              if (_showSourceSelector)
                _buildSourceSelector(
                  isDark,
                  l10n,
                ).animate().fadeIn(delay: 220.ms),
              if (_showSourceSelector) const SizedBox(height: AppSizes.spacing12),
              if (double.tryParse(_balanceController.text) != null &&
                  double.parse(_balanceController.text) > 0 &&
                  widget.bank == null)
                _buildSkipSourceOption(
                  isDark,
                  l10n,
                ).animate().fadeIn(delay: 240.ms),
              if (double.tryParse(_balanceController.text) != null &&
                  double.parse(_balanceController.text) > 0 &&
                  widget.bank == null)
                const SizedBox(height: AppSizes.spacing12),
              _buildCurrencySelector(
                isDark,
                l10n,
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildBankTypeSelector(
                isDark,
                l10n,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildConditionalInterestFields(isDark, l10n),
              _buildDescriptionField(
                isDark,
                l10n,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildActiveSwitch(isDark, l10n).animate().fadeIn(delay: 450.ms),
              const SizedBox(height: AppSizes.spacing16),
              _buildSaveButton(l10n).animate().fadeIn(delay: 500.ms),
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
        labelText: l10n.bankName,
        hintText: l10n.bankNameHint,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(AppIcons.bank, color: AppColors.primary),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.bankNameRequired;
        }
        return null;
      },
    );
  }

  Widget _buildAccountNumberField(bool isDark, AppLocalizations l10n) {
    return TextFormField(
      controller: _accountNumberController,
      style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
      decoration: InputDecoration(
        labelText: l10n.accountNumber,
        hintText: l10n.accountNumberHint,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(AppIcons.edit, color: AppColors.primary),
      ),
    );
  }

  Widget _buildBalanceField(bool isDark, AppLocalizations l10n) {
    return TextFormField(
      controller: _balanceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: isDark ? AppColors.textDark : Colors.black87,
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: _onBalanceChanged,
      decoration: InputDecoration(
        labelText: l10n.currentBalance,
        hintText: '0.00',
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(AppIcons.money, color: AppColors.primary),
        suffixText: _currency ?? 'BIF',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.balanceRequired;
        }
        if (double.tryParse(value) == null) {
          return l10n.invalidBalance;
        }
        return null;
      },
    );
  }

  Widget _buildCurrencySelector(bool isDark, AppLocalizations l10n) {
    ref.watch(displayCurrencyProvider);
    final currentCurrency = _currency ?? 'BIF';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.currency,
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
            final isSelected = currentCurrency == currency.code;
            return GestureDetector(
              onTap: () => setState(() {
                _currency = currency.code;
                _selectedSource = null; // Reset source selection
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
                      textAlign: TextAlign.center,
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

  Widget _buildBankTypeSelector(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bankType,
          style: TextStyle(
            fontSize: AppSizes.textSmall,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDark : Colors.black87,
          ),
        ),
        const SizedBox(height: AppSizes.spacing12),
        Row(
          children: [
            Flexible(
              child: _TypeButton(
                label: l10n.free,
                icon: AppIcons.success,
                color: AppColors.success,
                isSelected: _bankType == BankType.free,
                onTap: () => setState(() => _bankType = BankType.free),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSizes.spacing12),
            Flexible(
              child: _TypeButton(
                label: l10n.paid,
                icon: AppIcons.warning,
                color: AppColors.warning,
                isSelected: _bankType == BankType.paid,
                onTap: () => setState(() => _bankType = BankType.paid),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionalInterestFields(bool isDark, AppLocalizations l10n) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _bankType == BankType.paid
          ? Column(
              key: const ValueKey('interest_fields'),
              children: [
                _buildInterestFields(isDark, l10n),
                const SizedBox(height: AppSizes.spacing12),
              ],
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }

  Widget _buildInterestFields(bool isDark, AppLocalizations l10n) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.warning, color: AppColors.warning, size: 20.sp),
              const SizedBox(width: AppSizes.spacing12),
              Text(
                l10n.feeConfiguration,
                style: TextStyle(
                  fontSize: AppSizes.textMedium,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing12),
          TextFormField(
            controller: _interestValueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              labelText: l10n.feeAmount,
              hintText: '0.00',
              filled: true,
              fillColor: isDark
                  ? AppColors.cardBackgroundDark
                  : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(AppIcons.money, color: AppColors.warning),
              suffixText:
                  _interestCalculation == InterestCalculation.fixedAmount
                  ? _currency
                  : '%',
            ),
            validator: (value) {
              if (_bankType == BankType.paid &&
                  (value == null || value.trim().isEmpty)) {
                return l10n.feesRequiredForPaidBank;
              }
              if (value != null &&
                  value.trim().isNotEmpty &&
                  double.tryParse(value) == null) {
                return l10n.invalidAmount;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.spacing12),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<InterestCalculation>(
                  initialValue: _interestCalculation,
                  decoration: InputDecoration(
                    labelText: l10n.type,
                    filled: true,
                    fillColor: isDark
                        ? AppColors.cardBackgroundDark
                        : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      AppIcons.filter,
                      color: AppColors.warning,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                  dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                  style: TextStyle(
                    color: isDark ? AppColors.textDark : Colors.black87,
                    fontSize: 12.sp,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: InterestCalculation.fixedAmount,
                      child: Text(
                        l10n.fixedAmount,
                        style: TextStyle(fontSize: 12.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: InterestCalculation.percentage,
                      child: Text(
                        l10n.percentage,
                        style: TextStyle(fontSize: 12.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _interestCalculation = value);
                    }
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<InterestType>(
                  initialValue: _interestType,
                  decoration: InputDecoration(
                    labelText: l10n.period,
                    filled: true,
                    fillColor: isDark
                        ? AppColors.cardBackgroundDark
                        : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      AppIcons.calendar,
                      color: AppColors.warning,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                  dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                  style: TextStyle(
                    color: isDark ? AppColors.textDark : Colors.black87,
                    fontSize: 12.sp,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: InterestType.monthly,
                      child: Text(
                        l10n.monthly,
                        style: TextStyle(fontSize: 12.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: InterestType.annual,
                      child: Text(
                        l10n.annual,
                        style: TextStyle(fontSize: 12.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _interestType = value);
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
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.activeAccount,
                style: TextStyle(
                  fontSize: AppSizes.textMedium,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                l10n.includeInCalculations,
                style: TextStyle(
                  fontSize: AppSizes.textSmall,
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
    return Container(
      width: double.infinity,
      height: 48.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveBank,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Text(
          widget.bank == null ? l10n.addBank : l10n.save,
          style: const TextStyle(
            fontSize: AppSizes.textMedium,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSourceSelector(bool isDark, AppLocalizations l10n) {
    final sourcesAsync = ref.watch(originalUnifiedSourcesProvider);

    return sourcesAsync.when(
      data: (sources) {
        final bankCurrency = _currency ?? 'BIF';
        final availableSources = sources
            .where(
              (s) =>
                  s.amount > 0 &&
                  s.isActive &&
                  !s.isDeleted &&
                  s.currency == bankCurrency,
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
                                  style: const TextStyle(
                                    fontSize: AppSizes.textSmall,
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
        padding: const EdgeInsets.all(AppSizes.spacing12),
        child: Text(
          l10n.loadingError,
          style: const TextStyle(color: AppColors.error),
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
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
                    (double.tryParse(_balanceController.text) ?? 0) > 0 &&
                    widget.bank == null;
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
                    fontSize: AppSizes.textMedium,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.moneyExistsInRealBank,
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
        ],
      ),
    );
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.borderDark : Colors.grey.shade300),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? color
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : Colors.grey.shade600),
              size: 16.sp,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? color
                    : (isDark ? AppColors.textDark : Colors.black87),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: AppSizes.textSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
