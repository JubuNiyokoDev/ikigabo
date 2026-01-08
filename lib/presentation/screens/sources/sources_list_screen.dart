import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ikigabo/presentation/providers/source_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/source_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/search_provider.dart' hide filteredSourcesProvider;
import '../../providers/theme_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/currency_amount_widget.dart';
import '../../widgets/search_bar.dart' as custom;
import 'add_source_screen.dart';

class SourcesListScreen extends ConsumerStatefulWidget {
  const SourcesListScreen({super.key});

  @override
  ConsumerState<SourcesListScreen> createState() => _SourcesListScreenState();
}

class _SourcesListScreenState extends ConsumerState<SourcesListScreen> {
  bool _isSearchVisible = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    ref.watch(displayCurrencyProvider);
    final sourcesAsync = ref.watch(filteredSourcesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n, isDark),
            if (_isSearchVisible) ...[
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: custom.SearchBar(hintText: l10n.searchSource),
              ),
            ],
            SizedBox(height: 12.h),
            Expanded(
              child: sourcesAsync.when(
                data: (sources) => sources.isEmpty
                    ? _buildEmptyState(l10n)
                    : _buildSourcesList(sources, l10n),
                loading: () => _buildLoadingState(),
                error: (error, stack) =>
                    _buildErrorState(error.toString(), l10n),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSourceScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: Icon(AppIcons.add, color: Colors.white, size: 18.sp),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              AppIcons.back,
              color: isDark ? AppColors.textDark : Colors.black87,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mySources,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
                Text(
                  l10n.manageYourMoneySources,
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
          IconButton(
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  ref.read(searchQueryProvider.notifier).state = '';
                }
              });
            },
            icon: Icon(
              _isSearchVisible ? AppIcons.close : AppIcons.search,
              color: isDark ? AppColors.textDark : Colors.black87,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesList(List<SourceModel> sources, AppLocalizations l10n) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        return _SourceCard(
          source: source,
          l10n: l10n,
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeProvider);
        final isDark = themeMode == ThemeMode.dark;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(50.r),
                ),
                child: Icon(
                  AppIcons.wallet,
                  size: 18.sp,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                l10n.noSources,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                l10n.addFirstSource,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                ),
              ),
            ],
          ),
        ).animate().fadeIn();
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildErrorState(String error, AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeProvider);
        final isDark = themeMode == ThemeMode.dark;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.error, size: 20.sp, color: AppColors.error),
              SizedBox(height: 12.h),
              Text(
                l10n.error,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SourceCard extends ConsumerWidget {
  final SourceModel source;
  final AppLocalizations l10n;

  const _SourceCard({required this.source, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Dismissible(
      key: Key(source.id.toString()),
      background: _buildSwipeBackground(isDark, isDelete: false),
      secondaryBackground: _buildSwipeBackground(isDark, isDelete: true),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe vers la gauche = Supprimer
          final shouldDelete = await _showDeleteDialog(context, ref);
          if (shouldDelete) {
            // Vérifier si c'est une vraie source ou une dette/banque/asset
            if (source.id > 0) {
              // Vraie source
              await ref
                  .read(sourceControllerProvider.notifier)
                  .deleteSource(source.id);
            } else {
              // Dette, banque ou asset (ID négatif) - ne pas supprimer depuis ici
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Supprimez cet élément depuis sa page dédiée'),
                  backgroundColor: AppColors.warning,
                ),
              );
            }
          }
          return shouldDelete && source.id > 0;
        } else {
          // Swipe vers la droite = Éditer
          if (source.id > 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddSourceScreen(source: source),
              ),
            );
          }
          return false;
        }
      },
      onDismissed: (direction) async {
        // Ne pas faire l'action ici car elle est déjà faite dans confirmDismiss
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddSourceScreen(source: source),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  _buildIcon(),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source.name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textDark : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          _getTypeLabel(source.type, l10n),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CurrencyAmountWidget(
                        amount: source.amount,
                        originalCurrency: source.currency,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: source.amount >= 0
                              ? Colors.green
                              : AppColors.error,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: source.isActive
                              ? Colors.green.withValues(alpha: 0.2)
                              : (isDark
                                        ? AppColors.textSecondaryDark
                                        : Colors.grey)
                                    .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          source.isActive ? l10n.active : l10n.inactive,
                          style: TextStyle(
                            fontSize: 8.sp,
                            color: source.isActive
                                ? Colors.green
                                : (isDark
                                      ? AppColors.textSecondaryDark
                                      : Colors.grey),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(bool isDark, {required bool isDelete}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDelete ? AppColors.error : Colors.blue,
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: isDelete ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Icon(
        isDelete ? AppIcons.delete : AppIcons.edit,
        color: Colors.white,
        size: 20.sp,
      ),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final themeMode = ref.read(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            title: Text(
              l10n.delete,
              style: TextStyle(
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
            content: Text(
              l10n.confirmDeleteAsset.replaceAll('"${source.name}"', '"${source.name}"'),
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

    switch (source.type) {
      case SourceType.pocket:
        icon = AppIcons.pocket;
        color = AppColors.primary;
        break;
      case SourceType.safe:
        icon = AppIcons.safe;
        color = AppColors.warning;
        break;
      case SourceType.cash:
        icon = AppIcons.money;
        color = AppColors.success;
        break;
      case SourceType.custom:
        icon = AppIcons.custom;
        color = AppColors.secondary;
        break;
    }

    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(icon, color: color, size: 18.sp),
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
}
