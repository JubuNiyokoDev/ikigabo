import 'package:isar/isar.dart';

part 'settings_model.g.dart';

enum AppLanguage {
  kirundi,
  french,
  english,
  swahili,
}

enum ThemeMode {
  light,
  dark,
  system,
}

@collection
class SettingsModel {
  Id id = Isar.autoIncrement;

  @enumerated
  late AppLanguage language;

  @enumerated
  late ThemeMode themeMode;

  late String defaultCurrency;

  late bool notificationsEnabled;

  late bool biometricEnabled;

  late bool autoLockEnabled;

  late int autoLockMinutes;

  late bool showBalanceOnHome;

  late bool enableScreenshot;

  late DateTime createdAt;

  DateTime? updatedAt;

  String? dateFormat;

  String? timeFormat;

  bool? enableBackup;

  String? backupPath;

  int? backupFrequencyDays;

  DateTime? lastBackupDate;

  SettingsModel({
    this.id = Isar.autoIncrement,
    this.language = AppLanguage.french,
    this.themeMode = ThemeMode.system,
    this.defaultCurrency = 'BIF',
    this.notificationsEnabled = true,
    this.biometricEnabled = false,
    this.autoLockEnabled = true,
    this.autoLockMinutes = 5,
    this.showBalanceOnHome = true,
    this.enableScreenshot = false,
    required this.createdAt,
    this.updatedAt,
    this.dateFormat = 'dd/MM/yyyy',
    this.timeFormat = 'HH:mm',
    this.enableBackup = true,
    this.backupPath,
    this.backupFrequencyDays = 7,
    this.lastBackupDate,
  });
}
