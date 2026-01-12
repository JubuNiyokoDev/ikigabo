import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/pdf_export_service.dart';
import '../../core/services/ad_manager.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/asset_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/bank_model.dart';
import '../../data/models/source_model.dart';

final pdfExportProvider = StateNotifierProvider<PdfExportNotifier, PdfExportState>((ref) {
  return PdfExportNotifier();
});

class PdfExportState {
  final bool isExporting;
  final String? lastExportPath;
  final String? error;

  const PdfExportState({
    this.isExporting = false,
    this.lastExportPath,
    this.error,
  });

  PdfExportState copyWith({
    bool? isExporting,
    String? lastExportPath,
    String? error,
  }) {
    return PdfExportState(
      isExporting: isExporting ?? this.isExporting,
      lastExportPath: lastExportPath ?? this.lastExportPath,
      error: error,
    );
  }
}

class PdfExportNotifier extends StateNotifier<PdfExportState> {
  PdfExportNotifier() : super(const PdfExportState());

  Future<void> exportFinancialReport({
    required List<TransactionModel> transactions,
    required List<AssetModel> assets,
    required List<DebtModel> debts,
    required List<BankModel> banks,
    required List<SourceModel> sources,
    required double totalWealth,
    required double totalIncome,
    required double totalExpense,
    required String period,
    String? customTitle,
  }) async {
    if (state.isExporting) return;

    state = state.copyWith(isExporting: true, error: null);

    try {
      // Vérifier les ads
      final canProceed = await AdManager.showRewardedForPdfExport();
      if (!canProceed) {
        state = state.copyWith(isExporting: false);
        return;
      }

      final filePath = await PdfExportService.exportFinancialReport(
        transactions: transactions,
        assets: assets,
        debts: debts,
        banks: banks,
        sources: sources,
        totalWealth: totalWealth,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        period: period,
        customTitle: customTitle,
      );

      state = state.copyWith(
        isExporting: false,
        lastExportPath: filePath,
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
      );
    }
  }

  Future<void> exportAssetReport(List<AssetModel> assets) async {
    if (state.isExporting) return;

    state = state.copyWith(isExporting: true, error: null);

    try {
      // Vérifier les ads
      final canProceed = await AdManager.showRewardedForPdfExport();
      if (!canProceed) {
        state = state.copyWith(isExporting: false);
        return;
      }

      final filePath = await PdfExportService.exportAssetReport(assets);

      state = state.copyWith(
        isExporting: false,
        lastExportPath: filePath,
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
      );
    }
  }

  Future<void> exportDebtReport(List<DebtModel> debts) async {
    if (state.isExporting) return;

    state = state.copyWith(isExporting: true, error: null);

    try {
      // Vérifier les ads
      final canProceed = await AdManager.showRewardedForPdfExport();
      if (!canProceed) {
        state = state.copyWith(isExporting: false);
        return;
      }

      final filePath = await PdfExportService.exportDebtReport(debts);

      state = state.copyWith(
        isExporting: false,
        lastExportPath: filePath,
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}