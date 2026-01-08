import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/asset_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/asset_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/currency_amount_widget.dart';
import 'add_asset_screen.dart';

class AssetDetailScreen extends ConsumerWidget {
  final AssetModel asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final profitLoss = asset.profitLoss;
    final profitLossPercentage = asset.profitLossPercentage;
    final isProfitable = profitLoss >= 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(AppSizes.spacing12),
                children: [
                  _buildValueCard(
                    context,
                    isDark,
                    isProfitable,
                    profitLoss,
                    profitLossPercentage,
                  ),
                  SizedBox(height: AppSizes.spacing12),
                  _buildInfoSection(context, isDark),
                  SizedBox(height: AppSizes.spacing12),
                  _buildFinancialSection(context, isDark),
                  SizedBox(height: AppSizes.spacing12),
                  _buildActionsSection(context, ref, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(AppIcons.back, color: Colors.white, size: 18),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddAssetScreen(asset: asset),
                    ),
                  );
                },
                icon: const Icon(AppIcons.edit, color: Colors.white, size: 18),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spacing12),
          Container(
            width: 28.w,
            height: 28.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(_getTypeIcon(), size: 14.sp, color: Colors.white),
          ).animate().scale(delay: 100.ms),
          SizedBox(height: AppSizes.spacing12),
          Text(
            asset.name,
            style: TextStyle(
              fontSize: AppSizes.textLarge,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          SizedBox(height: 2.h),
          Text(
            _getTypeLabel(asset.type, context),
            style: TextStyle(fontSize: AppSizes.textSmall, color: Colors.white70),
          ).animate().fadeIn(delay: 250.ms),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    IconData icon;
    switch (asset.type) {
      case AssetType.livestock:
        icon = AppIcons.livestock;
        break;
      case AssetType.crop:
        icon = AppIcons.crop;
        break;
      case AssetType.land:
        icon = AppIcons.land;
        break;
      case AssetType.vehicle:
        icon = AppIcons.vehicle;
        break;
      case AssetType.equipment:
        icon = AppIcons.equipment;
        break;
      case AssetType.jewelry:
        icon = AppIcons.jewelry;
        break;
      case AssetType.other:
        icon = AppIcons.asset;
        break;
    }

    return icon;
  }

  Widget _buildValueCard(
    BuildContext context,
    bool isDark,
    bool isProfitable,
    double profitLoss,
    double profitLossPercentage,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            l10n.totalValue,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 12),
          CurrencyAmountWidget(
            amount: asset.totalValue,
            originalCurrency: asset.currency,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
          if (asset.quantity != null && asset.quantity! > 1) ...[
            const SizedBox(height: 12),
            Text(
              '${asset.currentValue.toStringAsFixed(0)} ${asset.currency} × ${asset.quantity}${asset.unit != null ? ' ${asset.unit}' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isProfitable
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isProfitable ? AppIcons.trendingUp : AppIcons.trendingDown,
                  color: isProfitable ? AppColors.success : AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                CurrencyAmountWidget(
                  amount: profitLoss,
                  originalCurrency: asset.currency,
                  showSymbol: false,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isProfitable ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${profitLossPercentage >= 0 ? '+' : ''}${profitLossPercentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isProfitable ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildInfoSection(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.info, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                l10n.information,
                style: TextStyle(
                  fontSize: AppSizes.textSmall,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (asset.location != null) ...[
            _InfoRow(
              label: l10n.location,
              value: asset.location!,
              icon: AppIcons.land,
            ),
            const Divider(height: 16, color: AppColors.borderDark),
          ],
          _InfoRow(
            label: l10n.purchaseDate,
            value:
                '${asset.purchaseDate.day}/${asset.purchaseDate.month}/${asset.purchaseDate.year}',
            icon: AppIcons.calendar,
          ),
          const Divider(height: 16, color: AppColors.borderDark),
          _InfoRow(
            label: l10n.status,
            value: _getStatusLabel(asset.status, l10n),
            icon: AppIcons.info,
            valueColor: _getStatusColor(asset.status),
          ),
          if (asset.description != null) ...[
            const Divider(height: 16, color: AppColors.borderDark),
            _InfoRow(
              label: l10n.description,
              value: asset.description!,
              icon: AppIcons.note,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildFinancialSection(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.money, color: AppColors.primary, size: 16),
              SizedBox(width: AppSizes.spacing12),
              Text(
                l10n.financialDetails,
                style: TextStyle(
                  fontSize: AppSizes.textMedium,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spacing12),
          _InfoRow(
            label: l10n.purchasePrice,
            value: '',
            icon: AppIcons.money,
            customValue: CurrencyAmountWidget(
              amount: asset.purchasePrice,
              originalCurrency: asset.currency,
              style: TextStyle(
                fontSize: AppSizes.textSmall,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
          ),
          Divider(height: AppSizes.spacing12, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
          _InfoRow(
            label: l10n.currentValue,
            value: '',
            icon: AppIcons.money,
            valueColor: AppColors.accent,
            customValue: CurrencyAmountWidget(
              amount: asset.currentValue,
              originalCurrency: asset.currency,
              style: const TextStyle(
                fontSize: AppSizes.textSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
          if (asset.quantity != null) ...[
            Divider(height: AppSizes.spacing12, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
            _InfoRow(
              label: l10n.quantity,
              value:
                  '${asset.quantity}${asset.unit != null ? ' ${asset.unit}' : ''}',
              icon: AppIcons.filter,
            ),
          ],
          Divider(height: AppSizes.spacing12, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
          _InfoRow(
            label: l10n.profitLoss,
            value: '',
            icon: asset.profitLoss >= 0
                ? AppIcons.trendingUp
                : AppIcons.trendingDown,
            valueColor: asset.profitLoss >= 0
                ? AppColors.success
                : AppColors.error,
            customValue: CurrencyAmountWidget(
              amount: asset.profitLoss,
              originalCurrency: asset.currency,
              style: TextStyle(
                fontSize: AppSizes.textSmall,
                fontWeight: FontWeight.w600,
                color: asset.profitLoss >= 0
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildActionsSection(BuildContext context, WidgetRef ref, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.actions,
            style: TextStyle(
              fontSize: AppSizes.textMedium,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          SizedBox(height: AppSizes.spacing12),
          _ActionButton(
            label: l10n.editAsset,
            icon: AppIcons.edit,
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddAssetScreen(asset: asset)),
              );
            },
          ),
          SizedBox(height: AppSizes.spacing12),
          _ActionButton(
            label: l10n.deleteAsset,
            icon: AppIcons.delete,
            color: AppColors.error,
            onTap: () {
              _showDeleteDialog(context, ref);
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          l10n.deleteAsset,
          style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
        ),
        content: Text(
          '${l10n.confirmDeleteAsset} "${asset.name}" ?',
          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(assetControllerProvider.notifier)
                    .deleteAsset(asset.id);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.assetDeletedSuccessfully),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(AssetType type, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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

  String _getStatusLabel(AssetStatus status, AppLocalizations l10n) {
    switch (status) {
      case AssetStatus.owned:
        return l10n.owned;
      case AssetStatus.sold:
        return l10n.sold;
      case AssetStatus.lost:
        return l10n.lost;
      case AssetStatus.donated:
        return l10n.donated;
    }
  }

  Color _getStatusColor(AssetStatus status) {
    switch (status) {
      case AssetStatus.owned:
        return AppColors.success;
      case AssetStatus.sold:
        return AppColors.info;
      case AssetStatus.lost:
        return AppColors.error;
      case AssetStatus.donated:
        return AppColors.warning;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final Widget? customValue;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.customValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.textSmall,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 1),
              customValue ??
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: AppSizes.textSmall,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? AppColors.textDark,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(AppIcons.back, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
