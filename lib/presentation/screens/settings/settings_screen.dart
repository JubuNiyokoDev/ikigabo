import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ikigabo/presentation/providers/isar_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/currencies.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/currency_provider.dart' hide preferencesServiceProvider;
import '../../providers/pin_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../providers/source_provider.dart';
import '../../providers/bank_provider.dart';
import '../../providers/asset_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/transaction_provider.dart'
    hide thisMonthIncomeProvider, thisMonthExpenseProvider;
import '../../providers/dashboard_provider.dart';
import '../notifications/notification_settings_screen.dart';
import '../backup/backup_screen.dart';
import '../categories/categories_management_screen.dart';
import '../budgets/budgets_screen.dart';
import '../security/pin_screen.dart';
import '../../../core/services/ad_manager.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir le lien: $url')),
      );
    }
  }

  Future<void> _shareApp() async {
    await Share.share(
      'Découvrez Ikigabo - Gestion de patrimoine personnel\n'
      'https://play.google.com/store/apps/details?id=com.ikigabo.ikigabo',
      subject: 'Ikigabo App',
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    await _launchUrl(
      context,
      'https://play.google.com/store/apps/details?id=com.ikigabo.ikigabo',
    );
  }

  Future<void> _reportProblem(BuildContext context) async {
    try {
      final uri = Uri(
        scheme: 'mailto',
        path: 'niyondikojoffreasjubu@gmail.com',
        queryParameters: {
          'subject': 'Problème Ikigabo',
          'body': 'Décrivez votre problème...',
        },
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'No email app found';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email: niyondikojoffreasjubu@gmail.com'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final languages = [
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'rn', 'name': 'Kirundi', 'flag': '🇧🇮'},
      {'code': 'sw', 'name': 'Kiswahili', 'flag': '🇹🇿'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondaryDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.chooseLanguage,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ...languages.map(
              (lang) => ListTile(
                leading: Text(
                  lang['flag']!,
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text(
                  lang['name']!,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(lang['code']!);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPinOptions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefsService = ref.read(preferencesServiceProvider).value;
    final hasPinSaved = prefsService?.getSavedPin() != null;
    final themeMode = ref.read(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.textSecondaryDark : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.pinCode,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (hasPinSaved) ...[
              ListTile(
                leading: const Icon(AppIcons.edit, color: AppColors.primary),
                title: Text(
                  l10n.changePin,
                  style: TextStyle(
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _changePinFlow(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(AppIcons.delete, color: AppColors.error),
                title: Text(
                  l10n.disablePin,
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showPinVerificationDialog(context, ref);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(AppIcons.add, color: AppColors.primary),
                title: Text(
                  l10n.setupPin,
                  style: TextStyle(
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PinScreen(mode: PinMode.setup),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _changePinFlow(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinScreen(
          mode: PinMode.setup,
          onSuccess: () {}, // Callback vide pour éviter l'erreur
        ),
      ),
    );
  }

  void _showPinVerificationDialog(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (pinContext) => PinScreen(
          mode: PinMode.verify,
          onSuccess: () {
            Navigator.pop(pinContext);
            ref.read(pinProvider.notifier).disablePin();
          },
        ),
      ),
    );
  }

  void _showCurrencySelector(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final displayCurrencyAsync = ref.read(displayCurrencyProvider);
    final currentCurrency = displayCurrencyAsync.when(
      data: (curr) => curr,
      loading: () => AppCurrencies.bif,
      error: (_, __) => AppCurrencies.bif,
    );
    final themeMode = ref.read(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.defaultCurrency,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.grey[900],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: AppCurrencies.all.length,
                  itemBuilder: (context, index) {
                    final currency = AppCurrencies.all[index];
                    final isSelected = currentCurrency.code == currency.code;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: AppColors.primary, width: 1.5)
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : (isDark
                                      ? AppColors.backgroundDark
                                      : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              currency.flag,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        title: Text(
                          currency.getName(context),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textDark
                                : Colors.grey[900],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${currency.code} (${currency.symbol})',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 22,
                              )
                            : null,
                        onTap: () {
                          ref
                              .read(currencyControllerProvider.notifier)
                              .setDisplayCurrency(currency.code);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAllDataDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          l10n.deleteAllData,
          style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
        ),
        content: Text(
          l10n.deleteAllDataConfirmation,
          style: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _authenticateAndDelete(context, ref, l10n);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _authenticateAndDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    // Vérifier biométrie d'abord
    final biometricState = ref.read(biometricProvider);
    if (biometricState == BiometricState.enabled) {
      final success = await ref
          .read(biometricProvider.notifier)
          .authenticateWithBiometric();
      if (success) {
        _deleteAllData(context, ref, l10n);
        return;
      }
    }

    // Sinon vérifier PIN
    final prefsService = ref.read(preferencesServiceProvider).value;
    if (prefsService?.isPinEnabled() == true) {
      final navigator = Navigator.of(context); // Sauvegarder la référence

      navigator.push(
        MaterialPageRoute(
          builder: (_) => PinScreen(
            mode: PinMode.verify,
            onSuccess: () {
              navigator.pop(); // Utiliser la référence sauvegardée
              _deleteAllData(context, ref, l10n);
            },
          ),
        ),
      );
      return;
    }

    // Aucune sécurité configurée, supprimer directement
    _deleteAllData(context, ref, l10n);
  }

  void _deleteAllData(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    try {
      // Supprimer toutes les données de la base
      final isar = ref.read(isarProvider).value;
      if (isar != null) {
        await isar.writeTxn(() async {
          await isar.clear();
        });
      }

      // Réinitialiser les préférences (garder seulement langue et thème)
      final prefsService = ref.read(preferencesServiceProvider).value;
      final currentLocale = ref.read(localeProvider).languageCode;
      final currentTheme = ref.read(themeProvider);

      await prefsService?.clearAllData();
      await prefsService?.setLanguage(currentLocale);
      await prefsService?.setThemeMode(currentTheme);

      // Invalider tous les providers pour forcer le refresh
      ref.invalidate(sourcesStreamProvider);
      ref.invalidate(banksStreamProvider);
      ref.invalidate(assetsStreamProvider);
      ref.invalidate(debtsStreamProvider);
      ref.invalidate(transactionsStreamProvider);
      ref.invalidate(totalWealthProvider);
      ref.invalidate(thisMonthIncomeProvider);
      ref.invalidate(thisMonthExpenseProvider);
      ref.invalidate(weeklyActivityProvider);
      ref.invalidate(monthlyGrowthProvider);
      ref.invalidate(assetsVsLiabilitiesProvider);

      // Afficher message de succès
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.allDataDeleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Déclencher ads settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdManager.showSettingsAd();
    });

    final themeMode = ref.watch(themeProvider);
    final currentLocale = ref.watch(localeProvider);
    final displayCurrencyAsync = ref.watch(displayCurrencyProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = themeMode == ThemeMode.dark;

    final languageNames = {
      'fr': 'Français',
      'en': 'English',
      'rn': 'Kirundi',
      'sw': 'Kiswahili',
    };

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(isDark, l10n),
            const SizedBox(height: 20),

            // Général
            _buildSection(l10n.general, isDark),
            _buildSettingTile(
              icon: AppIcons.language,
              title: l10n.language,
              subtitle: languageNames[currentLocale.languageCode] ?? 'Français',
              onTap: () => _showLanguageSelector(context, ref),
              isDark: isDark,
            ).animate().fadeIn(delay: 100.ms),
            _buildSettingTile(
              icon: AppIcons.theme,
              title: l10n.theme,
              subtitle: isDark ? l10n.dark : l10n.light,
              trailing: Switch(
                value: isDark,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
                activeTrackColor: AppColors.primary,
              ),
              isDark: isDark,
            ).animate().fadeIn(delay: 200.ms),
            _buildSettingTile(
              icon: AppIcons.money,
              title: l10n.defaultCurrency,
              subtitle: displayCurrencyAsync.when(
                data: (currency) =>
                    '${currency.flag} ${currency.getName(context)} (${currency.symbol})',
                loading: () => '🇧🇮 Franc Burundais (FBu)',
                error: (_, __) => '🇧🇮 Franc Burundais (FBu)',
              ),
              onTap: () => _showCurrencySelector(context, ref),
              isDark: isDark,
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 20),

            // Transactions
            _buildSection(l10n.transactions, isDark),
            _buildSettingTile(
              icon: AppIcons.filter,
              title: l10n.category,
              subtitle: l10n.manageCategoriesSubtitle,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CategoriesManagementScreen(),
                  ),
                );
              },
              isDark: isDark,
            ).animate().fadeIn(delay: 350.ms),
            _buildSettingTile(
              icon: AppIcons.chart,
              title: l10n.budgetsAndGoals,
              subtitle: l10n.manageFinancialGoals,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BudgetsScreen()),
                );
              },
              isDark: isDark,
            ).animate().fadeIn(delay: 375.ms),

            const SizedBox(height: 20),

            // Sécurité
            _buildSection(l10n.security, isDark),
            _buildSettingTile(
              icon: AppIcons.lock,
              title: l10n.pinCode,
              subtitle: l10n.changePinCode,
              onTap: () => _showPinOptions(context, ref),
              isDark: isDark,
            ).animate().fadeIn(delay: 400.ms),
            Consumer(
              builder: (context, ref, child) {
                final biometricState = ref.watch(biometricProvider);
                final isEnabled = biometricState == BiometricState.enabled;
                final isAvailable =
                    biometricState != BiometricState.unavailable;

                return _buildSettingTile(
                  icon: AppIcons.fingerprint,
                  title: l10n.biometricAuth,
                  subtitle: l10n.fingerprint,
                  trailing: Switch(
                    value: isEnabled,
                    onChanged: isAvailable
                        ? (value) async {
                            print('Biometric toggle: $value'); // Debug
                            if (value) {
                              final success = await ref
                                  .read(biometricProvider.notifier)
                                  .enableBiometric();
                              print('Enable result: $success'); // Debug
                            } else {
                              // Demander authentification avant de désactiver
                              final authenticated = await ref
                                  .read(biometricProvider.notifier)
                                  .authenticateWithBiometric();
                              if (authenticated) {
                                final success = await ref
                                    .read(biometricProvider.notifier)
                                    .disableBiometric();
                                print('Disable result: $success'); // Debug
                              }
                            }
                          }
                        : null,
                    activeTrackColor: AppColors.primary,
                  ),
                  isDark: isDark,
                );
              },
            ).animate().fadeIn(delay: 500.ms),
            _buildSettingTile(
              icon: AppIcons.notification,
              title: l10n.notifications,
              subtitle: l10n.manageNotifications,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                );
              },
              isDark: isDark,
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 20),

            // Données
            _buildSection(l10n.data, isDark),
            Consumer(
              builder: (context, ref, child) {
                final prefsService = ref
                    .watch(preferencesServiceProvider)
                    .value;
                final isEnabled = prefsService?.isAutoBackupEnabled() ?? true;

                return _buildSettingTile(
                  icon: AppIcons.backup,
                  title: l10n.autoBackup,
                  subtitle: l10n.enableBackup,
                  trailing: Switch(
                    value: isEnabled,
                    onChanged: (value) {
                      prefsService?.setAutoBackupEnabled(value);
                    },
                    activeTrackColor: AppColors.primary,
                  ),
                  isDark: isDark,
                );
              },
            ).animate().fadeIn(delay: 700.ms),
            _buildSettingTile(
              icon: AppIcons.export,
              title: l10n.backupRestore,
              subtitle: l10n.manageBackups,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BackupScreen()),
                );
              },
              isDark: isDark,
            ).animate().fadeIn(delay: 800.ms),

            const SizedBox(height: 20),

            // Support
            _buildSection(l10n.support, isDark),
            _buildSettingTile(
              icon: AppIcons.warning,
              title: l10n.reportProblem,
              subtitle: l10n.reportProblemSubtitle,
              onTap: () => _reportProblem(context),
              isDark: isDark,
            ).animate().fadeIn(delay: 900.ms),
            _buildSettingTile(
              icon: AppIcons.success,
              title: l10n.rateThisApp,
              subtitle: l10n.rateOnPlayStore,
              onTap: () => _rateApp(context),
              isDark: isDark,
            ).animate().fadeIn(delay: 920.ms),
            _buildSettingTile(
              icon: AppIcons.export,
              title: l10n.shareThisApp,
              subtitle: l10n.shareWithFriends,
              onTap: _shareApp,
              isDark: isDark,
            ).animate().fadeIn(delay: 940.ms),
            _buildSettingTile(
              icon: AppIcons.menu,
              title: l10n.moreApps,
              subtitle: l10n.discoverOtherApps,
              onTap: () => _launchUrl(
                context,
                'https://play.google.com/store/apps/dev?id=RundiNova',
              ),
              isDark: isDark,
            ).animate().fadeIn(delay: 960.ms),

            const SizedBox(height: 20),

            // Légal
            _buildSection(l10n.legal, isDark),
            _buildSettingTile(
              icon: AppIcons.info,
              title: l10n.version,
              subtitle: '1.0.0 (1)',
              isDark: isDark,
            ).animate().fadeIn(delay: 980.ms),
            _buildSettingTile(
              icon: AppIcons.note,
              title: l10n.termsAndConditions,
              subtitle: l10n.termsOfUse,
              onTap: () => _launchUrl(
                context,
                'https://jubuniyokodev.github.io/ikigabo/terms.html',
              ),
              isDark: isDark,
            ).animate().fadeIn(delay: 1000.ms),
            _buildSettingTile(
              icon: AppIcons.security,
              title: l10n.privacyPolicy,
              subtitle: l10n.privacyPolicySubtitle,
              onTap: () => _launchUrl(
                context,
                'https://jubuniyokodev.github.io/ikigabo/privacy-policy.html',
              ),
              isDark: isDark,
            ).animate().fadeIn(delay: 1020.ms),

            const SizedBox(height: 16),

            // Danger Zone
            _buildDangerZone(
              isDark,
              l10n,
              context,
              ref,
            ).animate().fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settings,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textDark : Colors.black87,
          ),
        ).animate().fadeIn(delay: 50.ms),
        const SizedBox(height: 6),
        Text(
          l10n.manageYourApp,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textSecondaryDark : Colors.black54,
          ),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildSection(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textSecondaryDark : Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textDark : Colors.black87,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (onTap != null)
                  Icon(
                    AppIcons.back,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.black54,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone(
    bool isDark,
    AppLocalizations l10n,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.warning, color: AppColors.error, size: 24),
              const SizedBox(width: 8),
              Text(
                l10n.dangerZone,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              _showDeleteAllDataDialog(context, ref, l10n, isDark);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: EdgeInsets.zero,
            ),
            child: Text(l10n.deleteAllData),
          ),
        ],
      ),
    );
  }
}
