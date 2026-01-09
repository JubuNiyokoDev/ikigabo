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
  static const int _bankAdFrequency = 3;
  static const int _sourceAdFrequency = 3;
  static const int _debtAdFrequency = 3;
  static const int _assetAdFrequency = 3;
  static const int _settingsAdFrequency = 4;
  static const int _dashboardAdFrequency = 8;
  static const int _reportAdFrequency = 5;
  static const int _rewardedAdFrequency = 10;

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

  // Logique commune pour interstitial
  static Future<void> _showAdForAction(String countKey, int frequency) async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(countKey) ?? 0) + 1;
    await prefs.setInt(countKey, count);
    
    // Seulement afficher si la fréquence est atteinte
    if (count % frequency == 0) {
      await AdsService.showInterstitial();
    }
    
    // Incrémenter aussi le compteur rewarded
    showAutoRewardedAd();
  }

  // Logique commune pour rewarded
  static Future<void> _showRewardedForAction(String countKey, int frequency) async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(countKey) ?? 0) + 1;
    await prefs.setInt(countKey, count);
    
    if (count % frequency == 0) {
      await AdsService.showRewarded(onReward: () {
        print('Récompense automatique accordée!');
      });
    }
  }

  // Pub récompensée avant fonctionnalités importantes
  static Future<bool> showRewardedForImportantAction(String actionName) async {
    bool rewardGranted = false;
    
    await AdsService.showRewarded(onReward: () {
      rewardGranted = true;
      print('Récompense accordée pour: $actionName');
    });
    
    return rewardGranted;
  }

  // Actions importantes qui nécessitent une pub récompensée
  static Future<bool> showRewardedForBankCreation() async {
    return await showRewardedForImportantAction('Création banque');
  }

  static Future<bool> showRewardedForLargeTransaction() async {
    return await showRewardedForImportantAction('Transaction importante');
  }

  static Future<bool> showRewardedForDebtCreation() async {
    return await showRewardedForImportantAction('Création dette');
  }

  static Future<bool> showRewardedForAssetCreation() async {
    return await showRewardedForImportantAction('Création asset');
  }

  static Future<bool> showRewardedForReports() async {
    return await showRewardedForImportantAction('Consultation rapports');
  }

  // Nouvelles fonctionnalités riches
  static Future<bool> showRewardedForImportExport() async {
    return await showRewardedForImportantAction('Import/Export données');
  }

  static Future<bool> showRewardedForPinSetup() async {
    return await showRewardedForImportantAction('Configuration PIN');
  }
}