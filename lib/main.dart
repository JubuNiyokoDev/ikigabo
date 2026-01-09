import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_icons.dart';
import 'l10n/app_localizations.dart';
import 'l10n/fallback_material_localizations.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/pin_provider.dart';
import 'presentation/providers/banner_provider.dart';
import 'presentation/screens/security/pin_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/sources/sources_list_screen.dart';
import 'presentation/screens/banks/banks_list_screen.dart';
import 'presentation/screens/assets/assets_list_screen.dart';
import 'presentation/screens/debts/debts_list_screen.dart';
import 'presentation/screens/transactions/add_transaction_bottom_sheet.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/stats/stats_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/providers/debt_provider.dart';
import 'presentation/providers/integrated_notification_provider.dart';
import 'presentation/providers/onboarding_provider.dart';
import 'data/services/notification_service.dart';
import 'core/services/real_alarm_service.dart';
import 'presentation/widgets/shimmer_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les services d'alarme et notifications
  await RealAlarmService.initialize();
  await NotificationService().initialize();

  // Configuration edge-to-edge compatible Android 15
  // Ne plus utiliser setSystemUIOverlayStyle qui est déprécié
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  runApp(const ProviderScope(child: IkigaboApp()));
}

class IkigaboApp extends ConsumerWidget {
  const IkigaboApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Ikigabo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr'),
            Locale('en'),
            Locale('rn'),
            Locale('sw'),
          ],
          locale: locale,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            // Pour Kirundi et Swahili, retourner la locale demandée
            // Flutter utilisera le français comme fallback pour Material/Cupertino
            if (locale.languageCode == 'rn' || locale.languageCode == 'sw') {
              // Retourner la locale demandée pour AppLocalizations
              // mais Flutter utilisera 'fr' comme fallback pour Material
              return locale;
            }

            // Pour les autres langues, vérifier si supportée
            for (final supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }

            // Fallback par défaut: français
            return const Locale('fr');
          },
          home: const AppNavigator(),
        );
      },
    );
  }
}

class AppNavigator extends ConsumerWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingCompleteProvider);

    return onboardingAsync.when(
      data: (onboardingComplete) {
        // Si l'onboarding n'est pas complété, l'afficher
        if (!onboardingComplete) {
          return const OnboardingScreen();
        }

        // Sinon, procéder avec la logique PIN
        final pinState = ref.watch(pinProvider);

        switch (pinState) {
          case PinState.loading:
            return const Scaffold(body: Center(child: ShimmerWidget(width: 50, height: 50)));
          case PinState.notSet:
            return PinScreen(
              mode: PinMode.setup,
              onSuccess: () {
                // Le provider gère déjà le changement d'état
              },
            );
          case PinState.required:
            return PinScreen(
              mode: PinMode.verify,
              onSuccess: () {
                // Le provider gère déjà le changement d'état
              },
            );
          case PinState.authenticated:
            return const MainScreen();
        }
      },
      loading: () => const Scaffold(body: Center(child: ShimmerWidget(width: 50, height: 50))),
      error: (error, stackTrace) {
        // En cas d'erreur, afficher l'onboarding par défaut
        return const OnboardingScreen();
      },
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialiser les alarmes et notifications au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(debtAlarmsInitProvider);
      ref.read(notificationWatcherProvider);
      // Initialiser le banner provider
      ref.read(bannerProvider);
    });
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const _NavigationScreen(),
    const DashboardScreen(),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  void _onNavTap(int index) {
    if (index == 2) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AddTransactionBottomSheet(),
      );
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(AppIcons.home, 0),
              _buildNavItem(AppIcons.menu, 1),
              _buildAddButton(),
              _buildNavItem(AppIcons.stats, 3),
              _buildNavItem(AppIcons.settings, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).textTheme.bodySmall?.color;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: color, size: 20.sp),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _onNavTap(2),
      child: Container(
        width: 48.w,
        height: 48.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 10.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Icon(AppIcons.add, color: Colors.white, size: 24.sp),
      ),
    );
  }
}

class _NavigationScreen extends ConsumerWidget {
  const _NavigationScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.management,
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6.h),
              Text(
                l10n.accessAllYourData,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              SizedBox(height: 24.h),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1.1,
                  children: [
                    _NavigationCard(
                      title: l10n.mySources,
                      icon: AppIcons.wallet,
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SourcesListScreen(),
                        ),
                      ),
                    ),
                    _NavigationCard(
                      title: l10n.banks,
                      icon: AppIcons.bank,
                      color: Theme.of(context).colorScheme.secondary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BanksListScreen(),
                        ),
                      ),
                    ),
                    _NavigationCard(
                      title: l10n.assets,
                      icon: AppIcons.assets,
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AssetsListScreen(),
                        ),
                      ),
                    ),
                    _NavigationCard(
                      title: l10n.debts,
                      icon: AppIcons.debt,
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DebtsListScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
