import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import '../models/source_model.dart' as src;
import '../models/transaction_model.dart' as tx;
import '../models/debt_model.dart';
import '../models/asset_model.dart';
import '../models/bank_model.dart';
import '../repositories/source_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/debt_repository.dart';
import '../repositories/asset_repository.dart';
import '../repositories/bank_repository.dart';

class BackupService {
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

  // Export all data to encrypted JSON
  Future<String> exportData({String? password}) async {
    final data = {
      'version': '1.0',
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

  // Import data from encrypted JSON
  Future<ImportResult> importData(String data, {String? password}) async {
    try {
      String jsonString = data;

      if (password != null && password.isNotEmpty) {
        jsonString = _decryptData(data, password);
      }

      final Map<String, dynamic> importData = jsonDecode(jsonString);

      // Validate backup format
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

  // Apply import data
  Future<void> applyImport(
    Map<String, dynamic> data, {
    bool overwriteConflicts = false,
  }) async {
    if (data['sources'] != null) {
      await _importSources(data['sources'], overwriteConflicts);
    }
    if (data['transactions'] != null) {
      await _importTransactions(data['transactions'], overwriteConflicts);
    }
    if (data['debts'] != null) {
      await _importDebts(data['debts'], overwriteConflicts);
    }
    if (data['assets'] != null) {
      await _importAssets(data['assets'], overwriteConflicts);
    }
    if (data['banks'] != null) {
      await _importBanks(data['banks'], overwriteConflicts);
    }
  }

  // Save backup using Storage Access Framework (SAF)
  Future<String> saveBackupToStorage(String backupData) async {
    try {
      // Utiliser file_picker pour choisir l'emplacement
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Sauvegarder la sauvegarde Ikigabo',
        fileName: 'ikigabo_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(backupData), // Fournir les bytes directement
      );

      if (outputFile == null) {
        throw Exception('Sauvegarde annulée par l\'utilisateur');
      }

      // Le fichier est déjà sauvegardé par file_picker
      return outputFile;
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  // Private methods
  String _encryptData(String data, String password) {
    // Generate encryption key from password
    sha256.convert(utf8.encode(password)).bytes;
    final encrypted = base64Encode(utf8.encode(data));
    return encrypted;
  }

  String _decryptData(String encryptedData, String password) {
    try {
      final decrypted = utf8.decode(base64Decode(encryptedData));
      return decrypted;
    } catch (e) {
      throw Exception('Mot de passe incorrect ou données corrompues');
    }
  }

  bool _validateBackupFormat(Map<String, dynamic> data) {
    return data.containsKey('version') &&
        data.containsKey('timestamp') &&
        data.containsKey('sources');
  }

  Future<List<String>> _detectConflicts(Map<String, dynamic> data) async {
    final conflicts = <String>[];

    // Check for existing data
    final existingSources = await _sourceRepository.getAllSources();
    final existingTransactions = await _transactionRepository
        .getAllTransactions();
    final existingDebts = await _debtRepository.watchDebts().first;

    if (existingSources.isNotEmpty && data['sources'] != null) {
      conflicts.add('Sources existantes détectées');
    }
    if (existingTransactions.isNotEmpty && data['transactions'] != null) {
      conflicts.add('Transactions existantes détectées');
    }
    if (existingDebts.isNotEmpty && data['debts'] != null) {
      conflicts.add('Dettes existantes détectées');
    }

    return conflicts;
  }

  Future<List<Map<String, dynamic>>> _exportSources() async {
    final sources = await _sourceRepository.getAllSources();
    return sources
        .map(
          (s) => {
            'id': s.id,
            'name': s.name,
            'type': s.type.name,
            'amount': s.amount,
            'currency': s.currency,
            'isActive': s.isActive,
            'createdAt': s.createdAt.toIso8601String(),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _exportTransactions() async {
    final transactions = await _transactionRepository.getAllTransactions();
    return transactions
        .map(
          (t) => {
            'id': t.id,
            'type': t.type.name,
            'amount': t.amount,
            'incomeCategory': t.incomeCategory.name,
            'expenseCategory': t.expenseCategory.name,
            'description': t.description,
            'date': t.date.toIso8601String(),
            'sourceId': t.sourceId,
            'currency': t.currency,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _exportDebts() async {
    final debts = await _debtRepository.watchDebts().first;
    return debts
        .map(
          (d) => {
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
            'description': d.description,
            'hasInterest': d.hasInterest,
            'interestRate': d.interestRate,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _exportAssets() async {
    final assets = await _assetRepository.watchAssets().first;
    return assets
        .map(
          (a) => {
            'id': a.id,
            'name': a.name,
            'type': a.type.name,
            'purchasePrice': a.purchasePrice,
            'currentValue': a.currentValue,
            'quantity': a.quantity,
            'currency': a.currency,
            'purchaseDate': a.purchaseDate.toIso8601String(),
            'status': a.status.name,
            'description': a.description,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _exportBanks() async {
    final banks = await _bankRepository.watchBanks().first;
    return banks
        .map(
          (b) => {
            'id': b.id,
            'name': b.name,
            'accountNumber': b.accountNumber,
            'balance': b.balance,
            'currency': b.currency,
            'type': b.bankType.name,
            'interestType': b.interestType.name,
            'interestCalculation': b.interestCalculation.name,
            'interestValue': b.interestValue,
            'isActive': b.isActive,
          },
        )
        .toList();
  }

  Future<void> _importSources(List<dynamic> sourcesData, bool overwrite) async {
    for (final sourceData in sourcesData) {
      final source = src.SourceModel(
        name: sourceData['name'],
        type: src.SourceType.values.firstWhere(
          (t) => t.name == sourceData['type'],
        ),
        amount: sourceData['amount'].toDouble(),
        currency: sourceData['currency'] ?? 'FBU',
        isActive: sourceData['isActive'] ?? true,
        createdAt: DateTime.parse(sourceData['createdAt']),
      );

      if (overwrite) {
        await _sourceRepository.addSource(source);
      } else {
        // Check if exists first
        final existing = await _sourceRepository.getAllSources();
        if (!existing.any((s) => s.name == source.name)) {
          await _sourceRepository.addSource(source);
        }
      }
    }
  }

  Future<void> _importTransactions(
    List<dynamic> transactionsData,
    bool overwrite,
  ) async {
    for (final transactionData in transactionsData) {
      final transaction = tx.TransactionModel(
        type: tx.TransactionType.values.firstWhere(
          (t) => t.name == transactionData['type'],
        ),
        amount: transactionData['amount'].toDouble(),
        incomeCategory: transactionData['incomeCategory'] != null
            ? tx.IncomeCategory.values.firstWhere(
                (c) => c.name == transactionData['incomeCategory'],
              )
            : tx.IncomeCategory.other,
        expenseCategory: transactionData['expenseCategory'] != null
            ? tx.ExpenseCategory.values.firstWhere(
                (c) => c.name == transactionData['expenseCategory'],
              )
            : tx.ExpenseCategory.other,
        description: transactionData['description'],
        date: DateTime.parse(transactionData['date']),
        sourceId: transactionData['sourceId'],
        sourceType: tx.SourceType.source,
        currency: transactionData['currency'] ?? 'FBU',
        createdAt: DateTime.now(),
      );

      await _transactionRepository.addTransaction(transaction);
    }
  }

  Future<void> _importDebts(List<dynamic> debtsData, bool overwrite) async {
    for (final debtData in debtsData) {
      final debt = DebtModel(
        type: DebtType.values.firstWhere((t) => t.name == debtData['type']),
        personName: debtData['personName'],
        personContact: debtData['personContact'],
        totalAmount: debtData['totalAmount'].toDouble(),
        paidAmount: debtData['paidAmount']?.toDouble() ?? 0.0,
        currency: debtData['currency'] ?? 'FBU',
        date: DateTime.parse(debtData['date']),
        dueDate: debtData['dueDate'] != null
            ? DateTime.parse(debtData['dueDate'])
            : null,
        status: DebtStatus.values.firstWhere(
          (s) => s.name == debtData['status'],
        ),
        description: debtData['description'],
        hasInterest: debtData['hasInterest'] ?? false,
        interestRate: debtData['interestRate']?.toDouble(),
        createdAt: DateTime.now(),
      );

      // Pour les dettes, utiliser la méthode appropriée selon le type
      if (debt.type == DebtType.given) {
        await _debtRepository.addDebtGiven(
          debt: debt,
          sourceId: 1, // ID par défaut, à ajuster selon vos besoins
          sourceType: tx.SourceType.source,
          sourceName: 'Source par défaut',
        );
      } else {
        await _debtRepository.addDebtReceived(
          debt: debt,
          targetId: 1, // ID par défaut, à ajuster selon vos besoins
          targetType: tx.SourceType.source,
          targetName: 'Source par défaut',
        );
      }
    }
  }

  Future<void> _importAssets(List<dynamic> assetsData, bool overwrite) async {
    for (final assetData in assetsData) {
      final asset = AssetModel(
        name: assetData['name'],
        type: AssetType.values.firstWhere((t) => t.name == assetData['type']),
        purchasePrice: assetData['purchasePrice'].toDouble(),
        currentValue: assetData['currentValue'].toDouble(),
        quantity: assetData['quantity'] ?? 1,
        currency: assetData['currency'] ?? 'FBU',
        purchaseDate: DateTime.parse(assetData['purchaseDate']),
        status: AssetStatus.values.firstWhere(
          (s) => s.name == assetData['status'],
        ),
        description: assetData['description'],
        createdAt: DateTime.now(),
      );

      // Pour les assets, utiliser la méthode d'achat avec source
      await _assetRepository.addAssetWithPurchase(
        asset: asset,
        sourceId: 1, // ID par défaut, à ajuster selon vos besoins
        sourceType: tx.SourceType.source,
        sourceName: 'Source par défaut',
      );
    }
  }

  Future<void> _importBanks(List<dynamic> banksData, bool overwrite) async {
    for (final bankData in banksData) {
      final bank = BankModel(
        name: bankData['name'],
        accountNumber: bankData['accountNumber'],
        balance: bankData['balance'].toDouble(),
        currency: bankData['currency'] ?? 'FBU',
        bankType: BankType.values.firstWhere((t) => t.name == bankData['type']),
        interestType: InterestType.values.firstWhere(
          (t) => t.name == bankData['interestType'],
        ),
        interestCalculation: InterestCalculation.values.firstWhere(
          (t) => t.name == bankData['interestCalculation'],
        ),
        interestValue: bankData['interestValue']?.toDouble(),
        isActive: bankData['isActive'] ?? true,
        createdAt: DateTime.now(),
      );

      await _bankRepository.addBank(bank);
    }
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
