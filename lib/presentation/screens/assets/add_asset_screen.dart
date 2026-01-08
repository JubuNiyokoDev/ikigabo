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
import '../../../data/models/asset_model.dart';
import '../../../data/models/source_model.dart';
import '../../../data/models/transaction_model.dart' as tx;
import '../../../l10n/app_localizations.dart';
import '../../providers/asset_provider.dart';
import '../../providers/source_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/currency_provider.dart';

class AddAssetScreen extends ConsumerStatefulWidget {
  final AssetModel? asset;

  const AddAssetScreen({super.key, this.asset});

  @override
  ConsumerState<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends ConsumerState<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  AssetType _assetType = AssetType.livestock;
  AssetStatus _status = AssetStatus.owned;
  String? _currency;
  DateTime _purchaseDate = DateTime.now();
  SourceModel? _selectedSource;
  bool _showSourceSelector = false;
  bool _skipSourceSelection = false;

  @override
  void initState() {
    super.initState();
    if (widget.asset != null) {
      _nameController.text = widget.asset!.name;
      _purchasePriceController.text = widget.asset!.purchasePrice.toString();
      _currentValueController.text = widget.asset!.currentValue.toString();
      _quantityController.text = widget.asset!.quantity?.toString() ?? '';
      _unitController.text = widget.asset!.unit ?? '';
      _locationController.text = widget.asset!.location ?? '';
      _descriptionController.text = widget.asset!.description ?? '';
      _assetType = widget.asset!.type;
      _status = widget.asset!.status;
      _currency = widget.asset!.currency;
      _purchaseDate = widget.asset!.purchaseDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _currentValueController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onPurchasePriceChanged(String value) {
    final amount = double.tryParse(value) ?? 0;
    setState(() {
      _showSourceSelector =
          amount > 0 && widget.asset == null && !_skipSourceSelection;
      if (!_showSourceSelector) {
        _selectedSource = null;
      }
    });
  }

  Future<void> _saveAsset() async {
    if (_formKey.currentState!.validate()) {
      final purchasePrice = double.parse(_purchasePriceController.text);

      // Vérifier la source si prix d'achat > 0
      if (purchasePrice > 0 && widget.asset == null && !_skipSourceSelection) {
        if (_selectedSource == null) {
          final l10n = AppLocalizations.of(context)!;
          _showError(l10n.pleaseSelectSource);
          return;
        }

        // Vérifier si la source a assez d'argent
        if (_selectedSource!.amount < purchasePrice) {
          final l10n = AppLocalizations.of(context)!;
          _showError('${l10n.insufficientBalance} ${_selectedSource!.name}');
          return;
        }

        // Vérifier la compatibilité des devises
        final assetCurrency = _currency ?? 'BIF';
        if (_selectedSource!.currency != assetCurrency) {
          final l10n = AppLocalizations.of(context)!;
          _showError(
            '${l10n.currencyMismatch}: ${_selectedSource!.currency} ≠ $assetCurrency',
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
      final asset = AssetModel(
        id: widget.asset?.id ?? Isar.autoIncrement,
        name: _nameController.text.trim(),
        type: _assetType,
        purchasePrice: double.parse(_purchasePriceController.text),
        currentValue: double.parse(_currentValueController.text),
        currency: _currency ?? currency.code,
        purchaseDate: _purchaseDate,
        status: _status,
        quantity: _quantityController.text.trim().isEmpty
            ? null
            : int.parse(_quantityController.text),
        unit: _unitController.text.trim().isEmpty
            ? null
            : _unitController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: widget.asset?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        final controller = ref.read(assetControllerProvider.notifier);
        if (widget.asset == null) {
          if (purchasePrice > 0 &&
              _selectedSource != null &&
              !_skipSourceSelection) {
            // Asset avec achat depuis une source
            await controller.addAssetWithPurchase(
              asset: asset,
              sourceId: _selectedSource!.id,
              sourceType: tx.SourceType.source,
              sourceName: _selectedSource!.name,
            );
          } else {
            // Asset sans achat ou avec argent externe
            await controller.addAsset(asset);
          }
        } else {
          await controller.updateAsset(asset);
        }

        if (mounted) {
          Navigator.pop(context);
          final l10n = AppLocalizations.of(context)!;
          _showSuccess(
            widget.asset == null
                ? l10n.assetAddedSuccess
                : l10n.assetUpdatedSuccess,
          );
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
          widget.asset == null ? l10n.newAsset : l10n.editAsset,
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
              _buildAssetTypeSelector(
                isDark,
                l10n,
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildPurchasePriceField(isDark).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: AppSizes.spacing12),
              if (_showSourceSelector)
                _buildSourceSelector(
                  isDark,
                  l10n,
                ).animate().fadeIn(delay: 220.ms),
              if (_showSourceSelector) const SizedBox(height: AppSizes.spacing12),
              if (double.tryParse(_purchasePriceController.text) != null &&
                  double.parse(_purchasePriceController.text) > 0 &&
                  widget.asset == null)
                _buildSkipSourceOption(
                  isDark,
                  l10n,
                ).animate().fadeIn(delay: 240.ms),
              if (double.tryParse(_purchasePriceController.text) != null &&
                  double.parse(_purchasePriceController.text) > 0 &&
                  widget.asset == null)
                const SizedBox(height: AppSizes.spacing12),
              _buildCurrentValueField(isDark).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildCurrencySelector(isDark).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildQuantityFields(isDark).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildPurchaseDatePicker(isDark).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildLocationField(isDark).animate().fadeIn(delay: 450.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildDescriptionField(isDark).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: AppSizes.spacing12),
              _buildSaveButton(l10n).animate().fadeIn(delay: 550.ms),
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
        labelText: l10n.assetName,
        hintText: l10n.assetNameHint,
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
          return l10n.assetNameRequired;
        }
        return null;
      },
    );
  }

  Widget _buildAssetTypeSelector(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.assetType,
          style: TextStyle(
            fontSize: AppSizes.textSmall,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDark : Colors.black87,
          ),
        ),
        const SizedBox(height: AppSizes.spacing12),
        Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          children: AssetType.values.map((type) {
            final isSelected = _assetType == type;
            return FilterChip(
              label: Text(_getTypeLabel(type, l10n)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _assetType = type);
              },
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              selectedColor: AppColors.accent.withValues(alpha: 0.3),
              checkmarkColor: AppColors.accent,
              labelStyle: const TextStyle(fontSize: AppSizes.textSmall),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPurchasePriceField(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _purchasePriceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: isDark ? AppColors.textDark : Colors.black87,
        fontSize: AppSizes.textMedium,
        fontWeight: FontWeight.w600,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: _onPurchasePriceChanged,
      decoration: InputDecoration(
        labelText: l10n.purchasePrice,
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
          return l10n.purchasePriceRequired;
        }
        if (double.tryParse(value) == null) {
          return l10n.invalidPrice;
        }
        return null;
      },
    );
  }

  Widget _buildCurrentValueField(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _currentValueController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: isDark ? AppColors.textDark : Colors.black87,
        fontSize: AppSizes.textMedium,
        fontWeight: FontWeight.w600,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: l10n.currentValue,
        hintText: '0.00',
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(AppIcons.money, color: AppColors.success),
        suffixText: _currency,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.currentValueRequired;
        }
        if (double.tryParse(value) == null) {
          return l10n.invalidValue;
        }
        return null;
      },
    );
  }

  Widget _buildCurrencySelector(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
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
                    Text(currency.flag, style: TextStyle(fontSize: 16.sp)),
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

  Widget _buildQuantityFields(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.quantity,
              hintText: '1',
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(AppIcons.filter, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spacing12),
        Expanded(
          child: TextFormField(
            controller: _unitController,
            style: TextStyle(
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: l10n.unit,
              hintText: l10n.unitHint,
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseDatePicker(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _purchaseDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: AppColors.primary,
                  surface: isDark ? AppColors.surfaceDark : Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() => _purchaseDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.purchaseDate,
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(AppIcons.calendar, color: AppColors.primary),
        ),
        child: Text(
          '${_purchaseDate.day}/${_purchaseDate.month}/${_purchaseDate.year}',
          style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildLocationField(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _locationController,
      style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
      decoration: InputDecoration(
        labelText: l10n.location,
        hintText: l10n.locationHint,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(AppIcons.land, color: AppColors.primary),
      ),
    );
  }

  Widget _buildDescriptionField(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
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

  Widget _buildSaveButton(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 44.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveAsset,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Text(
          widget.asset == null ? l10n.addAsset : l10n.save,
          style: const TextStyle(
            fontSize: AppSizes.textMedium,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(AssetType type, AppLocalizations l10n) {
    switch (type) {
      case AssetType.livestock:
        return l10n.livestock;
      case AssetType.crop:
        return l10n.crop;
      case AssetType.land:
        return l10n.land;
      case AssetType.vehicle:
        return l10n.vehicle;
      case AssetType.equipment:
        return l10n.equipment;
      case AssetType.jewelry:
        return l10n.jewelry;
      case AssetType.other:
        return l10n.other;
    }
  }

  Widget _buildSourceSelector(bool isDark, AppLocalizations l10n) {
    final sourcesAsync = ref.watch(originalSourcesProvider);

    return sourcesAsync.when(
      data: (sources) {
        final assetCurrency = _currency ?? 'BIF';
        final availableSources = sources
            .where(
              (s) =>
                  s.amount > 0 &&
                  s.isActive &&
                  !s.isDeleted &&
                  s.currency == assetCurrency,
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
                    (double.tryParse(_purchasePriceController.text) ?? 0) > 0 &&
                    widget.asset == null;
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
                  l10n.assetAlreadyOwned,
                  style: TextStyle(
                    fontSize: AppSizes.textMedium,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.assetWasAlreadyOwned,
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
