import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/currencies.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../providers/filter_provider.dart';
import '../providers/currency_provider.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  DateTimeRange? _selectedDateRange;
  TransactionType? _selectedType;
  RangeValues? _amountRange;

  @override
  void initState() {
    super.initState();
    final dateFilter = ref.read(dateFilterProvider);
    final typeFilter = ref.read(typeFilterProvider);
    final amountFilter = ref.read(amountRangeProvider);

    if (dateFilter != null) {
      _selectedDateRange = DateTimeRange(start: dateFilter.start, end: dateFilter.end);
    }
    _selectedType = typeFilter;
    if (amountFilter != null) {
      _amountRange = RangeValues(amountFilter.min, amountFilter.max);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(AppIcons.close, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDateFilter(),
          const SizedBox(height: 20),
          _buildTypeFilter(),
          const SizedBox(height: 20),
          _buildAmountFilter(),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Effacer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Période',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.calendar, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDateRange == null
                        ? 'Sélectionner une période'
                        : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                    style: TextStyle(
                      color: _selectedDateRange == null
                          ? AppColors.textSecondaryDark
                          : AppColors.textDark,
                    ),
                  ),
                ),
                if (_selectedDateRange != null)
                  IconButton(
                    onPressed: () => setState(() => _selectedDateRange = null),
                    icon: const Icon(AppIcons.close, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type de transaction',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FilterChip(
                label: 'Entrées',
                isSelected: _selectedType == TransactionType.income,
                onTap: () => setState(() {
                  _selectedType = _selectedType == TransactionType.income ? null : TransactionType.income;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FilterChip(
                label: 'Sorties',
                isSelected: _selectedType == TransactionType.expense,
                onTap: () => setState(() {
                  _selectedType = _selectedType == TransactionType.expense ? null : TransactionType.expense;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountFilter() {
    final currency = ref.watch(displayCurrencyProvider).value ?? AppCurrencies.all.first;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Montant',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        if (_amountRange != null) ...[
          RangeSlider(
            values: _amountRange!,
            min: 0,
            max: 1000000,
            divisions: 100,
            labels: RangeLabels(
              CurrencyFormatter.formatAmount(_amountRange!.start, currency),
              CurrencyFormatter.formatAmount(_amountRange!.end, currency),
            ),
            onChanged: (values) => setState(() => _amountRange = values),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(CurrencyFormatter.formatAmount(_amountRange!.start, currency)),
              Text(CurrencyFormatter.formatAmount(_amountRange!.end, currency)),
            ],
          ),
        ] else ...[
          InkWell(
            onTap: () => setState(() => _amountRange = const RangeValues(0, 100000)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Row(
                children: [
                  Icon(AppIcons.money, color: AppColors.primary),
                  SizedBox(width: 12),
                  Text(
                    'Définir une fourchette de montant',
                    style: TextStyle(color: AppColors.textSecondaryDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDateRange = null;
      _selectedType = null;
      _amountRange = null;
    });
    ref.read(clearFiltersProvider);
    Navigator.pop(context);
  }

  void _applyFilters() {
    if (_selectedDateRange != null) {
      ref.read(dateFilterProvider.notifier).state = DateRange(
        _selectedDateRange!.start,
        _selectedDateRange!.end,
      );
    } else {
      ref.read(dateFilterProvider.notifier).state = null;
    }

    ref.read(typeFilterProvider.notifier).state = _selectedType;

    if (_amountRange != null) {
      ref.read(amountRangeProvider.notifier).state = AmountRange(
        _amountRange!.start,
        _amountRange!.end,
      );
    } else {
      ref.read(amountRangeProvider.notifier).state = null;
    }

    Navigator.pop(context);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderDark,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textDark,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}