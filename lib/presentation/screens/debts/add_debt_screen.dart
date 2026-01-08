import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ikigabo/data/models/debt_model.dart';
import 'package:ikigabo/data/models/source_model.dart';
import 'package:ikigabo/presentation/providers/currency_provider.dart';
import 'package:isar/isar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/currencies.dart';
import '../../../data/models/transaction_model.dart' as tx;
import '../../../l10n/app_localizations.dart';
import '../../providers/debt_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/source_provider.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  final DebtModel? debt;

  const AddDebtScreen({super.key, this.debt});

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _personNameController = TextEditingController();
  final _personContactController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _collateralController = TextEditingController();
  final _descriptionController = TextEditingController();

  DebtType _debtType = DebtType.given;
  String _currency = AppCurrencies.defaultCurrency.code;
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  bool _hasInterest = false;
  bool _hasReminder = false;
  DateTime? _reminderDateTime;

  // Sélecteur de source
  int? _selectedSourceId;
  String? _selectedSourceName;
  String _selectedSourceType = 'source';
  bool _isExternalMoney = false;

  @override
  void initState() {
    super.initState();
    if (widget.debt != null) {
      _personNameController.text = widget.debt!.personName;
      _personContactController.text = widget.debt!.personContact ?? '';
      _totalAmountController.text = widget.debt!.totalAmount.toString();
      _interestRateController.text = widget.debt!.interestRate?.toString() ?? '';
      _collateralController.text = widget.debt!.collateral ?? '';
      _descriptionController.text = widget.debt!.description ?? '';
      _debtType = widget.debt!.type;
      _currency = widget.debt!.currency;
      _date = widget.debt!.date;
      _dueDate = widget.debt!.dueDate;
      _hasInterest = widget.debt!.hasInterest;
      _hasReminder = widget.debt!.hasReminder;
      _reminderDateTime = widget.debt!.reminderDateTime;
    } else {
      // Pour une nouvelle dette, utiliser la devise par défaut de l'utilisateur
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
    _personNameController.dispose();
    _personContactController.dispose();
    _totalAmountController.dispose();
    _interestRateController.dispose();
    _collateralController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveDebt() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      final debt = DebtModel(
        id: widget.debt?.id ?? Isar.autoIncrement,
        type: _debtType,
        personName: _personNameController.text.trim(),
        personContact: _personContactController.text.trim().isEmpty
            ? null
            : _personContactController.text.trim(),
        totalAmount: double.parse(_totalAmountController.text),
        paidAmount: widget.debt?.paidAmount ?? 0.0,
        currency: _currency,
        date: _date,
        dueDate: _dueDate,
        status: widget.debt?.status ?? DebtStatus.pending,
        hasInterest: _hasInterest,
        interestRate: _hasInterest && _interestRateController.text.trim().isNotEmpty
            ? double.parse(_interestRateController.text)
            : null,
        collateral: _collateralController.text.trim().isEmpty
            ? null
            : _collateralController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        hasReminder: _hasReminder,
        reminderDateTime: _hasReminder ? _reminderDateTime : null,
        createdAt: widget.debt?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        final controller = ref.read(debtControllerProvider.notifier);
        if (widget.debt == null) {
          final amount = double.parse(_totalAmountController.text);
          
          // Vérifier qu'une source est sélectionnée ou que c'est de l'argent externe
          if (!_isExternalMoney && (_selectedSourceId == null || _selectedSourceName == null)) {
            _showError(l10n.pleaseSelectSource);
            return;
          }

          // Vérifier la compatibilité des devises si source sélectionnée
          if (!_isExternalMoney) {
            final sourcesAsync = ref.read(originalUnifiedSourcesProvider);
            final sources = await sourcesAsync.when(
              data: (data) => Future.value(data),
              loading: () => Future.value(<SourceModel>[]),
              error: (_, __) => Future.value(<SourceModel>[]),
            );
            
            final selectedSource = sources.firstWhere(
              (s) => (s.id > 0 ? s.id : -s.id) == _selectedSourceId,
              orElse: () => throw Exception(l10n.error),
            );
            
            // Vérifier la devise
            if (selectedSource.currency != _currency) {
              _showError('${l10n.currencyMismatch}: ${selectedSource.currency} ≠ $_currency');
              return;
            }
            
            // Vérifier le solde suffisant
            if (selectedSource.amount < amount) {
              _showError('${l10n.insufficientBalance} ${selectedSource.name}');
              return;
            }
          }

          // Pour une nouvelle dette, utiliser la méthode appropriée selon le type
          if (_debtType == DebtType.given) {
            if (_isExternalMoney) {
              // TODO: Implémenter addDebtGivenExternal si nécessaire
              _showError(l10n.restoreFeatureComingSoon);
              return;
            } else {
              await controller.addDebtGiven(
                debt: debt,
                sourceId: _selectedSourceId!,
                sourceName: _selectedSourceName!,
                sourceType: _selectedSourceType == 'bank' ? tx.SourceType.bank : tx.SourceType.source,
              );
            }
          } else {
            if (_isExternalMoney) {
              // TODO: Implémenter addDebtReceivedExternal si nécessaire
              _showError(l10n.restoreFeatureComingSoon);
              return;
            } else {
              await controller.addDebtReceived(
                debt: debt,
                targetId: _selectedSourceId!,
                targetName: _selectedSourceName!,
                targetType: _selectedSourceType == 'bank' ? tx.SourceType.bank : tx.SourceType.source,
              );
            }
          }
        } else {
          await controller.updateDebt(debt);
        }

        if (mounted) {
          Navigator.pop(context);
          _showSuccess(
            widget.debt == null
                ? l10n.debtAddedSuccess
                : l10n.debtUpdatedSuccess,
          );
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
          widget.debt == null ? l10n.newDebt : l10n.editDebt,
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
              _buildDebtTypeSelector(isDark, l10n).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildPersonNameField(isDark, l10n).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildPersonContactField(isDark, l10n).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildTotalAmountField(isDark).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: AppSizes.spacing12),
              if (widget.debt == null && double.tryParse(_totalAmountController.text) != null && double.parse(_totalAmountController.text) > 0)
                _buildSourceSelector(isDark, l10n).animate().fadeIn(delay: 275.ms),
              if (widget.debt == null && double.tryParse(_totalAmountController.text) != null && double.parse(_totalAmountController.text) > 0)
                const SizedBox(height: AppSizes.spacing12),
              _buildCurrencySelector(isDark).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildDatePicker(isDark).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildDueDatePicker(isDark).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildReminderSection(isDark, l10n).animate().fadeIn(delay: 425.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildInterestSection(isDark).animate().fadeIn(delay: 450.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildCollateralField(isDark).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildDescriptionField(isDark).animate().fadeIn(delay: 550.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildSaveButton().animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebtTypeSelector(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.debtType,
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
                label: l10n.lent,
                icon: AppIcons.debtGiven,
                color: AppColors.success,
                isSelected: _debtType == DebtType.given,
                onTap: () => setState(() => _debtType = DebtType.given),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSizes.spacing12),
            Flexible(
              child: _TypeButton(
                label: l10n.borrowed,
                icon: AppIcons.debtReceived,
                color: AppColors.error,
                isSelected: _debtType == DebtType.received,
                onTap: () => setState(() => _debtType = DebtType.received),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonNameField(bool isDark, AppLocalizations l10n) {
    return TextFormField(
      controller: _personNameController,
      style: TextStyle(
        color: isDark ? AppColors.textDark : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: _debtType == DebtType.given ? l10n.borrowerName : l10n.lenderName,
        hintText: l10n.personNameHint,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(AppIcons.user, color: AppColors.primary),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.nameRequired;
        }
        return null;
      },
    );
  }

  Widget _buildPersonContactField(bool isDark, AppLocalizations l10n) {
    return TextFormField(
      controller: _personContactController,
      style: TextStyle(
        color: isDark ? AppColors.textDark : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: l10n.contact,
        hintText: l10n.contactHint,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(AppIcons.phone, color: AppColors.primary),
      ),
    );
  }

  Widget _buildTotalAmountField(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _totalAmountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: isDark ? AppColors.textDark : Colors.black87,
        fontSize: AppSizes.textMedium,
        fontWeight: FontWeight.w600,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (value) => setState(() {}), // Force rebuild when amount changes
      decoration: InputDecoration(
        labelText: l10n.totalAmount,
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

  Widget _buildCurrencySelector(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
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
        Row(
          children: AppCurrencies.all.map((currency) {
            final isSelected = _currency == currency.code;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currency = currency.code),
                child: Container(
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.surfaceDark : Colors.white),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : Colors.grey.shade300),
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
                      fontSize: AppSizes.textSmall,
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

  Widget _buildDatePicker(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _date,
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
          setState(() => _date = date);
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
          '${_date.day}/${_date.month}/${_date.year}',
          style: TextStyle(
            color: isDark ? AppColors.textDark : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildDueDatePicker(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
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
          setState(() => _dueDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.dueDateOptional,
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(AppIcons.calendar, color: AppColors.warning),
          suffixIcon: _dueDate != null
              ? IconButton(
                  icon: const Icon(AppIcons.close, size: 22),
                  onPressed: () => setState(() => _dueDate = null),
                )
              : null,
        ),
        child: Text(
          _dueDate != null
              ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
              : l10n.none,
          style: TextStyle(
            color: _dueDate != null
                ? (isDark ? AppColors.textDark : Colors.black87)
                : (isDark ? AppColors.textSecondaryDark : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderSection(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rappel d\'alarme',
                    style: TextStyle(
                      fontSize: AppSizes.textMedium,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Recevoir une alarme à une heure précise',
                    style: TextStyle(
                      fontSize: AppSizes.textSmall,
                      color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _hasReminder,
                onChanged: (value) => setState(() => _hasReminder = value),
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
          if (_hasReminder) ...[
            const SizedBox(height: AppSizes.spacing12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _reminderDateTime ?? DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_reminderDateTime ?? DateTime.now()),
                  );
                  if (time != null) {
                    setState(() {
                      _reminderDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date et heure du rappel',
                  filled: true,
                  fillColor: isDark ? AppColors.cardBackgroundDark : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(AppIcons.notification, color: AppColors.warning),
                ),
                child: Text(
                  _reminderDateTime != null
                      ? '${_reminderDateTime!.day}/${_reminderDateTime!.month}/${_reminderDateTime!.year} à ${_reminderDateTime!.hour.toString().padLeft(2, '0')}:${_reminderDateTime!.minute.toString().padLeft(2, '0')}'
                      : 'Choisir date et heure',
                  style: TextStyle(
                    color: _reminderDateTime != null
                        ? (isDark ? AppColors.textDark : Colors.black87)
                        : (isDark ? AppColors.textSecondaryDark : Colors.black54),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInterestSection(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.withInterest,
                    style: TextStyle(
                      fontSize: AppSizes.textMedium,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    l10n.addInterestRate,
                    style: TextStyle(
                      fontSize: AppSizes.textSmall,
                      color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _hasInterest,
                onChanged: (value) => setState(() => _hasInterest = value),
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
          if (_hasInterest) ...[
            const SizedBox(height: AppSizes.spacing12),
            TextFormField(
              controller: _interestRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: l10n.interestRate,
                hintText: l10n.interestRateHint,
                filled: true,
                fillColor: isDark ? AppColors.cardBackgroundDark : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(AppIcons.money, color: AppColors.warning),
                suffixText: '%',
              ),
              validator: (value) {
                if (_hasInterest && (value == null || value.trim().isEmpty)) {
                  return l10n.interestRateRequired;
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollateralField(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _collateralController,
      style: TextStyle(
        color: isDark ? AppColors.textDark : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: l10n.collateral,
        hintText: l10n.collateralHint,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(AppIcons.asset, color: AppColors.primary),
      ),
    );
  }

  Widget _buildDescriptionField(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _descriptionController,
      maxLines: 2,
      style: TextStyle(
        color: isDark ? AppColors.textDark : Colors.black87,
      ),
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

  Widget _buildSourceSelector(bool isDark, AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, child) {
        final sourcesAsync = ref.watch(originalUnifiedSourcesProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _debtType == DebtType.given ? l10n.debtGivenSourceHint : l10n.debtReceivedSourceHint,
              style: TextStyle(
                fontSize: AppSizes.textSmall,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
            const SizedBox(height: AppSizes.spacing12),

            // Option argent externe
            GestureDetector(
              onTap: () => setState(() {
                _isExternalMoney = true;
                _selectedSourceId = null;
                _selectedSourceName = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isExternalMoney
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isExternalMoney
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.money,
                      color: _isExternalMoney ? AppColors.primary : AppColors.textSecondaryDark,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.externalMoney,
                      style: TextStyle(
                        color: _isExternalMoney
                            ? AppColors.primary
                            : (isDark ? AppColors.textDark : Colors.black87),
                        fontWeight: _isExternalMoney ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Liste des sources
            sourcesAsync.when(
              data: (sources) {
                final debtCurrency = _currency;
                final availableSources = sources
                    .where(
                      (s) =>
                          s.amount > 0 &&
                          s.isActive &&
                          !s.isDeleted &&
                          s.currency == debtCurrency,
                    )
                    .toList();

                if (availableSources.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(AppIcons.warning, color: AppColors.warning, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${l10n.noCurrencySourceAvailable} $_currency',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: availableSources.map((source) {
                  final realId = source.id > 0 ? source.id : -source.id;
                  final sourceKey = '${realId}_${source.iconName ?? 'source'}';
                  final selectedKey = _selectedSourceId != null && _selectedSourceName != null
                      ? '${_selectedSourceId}_$_selectedSourceType'
                      : null;
                  final isSelected = !_isExternalMoney && selectedKey == sourceKey;

                  return GestureDetector(
                    onTap: () => setState(() {
                      _isExternalMoney = false;
                      _selectedSourceId = realId;
                      _selectedSourceName = source.name;
                      _selectedSourceType = source.iconName ?? 'source';
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : (isDark ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.borderDark : Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            source.iconName == 'bank' ? AppIcons.bank : AppIcons.wallet,
                            color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  source.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark ? AppColors.textDark : Colors.black87),
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  '${source.amount.toStringAsFixed(0)} ${source.currency}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('${l10n.error}: $e'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSaveButton() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      height: 48.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _debtType == DebtType.given
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
              : [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: (_debtType == DebtType.given
                ? AppColors.success
                : AppColors.error).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveDebt,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Text(
          widget.debt == null ? l10n.addDebt : l10n.save,
          style: const TextStyle(
            fontSize: AppSizes.textMedium,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
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
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
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
                  : (isDark ? AppColors.textSecondaryDark : Colors.grey.shade600),
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
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
