import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../models/asset_model.dart';
import '../models/bank_model.dart';
import '../models/debt_model.dart';
import '../models/source_model.dart' as src;
import '../models/transaction_model.dart' as tx;
import '../repositories/asset_repository.dart';
import '../repositories/bank_repository.dart';
import '../repositories/debt_repository.dart';
import '../repositories/source_repository.dart';
import '../repositories/transaction_repository.dart';

enum ImportConflictStrategy { skipExisting, overwrite, smartMerge }

class BackupService {
  static const int _encryptionVersion = 2;
  static const int _pbkdf2Iterations = 100000;
  static const int _aesKeyLength = 32;

  final SourceRepository _sourceRepository;
  final TransactionRepository _transactionRepository;
  final DebtRepository _debtRepository;
  final AssetRepository _assetRepository;
  final BankRepository _bankRepository;

  BackupService({
    required SourceRepository sourceRepository,
    required TransactionRepository transactionRepository,
    required DebtRepository debtRepository,
    required AssetRepository assetRepository,
    required BankRepository bankRepository,
  }) : _sourceRepository = sourceRepository,
       _transactionRepository = transactionRepository,
       _debtRepository = debtRepository,
       _assetRepository = assetRepository,
       _bankRepository = bankRepository;

  // Export all data to encrypted JSON.
  Future<String> exportData({String? password}) async {
    final data = <String, dynamic>{
      'version': '2.0',
      'timestamp': DateTime.now().toIso8601String(),
      'sources': await _exportSources(),
      'transactions': await _exportTransactions(),
      'debts': await _exportDebts(),
      'assets': await _exportAssets(),
      'banks': await _exportBanks(),
    };

    final jsonString = jsonEncode(data);
    if (password != null && password.isNotEmpty) {
      return _encryptData(jsonString, password);
    }
    return jsonString;
  }

  // Import data from encrypted JSON.
  Future<ImportResult> importData(String data, {String? password}) async {
    try {
      if (_isEncryptedPayload(data) && (password == null || password.isEmpty)) {
        return ImportResult(
          success: false,
          error: 'Cette sauvegarde est protégée par mot de passe',
        );
      }

      var jsonString = data;
      if (password != null && password.isNotEmpty) {
        jsonString = _decryptData(data, password);
      }

      final importData = jsonDecode(jsonString);
      if (importData is! Map<String, dynamic>) {
        return ImportResult(
          success: false,
          error: 'Format de sauvegarde invalide',
        );
      }

      if (!_validateBackupFormat(importData)) {
        return ImportResult(
          success: false,
          error: 'Format de sauvegarde invalide',
        );
      }

      final conflicts = await _detectConflicts(importData);
      return ImportResult(
        success: true,
        conflicts: conflicts,
        data: importData,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Erreur lors de l\'importation: $e',
      );
    }
  }

  // Apply import data.
  Future<void> applyImport(
    Map<String, dynamic> data, {
    bool overwriteConflicts = false,
    ImportConflictStrategy strategy = ImportConflictStrategy.skipExisting,
  }) async {
    final effectiveStrategy = overwriteConflicts
        ? ImportConflictStrategy.overwrite
        : strategy;
    final sourceIdMap = <int, int>{};
    final bankIdMap = <int, int>{};
    final assetIdMap = <int, int>{};
    final debtIdMap = <int, int>{};

    if (data['sources'] is List<dynamic>) {
      sourceIdMap.addAll(
        await _importSources(
          data['sources'] as List<dynamic>,
          effectiveStrategy,
        ),
      );
    }
    if (data['banks'] is List<dynamic>) {
      bankIdMap.addAll(
        await _importBanks(data['banks'] as List<dynamic>, effectiveStrategy),
      );
    }
    if (data['assets'] is List<dynamic>) {
      assetIdMap.addAll(
        await _importAssets(data['assets'] as List<dynamic>, effectiveStrategy),
      );
    }
    if (data['debts'] is List<dynamic>) {
      debtIdMap.addAll(
        await _importDebts(data['debts'] as List<dynamic>, effectiveStrategy),
      );
    }
    if (data['transactions'] is List<dynamic>) {
      await _importTransactions(
        data['transactions'] as List<dynamic>,
        effectiveStrategy,
        sourceIdMap: sourceIdMap,
        bankIdMap: bankIdMap,
        assetIdMap: assetIdMap,
        debtIdMap: debtIdMap,
      );
    }
  }

  // Save backup using Storage Access Framework (SAF).
  Future<String> saveBackupToStorage(String backupData) async {
    try {
      final now = DateTime.now();
      final dateFormat = DateFormat('dd-MMM-yyyy_HH\'h\'mm');
      final readableDate = dateFormat.format(now);

      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Sauvegarder la sauvegarde Ikigabo',
        fileName: 'ikigabo_backup_$readableDate.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(backupData),
      );

      if (outputFile == null) {
        throw Exception('Sauvegarde annulée par l\'utilisateur');
      }
      return outputFile;
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  // Import backup from file picker.
  Future<String?> loadBackupFromStorage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Sélectionner une sauvegarde Ikigabo',
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return file.readAsString();
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors du chargement: $e');
    }
  }

  String _encryptData(String data, String password) {
    final salt = _randomBytes(16);
    final ivBytes = _randomBytes(16);
    final keyBytes = _deriveKey(
      password: password,
      salt: salt,
      iterations: _pbkdf2Iterations,
      keyLength: _aesKeyLength,
    );

    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt.IV(Uint8List.fromList(ivBytes));
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    final encrypted = encrypter.encrypt(data, iv: iv);

    final payload = <String, dynamic>{
      'encrypted': true,
      'version': _encryptionVersion,
      'algorithm': 'AES-CBC-PBKDF2-SHA256',
      'iterations': _pbkdf2Iterations,
      'salt': base64Encode(salt),
      'iv': base64Encode(ivBytes),
      'ciphertext': encrypted.base64,
    };

    return jsonEncode(payload);
  }

  String _decryptData(String encryptedData, String password) {
    // Format sécurisé v2.
    try {
      final parsed = jsonDecode(encryptedData);
      if (parsed is Map<String, dynamic> && parsed['encrypted'] == true) {
        final iterations = _toInt(parsed['iterations']) ?? _pbkdf2Iterations;
        final saltB64 = parsed['salt'] as String?;
        final ivB64 = parsed['iv'] as String?;
        final cipherText = parsed['ciphertext'] as String?;

        if (saltB64 == null || ivB64 == null || cipherText == null) {
          throw Exception('Données chiffrées incomplètes');
        }

        final salt = base64Decode(saltB64);
        final ivBytes = base64Decode(ivB64);
        final keyBytes = _deriveKey(
          password: password,
          salt: salt,
          iterations: iterations,
          keyLength: _aesKeyLength,
        );

        final key = encrypt.Key(Uint8List.fromList(keyBytes));
        final iv = encrypt.IV(Uint8List.fromList(ivBytes));
        final encrypter = encrypt.Encrypter(
          encrypt.AES(key, mode: encrypt.AESMode.cbc),
        );
        return encrypter.decrypt64(cipherText, iv: iv);
      }
    } catch (_) {
      // Fallback ci-dessous (format legacy).
    }

    // Compatibilité legacy: ancien pseudo-chiffrement base64.
    try {
      return utf8.decode(base64Decode(encryptedData));
    } catch (e) {
      throw Exception('Mot de passe incorrect ou données corrompues');
    }
  }

  bool _isEncryptedPayload(String data) {
    try {
      final parsed = jsonDecode(data);
      return parsed is Map<String, dynamic> && parsed['encrypted'] == true;
    } catch (_) {
      return false;
    }
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  List<int> _deriveKey({
    required String password,
    required List<int> salt,
    required int iterations,
    required int keyLength,
  }) {
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, passwordBytes);
    const hashLength = 32; // SHA256 output
    final blockCount = (keyLength / hashLength).ceil();
    final output = BytesBuilder();

    for (var block = 1; block <= blockCount; block++) {
      final initial = <int>[...salt, ..._int32BigEndian(block)];
      var u = hmac.convert(initial).bytes;
      final t = List<int>.from(u);

      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }

      output.add(t);
    }

    return output.toBytes().sublist(0, keyLength);
  }

  List<int> _int32BigEndian(int value) {
    return <int>[
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
  }

  bool _validateBackupFormat(Map<String, dynamic> data) {
    return data.containsKey('version') &&
        data.containsKey('timestamp') &&
        data.containsKey('sources');
  }

  Future<List<String>> _detectConflicts(Map<String, dynamic> data) async {
    final conflicts = <String>[];
    final existingSources = await _sourceRepository.getAllSources();
    final existingTransactions = await _transactionRepository
        .getAllTransactions();
    final existingDebts = await _debtRepository.watchDebts().first;
    final existingAssets = await _assetRepository.watchAssets().first;
    final existingBanks = await _bankRepository.watchBanks().first;

    if (existingSources.isNotEmpty && data['sources'] != null) {
      conflicts.add('Sources existantes détectées');
    }
    if (existingTransactions.isNotEmpty && data['transactions'] != null) {
      conflicts.add('Transactions existantes détectées');
    }
    if (existingDebts.isNotEmpty && data['debts'] != null) {
      conflicts.add('Dettes existantes détectées');
    }
    if (existingAssets.isNotEmpty && data['assets'] != null) {
      conflicts.add('Actifs existants détectés');
    }
    if (existingBanks.isNotEmpty && data['banks'] != null) {
      conflicts.add('Banques existantes détectées');
    }

    return conflicts;
  }

  Future<List<Map<String, dynamic>>> _exportSources() async {
    final sources = await _sourceRepository.getAllSources();
    return sources
        .map(
          (s) => <String, dynamic>{
            'id': s.id,
            'name': s.name,
            'type': s.type.name,
            'amount': s.amount,
            'currency': s.currency,
            'isActive': s.isActive,
            'isPassive': s.isPassive,
            'description': s.description,
            'iconName': s.iconName,
            'color': s.color,
            'isDeleted': s.isDeleted,
            'createdAt': s.createdAt.toIso8601String(),
            'updatedAt': s.updatedAt?.toIso8601String(),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _exportTransactions() async {
    final transactions = await _transactionRepository.getAllTransactions();
    return transactions
        .map(
          (t) => <String, dynamic>{
            'id': t.id,
            'type': t.type.name,
            'incomeCategory': t.incomeCategory.name,
            'expenseCategory': t.expenseCategory.name,
            'amount': t.amount,
            'currency': t.currency,
            'sourceId': t.sourceId,
            'sourceName': t.sourceName,
            'sourceType': t.sourceType.name,
            'targetSourceId': t.targetSourceId,
            'targetSourceName': t.targetSourceName,
            'targetSourceType': t.targetSourceType?.name,
            'date': t.date.toIso8601String(),
            'createdAt': t.createdAt.toIso8601String(),
            'updatedAt': t.updatedAt?.toIso8601String(),
            'description': t.description,
            'note': t.note,
            'attachmentPath': t.attachmentPath,
            'isDeleted': t.isDeleted,
            'status': t.status.name,
            'isRecurring': t.isRecurring,
            'recurringPattern': t.recurringPattern,
            'recurringEndDate': t.recurringEndDate?.toIso8601String(),
            'relatedDebtId': t.relatedDebtId,
            'relatedAssetId': t.relatedAssetId,
            'relatedBankId': t.relatedBankId,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _exportDebts() async {
    final debts = await _debtRepository.watchDebts().first;
    return debts
        .map(
          (d) => <String, dynamic>{
            'id': d.id,
            'type': d.type.name,
            'personName': d.personName,
            'personContact': d.personContact,
            'totalAmount': d.totalAmount,
            'paidAmount': d.paidAmount,
            'currency': d.currency,
            'date': d.date.toIso8601String(),
            'dueDate': d.dueDate?.toIso8601String(),
            'status': d.status.name,
            'createdAt': d.createdAt.toIso8601String(),
            'updatedAt': d.updatedAt?.toIso8601String(),
            'description': d.description,
            'notes': d.notes,
            'isDeleted': d.isDeleted,
            'relatedTransactionId': d.relatedTransactionId,
            'paymentTransactionIds': d.paymentTransactionIds,
            'hasInterest': d.hasInterest,
            'interestRate': d.interestRate,
            'collateral': d.collateral,
            'hasReminder': d.hasReminder,
            'reminderDateTime': d.reminderDateTime?.toIso8601String(),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _exportAssets() async {
    final assets = await _assetRepository.watchAssets().first;
    return assets
        .map(
          (a) => <String, dynamic>{
            'id': a.id,
            'name': a.name,
            'type': a.type.name,
            'purchasePrice': a.purchasePrice,
            'currentValue': a.currentValue,
            'quantity': a.quantity,
            'unit': a.unit,
            'currency': a.currency,
            'purchaseDate': a.purchaseDate.toIso8601String(),
            'status': a.status.name,
            'createdAt': a.createdAt.toIso8601String(),
            'updatedAt': a.updatedAt?.toIso8601String(),
            'description': a.description,
            'location': a.location,
            'notes': a.notes,
            'isDeleted': a.isDeleted,
            'relatedTransactionId': a.relatedTransactionId,
            'soldDate': a.soldDate?.toIso8601String(),
            'soldPrice': a.soldPrice,
            'imagePaths': a.imagePaths,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _exportBanks() async {
    final banks = await _bankRepository.watchBanks().first;
    return banks
        .map(
          (b) => <String, dynamic>{
            'id': b.id,
            'name': b.name,
            'balance': b.balance,
            'currency': b.currency,
            'type': b.bankType.name,
            'interestType': b.interestType.name,
            'interestCalculation': b.interestCalculation.name,
            'interestValue': b.interestValue,
            'nextDeductionDate': b.nextDeductionDate?.toIso8601String(),
            'lastDeductionDate': b.lastDeductionDate?.toIso8601String(),
            'createdAt': b.createdAt.toIso8601String(),
            'updatedAt': b.updatedAt?.toIso8601String(),
            'description': b.description,
            'accountNumber': b.accountNumber,
            'iconName': b.iconName,
            'color': b.color,
            'isActive': b.isActive,
            'isDeleted': b.isDeleted,
          },
        )
        .toList();
  }

  Future<Map<int, int>> _importSources(
    List<dynamic> sourcesData,
    ImportConflictStrategy strategy,
  ) async {
    final isar = _sourceRepository.isar;
    final overwrite = strategy == ImportConflictStrategy.overwrite;
    final smartMerge = strategy == ImportConflictStrategy.smartMerge;
    final existingSources = overwrite
        ? <src.SourceModel>[]
        : await _sourceRepository.getAllSources();
    final idMap = <int, int>{};

    for (final sourceData in sourcesData) {
      if (sourceData is! Map<String, dynamic>) continue;

      final source = src.SourceModel(
        name: sourceData['name'] as String? ?? '',
        type: _parseEnum(
          src.SourceType.values,
          sourceData['type'],
          src.SourceType.custom,
        ),
        amount: _toDouble(sourceData['amount']) ?? 0.0,
        currency: sourceData['currency'] as String? ?? 'BIF',
        isActive: _toBool(sourceData['isActive']) ?? true,
        isPassive: _toBool(sourceData['isPassive']) ?? false,
        createdAt: _parseDate(sourceData['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDate(sourceData['updatedAt']),
        description: sourceData['description'] as String?,
        iconName: sourceData['iconName'] as String?,
        color: sourceData['color'] as String?,
        isDeleted: _toBool(sourceData['isDeleted']) ?? false,
      );

      final importedId = _toInt(sourceData['id']);

      if (smartMerge) {
        final byNaturalKey = existingSources.where(
          (s) =>
              _sameText(s.name, source.name) &&
              s.type == source.type &&
              _sameText(s.currency, source.currency),
        );
        final byId = importedId == null
            ? null
            : await isar.sourceModels.get(importedId);
        final existing = byNaturalKey.isNotEmpty
            ? byNaturalKey.first
            : (byId != null && _sameText(byId.name, source.name) ? byId : null);

        if (existing != null) {
          if (importedId != null && importedId > 0) {
            idMap[importedId] = existing.id;
          }
          if (_isImportedNewer(
            importedCreatedAt: source.createdAt,
            importedUpdatedAt: source.updatedAt,
            existingCreatedAt: existing.createdAt,
            existingUpdatedAt: existing.updatedAt,
          )) {
            source.id = existing.id;
            await isar.writeTxn(() async => isar.sourceModels.put(source));
          }
          continue;
        }

        if (importedId != null && importedId > 0 && byId == null) {
          source.id = importedId;
        }
      } else {
        if (importedId != null && importedId > 0) {
          source.id = importedId;
        }
      }

      if (strategy == ImportConflictStrategy.skipExisting) {
        final existing = existingSources.where((s) => s.name == source.name);
        if (existing.isNotEmpty) {
          if (importedId != null && importedId > 0) {
            idMap[importedId] = existing.first.id;
          }
          continue;
        }
      }

      await isar.writeTxn(() async {
        final storedId = await isar.sourceModels.put(source);
        if (importedId != null && importedId > 0) {
          idMap[importedId] = storedId;
        }
      });
    }

    return idMap;
  }

  Future<Map<int, int>> _importBanks(
    List<dynamic> banksData,
    ImportConflictStrategy strategy,
  ) async {
    final isar = _bankRepository.isar;
    final overwrite = strategy == ImportConflictStrategy.overwrite;
    final smartMerge = strategy == ImportConflictStrategy.smartMerge;
    final existingBanks = overwrite
        ? <BankModel>[]
        : await _bankRepository.getAllBanks();
    final idMap = <int, int>{};

    for (final bankData in banksData) {
      if (bankData is! Map<String, dynamic>) continue;

      final bank = BankModel(
        name: bankData['name'] as String? ?? '',
        balance: _toDouble(bankData['balance']) ?? 0.0,
        currency: bankData['currency'] as String? ?? 'BIF',
        bankType: _parseEnum(BankType.values, bankData['type'], BankType.free),
        interestType: _parseEnum(
          InterestType.values,
          bankData['interestType'],
          InterestType.monthly,
        ),
        interestCalculation: _parseEnum(
          InterestCalculation.values,
          bankData['interestCalculation'],
          InterestCalculation.fixedAmount,
        ),
        interestValue: _toDouble(bankData['interestValue']),
        nextDeductionDate: _parseDate(bankData['nextDeductionDate']),
        lastDeductionDate: _parseDate(bankData['lastDeductionDate']),
        createdAt: _parseDate(bankData['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDate(bankData['updatedAt']),
        description: bankData['description'] as String?,
        accountNumber: bankData['accountNumber'] as String?,
        iconName: bankData['iconName'] as String?,
        color: bankData['color'] as String?,
        isActive: _toBool(bankData['isActive']) ?? true,
        isDeleted: _toBool(bankData['isDeleted']) ?? false,
      );

      final importedId = _toInt(bankData['id']);

      if (smartMerge) {
        final byNaturalKey = existingBanks.where(
          (b) =>
              _sameText(b.name, bank.name) &&
              _sameText(b.accountNumber ?? '', bank.accountNumber ?? '') &&
              _sameText(b.currency, bank.currency),
        );
        final byId = importedId == null
            ? null
            : await isar.bankModels.get(importedId);
        final existing = byNaturalKey.isNotEmpty
            ? byNaturalKey.first
            : (byId != null && _sameText(byId.name, bank.name) ? byId : null);

        if (existing != null) {
          if (importedId != null && importedId > 0) {
            idMap[importedId] = existing.id;
          }
          if (_isImportedNewer(
            importedCreatedAt: bank.createdAt,
            importedUpdatedAt: bank.updatedAt,
            existingCreatedAt: existing.createdAt,
            existingUpdatedAt: existing.updatedAt,
          )) {
            bank.id = existing.id;
            await isar.writeTxn(() async => isar.bankModels.put(bank));
          }
          continue;
        }

        if (importedId != null && importedId > 0 && byId == null) {
          bank.id = importedId;
        }
      } else {
        if (importedId != null && importedId > 0) {
          bank.id = importedId;
        }
      }

      if (strategy == ImportConflictStrategy.skipExisting) {
        final existing = existingBanks.where(
          (b) =>
              b.name == bank.name &&
              (b.accountNumber ?? '') == (bank.accountNumber ?? ''),
        );
        if (existing.isNotEmpty) {
          if (importedId != null && importedId > 0) {
            idMap[importedId] = existing.first.id;
          }
          continue;
        }
      }

      await isar.writeTxn(() async {
        final storedId = await isar.bankModels.put(bank);
        if (importedId != null && importedId > 0) {
          idMap[importedId] = storedId;
        }
      });
    }

    return idMap;
  }

  Future<Map<int, int>> _importAssets(
    List<dynamic> assetsData,
    ImportConflictStrategy strategy,
  ) async {
    final isar = _assetRepository.isar;
    final overwrite = strategy == ImportConflictStrategy.overwrite;
    final smartMerge = strategy == ImportConflictStrategy.smartMerge;
    final existingAssets = overwrite
        ? <AssetModel>[]
        : await _assetRepository.getAllAssets();
    final idMap = <int, int>{};

    for (final assetData in assetsData) {
      if (assetData is! Map<String, dynamic>) continue;

      final asset = AssetModel(
        name: assetData['name'] as String? ?? '',
        type: _parseEnum(AssetType.values, assetData['type'], AssetType.other),
        purchasePrice: _toDouble(assetData['purchasePrice']) ?? 0.0,
        currentValue: _toDouble(assetData['currentValue']) ?? 0.0,
        quantity: _toInt(assetData['quantity']),
        unit: assetData['unit'] as String?,
        currency: assetData['currency'] as String? ?? 'BIF',
        purchaseDate: _parseDate(assetData['purchaseDate']) ?? DateTime.now(),
        status: _parseEnum(
          AssetStatus.values,
          assetData['status'],
          AssetStatus.owned,
        ),
        createdAt: _parseDate(assetData['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDate(assetData['updatedAt']),
        description: assetData['description'] as String?,
        location: assetData['location'] as String?,
        notes: assetData['notes'] as String?,
        isDeleted: _toBool(assetData['isDeleted']) ?? false,
        relatedTransactionId: _toInt(assetData['relatedTransactionId']),
        soldDate: _parseDate(assetData['soldDate']),
        soldPrice: _toDouble(assetData['soldPrice']),
        imagePaths: (assetData['imagePaths'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
      );

      final importedId = _toInt(assetData['id']);

      if (smartMerge) {
        final byNaturalKey = existingAssets.where(
          (a) =>
              _sameText(a.name, asset.name) &&
              a.type == asset.type &&
              _sameDay(a.purchaseDate, asset.purchaseDate),
        );
        final byId = importedId == null
            ? null
            : await isar.assetModels.get(importedId);
        final existing = byNaturalKey.isNotEmpty
            ? byNaturalKey.first
            : (byId != null && _sameText(byId.name, asset.name) ? byId : null);

        if (existing != null) {
          if (importedId != null && importedId > 0) {
            idMap[importedId] = existing.id;
          }
          if (_isImportedNewer(
            importedCreatedAt: asset.createdAt,
            importedUpdatedAt: asset.updatedAt,
            existingCreatedAt: existing.createdAt,
            existingUpdatedAt: existing.updatedAt,
          )) {
            asset.id = existing.id;
            await isar.writeTxn(() async => isar.assetModels.put(asset));
          }
          continue;
        }

        if (importedId != null && importedId > 0 && byId == null) {
          asset.id = importedId;
        }
      } else {
        if (importedId != null && importedId > 0) {
          asset.id = importedId;
        }
      }

      if (strategy == ImportConflictStrategy.skipExisting) {
        final existing = existingAssets.where(
          (a) =>
              a.name == asset.name &&
              a.purchaseDate.isAtSameMomentAs(asset.purchaseDate),
        );
        if (existing.isNotEmpty) {
          if (importedId != null && importedId > 0) {
            idMap[importedId] = existing.first.id;
          }
          continue;
        }
      }

      await isar.writeTxn(() async {
        final storedId = await isar.assetModels.put(asset);
        if (importedId != null && importedId > 0) {
          idMap[importedId] = storedId;
        }
      });
    }

    return idMap;
  }

  Future<Map<int, int>> _importDebts(
    List<dynamic> debtsData,
    ImportConflictStrategy strategy,
  ) async {
    final isar = _debtRepository.isar;
    final overwrite = strategy == ImportConflictStrategy.overwrite;
    final smartMerge = strategy == ImportConflictStrategy.smartMerge;
    final existingDebts = overwrite
        ? <DebtModel>[]
        : await _debtRepository.getAllDebts();
    final idMap = <int, int>{};

    for (final debtData in debtsData) {
      if (debtData is! Map<String, dynamic>) continue;

      final debt = DebtModel(
        type: _parseEnum(DebtType.values, debtData['type'], DebtType.given),
        personName: debtData['personName'] as String? ?? '',
        personContact: debtData['personContact'] as String?,
        totalAmount: _toDouble(debtData['totalAmount']) ?? 0.0,
        paidAmount: _toDouble(debtData['paidAmount']) ?? 0.0,
        currency: debtData['currency'] as String? ?? 'BIF',
        date: _parseDate(debtData['date']) ?? DateTime.now(),
        dueDate: _parseDate(debtData['dueDate']),
        status: _parseEnum(
          DebtStatus.values,
          debtData['status'],
          DebtStatus.pending,
        ),
        createdAt: _parseDate(debtData['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDate(debtData['updatedAt']),
        description: debtData['description'] as String?,
        notes: debtData['notes'] as String?,
        isDeleted: _toBool(debtData['isDeleted']) ?? false,
        relatedTransactionId: _toInt(debtData['relatedTransactionId']),
        paymentTransactionIds:
            (debtData['paymentTransactionIds'] as List<dynamic>?)
                ?.map((e) => _toInt(e))
                .whereType<int>()
                .toList(),
        hasInterest: _toBool(debtData['hasInterest']) ?? false,
        interestRate: _toDouble(debtData['interestRate']),
        collateral: debtData['collateral'] as String?,
        hasReminder: _toBool(debtData['hasReminder']) ?? false,
        reminderDateTime: _parseDate(debtData['reminderDateTime']),
      );

      final importedId = _toInt(debtData['id']);

      if (smartMerge) {
        final byNaturalKey = existingDebts.where(
          (d) =>
              _sameText(d.personName, debt.personName) &&
              d.type == debt.type &&
              d.totalAmount == debt.totalAmount &&
              _sameDay(d.date, debt.date),
        );
        final byId = importedId == null
            ? null
            : await isar.debtModels.get(importedId);
        final existing = byNaturalKey.isNotEmpty
            ? byNaturalKey.first
            : (byId != null && _sameText(byId.personName, debt.personName)
                  ? byId
                  : null);

        if (existing != null) {
          if (importedId != null && importedId > 0) {
            idMap[importedId] = existing.id;
          }
          if (_isImportedNewer(
            importedCreatedAt: debt.createdAt,
            importedUpdatedAt: debt.updatedAt,
            existingCreatedAt: existing.createdAt,
            existingUpdatedAt: existing.updatedAt,
          )) {
            debt.id = existing.id;
            await isar.writeTxn(() async => isar.debtModels.put(debt));
          }
          continue;
        }

        if (importedId != null && importedId > 0 && byId == null) {
          debt.id = importedId;
        }
      } else {
        if (importedId != null && importedId > 0) {
          debt.id = importedId;
        }
      }

      if (strategy == ImportConflictStrategy.skipExisting) {
        final existing = existingDebts.where(
          (d) =>
              d.personName == debt.personName &&
              d.totalAmount == debt.totalAmount &&
              d.date.isAtSameMomentAs(debt.date),
        );
        if (existing.isNotEmpty) {
          if (importedId != null && importedId > 0) {
            idMap[importedId] = existing.first.id;
          }
          continue;
        }
      }

      await isar.writeTxn(() async {
        final storedId = await isar.debtModels.put(debt);
        if (importedId != null && importedId > 0) {
          idMap[importedId] = storedId;
        }
      });
    }

    return idMap;
  }

  Future<void> _importTransactions(
    List<dynamic> transactionsData,
    ImportConflictStrategy strategy, {
    required Map<int, int> sourceIdMap,
    required Map<int, int> bankIdMap,
    required Map<int, int> assetIdMap,
    required Map<int, int> debtIdMap,
  }) async {
    final isar = _transactionRepository.isar;
    final overwrite = strategy == ImportConflictStrategy.overwrite;
    final smartMerge = strategy == ImportConflictStrategy.smartMerge;
    final existingTransactions = smartMerge
        ? await _transactionRepository.getAllTransactions()
        : <tx.TransactionModel>[];

    for (final transactionData in transactionsData) {
      if (transactionData is! Map<String, dynamic>) continue;

      final sourceType = _parseEnum(
        tx.SourceType.values,
        transactionData['sourceType'],
        tx.SourceType.source,
      );
      final targetSourceType = _parseNullableEnum(
        tx.SourceType.values,
        transactionData['targetSourceType'],
      );

      final transaction = tx.TransactionModel(
        type: _parseEnum(
          tx.TransactionType.values,
          transactionData['type'],
          tx.TransactionType.expense,
        ),
        incomeCategory: _parseEnum(
          tx.IncomeCategory.values,
          transactionData['incomeCategory'],
          tx.IncomeCategory.other,
        ),
        expenseCategory: _parseEnum(
          tx.ExpenseCategory.values,
          transactionData['expenseCategory'],
          tx.ExpenseCategory.other,
        ),
        amount: _toDouble(transactionData['amount']) ?? 0.0,
        currency: transactionData['currency'] as String? ?? 'BIF',
        sourceId: _mapEntityId(
          id: _toInt(transactionData['sourceId']) ?? 0,
          type: sourceType,
          sourceIdMap: sourceIdMap,
          bankIdMap: bankIdMap,
          assetIdMap: assetIdMap,
          debtIdMap: debtIdMap,
        ),
        sourceName: transactionData['sourceName'] as String?,
        sourceType: sourceType,
        targetSourceId: _mapNullableEntityId(
          id: _toInt(transactionData['targetSourceId']),
          type: targetSourceType,
          sourceIdMap: sourceIdMap,
          bankIdMap: bankIdMap,
          assetIdMap: assetIdMap,
          debtIdMap: debtIdMap,
        ),
        targetSourceName: transactionData['targetSourceName'] as String?,
        targetSourceType: targetSourceType,
        date: _parseDate(transactionData['date']) ?? DateTime.now(),
        createdAt: _parseDate(transactionData['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDate(transactionData['updatedAt']),
        description: transactionData['description'] as String?,
        note: transactionData['note'] as String?,
        attachmentPath: transactionData['attachmentPath'] as String?,
        isDeleted: _toBool(transactionData['isDeleted']) ?? false,
        status: _parseEnum(
          tx.TransactionStatus.values,
          transactionData['status'],
          tx.TransactionStatus.active,
        ),
        isRecurring: _toBool(transactionData['isRecurring']) ?? false,
        recurringPattern: transactionData['recurringPattern'] as String?,
        recurringEndDate: _parseDate(transactionData['recurringEndDate']),
        relatedDebtId: _mapIdWithMap(
          _toInt(transactionData['relatedDebtId']),
          debtIdMap,
        ),
        relatedAssetId: _mapIdWithMap(
          _toInt(transactionData['relatedAssetId']),
          assetIdMap,
        ),
        relatedBankId: _mapIdWithMap(
          _toInt(transactionData['relatedBankId']),
          bankIdMap,
        ),
      );

      final importedId = _toInt(transactionData['id']);

      if (smartMerge) {
        final byId = importedId == null
            ? null
            : await isar.transactionModels.get(importedId);
        final bySignature = existingTransactions.where(
          (existing) => _sameTransactionSignature(existing, transaction),
        );
        final existing = bySignature.isNotEmpty
            ? bySignature.first
            : (byId != null && _sameTransactionSignature(byId, transaction)
                  ? byId
                  : null);

        if (existing != null) {
          if (_isImportedNewer(
            importedCreatedAt: transaction.createdAt,
            importedUpdatedAt: transaction.updatedAt,
            existingCreatedAt: existing.createdAt,
            existingUpdatedAt: existing.updatedAt,
          )) {
            transaction.id = existing.id;
            await isar.writeTxn(
              () async => isar.transactionModels.put(transaction),
            );
          }
          continue;
        }

        if (importedId != null && importedId > 0 && byId == null) {
          transaction.id = importedId;
        }
      } else {
        if (importedId != null && importedId > 0) {
          transaction.id = importedId;
        }
      }

      if (!overwrite &&
          strategy == ImportConflictStrategy.skipExisting &&
          importedId != null) {
        final existing = await isar.transactionModels.get(importedId);
        if (existing != null) continue;
      }

      await isar.writeTxn(() async {
        await isar.transactionModels.put(transaction);
      });
    }
  }

  int _mapEntityId({
    required int id,
    required tx.SourceType type,
    required Map<int, int> sourceIdMap,
    required Map<int, int> bankIdMap,
    required Map<int, int> assetIdMap,
    required Map<int, int> debtIdMap,
  }) {
    return switch (type) {
      tx.SourceType.source => sourceIdMap[id] ?? id,
      tx.SourceType.bank => bankIdMap[id] ?? id,
      tx.SourceType.asset => assetIdMap[id] ?? id,
      tx.SourceType.debt => debtIdMap[id] ?? id,
      tx.SourceType.external => id,
    };
  }

  int? _mapNullableEntityId({
    required int? id,
    required tx.SourceType? type,
    required Map<int, int> sourceIdMap,
    required Map<int, int> bankIdMap,
    required Map<int, int> assetIdMap,
    required Map<int, int> debtIdMap,
  }) {
    if (id == null || type == null) return id;
    return _mapEntityId(
      id: id,
      type: type,
      sourceIdMap: sourceIdMap,
      bankIdMap: bankIdMap,
      assetIdMap: assetIdMap,
      debtIdMap: debtIdMap,
    );
  }

  int? _mapIdWithMap(int? id, Map<int, int> mapping) {
    if (id == null) return null;
    return mapping[id] ?? id;
  }

  bool _sameText(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _lastTouched(DateTime createdAt, DateTime? updatedAt) {
    return updatedAt ?? createdAt;
  }

  bool _isImportedNewer({
    required DateTime importedCreatedAt,
    required DateTime? importedUpdatedAt,
    required DateTime existingCreatedAt,
    required DateTime? existingUpdatedAt,
  }) {
    return _lastTouched(
      importedCreatedAt,
      importedUpdatedAt,
    ).isAfter(_lastTouched(existingCreatedAt, existingUpdatedAt));
  }

  bool _sameTransactionSignature(tx.TransactionModel a, tx.TransactionModel b) {
    return a.type == b.type &&
        a.amount == b.amount &&
        _sameText(a.currency, b.currency) &&
        a.date.isAtSameMomentAs(b.date) &&
        a.createdAt.isAtSameMomentAs(b.createdAt) &&
        _sameText(a.sourceName ?? '', b.sourceName ?? '') &&
        _sameText(a.targetSourceName ?? '', b.targetSourceName ?? '') &&
        _sameText(a.description ?? '', b.description ?? '') &&
        _sameText(a.note ?? '', b.note ?? '');
  }

  T _parseEnum<T extends Enum>(List<T> values, dynamic value, T fallback) {
    if (value is String) {
      for (final item in values) {
        if (item.name == value) return item;
      }
    }
    return fallback;
  }

  T? _parseNullableEnum<T extends Enum>(List<T> values, dynamic value) {
    if (value == null) return null;
    return _parseEnum(values, value, values.first);
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool? _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class ImportResult {
  final bool success;
  final String? error;
  final List<String> conflicts;
  final Map<String, dynamic>? data;

  ImportResult({
    required this.success,
    this.error,
    this.conflicts = const [],
    this.data,
  });
}
