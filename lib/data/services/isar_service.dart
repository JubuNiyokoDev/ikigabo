import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/asset_model.dart';
import '../models/bank_model.dart';
import '../models/debt_model.dart';
import '../models/security_model.dart';
import '../models/settings_model.dart';
import '../models/source_model.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/debt_payment_model.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal();

  Isar? _isar;

  Future<Isar> get isar async {
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }
    _isar = await _initIsar();
    return _isar!;
  }

  Future<Isar> _initIsar() async {
    final dir = await getApplicationDocumentsDirectory();

    return await Isar.open(
      [
        SourceModelSchema,
        BankModelSchema,
        TransactionModelSchema,
        AssetModelSchema,
        DebtModelSchema,
        DebtPaymentModelSchema,
        SettingsModelSchema,
        SecurityModelSchema,
        BudgetModelSchema,
        CategoryModelSchema,
      ],
      directory: dir.path,
      name: 'ikigabo_db',
      inspector: true,
    );
  }

  Future<void> closeDatabase() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _isar = null;
    }
  }

  Future<void> clearAllData() async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.clear();
    });
  }
}
