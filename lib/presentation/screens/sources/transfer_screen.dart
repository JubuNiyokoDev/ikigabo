import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/currencies.dart';
import '../../../data/models/transaction_model.dart' as tx;
import '../../../data/models/source_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/source_provider.dart';
import '../../providers/transaction_service_provider.dart';
import '../../providers/theme_provider.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _fromSourceId;
  tx.SourceType? _fromSourceType;
  String? _fromSourceName;

  int? _toSourceId;
  tx.SourceType? _toSourceType;
  String? _toSourceName;

  String _selectedCurrency = 'BIF';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  tx.SourceType _detectSourceType(dynamic source) {
    if (source.id < 0) {
      if (source.id <= -3000000) {
        return tx.SourceType.debt;
      } else if (source.id <= -2000000) {
        return tx.SourceType.debt;
      } else if (source.id <= -1000000) {
        return tx.SourceType.asset;
      } else {
        return tx.SourceType.bank;
      }
    }
    return tx.SourceType.source;
  }

  Future<void> _saveTransfer() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      if (_fromSourceId == null || _toSourceId == null) {
        _showError('Veuillez sélectionner la source et la destination');
        return;
      }

      if (_fromSourceId == _toSourceId) {
        _showError('La source et la destination doivent être différentes');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final controller = ref.read(transactionServiceControllerProvider.notifier);
        await controller.createTransfer(
          amount: double.parse(_amountController.text),
          currency: _selectedCurrency,
          sourceId: _fromSourceId!,
          sourceType: _fromSourceType ?? tx.SourceType.source,
          targetId: _toSourceId!,
          targetType: _toSourceType ?? tx.SourceType.source,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          date: _selectedDate,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pop(context);
          _showSuccess(l10n.transactionAddedSuccess);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('${l10n.error}: $e');
        }
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
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            AppIcons.back,
            color: isDark ? AppColors.textDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(AppIcons.transfer, color: AppColors.primary, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Text(
              'Transfert',
              style: TextStyle(
                fontSize: AppSizes.textMedium,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.spacing12),
          children: [
            _buildFromSourceSelector(isDark, l10n),
            const SizedBox(height: AppSizes.spacing12),
            _buildToSourceSelector(isDark, l10n),
            const SizedBox(height: AppSizes.spacing12),
            _buildAmountField(isDark, l10n),
            const SizedBox(height: AppSizes.spacing12),
            _buildCurrencySelector(isDark, l10n),
            const SizedBox(height: AppSizes.spacing12),
            _buildDatePicker(isDark, l10n),
            const SizedBox(height: AppSizes.spacing12),
            _buildDescriptionField(isDark, l10n),
            const SizedBox(height: AppSizes.spacing12),
            _buildSaveButton(l10n),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFromSourceSelector(bool isDark, AppLocalizations l10n) {
    final sourcesAsync = ref.watch(originalUnifiedSourcesProvider);
    return _buildSourceSelector(
      sourcesAsync: sourcesAsync,
      title: 'Source de départ',
      selectedId: _fromSourceId,
      onSelected: (id, name, type) {
        setState(() {
          _fromSourceId = id;
          _fromSourceName = name;
          _fromSourceType = type;
        });
      },
      isDark: isDark,
      excludeId: _toSourceId,
      filterZeroBalance: true,
    );
  }

  Widget _buildToSourceSelector(bool isDark, AppLocalizations l10n) {
    final sourcesAsync = ref.watch(originalUnifiedSourcesProvider);
    return _buildSourceSelector(
      sourcesAsync: sourcesAsync,
      title: 'Source de destination',
      selectedId: _toSourceId,
      onSelected: (id, name, type) {
        setState(() {
          _toSourceId = id;
          _toSourceName = name;
          _toSourceType = type;
        });
      },
      isDark: isDark,
      excludeId: _fromSourceId,
      filterZeroBalance: false,
    );
  }

  Widget _buildSourceSelector({
    required AsyncValue<List<SourceModel>> sourcesAsync,
    required String title,
    required int? selectedId,
    required void Function(int id, String name, tx.SourceType type) onSelected,
    required bool isDark,
    int? excludeId,
    bool filterZeroBalance = false,
  }) {
    return sourcesAsync.when(
      data: (sources) {
        final availableSources = sources.where((s) {
          if (s.currency != _selectedCurrency) return false;
          if (!s.isActive || s.isDeleted) return false;
          if (s.id == excludeId) return false;
          if (filterZeroBalance && s.amount <= 0) return false;
          return true;
        }).toList();

        if (availableSources.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSizes.spacing12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.warning, color: AppColors.warning, size: 20),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: Text(
                    filterZeroBalance
                        ? 'Aucune source avec solde disponible pour $_selectedCurrency'
                        : 'Aucune source disponible pour $_selectedCurrency',
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
              title,
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
                  final isSelected = selectedId == source.id;
                  return GestureDetector(
                    onTap: () => onSelected(
                      source.id,
                      source.name,
                      _detectSourceType(source),
                    ),
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
      error: (error, _) => Text(l10nError),
    );
  }

  String get l10nError {
    final l10n = AppLocalizations.of(context)!;
    return l10n.loadingError;
  }

  IconData _getSourceIcon(dynamic source) {
    if (source.iconName == 'bank') return AppIcons.bank;
    if (source.iconName == 'assets') return AppIcons.assets;
    if (source.iconName == 'debt_given') return AppIcons.debt;
    if (source.iconName == 'debt_received') return AppIcons.debt;
    return AppIcons.wallet;
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
        prefixIcon: const Icon(AppIcons.money, color: AppColors.primary),
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
                _fromSourceId = null;
                _toSourceId = null;
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
        hintText: 'Ex: Virement cash vers compte bancaire',
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
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
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
        onPressed: _isLoading ? null : _saveTransfer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          disabledBackgroundColor: Colors.transparent,
        ),
        child: _isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Transférer',
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
