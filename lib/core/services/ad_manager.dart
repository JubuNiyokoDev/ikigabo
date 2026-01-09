import 'package:shared_preferences/shared_preferences.dart';
import 'ads_service.dart';

class AdManager {
  // Compteurs pour différentes actions
  static const String _bankActionCount = 'bank_action_count';
  static const String _sourceActionCount = 'source_action_count';
  static const String _debtActionCount = 'debt_action_count';
  static const String _assetActionCount = 'asset_action_count';
  static const String _settingsOpenCount = 'settings_open_count';
  static const String _dashboardOpenCount = 'dashboard_open_count';
  static const String _reportViewCount = 'report_view_count';
  static const String _rewardedActionCount = 'rewarded_action_count';

  // Fréquences d'affichage (tous les X actions)
  static const int _bankAdFrequency = 10;
  static const int _sourceAdFrequency = 10;
  static const int _debtAdFrequency = 10;
  static const int _assetAdFrequency = 10;
  static const int _settingsAdFrequency = 10;
  static const int _dashboardAdFrequency = 10;
  static const int _reportAdFrequency = 10;
  static const int _rewardedAdFrequency = 15;

  // Banques (ajout/modification)
  static Future<void> showBankAd() async {
    await _showAdForAction(_bankActionCount, _bankAdFrequency);
  }

  // Sources (ajout/modification)
  static Future<void> showSourceAd() async {
    await _showAdForAction(_sourceActionCount, _sourceAdFrequency);
  }

  // Dettes (ajout/modification/paiement)
  static Future<void> showDebtAd() async {
    await _showAdForAction(_debtActionCount, _debtAdFrequency);
  }

  // Assets (ajout/modification)
  static Future<void> showAssetAd() async {
    await _showAdForAction(_assetActionCount, _assetAdFrequency);
  }

  // Settings (ouverture)
  static Future<void> showSettingsAd() async {
    await _showAdForAction(_settingsOpenCount, _settingsAdFrequency);
  }

  // Dashboard (ouverture app)
  static Future<void> showDashboardAd() async {
    await _showAdForAction(_dashboardOpenCount, _dashboardAdFrequency);
  }

  // Rapports/Statistiques
  static Future<void> showReportAd() async {
    await _showAdForAction(_reportViewCount, _reportAdFrequency);
  }

  // Rewarded automatique (toutes les 10 actions globales)
  static Future<void> showAutoRewardedAd() async {
    await _showRewardedForAction(_rewardedActionCount, _rewardedAdFrequency);
  }

  // Logique commune pour interstitial (simple et efficace)
  static Future<void> _showAdForAction(String countKey, int frequency) async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(countKey) ?? 0) + 1;
    await prefs.setInt(countKey, count);

    print('Action $countKey: $count/$frequency');

    // Afficher ad si fréquence atteinte
    if (count % frequency == 0) {
      print('Tentative d\'affichage interstitial pour $countKey');
      try {
        await AdsService.showInterstitial();
        print('Interstitial affichée avec succès');
      } catch (e) {
        print('Erreur interstitial: $e');
      }
    }

    // Incrémenter compteur rewarded
    showAutoRewardedAd();
  }

  // Logique commune pour rewarded automatique (simple)
  static Future<void> _showRewardedForAction(
    String countKey,
    int frequency,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(countKey) ?? 0) + 1;
    await prefs.setInt(countKey, count);

    print('Rewarded auto $countKey: $count/$frequency');

    if (count % frequency == 0) {
      print('Tentative rewarded automatique');
      try {
        await AdsService.showRewarded(
          onReward: () {
            print('Récompense automatique accordée!');
          },
        );
      } catch (e) {
        print('Erreur rewarded auto: $e');
      }
    }
  }

  // Pub récompensée pour fonctionnalités importantes (simple avec cooldown)
  static Future<bool> showRewardedForImportantAction(String actionName) async {
    final prefs = await SharedPreferences.getInstance();
    final lastRewardedKey = 'last_rewarded_$actionName';
    final lastRewarded = prefs.getInt(lastRewardedKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Cooldown 5 minutes
    if (now - lastRewarded < 5 * 60 * 1000) {
      print('Cooldown actif pour $actionName - Autorisation directe');
      return true;
    }

    print('Tentative rewarded pour $actionName');
    bool rewardGranted = false;

    try {
      await AdsService.showRewarded(
        onReward: () {
          rewardGranted = true;
          prefs.setInt(lastRewardedKey, now);
          print('Récompense accordée pour $actionName');
        },
      );

      // Si pas de récompense après 5 sec, autoriser
      if (!rewardGranted) {
        await Future.delayed(const Duration(seconds: 5));
        print('Timeout pour $actionName - Autorisation accordée');
        return true;
      }
    } catch (e) {
      print('Erreur rewarded $actionName: $e - Autorisation accordée');
      return true;
    }

    return rewardGranted;
  }

  // Actions importantes qui nécessitent une pub récompensée (avec cooldown)
  static Future<bool> showRewardedForBankCreation() async {
    return await showRewardedForImportantAction('bank_creation');
  }

  static Future<bool> showRewardedForLargeTransaction() async {
    return await showRewardedForImportantAction('large_transaction');
  }

  static Future<bool> showRewardedForDebtCreation() async {
    return await showRewardedForImportantAction('debt_creation');
  }

  static Future<bool> showRewardedForAssetCreation() async {
    return await showRewardedForImportantAction('asset_creation');
  }

  static Future<bool> showRewardedForReports() async {
    return await showRewardedForImportantAction('reports_access');
  }

  // Nouvelles fonctionnalités riches (avec cooldown)
  static Future<bool> showRewardedForImportExport() async {
    return await showRewardedForImportantAction('import_export');
  }

  static Future<bool> showRewardedForPinSetup() async {
    return await showRewardedForImportantAction('pin_setup');
  }
}
