import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/transaction_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/theme_provider.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
  });

  @override
  ConsumerState<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late TransactionType _type;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.transaction.amount.toString();
    _descriptionController.text = widget.transaction.description ?? '';
    _type = widget.transaction.type;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
          'Modifier Transaction',
          style: TextStyle(
            color: isDark ? AppColors.textDark : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Montant',
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(AppIcons.money, color: AppColors.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Montant requis';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Montant invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(AppIcons.note, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _TypeButton(
                        label: l10n.entry,
                        icon: AppIcons.income,
                        color: AppColors.success,
                        isSelected: _type == TransactionType.income,
                        onTap: () => setState(() => _type = TransactionType.income),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TypeButton(
                        label: l10n.exit,
                        icon: AppIcons.expense,
                        color: AppColors.error,
                        isSelected: _type == TransactionType.expense,
                        onTap: () => setState(() => _type = TransactionType.expense),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.save,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveTransaction() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      try {
        final updatedTransaction = TransactionModel(
          id: widget.transaction.id,
          type: _type,
          amount: double.parse(_amountController.text),
          currency: widget.transaction.currency,
          sourceId: widget.transaction.sourceId,
          sourceName: widget.transaction.sourceName,
          sourceType: widget.transaction.sourceType,
          targetSourceId: widget.transaction.targetSourceId,
          targetSourceName: widget.transaction.targetSourceName,
          targetSourceType: widget.transaction.targetSourceType,
          date: widget.transaction.date,
          createdAt: widget.transaction.createdAt,
          updatedAt: DateTime.now(),
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          incomeCategory: _type == TransactionType.income ? IncomeCategory.other : widget.transaction.incomeCategory,
          expenseCategory: _type == TransactionType.expense ? ExpenseCategory.other : widget.transaction.expenseCategory,
        );

        await ref.read(transactionControllerProvider.notifier).updateTransaction(updatedTransaction);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.transactionUpdated),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : (isDark ? AppColors.textDark : Colors.black87),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}