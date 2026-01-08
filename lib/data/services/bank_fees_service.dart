import 'dart:async';
import '../models/bank_model.dart';
import '../models/transaction_model.dart';
import '../repositories/bank_repository.dart';
import '../repositories/transaction_repository.dart';

class BankFeesService {
  final BankRepository _bankRepository;
  final TransactionRepository _transactionRepository;
  Timer? _timer;

  BankFeesService(this._bankRepository, this._transactionRepository) {
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    // Vérifier toutes les heures
    _timer = Timer.periodic(const Duration(hours: 1), (_) {
      _processAutomaticDeductions();
    });
  }

  Future<void> _processAutomaticDeductions() async {
    final banks = await _bankRepository.getAllBanks();
    
    for (final bank in banks) {
      if (bank.shouldDeductInterest()) {
        await _deductBankFees(bank);
      }
    }
  }

  Future<void> _deductBankFees(BankModel bank) async {
    final feeAmount = bank.calculateInterest();
    
    if (feeAmount <= 0) return;

    // Déduire les frais du solde
    bank.balance = bank.balance - feeAmount;
    bank.lastDeductionDate = DateTime.now();
    bank.nextDeductionDate = bank.calculateNextDeductionDate();
    
    await _bankRepository.updateBank(bank);

    // Créer une transaction pour les frais
    final feeTransaction = TransactionModel(
      type: TransactionType.expense,
      expenseCategory: ExpenseCategory.bankFees,
      amount: feeAmount,
      currency: bank.currency,
      sourceId: bank.id,
      sourceName: bank.name,
      sourceType: SourceType.bank,
      date: DateTime.now(),
      createdAt: DateTime.now(),
      description: 'Frais bancaires automatiques - ${bank.name}',
      note: 'Déduction automatique ${bank.interestType.name}',
      relatedBankId: bank.id,
    );

    await _transactionRepository.addTransaction(feeTransaction);
  }

  Future<void> processManualDeduction(int bankId) async {
    final bank = await _bankRepository.getBankById(bankId);
    if (bank != null) {
      await _deductBankFees(bank);
    }
  }

  Future<List<BankModel>> getBanksWithPendingFees() async {
    final banks = await _bankRepository.getAllBanks();
    return banks.where((bank) => bank.shouldDeductInterest()).toList();
  }

  Future<double> calculateTotalPendingFees() async {
    final pendingBanks = await getBanksWithPendingFees();
    return pendingBanks.fold<double>(
      0.0, 
      (sum, bank) => sum + bank.calculateInterest(),
    );
  }

  void dispose() {
    _timer?.cancel();
  }
}