import 'package:isar_community/isar.dart';

part 'security_model.g.dart';

enum SecurityType {
  pin,
  password,
  biometric,
  none,
}

@collection
class SecurityModel {
  Id id = Isar.autoIncrement;

  @enumerated
  late SecurityType securityType;

  String? pinHash;

  String? passwordHash;

  late bool biometricEnabled;

  late int failedAttempts;

  late int maxFailedAttempts;

  DateTime? lockedUntil;

  DateTime? lastSuccessfulLogin;

  DateTime? lastFailedLogin;

  late DateTime createdAt;

  DateTime? updatedAt;

  String? salt;

  late bool requireSecurityOnStart;

  late bool requireSecurityOnTransaction;

  SecurityModel({
    this.id = Isar.autoIncrement,
    this.securityType = SecurityType.none,
    this.pinHash,
    this.passwordHash,
    this.biometricEnabled = false,
    this.failedAttempts = 0,
    this.maxFailedAttempts = 5,
    this.lockedUntil,
    this.lastSuccessfulLogin,
    this.lastFailedLogin,
    required this.createdAt,
    this.updatedAt,
    this.salt,
    this.requireSecurityOnStart = true,
    this.requireSecurityOnTransaction = false,
  });

  bool get isLocked {
    if (lockedUntil == null) return false;
    if (DateTime.now().isBefore(lockedUntil!)) return true;
    return false;
  }

  int get remainingLockMinutes {
    if (lockedUntil == null) return 0;
    final diff = lockedUntil!.difference(DateTime.now());
    return diff.inMinutes;
  }

  void recordFailedAttempt() {
    failedAttempts++;
    lastFailedLogin = DateTime.now();

    if (failedAttempts >= maxFailedAttempts) {
      final lockDuration = Duration(minutes: failedAttempts * 5);
      lockedUntil = DateTime.now().add(lockDuration);
    }

    updatedAt = DateTime.now();
  }

  void recordSuccessfulLogin() {
    failedAttempts = 0;
    lockedUntil = null;
    lastSuccessfulLogin = DateTime.now();
    updatedAt = DateTime.now();
  }
}
