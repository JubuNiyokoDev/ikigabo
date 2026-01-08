import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/pdf_export_service.dart';
import 'transaction_provider.dart';
import 'asset_provider.dart';
import 'debt_provider.dart';
import 'bank_provider.dart';
import 'source_provider.dart';
import 'dashboard_provider.dart';

final pdfExportProvider = Provider<PdfExportService>((ref) {
  return PdfExportService();
});

final exportFinancialReportProvider = FutureProvider.family<void, String>((ref, period) async {
  final transactions = await ref.read(transactionsStreamProvider.future);
  final assets = await ref.read(assetsStreamProvider.future);
  final debts = await ref.read(debtsStreamProvider.future);
  final banks = await ref.read(banksStreamProvider.future);
  final sources = await ref.read(sourcesStreamProvider.future);
  final totalWealth = await ref.read(totalWealthProvider.future);
  final totalIncome = await ref.read(totalIncomeProvider.future);
  final totalExpense = await ref.read(totalExpenseProvider.future);

  await PdfExportService.exportFinancialReport(
    transactions: transactions,
    assets: assets,
    debts: debts,
    banks: banks,
    sources: sources,
    totalWealth: totalWealth,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    period: period,
  );
});

final exportAssetReportProvider = FutureProvider<void>((ref) async {
  final assets = await ref.read(assetsStreamProvider.future);
  await PdfExportService.exportAssetReport(assets);
});

final exportDebtReportProvider = FutureProvider<void>((ref) async {
  final debts = await ref.read(debtsStreamProvider.future);
  await PdfExportService.exportDebtReport(debts);
});