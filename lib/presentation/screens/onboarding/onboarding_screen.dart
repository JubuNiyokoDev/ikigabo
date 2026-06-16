import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../providers/preferences_provider.dart' as prefs;
import '../../providers/onboarding_provider.dart';
import '../../widgets/loading_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _pageCount = 4;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(prefs.preferencesServiceProvider)
          .value
          ?.setOnboardingCompleted(true);

      // Invalider le provider pour forcer le refresh
      ref.invalidate(onboardingCompleteProvider);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: AppSizes.textMedium,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      l10n.skip,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey,
                        fontSize: AppSizes.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildPage1(isDark, l10n),
                  _buildPage2(isDark, l10n),
                  _buildPage3(isDark, l10n),
                  _buildPage4(isDark, l10n),
                ],
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pageCount, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: _currentPage == index ? 24.w : 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.borderDark
                              : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                );
              }),
            ),

            SizedBox(height: 24.h),

            // Next/Get Started button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: LoadingButton(
                text: _currentPage == _pageCount - 1
                    ? l10n.getStarted
                    : l10n.next,
                onPressed: _isLoading ? null : _nextPage,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1(bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60.r),
            ),
            child: Icon(AppIcons.money, size: 60.sp, color: AppColors.primary),
          ).animate().scale(delay: 200.ms),

          SizedBox(height: 32.h),

          Text(
            l10n.onboardingTitle1,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),

          SizedBox(height: 16.h),

          Text(
            l10n.onboardingDesc1,
            style: TextStyle(
              fontSize: AppSizes.textMedium,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),

          SizedBox(height: 24.h),

          _buildQuickPoints(isDark: isDark, points: _quickPoints(l10n, 1)),
        ],
      ),
    );
  }

  Widget _buildPage2(bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60.r),
            ),
            child: Icon(AppIcons.assets, size: 60.sp, color: AppColors.success),
          ).animate().scale(delay: 200.ms),

          SizedBox(height: 32.h),

          Text(
            l10n.onboardingTitle2,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),

          SizedBox(height: 16.h),

          Text(
            l10n.onboardingDesc2,
            style: TextStyle(
              fontSize: AppSizes.textMedium,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),

          SizedBox(height: 24.h),

          _buildQuickPoints(isDark: isDark, points: _quickPoints(l10n, 2)),
        ],
      ),
    );
  }

  Widget _buildPage3(bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60.r),
            ),
            child: Icon(AppIcons.debt, size: 60.sp, color: AppColors.warning),
          ).animate().scale(delay: 200.ms),

          SizedBox(height: 32.h),

          Text(
            l10n.onboardingTitle3,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),

          SizedBox(height: 16.h),

          Text(
            l10n.onboardingDesc3,
            style: TextStyle(
              fontSize: AppSizes.textMedium,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),

          SizedBox(height: 24.h),

          _buildQuickPoints(isDark: isDark, points: _quickPoints(l10n, 3)),
        ],
      ),
    );
  }

  Widget _buildPage4(bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60.r),
            ),
            child: Icon(
              AppIcons.security,
              size: 60.sp,
              color: AppColors.accent,
            ),
          ).animate().scale(delay: 200.ms),

          SizedBox(height: 32.h),

          Text(
            l10n.onboardingTitle4,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),

          SizedBox(height: 16.h),

          Text(
            l10n.onboardingDesc4,
            style: TextStyle(
              fontSize: AppSizes.textMedium,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),

          SizedBox(height: 24.h),

          _buildQuickPoints(isDark: isDark, points: _quickPoints(l10n, 4)),
        ],
      ),
    );
  }

  Widget _buildQuickPoints({
    required bool isDark,
    required List<String> points,
  }) {
    return Column(
      children: points
          .map(
            (point) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                children: [
                  Container(
                    width: 22.w,
                    height: 22.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(
                      AppIcons.success,
                      color: AppColors.primary,
                      size: 13.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        height: 1.25,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ).animate().fadeIn(delay: 750.ms);
  }

  List<String> _quickPoints(AppLocalizations l10n, int page) {
    final language = l10n.localeName.split('_').first;

    const points = {
      'fr': {
        1: [
          'Sources, banques, actifs et dettes',
          'Solde total et historique au même endroit',
          'Fonctionne même sans connexion',
        ],
        2: [
          'Ajoutez chaque revenu ou dépense',
          'Faites des transferts entre comptes',
          'Suivez les statistiques automatiquement',
        ],
        3: [
          'Rappels avant les échéances',
          'Suivi des montants déjà payés',
          'Alertes quand une dette devient urgente',
        ],
        4: [
          'Code PIN pour protéger l’accès',
          'Sauvegarde locale ou Google Drive',
          'Notifications intelligentes si vous oubliez',
        ],
      },
      'en': {
        1: [
          'Sources, banks, assets and debts',
          'Total balance and history in one place',
          'Works even without internet',
        ],
        2: [
          'Add every income or expense',
          'Transfer money between accounts',
          'Track statistics automatically',
        ],
        3: [
          'Reminders before due dates',
          'Track amounts already paid',
          'Alerts when a debt becomes urgent',
        ],
        4: [
          'PIN code to protect access',
          'Local or Google Drive backup',
          'Smart reminders when you forget',
        ],
      },
      'rn': {
        1: [
          'Inkomoko, amabanki, itunga n’amadeni',
          'Igiteranyo n’amateka ahantu hamwe',
          'Bikora no ata internet ihari',
        ],
        2: [
          'Andika ayinjiye n’ayasohotse',
          'Rungika amahera hagati ya konti',
          'Raba ibiharuro vyikora',
        ],
        3: [
          'Ivyibutso imbere y’itariki',
          'Kurikirana ayamaze kwishyurwa',
          'Imenyesha iyo ideni ryihutirwa',
        ],
        4: [
          'PIN yo gukingira app',
          'Backup kuri telefone canke Google Drive',
          'Ivyibutso vy’ubwenge iyo wibagiye',
        ],
      },
      'sw': {
        1: [
          'Vyanzo, benki, mali na madeni',
          'Salio na historia mahali pamoja',
          'Inafanya kazi bila intaneti',
        ],
        2: [
          'Ongeza kila mapato au matumizi',
          'Hamisha fedha kati ya akaunti',
          'Fuatilia takwimu kiotomatiki',
        ],
        3: [
          'Vikumbusho kabla ya tarehe',
          'Fuatilia kiasi kilicholipwa',
          'Arifa deni likiwa la haraka',
        ],
        4: [
          'PIN kulinda ufikiaji',
          'Backup ya ndani au Google Drive',
          'Vikumbusho mahiri ukisahau',
        ],
      },
    };

    return points[language]?[page] ?? points['fr']![page]!;
  }
}
