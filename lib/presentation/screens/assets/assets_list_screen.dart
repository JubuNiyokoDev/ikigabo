import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ikigabo/core/constants/app_sizes.dart';
import 'package:ikigabo/core/utils/currency_formatter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/currencies.dart';
import '../../../data/models/asset_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/asset_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/currency_amount_widget.dart';
import 'add_asset_screen.dart';
import 'asset_detail_screen.dart';

class AssetsListScreen extends ConsumerWidget {
  const AssetsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final displayCurrencyAsync = ref.watch(displayCurrencyProvider);
    final assetsAsync = ref.watch(assetsStreamProvider);
    final totalValueAsync = ref.watch(totalAssetValueProvider);
    final assetStatsAsync = ref.watch(assetStatsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, totalValueAsync, l10n, displayCurrencyAsync),
            const SizedBox(height: 16),
            _buildStatsRow(assetStatsAsync, l10n, displayCurrencyAsync),
            const SizedBox(height: 16),
            Expanded(
              child: assetsAsync.when(
                data: (assets) {
                  final ownedAssets = assets
                      .where((a) => a.status == AssetStatus.owned)
                      .toList();
                  return ownedAssets.isEmpty
                      ? _buildEmptyState(context)
                      : _buildAssetsList(context, ownedAssets);
                },
                loading: () => _buildLoadingState(),
                error: (error, stack) =>
                    _buildErrorState(error.toString(), context),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAssetScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(AppIcons.add, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<double> totalValueAsync,
    AppLocalizations l10n,
    AsyncValue<Currency> displayCurrencyAsync,
  ) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.assets,
                      style: TextStyle(
                        fontSize: AppSizes.textMedium,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.convertibleAsset,
                      style: TextStyle(
                        fontSize: AppSizes.textSmall,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  AppIcons.filter,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.totalValue,
            style: TextStyle(
              fontSize: AppSizes.textSmall,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          totalValueAsync.when(
            data: (value) => DisplayCurrencyAmountWidget(
              amount: value,
              style: TextStyle(
                fontSize: AppSizes.textLarge,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            loading: () => const CircularProgressIndicator(color: Colors.white),
            error: (e, s) => DisplayCurrencyAmountWidget(
              amount: 0,
              style: TextStyle(
                fontSize: AppSizes.textLarge,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildStatsRow(
    AsyncValue<Map<String, dynamic>> statsAsync,
    AppLocalizations l10n,
    AsyncValue<Currency> displayCurrencyAsync,
  ) {
    return statsAsync.when(
      data: (stats) => Consumer(
        builder: (context, ref, child) {
          final themeMode = ref.watch(themeProvider);
          final isDark = themeMode == ThemeMode.dark;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    l10n.totalAssets,
                    '${stats['totalAssets']}',
                    AppIcons.asset,
                    AppColors.primary,
                    isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    l10n.profitLoss,
                    displayCurrencyAsync.when(
                      data: (currency) => CurrencyFormatter.formatAmount(
                        stats['totalProfitLoss'],
                        currency,
                      ),
                      loading: () => 'FBu 0',
                      error: (_, __) => 'FBu 0',
                    ),
                    stats['totalProfitLoss'] >= 0
                        ? AppIcons.trendingUp
                        : AppIcons.trendingDown,
                    stats['totalProfitLoss'] >= 0
                        ? AppColors.success
                        : AppColors.error,
                    isDark,
                  ),
                ),
              ],
            ),
          );
        },
      ).animate().slideX(delay: 200.ms),
      loading: () => Consumer(
        builder: (context, ref, child) {
          final themeMode = ref.watch(themeProvider);
          final isDark = themeMode == ThemeMode.dark;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _buildStatCardLoading(isDark)),
                const SizedBox(width: 14),
                Expanded(child: _buildStatCardLoading(isDark)),
              ],
            ),
          );
        },
      ),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: AppSizes.textSmall,
              color: isDark ? AppColors.textSecondaryDark : Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.textSmall,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardLoading(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundDark,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 12,
            width: 54,
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundDark,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 16,
            width: 54,
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundDark,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsList(BuildContext context, List<AssetModel> assets) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return _AssetCard(
          asset: asset,
          l10n: AppLocalizations.of(context)!,
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeProvider);
        final isDark = themeMode == ThemeMode.dark;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  AppIcons.asset,
                  size: 20,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noAssets,
                style: TextStyle(
                  fontSize: AppSizes.textLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.addFirstAsset,
                style: TextStyle(
                  fontSize: AppSizes.textSmall,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildErrorState(String error, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(AppIcons.error, size: 24, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            l10n.error,
            style: TextStyle(
              fontSize: AppSizes.textLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.textMedium,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetCard extends ConsumerWidget {
  final AssetModel asset;
  final AppLocalizations l10n;

  const _AssetCard({required this.asset, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final displayCurrencyAsync = ref.watch(displayCurrencyProvider);
    final profitLoss = asset.profitLoss;
    final isProfitable = profitLoss >= 0;

    return Dismissible(
      key: Key(asset.id.toString()),
      background: _buildSwipeBackground(false),
      secondaryBackground: _buildSwipeBackground(true),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final shouldDelete = await _showDeleteDialog(context, ref);
          if (shouldDelete) {
            await ref
                .read(assetControllerProvider.notifier)
                .deleteAsset(asset.id);
          }
          return shouldDelete;
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddAssetScreen(asset: asset)),
          );
          return false;
        }
      },
      onDismissed: (direction) async {
        // Ne pas faire l'action ici car elle est déjà faite dans confirmDismiss
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AssetDetailScreen(asset: asset)),
          );
        },
        onLongPress: () => _showAssetActions(context, ref),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            asset.name,
                            style: TextStyle(
                              fontSize: AppSizes.textSmall,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textDark
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (asset.quantity != null && asset.quantity! > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'x${asset.quantity}',
                              style: TextStyle(
                                fontSize: AppSizes.textSmall,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getTypeLabel(asset.type, l10n),
                      style: TextStyle(
                        fontSize: AppSizes.textSmall,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: CurrencyAmountWidget(
                            amount: asset.totalValue,
                            originalCurrency: asset.currency,
                            style: TextStyle(
                              fontSize: AppSizes.textSmall,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isProfitable
                                ? AppColors.success.withValues(alpha: 0.2)
                                : AppColors.error.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isProfitable
                                    ? AppIcons.trendingUp
                                    : AppIcons.trendingDown,
                                size: 10,
                                color: isProfitable
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${profitLoss >= 0 ? '+' : ''}${profitLoss.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: AppSizes.textSmall,
                                  fontWeight: FontWeight.w600,
                                  color: isProfitable
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                AppIcons.back,
                color: AppColors.textSecondaryDark,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(bool isDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDelete ? AppColors.error : Colors.blue,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: isDelete ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(
        isDelete ? AppIcons.delete : AppIcons.edit,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            title: Text(
              l10n.deleteAsset,
              style: TextStyle(
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
            content: Text(
              '${l10n.confirmDeleteAsset} "${asset.name}" ?',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : Colors.black54,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.delete),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (asset.type) {
      case AssetType.livestock:
        icon = AppIcons.livestock;
        color = AppColors.success;
        break;
      case AssetType.crop:
        icon = AppIcons.crop;
        color = AppColors.accent;
        break;
      case AssetType.land:
        icon = AppIcons.land;
        color = AppColors.warning;
        break;
      case AssetType.vehicle:
        icon = AppIcons.vehicle;
        color = AppColors.info;
        break;
      case AssetType.equipment:
        icon = AppIcons.equipment;
        color = AppColors.primary;
        break;
      case AssetType.jewelry:
        icon = AppIcons.jewelry;
        color = AppColors.secondary;
        break;
      case AssetType.other:
        icon = AppIcons.asset;
        color = AppColors.textSecondaryDark;
        break;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
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

  void _showAssetActions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              asset.name,
              style: TextStyle(
                fontSize: AppSizes.textMedium,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                AppIcons.edit,
                color: AppColors.primary,
                size: 18,
              ),
              title: Text(
                l10n.revaluate,
                style: TextStyle(
                  color: isDark ? AppColors.textDark : Colors.black87,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showRevaluationDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(
                AppIcons.money,
                color: AppColors.success,
                size: 18,
              ),
              title: Text(
                l10n.sell,
                style: TextStyle(
                  color: isDark ? AppColors.textDark : Colors.black87,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSellDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRevaluationDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final displayCurrencyAsync = ref.read(displayCurrencyProvider);
    final currency = displayCurrencyAsync.when(
      data: (curr) => curr,
      loading: () => AppCurrencies.bif,
      error: (_, __) => AppCurrencies.bif,
    );
    final controller = TextEditingController(
      text: asset.currentValue.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          l10n.revaluateAsset,
          style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
          decoration: InputDecoration(
            labelText: l10n.newValue,
            labelStyle: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : Colors.black54,
            ),
            suffixText: currency.code,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = double.tryParse(controller.text);
              if (newValue != null) {
                await ref
                    .read(assetControllerProvider.notifier)
                    .revaluateAsset(asset.id, newValue);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showSellDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final displayCurrencyAsync = ref.read(displayCurrencyProvider);
    final currency = displayCurrencyAsync.when(
      data: (curr) => curr,
      loading: () => AppCurrencies.bif,
      error: (_, __) => AppCurrencies.bif,
    );
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          l10n.sellAsset,
          style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
          decoration: InputDecoration(
            labelText: l10n.sellPrice,
            labelStyle: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : Colors.black54,
            ),
            suffixText: currency.code,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final sellPrice = double.tryParse(controller.text);
              if (sellPrice != null) {
                await ref
                    .read(assetControllerProvider.notifier)
                    .sellAsset(asset.id, sellPrice);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.sell),
          ),
        ],
      ),
    );
  }
}
