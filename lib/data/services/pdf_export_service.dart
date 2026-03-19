import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/constants/currencies.dart';
import '../../core/utils/currency_formatter.dart';
import '../models/asset_model.dart';
import '../models/bank_model.dart';
import '../models/debt_model.dart';
import '../models/source_model.dart' as src;
import '../models/transaction_model.dart' as tx;

enum ReportDatePreset {
  all,
  today,
  yesterday,
  last7Days,
  thisMonth,
  lastMonth,
  thisYear,
  custom,
}

enum ReportSortBy { newest, oldest, amountDesc, amountAsc, nameAsc, nameDesc }

class ReportDateRange {
  final DateTime start;
  final DateTime end;

  const ReportDateRange({required this.start, required this.end});

  bool contains(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return !normalized.isBefore(startDay) && !normalized.isAfter(endDay);
  }

  String label() {
    final formatter = DateFormat('dd/MM/yyyy');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }
}

class ReportExportFilters {
  final ReportDatePreset datePreset;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  final bool includeTransactions;
  final bool includeAssets;
  final bool includeDebts;
  final bool includeBanks;
  final bool includeSources;

  final bool includeDeleted;
  final bool includeCancelledTransactions;

  final Set<tx.TransactionType> transactionTypes;
  final Set<tx.TransactionStatus> transactionStatuses;
  final Set<tx.SourceType> transactionSourceTypes;
  final Set<tx.IncomeCategory> incomeCategories;
  final Set<tx.ExpenseCategory> expenseCategories;
  final Set<int> selectedTransactionSourceIds;
  final Set<int> selectedTransactionTargetIds;
  final Set<String> transactionCurrencies;
  final String? transactionKeyword;
  final bool recurringOnly;
  final bool nonRecurringOnly;
  final double? transactionMinAmount;
  final double? transactionMaxAmount;

  final Set<AssetType> assetTypes;
  final Set<AssetStatus> assetStatuses;
  final Set<int> selectedAssetIds;
  final Set<String> assetCurrencies;
  final String? assetKeyword;
  final double? assetMinValue;
  final double? assetMaxValue;

  final Set<DebtType> debtTypes;
  final Set<DebtStatus> debtStatuses;
  final Set<int> selectedDebtIds;
  final Set<String> debtCurrencies;
  final String? debtPersonKeyword;
  final bool debtOverdueOnly;
  final bool debtHasReminderOnly;
  final int? debtDueInDays;
  final double? debtMinAmount;
  final double? debtMaxAmount;

  final Set<BankType> bankTypes;
  final Set<InterestType> bankInterestTypes;
  final Set<int> selectedBankIds;
  final Set<String> bankCurrencies;
  final String? bankKeyword;
  final bool bankActiveOnly;
  final double? bankMinBalance;
  final double? bankMaxBalance;

  final Set<src.SourceType> sourceTypes;
  final Set<int> selectedSourceIds;
  final Set<String> sourceCurrencies;
  final String? sourceKeyword;
  final bool sourceActiveOnly;
  final bool sourcePassiveOnly;
  final double? sourceMinAmount;
  final double? sourceMaxAmount;

  final ReportSortBy sortBy;
  final int? maxTransactions;

  const ReportExportFilters({
    this.datePreset = ReportDatePreset.all,
    this.customStartDate,
    this.customEndDate,
    this.includeTransactions = true,
    this.includeAssets = true,
    this.includeDebts = true,
    this.includeBanks = true,
    this.includeSources = true,
    this.includeDeleted = false,
    this.includeCancelledTransactions = true,
    this.transactionTypes = const {},
    this.transactionStatuses = const {},
    this.transactionSourceTypes = const {},
    this.incomeCategories = const {},
    this.expenseCategories = const {},
    this.selectedTransactionSourceIds = const {},
    this.selectedTransactionTargetIds = const {},
    this.transactionCurrencies = const {},
    this.transactionKeyword,
    this.recurringOnly = false,
    this.nonRecurringOnly = false,
    this.transactionMinAmount,
    this.transactionMaxAmount,
    this.assetTypes = const {},
    this.assetStatuses = const {},
    this.selectedAssetIds = const {},
    this.assetCurrencies = const {},
    this.assetKeyword,
    this.assetMinValue,
    this.assetMaxValue,
    this.debtTypes = const {},
    this.debtStatuses = const {},
    this.selectedDebtIds = const {},
    this.debtCurrencies = const {},
    this.debtPersonKeyword,
    this.debtOverdueOnly = false,
    this.debtHasReminderOnly = false,
    this.debtDueInDays,
    this.debtMinAmount,
    this.debtMaxAmount,
    this.bankTypes = const {},
    this.bankInterestTypes = const {},
    this.selectedBankIds = const {},
    this.bankCurrencies = const {},
    this.bankKeyword,
    this.bankActiveOnly = false,
    this.bankMinBalance,
    this.bankMaxBalance,
    this.sourceTypes = const {},
    this.selectedSourceIds = const {},
    this.sourceCurrencies = const {},
    this.sourceKeyword,
    this.sourceActiveOnly = false,
    this.sourcePassiveOnly = false,
    this.sourceMinAmount,
    this.sourceMaxAmount,
    this.sortBy = ReportSortBy.newest,
    this.maxTransactions,
  });

  ReportDateRange? resolveDateRange([DateTime? nowValue]) {
    final now = nowValue ?? DateTime.now();
    switch (datePreset) {
      case ReportDatePreset.all:
        return null;
      case ReportDatePreset.today:
        return ReportDateRange(start: now, end: now);
      case ReportDatePreset.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return ReportDateRange(start: yesterday, end: yesterday);
      case ReportDatePreset.last7Days:
        return ReportDateRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );
      case ReportDatePreset.thisMonth:
        return ReportDateRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case ReportDatePreset.lastMonth:
        final firstDayCurrentMonth = DateTime(now.year, now.month, 1);
        final end = firstDayCurrentMonth.subtract(const Duration(days: 1));
        return ReportDateRange(
          start: DateTime(end.year, end.month, 1),
          end: end,
        );
      case ReportDatePreset.thisYear:
        return ReportDateRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
      case ReportDatePreset.custom:
        if (customStartDate == null || customEndDate == null) return null;
        return ReportDateRange(start: customStartDate!, end: customEndDate!);
    }
  }

  bool get hasAdvancedFilters {
    return datePreset != ReportDatePreset.all ||
        customStartDate != null ||
        customEndDate != null ||
        !includeTransactions ||
        !includeAssets ||
        !includeDebts ||
        !includeBanks ||
        !includeSources ||
        includeDeleted ||
        !includeCancelledTransactions ||
        transactionTypes.isNotEmpty ||
        transactionStatuses.isNotEmpty ||
        transactionSourceTypes.isNotEmpty ||
        incomeCategories.isNotEmpty ||
        expenseCategories.isNotEmpty ||
        selectedTransactionSourceIds.isNotEmpty ||
        selectedTransactionTargetIds.isNotEmpty ||
        transactionCurrencies.isNotEmpty ||
        (transactionKeyword?.trim().isNotEmpty ?? false) ||
        recurringOnly ||
        nonRecurringOnly ||
        transactionMinAmount != null ||
        transactionMaxAmount != null ||
        assetTypes.isNotEmpty ||
        assetStatuses.isNotEmpty ||
        selectedAssetIds.isNotEmpty ||
        assetCurrencies.isNotEmpty ||
        (assetKeyword?.trim().isNotEmpty ?? false) ||
        assetMinValue != null ||
        assetMaxValue != null ||
        debtTypes.isNotEmpty ||
        debtStatuses.isNotEmpty ||
        selectedDebtIds.isNotEmpty ||
        debtCurrencies.isNotEmpty ||
        (debtPersonKeyword?.trim().isNotEmpty ?? false) ||
        debtOverdueOnly ||
        debtHasReminderOnly ||
        debtDueInDays != null ||
        debtMinAmount != null ||
        debtMaxAmount != null ||
        bankTypes.isNotEmpty ||
        bankInterestTypes.isNotEmpty ||
        selectedBankIds.isNotEmpty ||
        bankCurrencies.isNotEmpty ||
        (bankKeyword?.trim().isNotEmpty ?? false) ||
        bankActiveOnly ||
        bankMinBalance != null ||
        bankMaxBalance != null ||
        sourceTypes.isNotEmpty ||
        selectedSourceIds.isNotEmpty ||
        sourceCurrencies.isNotEmpty ||
        (sourceKeyword?.trim().isNotEmpty ?? false) ||
        sourceActiveOnly ||
        sourcePassiveOnly ||
        sourceMinAmount != null ||
        sourceMaxAmount != null ||
        sortBy != ReportSortBy.newest ||
        maxTransactions != null;
  }
}

class _FilteredReportData {
  final List<tx.TransactionModel> transactions;
  final List<AssetModel> assets;
  final List<DebtModel> debts;
  final List<BankModel> banks;
  final List<src.SourceModel> sources;

  const _FilteredReportData({
    required this.transactions,
    required this.assets,
    required this.debts,
    required this.banks,
    required this.sources,
  });
}

class _ReportSummary {
  final double totalWealth;
  final double totalIncome;
  final double totalExpense;

  const _ReportSummary({
    required this.totalWealth,
    required this.totalIncome,
    required this.totalExpense,
  });

  double get balance => totalIncome - totalExpense;
}

class PdfExportService {
  // Keep chunks small so every table part fits safely on a single A4 page.
  static const int _rowsPerTableChunk = 10;
  static const int _maxSectionPages = 1200;

  static Future<String> exportFinancialReport({
    required List<tx.TransactionModel> transactions,
    required List<AssetModel> assets,
    required List<DebtModel> debts,
    required List<BankModel> banks,
    required List<src.SourceModel> sources,
    required double totalWealth,
    required double totalIncome,
    required double totalExpense,
    required String period,
    ReportExportFilters filters = const ReportExportFilters(),
    String? customTitle,
  }) async {
    final filtered = _applyFilters(
      transactions: transactions,
      assets: assets,
      debts: debts,
      banks: banks,
      sources: sources,
      filters: filters,
    );

    final summary = _computeSummary(
      filtered,
      fallbackTotalWealth: totalWealth,
      fallbackTotalIncome: totalIncome,
      fallbackTotalExpense: totalExpense,
    );

    final resolvedPeriod = _resolvePeriodLabel(period, filters);
    final pdf = await _createPdfDocument();

    _addOverviewPage(
      pdf: pdf,
      title: customTitle ?? 'Rapport Financier Complet',
      period: resolvedPeriod,
      summary: summary,
      filtered: filtered,
      filters: filters,
    );

    if (filters.includeTransactions) {
      _addTransactionsPages(pdf, filtered.transactions, filters);
    }
    if (filters.includeAssets) {
      _addAssetsPages(pdf, filtered.assets);
    }
    if (filters.includeDebts) {
      _addDebtsPages(pdf, filtered.debts);
    }
    if (filters.includeBanks) {
      _addBanksPages(pdf, filtered.banks);
    }
    if (filters.includeSources) {
      _addSourcesPages(pdf, filtered.sources);
    }

    final now = DateTime.now();
    final dateFormat = DateFormat('dd-MMM-yyyy_HH\'h\'mm');
    final readableDate = dateFormat.format(now);
    return _savePdf(pdf, 'rapport_financier_$readableDate');
  }

  static Future<String> exportAssetReport(List<AssetModel> assets) {
    return exportFinancialReport(
      transactions: const [],
      assets: assets,
      debts: const [],
      banks: const [],
      sources: const [],
      totalWealth: assets.fold<double>(
        0.0,
        (sum, item) => sum + item.totalValue,
      ),
      totalIncome: 0,
      totalExpense: 0,
      period: 'Tous les actifs',
      customTitle: 'Rapport des Actifs',
      filters: const ReportExportFilters(
        includeTransactions: false,
        includeAssets: true,
        includeDebts: false,
        includeBanks: false,
        includeSources: false,
      ),
    );
  }

  static Future<String> exportDebtReport(List<DebtModel> debts) {
    return exportFinancialReport(
      transactions: const [],
      assets: const [],
      debts: debts,
      banks: const [],
      sources: const [],
      totalWealth: 0,
      totalIncome: 0,
      totalExpense: 0,
      period: 'Toutes les dettes',
      customTitle: 'Rapport des Dettes',
      filters: const ReportExportFilters(
        includeTransactions: false,
        includeAssets: false,
        includeDebts: true,
        includeBanks: false,
        includeSources: false,
      ),
    );
  }

  static void _addOverviewPage({
    required pw.Document pdf,
    required String title,
    required String period,
    required _ReportSummary summary,
    required _FilteredReportData filtered,
    required ReportExportFilters filters,
  }) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(22),
        build: (context) {
          return _buildPageScaffold(
            context: context,
            content: [
              _buildHeader(title: title, period: period, summary: summary),
              pw.SizedBox(height: 12),
              _buildScopeSummary(filtered),
              if (filters.hasAdvancedFilters) ...[
                pw.SizedBox(height: 12),
                _buildFiltersSection(filters),
              ],
              pw.SizedBox(height: 14),
              _buildSummarySection(summary),
            ],
          );
        },
      ),
    );
  }

  static void _addTransactionsPages(
    pw.Document pdf,
    List<tx.TransactionModel> transactions,
    ReportExportFilters filters,
  ) {
    final displayRows =
        filters.maxTransactions != null && filters.maxTransactions! > 0
        ? transactions.take(filters.maxTransactions!).toList()
        : transactions;

    final rows = displayRows
        .map(
          (item) => [
            DateFormat('dd/MM/yyyy').format(item.date),
            _safeCell(_transactionTypeLabel(item.type), maxChars: 26),
            _safeCell(item.sourceName ?? '-', maxChars: 24),
            _safeCell(item.categoryName, maxChars: 26),
            _formatAmount(item.amount, item.currency),
            _safeCell(_transactionStatusLabel(item.status), maxChars: 16),
          ],
        )
        .toList();

    final notes = <String>[];
    if (displayRows.length != transactions.length) {
      notes.add(
        'Affichage limité à ${displayRows.length} lignes (sur ${transactions.length})',
      );
    }

    _addTableSectionPages(
      pdf: pdf,
      title: 'TRANSACTIONS',
      totalCount: transactions.length,
      headers: const [
        'Date',
        'Type',
        'Source',
        'Catégorie',
        'Montant',
        'Statut',
      ],
      rows: rows,
      emptyMessage: 'Aucune transaction correspondant aux filtres.',
      notes: notes,
    );
  }

  static void _addAssetsPages(pw.Document pdf, List<AssetModel> assets) {
    final rows = assets
        .map(
          (item) => [
            _safeCell(item.name, maxChars: 28),
            _safeCell(_assetTypeLabel(item.type), maxChars: 20),
            _safeCell(_assetStatusLabel(item.status), maxChars: 18),
            _formatAmount(item.totalValue, item.currency),
            _formatAmount(item.profitLoss, item.currency),
          ],
        )
        .toList();

    final totalValue = assets.fold<double>(
      0.0,
      (sum, item) => sum + item.totalValue,
    );

    _addTableSectionPages(
      pdf: pdf,
      title: 'ACTIFS',
      totalCount: assets.length,
      headers: const ['Nom', 'Type', 'Statut', 'Valeur', 'P&L'],
      rows: rows,
      emptyMessage: 'Aucun actif correspondant aux filtres.',
      notes: ['Valeur totale: ${_formatAmount(totalValue, 'BIF')}'],
    );
  }

  static void _addDebtsPages(pw.Document pdf, List<DebtModel> debts) {
    final rows = debts
        .map(
          (item) => [
            _safeCell(item.personName, maxChars: 30),
            _safeCell(item.type == DebtType.given ? 'Prêtée' : 'Empruntée'),
            _safeCell(_debtStatusLabel(item.status), maxChars: 18),
            item.dueDate != null
                ? DateFormat('dd/MM/yyyy').format(item.dueDate!)
                : '-',
            _formatAmount(item.remainingAmount, item.currency),
          ],
        )
        .toList();

    final totalGiven = debts
        .where((d) => d.type == DebtType.given)
        .fold<double>(0.0, (sum, item) => sum + item.remainingAmount);
    final totalReceived = debts
        .where((d) => d.type == DebtType.received)
        .fold<double>(0.0, (sum, item) => sum + item.remainingAmount);

    _addTableSectionPages(
      pdf: pdf,
      title: 'DETTES',
      totalCount: debts.length,
      headers: const ['Personne', 'Type', 'Statut', 'Echéance', 'Reste'],
      rows: rows,
      emptyMessage: 'Aucune dette correspondant aux filtres.',
      notes: [
        'Prêtées: ${_formatAmount(totalGiven, 'BIF')} | Empruntées: ${_formatAmount(totalReceived, 'BIF')}',
      ],
    );
  }

  static void _addBanksPages(pw.Document pdf, List<BankModel> banks) {
    final rows = banks
        .map(
          (item) => [
            _safeCell(item.name, maxChars: 28),
            _safeCell(item.bankType == BankType.free ? 'Gratuite' : 'Payante'),
            _safeCell(item.isActive ? 'Active' : 'Inactive'),
            _safeCell(
              item.interestType == InterestType.monthly ? 'Mensuel' : 'Annuel',
            ),
            _formatAmount(item.balance, item.currency),
          ],
        )
        .toList();

    final total = banks.fold<double>(0.0, (sum, item) => sum + item.balance);

    _addTableSectionPages(
      pdf: pdf,
      title: 'BANQUES',
      totalCount: banks.length,
      headers: const ['Nom', 'Type', 'Etat', 'Intérêt', 'Solde'],
      rows: rows,
      emptyMessage: 'Aucune banque correspondant aux filtres.',
      notes: ['Solde total: ${_formatAmount(total, 'BIF')}'],
    );
  }

  static void _addSourcesPages(pw.Document pdf, List<src.SourceModel> sources) {
    final rows = sources
        .map(
          (item) => [
            _safeCell(item.name, maxChars: 28),
            _safeCell(_sourceTypeLabel(item.type), maxChars: 22),
            _safeCell(item.isActive ? 'Active' : 'Inactive', maxChars: 16),
            _safeCell(
              item.isPassive ? 'Passive' : 'Active nette',
              maxChars: 18,
            ),
            _formatAmount(item.amount, item.currency),
          ],
        )
        .toList();

    final total = sources.fold<double>(0.0, (sum, item) => sum + item.amount);

    _addTableSectionPages(
      pdf: pdf,
      title: 'SOURCES',
      totalCount: sources.length,
      headers: const ['Nom', 'Type', 'Etat', 'Nature', 'Montant'],
      rows: rows,
      emptyMessage: 'Aucune source correspondant aux filtres.',
      notes: ['Total sources: ${_formatAmount(total, 'BIF')}'],
    );
  }

  static void _addTableSectionPages({
    required pw.Document pdf,
    required String title,
    required int totalCount,
    required List<String> headers,
    required List<List<String>> rows,
    required String emptyMessage,
    List<String> notes = const [],
  }) {
    final chunks = _chunkRows(rows);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(22),
        maxPages: _maxSectionPages,
        footer: (context) => _buildPageFooter(context),
        build: (context) {
          if (chunks.isEmpty) {
            return [
              _buildEmptySection(
                title: '$title ($totalCount)',
                message: emptyMessage,
              ),
              pw.SizedBox(height: 10),
              _buildFooter(),
            ];
          }

          return [
            _buildSectionTitle('$title ($totalCount)'),
            if (notes.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              ...notes.map(
                (line) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text(
                    _safeCell(line, maxChars: 96),
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ),
            ],
            if (chunks.length > 1) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                'Parties: ${chunks.length}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
            pw.SizedBox(height: 6),
            for (var i = 0; i < chunks.length; i++) ...[
              _buildSingleTable(headers: headers, rows: chunks[i]),
              if (i < chunks.length - 1) pw.SizedBox(height: 6),
            ],
            pw.SizedBox(height: 10),
            _buildFooter(),
          ];
        },
      ),
    );
  }

  static pw.Widget _buildPageScaffold({
    required pw.Context context,
    required List<pw.Widget> content,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        ...content,
        pw.Spacer(),
        _buildFooter(),
        pw.SizedBox(height: 4),
        _buildPageFooter(context),
      ],
    );
  }

  static _FilteredReportData _applyFilters({
    required List<tx.TransactionModel> transactions,
    required List<AssetModel> assets,
    required List<DebtModel> debts,
    required List<BankModel> banks,
    required List<src.SourceModel> sources,
    required ReportExportFilters filters,
  }) {
    final dateRange = filters.resolveDateRange();
    final now = DateTime.now();

    final filteredTransactions = filters.includeTransactions
        ? transactions.where((item) {
            if (!filters.includeDeleted && item.isDeleted) return false;
            if (!filters.includeCancelledTransactions &&
                item.status == tx.TransactionStatus.cancelled) {
              return false;
            }
            if (dateRange != null && !dateRange.contains(item.date)) {
              return false;
            }
            if (filters.transactionTypes.isNotEmpty &&
                !filters.transactionTypes.contains(item.type)) {
              return false;
            }
            if (filters.transactionStatuses.isNotEmpty &&
                !filters.transactionStatuses.contains(item.status)) {
              return false;
            }
            if (filters.transactionSourceTypes.isNotEmpty &&
                !filters.transactionSourceTypes.contains(item.sourceType)) {
              return false;
            }
            if (filters.selectedTransactionSourceIds.isNotEmpty &&
                !filters.selectedTransactionSourceIds.contains(item.sourceId)) {
              return false;
            }
            if (filters.selectedTransactionTargetIds.isNotEmpty) {
              final target = item.targetSourceId;
              if (target == null ||
                  !filters.selectedTransactionTargetIds.contains(target)) {
                return false;
              }
            }
            if (filters.recurringOnly && !item.isRecurring) return false;
            if (filters.nonRecurringOnly && item.isRecurring) return false;
            if (filters.incomeCategories.isNotEmpty &&
                item.type == tx.TransactionType.income &&
                !filters.incomeCategories.contains(item.incomeCategory)) {
              return false;
            }
            if (filters.expenseCategories.isNotEmpty &&
                item.type == tx.TransactionType.expense &&
                !filters.expenseCategories.contains(item.expenseCategory)) {
              return false;
            }
            if (filters.transactionMinAmount != null &&
                item.amount < filters.transactionMinAmount!) {
              return false;
            }
            if (filters.transactionMaxAmount != null &&
                item.amount > filters.transactionMaxAmount!) {
              return false;
            }
            if (filters.transactionCurrencies.isNotEmpty &&
                !filters.transactionCurrencies.contains(
                  item.currency.toUpperCase(),
                )) {
              return false;
            }
            final keyword = filters.transactionKeyword?.trim().toLowerCase();
            if (keyword != null && keyword.isNotEmpty) {
              final haystack = [
                item.categoryName,
                item.description,
                item.note,
                item.sourceName,
                item.targetSourceName,
              ].whereType<String>().join(' ').toLowerCase();
              if (!haystack.contains(keyword)) return false;
            }
            return true;
          }).toList()
        : <tx.TransactionModel>[];

    final filteredAssets = filters.includeAssets
        ? assets.where((item) {
            if (!filters.includeDeleted && item.isDeleted) return false;
            if (dateRange != null && !dateRange.contains(item.purchaseDate)) {
              return false;
            }
            if (filters.selectedAssetIds.isNotEmpty &&
                !filters.selectedAssetIds.contains(item.id)) {
              return false;
            }
            if (filters.assetTypes.isNotEmpty &&
                !filters.assetTypes.contains(item.type)) {
              return false;
            }
            if (filters.assetStatuses.isNotEmpty &&
                !filters.assetStatuses.contains(item.status)) {
              return false;
            }
            if (filters.assetMinValue != null &&
                item.totalValue < filters.assetMinValue!) {
              return false;
            }
            if (filters.assetMaxValue != null &&
                item.totalValue > filters.assetMaxValue!) {
              return false;
            }
            if (filters.assetCurrencies.isNotEmpty &&
                !filters.assetCurrencies.contains(
                  item.currency.toUpperCase(),
                )) {
              return false;
            }
            final keyword = filters.assetKeyword?.trim().toLowerCase();
            if (keyword != null && keyword.isNotEmpty) {
              final haystack = [
                item.name,
                item.description,
                item.location,
              ].whereType<String>().join(' ').toLowerCase();
              if (!haystack.contains(keyword)) return false;
            }
            return true;
          }).toList()
        : <AssetModel>[];

    final filteredDebts = filters.includeDebts
        ? debts.where((item) {
            if (!filters.includeDeleted && item.isDeleted) return false;
            if (dateRange != null && !dateRange.contains(item.date)) {
              return false;
            }
            if (filters.selectedDebtIds.isNotEmpty &&
                !filters.selectedDebtIds.contains(item.id)) {
              return false;
            }
            if (filters.debtTypes.isNotEmpty &&
                !filters.debtTypes.contains(item.type)) {
              return false;
            }
            if (filters.debtStatuses.isNotEmpty &&
                !filters.debtStatuses.contains(item.status)) {
              return false;
            }
            if (filters.debtOverdueOnly && !item.isOverdue) return false;
            if (filters.debtHasReminderOnly && !item.hasReminder) return false;
            if (filters.debtDueInDays != null) {
              if (item.dueDate == null) return false;
              final dueDate = item.dueDate!;
              final maxDate = now.add(Duration(days: filters.debtDueInDays!));
              final isWithinRange =
                  !dueDate.isBefore(DateTime(now.year, now.month, now.day)) &&
                  !dueDate.isAfter(
                    DateTime(maxDate.year, maxDate.month, maxDate.day),
                  );
              if (!isWithinRange) return false;
            }
            if (filters.debtMinAmount != null &&
                item.remainingAmount < filters.debtMinAmount!) {
              return false;
            }
            if (filters.debtMaxAmount != null &&
                item.remainingAmount > filters.debtMaxAmount!) {
              return false;
            }
            if (filters.debtCurrencies.isNotEmpty &&
                !filters.debtCurrencies.contains(item.currency.toUpperCase())) {
              return false;
            }
            final keyword = filters.debtPersonKeyword?.trim().toLowerCase();
            if (keyword != null && keyword.isNotEmpty) {
              final haystack = [
                item.personName,
                item.personContact,
                item.description,
                item.notes,
              ].whereType<String>().join(' ').toLowerCase();
              if (!haystack.contains(keyword)) return false;
            }
            return true;
          }).toList()
        : <DebtModel>[];

    final filteredBanks = filters.includeBanks
        ? banks.where((item) {
            if (!filters.includeDeleted && item.isDeleted) return false;
            if (dateRange != null && !dateRange.contains(item.createdAt)) {
              return false;
            }
            if (filters.selectedBankIds.isNotEmpty &&
                !filters.selectedBankIds.contains(item.id)) {
              return false;
            }
            if (filters.bankTypes.isNotEmpty &&
                !filters.bankTypes.contains(item.bankType)) {
              return false;
            }
            if (filters.bankInterestTypes.isNotEmpty &&
                !filters.bankInterestTypes.contains(item.interestType)) {
              return false;
            }
            if (filters.bankActiveOnly && !item.isActive) return false;
            if (filters.bankMinBalance != null &&
                item.balance < filters.bankMinBalance!) {
              return false;
            }
            if (filters.bankMaxBalance != null &&
                item.balance > filters.bankMaxBalance!) {
              return false;
            }
            if (filters.bankCurrencies.isNotEmpty &&
                !filters.bankCurrencies.contains(item.currency.toUpperCase())) {
              return false;
            }
            final keyword = filters.bankKeyword?.trim().toLowerCase();
            if (keyword != null && keyword.isNotEmpty) {
              final haystack = [
                item.name,
                item.description,
                item.accountNumber,
              ].whereType<String>().join(' ').toLowerCase();
              if (!haystack.contains(keyword)) return false;
            }
            return true;
          }).toList()
        : <BankModel>[];

    final filteredSources = filters.includeSources
        ? sources.where((item) {
            if (!filters.includeDeleted && item.isDeleted) return false;
            if (dateRange != null && !dateRange.contains(item.createdAt)) {
              return false;
            }
            if (filters.selectedSourceIds.isNotEmpty &&
                !filters.selectedSourceIds.contains(item.id)) {
              return false;
            }
            if (filters.sourceTypes.isNotEmpty &&
                !filters.sourceTypes.contains(item.type)) {
              return false;
            }
            if (filters.sourceActiveOnly && !item.isActive) return false;
            if (filters.sourcePassiveOnly && !item.isPassive) return false;
            if (filters.sourceMinAmount != null &&
                item.amount < filters.sourceMinAmount!) {
              return false;
            }
            if (filters.sourceMaxAmount != null &&
                item.amount > filters.sourceMaxAmount!) {
              return false;
            }
            if (filters.sourceCurrencies.isNotEmpty &&
                !filters.sourceCurrencies.contains(
                  item.currency.toUpperCase(),
                )) {
              return false;
            }
            final keyword = filters.sourceKeyword?.trim().toLowerCase();
            if (keyword != null && keyword.isNotEmpty) {
              final haystack = [
                item.name,
                item.description,
              ].whereType<String>().join(' ').toLowerCase();
              if (!haystack.contains(keyword)) return false;
            }
            return true;
          }).toList()
        : <src.SourceModel>[];

    _sortTransactions(filteredTransactions, filters.sortBy);
    _sortAssets(filteredAssets, filters.sortBy);
    _sortDebts(filteredDebts, filters.sortBy);
    _sortBanks(filteredBanks, filters.sortBy);
    _sortSources(filteredSources, filters.sortBy);

    return _FilteredReportData(
      transactions: filteredTransactions,
      assets: filteredAssets,
      debts: filteredDebts,
      banks: filteredBanks,
      sources: filteredSources,
    );
  }

  static _ReportSummary _computeSummary(
    _FilteredReportData data, {
    required double fallbackTotalWealth,
    required double fallbackTotalIncome,
    required double fallbackTotalExpense,
  }) {
    final income = data.transactions
        .where((t) => t.type == tx.TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final expense = data.transactions
        .where((t) => t.type == tx.TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final sourcesAmount = data.sources.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final banksAmount = data.banks.fold<double>(
      0,
      (sum, item) => sum + item.balance,
    );
    final assetsAmount = data.assets.fold<double>(
      0,
      (sum, item) => sum + item.totalValue,
    );
    final debtGiven = data.debts
        .where((d) => d.type == DebtType.given)
        .fold<double>(0, (sum, item) => sum + item.remainingAmount);
    final debtReceived = data.debts
        .where((d) => d.type == DebtType.received)
        .fold<double>(0, (sum, item) => sum + item.remainingAmount);

    final computedWealth =
        sourcesAmount + banksAmount + assetsAmount + debtGiven - debtReceived;

    return _ReportSummary(
      totalWealth:
          data.transactions.isEmpty &&
              data.assets.isEmpty &&
              data.debts.isEmpty &&
              data.banks.isEmpty &&
              data.sources.isEmpty
          ? fallbackTotalWealth
          : computedWealth,
      totalIncome: data.transactions.isEmpty ? fallbackTotalIncome : income,
      totalExpense: data.transactions.isEmpty ? fallbackTotalExpense : expense,
    );
  }

  static String _resolvePeriodLabel(
    String fallbackPeriod,
    ReportExportFilters filters,
  ) {
    final dateRange = filters.resolveDateRange();
    if (dateRange != null) return dateRange.label();

    return switch (filters.datePreset) {
      ReportDatePreset.all => fallbackPeriod,
      ReportDatePreset.today => 'Aujourd\'hui',
      ReportDatePreset.yesterday => 'Hier',
      ReportDatePreset.last7Days => '7 derniers jours',
      ReportDatePreset.thisMonth => 'Ce mois',
      ReportDatePreset.lastMonth => 'Mois dernier',
      ReportDatePreset.thisYear => 'Cette année',
      ReportDatePreset.custom => fallbackPeriod,
    };
  }

  static pw.Widget _buildHeader({
    required String title,
    required String period,
    required _ReportSummary summary,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey900,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'IKIGABO',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue100,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Période: $period',
            style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10),
          ),
          pw.Text(
            'Généré le ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildHeaderChip(
                'Patrimoine',
                _formatAmount(summary.totalWealth, 'BIF'),
              ),
              pw.SizedBox(width: 8),
              _buildHeaderChip(
                'Balance',
                _formatAmount(summary.balance, 'BIF'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(999),
      ),
      child: pw.Text(
        '$label: $value',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey900,
        ),
      ),
    );
  }

  static pw.Widget _buildScopeSummary(_FilteredReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _buildCountChip(
            'Transactions',
            data.transactions.length,
            PdfColors.blue,
          ),
          _buildCountChip('Actifs', data.assets.length, PdfColors.orange),
          _buildCountChip('Dettes', data.debts.length, PdfColors.red),
          _buildCountChip('Banques', data.banks.length, PdfColors.green),
          _buildCountChip('Sources', data.sources.length, PdfColors.purple),
        ],
      ),
    );
  }

  static pw.Widget _buildCountChip(String label, int count, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Text(
        '$label: $count',
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildFiltersSection(ReportExportFilters filters) {
    final tags = <String>[];
    final range = filters.resolveDateRange();
    if (range != null) {
      tags.add(_safeCell('Période: ${range.label()}', maxChars: 110));
    }
    if (filters.transactionTypes.isNotEmpty) {
      tags.add(
        _safeCell(
          'Types transactions: ${filters.transactionTypes.map((e) => _transactionTypeLabel(e)).join(', ')}',
          maxChars: 110,
        ),
      );
    }
    if (filters.transactionMinAmount != null ||
        filters.transactionMaxAmount != null) {
      tags.add(
        _safeCell(
          'Montant transactions: '
          '${filters.transactionMinAmount?.toStringAsFixed(0) ?? '0'} - '
          '${filters.transactionMaxAmount?.toStringAsFixed(0) ?? '∞'}',
          maxChars: 110,
        ),
      );
    }
    if (filters.selectedBankIds.isNotEmpty) {
      tags.add('Banques sélectionnées: ${filters.selectedBankIds.length}');
    }
    if (filters.selectedSourceIds.isNotEmpty) {
      tags.add('Sources sélectionnées: ${filters.selectedSourceIds.length}');
    }
    if (filters.selectedAssetIds.isNotEmpty) {
      tags.add('Actifs sélectionnés: ${filters.selectedAssetIds.length}');
    }
    if (filters.selectedDebtIds.isNotEmpty) {
      tags.add('Dettes sélectionnées: ${filters.selectedDebtIds.length}');
    }
    if (filters.debtOverdueOnly) tags.add('Dettes en retard uniquement');
    if (filters.bankActiveOnly) tags.add('Banques actives uniquement');
    if (filters.sourceActiveOnly) tags.add('Sources actives uniquement');
    if (filters.sourcePassiveOnly) tags.add('Sources passives uniquement');
    if (filters.transactionKeyword?.trim().isNotEmpty ?? false) {
      tags.add(
        _safeCell(
          'Mot-clé transaction: "${filters.transactionKeyword!.trim()}"',
          maxChars: 110,
        ),
      );
    }
    if (filters.debtPersonKeyword?.trim().isNotEmpty ?? false) {
      tags.add(
        _safeCell(
          'Mot-clé dette: "${filters.debtPersonKeyword!.trim()}"',
          maxChars: 110,
        ),
      );
    }

    if (tags.isEmpty) {
      tags.add('Rapport sans filtre avancé.');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('FILTRES APPLIQUES'),
        pw.SizedBox(height: 6),
        ...tags.map(
          (tag) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Bullet(text: tag, style: const pw.TextStyle(fontSize: 9)),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummarySection(_ReportSummary summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('RESUME FINANCIER'),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildMetricCard(
                label: 'Patrimoine',
                value: _formatAmount(summary.totalWealth, 'BIF'),
                color: PdfColors.blue,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildMetricCard(
                label: 'Revenus',
                value: _formatAmount(summary.totalIncome, 'BIF'),
                color: PdfColors.green,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildMetricCard(
                label: 'Dépenses',
                value: _formatAmount(summary.totalExpense, 'BIF'),
                color: PdfColors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMetricCard({
    required String label,
    required String value,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static List<List<List<String>>> _chunkRows(
    List<List<String>> rows, {
    int chunkSize = _rowsPerTableChunk,
  }) {
    if (rows.isEmpty) return const [];
    final chunks = <List<List<String>>>[];
    for (var i = 0; i < rows.length; i += chunkSize) {
      final end = math.min(i + chunkSize, rows.length);
      chunks.add(rows.sublist(i, end));
    }
    return chunks;
  }

  static List<pw.Widget> _buildTransactionsSectionWidgets(
    List<tx.TransactionModel> transactions,
    ReportExportFilters filters,
  ) {
    if (transactions.isEmpty) {
      return [
        _buildEmptySection(
          title: 'TRANSACTIONS',
          message: 'Aucune transaction correspondant aux filtres.',
        ),
      ];
    }

    final displayRows =
        filters.maxTransactions != null && filters.maxTransactions! > 0
        ? transactions.take(filters.maxTransactions!).toList()
        : transactions;

    final rows = displayRows
        .map(
          (item) => [
            DateFormat('dd/MM/yyyy').format(item.date),
            _safeCell(_transactionTypeLabel(item.type)),
            _safeCell(item.sourceName ?? '-'),
            _safeCell(item.categoryName),
            _formatAmount(item.amount, item.currency),
            _safeCell(_transactionStatusLabel(item.status)),
          ],
        )
        .toList();

    final rowChunks = _chunkRows(rows);

    return [
      _buildSectionTitle('TRANSACTIONS (${transactions.length})'),
      if (displayRows.length != transactions.length)
        pw.Text(
          'Affichage limité à ${displayRows.length} lignes (sur ${transactions.length})',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      pw.SizedBox(height: 6),
      for (var i = 0; i < rowChunks.length; i++) ...[
        _buildSingleTable(
          headers: const [
            'Date',
            'Type',
            'Source',
            'Catégorie',
            'Montant',
            'Statut',
          ],
          rows: rowChunks[i],
        ),
        if (i < rowChunks.length - 1) pw.SizedBox(height: 6),
      ],
    ];
  }

  static List<pw.Widget> _buildAssetsSectionWidgets(List<AssetModel> assets) {
    if (assets.isEmpty) {
      return [
        _buildEmptySection(
          title: 'ACTIFS',
          message: 'Aucun actif correspondant aux filtres.',
        ),
      ];
    }

    final rows = assets
        .map(
          (item) => [
            _safeCell(item.name),
            _safeCell(_assetTypeLabel(item.type)),
            _safeCell(_assetStatusLabel(item.status)),
            _formatAmount(item.totalValue, item.currency),
            _formatAmount(item.profitLoss, item.currency),
          ],
        )
        .toList();

    final totalValue = assets.fold<double>(
      0.0,
      (sum, item) => sum + item.totalValue,
    );
    final rowChunks = _chunkRows(rows);

    return [
      _buildSectionTitle('ACTIFS (${assets.length})'),
      pw.Text(
        'Valeur totale: ${_formatAmount(totalValue, 'BIF')}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 6),
      for (var i = 0; i < rowChunks.length; i++) ...[
        _buildSingleTable(
          headers: const ['Nom', 'Type', 'Statut', 'Valeur', 'P&L'],
          rows: rowChunks[i],
        ),
        if (i < rowChunks.length - 1) pw.SizedBox(height: 6),
      ],
    ];
  }

  static List<pw.Widget> _buildDebtsSectionWidgets(List<DebtModel> debts) {
    if (debts.isEmpty) {
      return [
        _buildEmptySection(
          title: 'DETTES',
          message: 'Aucune dette correspondant aux filtres.',
        ),
      ];
    }

    final rows = debts
        .map(
          (item) => [
            _safeCell(item.personName),
            _safeCell(item.type == DebtType.given ? 'Prêtée' : 'Empruntée'),
            _safeCell(_debtStatusLabel(item.status)),
            item.dueDate != null
                ? DateFormat('dd/MM/yyyy').format(item.dueDate!)
                : '-',
            _formatAmount(item.remainingAmount, item.currency),
          ],
        )
        .toList();

    final totalGiven = debts
        .where((d) => d.type == DebtType.given)
        .fold<double>(0.0, (sum, item) => sum + item.remainingAmount);
    final totalReceived = debts
        .where((d) => d.type == DebtType.received)
        .fold<double>(0.0, (sum, item) => sum + item.remainingAmount);
    final rowChunks = _chunkRows(rows);

    return [
      _buildSectionTitle('DETTES (${debts.length})'),
      pw.Text(
        'Prêtées: ${_formatAmount(totalGiven, 'BIF')} | Empruntées: ${_formatAmount(totalReceived, 'BIF')}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 6),
      for (var i = 0; i < rowChunks.length; i++) ...[
        _buildSingleTable(
          headers: const ['Personne', 'Type', 'Statut', 'Echéance', 'Reste'],
          rows: rowChunks[i],
        ),
        if (i < rowChunks.length - 1) pw.SizedBox(height: 6),
      ],
    ];
  }

  static List<pw.Widget> _buildBanksSectionWidgets(List<BankModel> banks) {
    if (banks.isEmpty) {
      return [
        _buildEmptySection(
          title: 'BANQUES',
          message: 'Aucune banque correspondant aux filtres.',
        ),
      ];
    }

    final rows = banks
        .map(
          (item) => [
            _safeCell(item.name),
            _safeCell(item.bankType == BankType.free ? 'Gratuite' : 'Payante'),
            _safeCell(item.isActive ? 'Active' : 'Inactive'),
            _safeCell(
              item.interestType == InterestType.monthly ? 'Mensuel' : 'Annuel',
            ),
            _formatAmount(item.balance, item.currency),
          ],
        )
        .toList();

    final total = banks.fold<double>(0.0, (sum, item) => sum + item.balance);
    final rowChunks = _chunkRows(rows);

    return [
      _buildSectionTitle('BANQUES (${banks.length})'),
      pw.Text(
        'Solde total: ${_formatAmount(total, 'BIF')}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 6),
      for (var i = 0; i < rowChunks.length; i++) ...[
        _buildSingleTable(
          headers: const ['Nom', 'Type', 'Etat', 'Intérêt', 'Solde'],
          rows: rowChunks[i],
        ),
        if (i < rowChunks.length - 1) pw.SizedBox(height: 6),
      ],
    ];
  }

  static List<pw.Widget> _buildSourcesSectionWidgets(
    List<src.SourceModel> sources,
  ) {
    if (sources.isEmpty) {
      return [
        _buildEmptySection(
          title: 'SOURCES',
          message: 'Aucune source correspondant aux filtres.',
        ),
      ];
    }

    final rows = sources
        .map(
          (item) => [
            _safeCell(item.name),
            _safeCell(_sourceTypeLabel(item.type)),
            _safeCell(item.isActive ? 'Active' : 'Inactive'),
            _safeCell(item.isPassive ? 'Passive' : 'Active nette'),
            _formatAmount(item.amount, item.currency),
          ],
        )
        .toList();

    final total = sources.fold<double>(0.0, (sum, item) => sum + item.amount);
    final rowChunks = _chunkRows(rows);

    return [
      _buildSectionTitle('SOURCES (${sources.length})'),
      pw.Text(
        'Total sources: ${_formatAmount(total, 'BIF')}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 6),
      for (var i = 0; i < rowChunks.length; i++) ...[
        _buildSingleTable(
          headers: const ['Nom', 'Type', 'Etat', 'Nature', 'Montant'],
          rows: rowChunks[i],
        ),
        if (i < rowChunks.length - 1) pw.SizedBox(height: 6),
      ],
    ];
  }

  static pw.Widget _buildTransactionsSection(
    List<tx.TransactionModel> transactions,
    ReportExportFilters filters,
  ) {
    if (transactions.isEmpty) {
      return _buildEmptySection(
        title: 'TRANSACTIONS',
        message: 'Aucune transaction correspondant aux filtres.',
      );
    }

    final displayRows =
        filters.maxTransactions != null && filters.maxTransactions! > 0
        ? transactions.take(filters.maxTransactions!).toList()
        : transactions;

    final rows = displayRows
        .map(
          (item) => [
            DateFormat('dd/MM/yyyy').format(item.date),
            _safeCell(_transactionTypeLabel(item.type)),
            _safeCell(item.sourceName ?? '-'),
            _safeCell(item.categoryName),
            _formatAmount(item.amount, item.currency),
            _safeCell(_transactionStatusLabel(item.status)),
          ],
        )
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('TRANSACTIONS (${transactions.length})'),
        if (displayRows.length != transactions.length)
          pw.Text(
            'Affichage limité à ${displayRows.length} lignes (sur ${transactions.length})',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        pw.SizedBox(height: 6),
        _buildTable(
          headers: const [
            'Date',
            'Type',
            'Source',
            'Catégorie',
            'Montant',
            'Statut',
          ],
          rows: rows,
        ),
      ],
    );
  }

  static pw.Widget _buildAssetsSection(List<AssetModel> assets) {
    if (assets.isEmpty) {
      return _buildEmptySection(
        title: 'ACTIFS',
        message: 'Aucun actif correspondant aux filtres.',
      );
    }

    final rows = assets
        .map(
          (item) => [
            _safeCell(item.name),
            _safeCell(_assetTypeLabel(item.type)),
            _safeCell(_assetStatusLabel(item.status)),
            _formatAmount(item.totalValue, item.currency),
            _formatAmount(item.profitLoss, item.currency),
          ],
        )
        .toList();

    final totalValue = assets.fold<double>(
      0.0,
      (sum, item) => sum + item.totalValue,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ACTIFS (${assets.length})'),
        pw.Text(
          'Valeur totale: ${_formatAmount(totalValue, 'BIF')}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 6),
        _buildTable(
          headers: const ['Nom', 'Type', 'Statut', 'Valeur', 'P&L'],
          rows: rows,
        ),
      ],
    );
  }

  static pw.Widget _buildDebtsSection(List<DebtModel> debts) {
    if (debts.isEmpty) {
      return _buildEmptySection(
        title: 'DETTES',
        message: 'Aucune dette correspondant aux filtres.',
      );
    }

    final rows = debts
        .map(
          (item) => [
            _safeCell(item.personName),
            _safeCell(item.type == DebtType.given ? 'Prêtée' : 'Empruntée'),
            _safeCell(_debtStatusLabel(item.status)),
            item.dueDate != null
                ? DateFormat('dd/MM/yyyy').format(item.dueDate!)
                : '-',
            _formatAmount(item.remainingAmount, item.currency),
          ],
        )
        .toList();

    final totalGiven = debts
        .where((d) => d.type == DebtType.given)
        .fold<double>(0.0, (sum, item) => sum + item.remainingAmount);
    final totalReceived = debts
        .where((d) => d.type == DebtType.received)
        .fold<double>(0.0, (sum, item) => sum + item.remainingAmount);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('DETTES (${debts.length})'),
        pw.Text(
          'Prêtées: ${_formatAmount(totalGiven, 'BIF')} | Empruntées: ${_formatAmount(totalReceived, 'BIF')}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 6),
        _buildTable(
          headers: const ['Personne', 'Type', 'Statut', 'Echéance', 'Reste'],
          rows: rows,
        ),
      ],
    );
  }

  static pw.Widget _buildBanksSection(List<BankModel> banks) {
    if (banks.isEmpty) {
      return _buildEmptySection(
        title: 'BANQUES',
        message: 'Aucune banque correspondant aux filtres.',
      );
    }

    final rows = banks
        .map(
          (item) => [
            _safeCell(item.name),
            _safeCell(item.bankType == BankType.free ? 'Gratuite' : 'Payante'),
            _safeCell(item.isActive ? 'Active' : 'Inactive'),
            _safeCell(
              item.interestType == InterestType.monthly ? 'Mensuel' : 'Annuel',
            ),
            _formatAmount(item.balance, item.currency),
          ],
        )
        .toList();

    final total = banks.fold<double>(0.0, (sum, item) => sum + item.balance);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('BANQUES (${banks.length})'),
        pw.Text(
          'Solde total: ${_formatAmount(total, 'BIF')}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 6),
        _buildTable(
          headers: const ['Nom', 'Type', 'Etat', 'Intérêt', 'Solde'],
          rows: rows,
        ),
      ],
    );
  }

  static pw.Widget _buildSourcesSection(List<src.SourceModel> sources) {
    if (sources.isEmpty) {
      return _buildEmptySection(
        title: 'SOURCES',
        message: 'Aucune source correspondant aux filtres.',
      );
    }

    final rows = sources
        .map(
          (item) => [
            _safeCell(item.name),
            _safeCell(_sourceTypeLabel(item.type)),
            _safeCell(item.isActive ? 'Active' : 'Inactive'),
            _safeCell(item.isPassive ? 'Passive' : 'Active nette'),
            _formatAmount(item.amount, item.currency),
          ],
        )
        .toList();

    final total = sources.fold<double>(0.0, (sum, item) => sum + item.amount);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('SOURCES (${sources.length})'),
        pw.Text(
          'Total sources: ${_formatAmount(total, 'BIF')}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 6),
        _buildTable(
          headers: const ['Nom', 'Type', 'Etat', 'Nature', 'Montant'],
          rows: rows,
        ),
      ],
    );
  }

  static pw.Widget _buildTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    if (rows.isEmpty) {
      return pw.SizedBox.shrink();
    }

    final chunks = <List<List<String>>>[];
    for (var i = 0; i < rows.length; i += _rowsPerTableChunk) {
      final end = math.min(i + _rowsPerTableChunk, rows.length);
      chunks.add(rows.sublist(i, end));
    }

    if (chunks.length == 1) {
      return _buildSingleTable(headers: headers, rows: chunks.first);
    }

    return pw.Column(
      children: [
        for (var i = 0; i < chunks.length; i++) ...[
          _buildSingleTable(headers: headers, rows: chunks[i]),
          if (i < chunks.length - 1) pw.SizedBox(height: 6),
        ],
      ],
    );
  }

  static pw.Widget _buildSingleTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 8.5,
        color: PdfColors.blueGrey900,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
    );
  }

  static pw.Widget _buildSectionTitle(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey800,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildEmptySection({
    required String title,
    required String message,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            message,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.Text(
          'Rapport généré par Ikigabo. Données locales, mode offline-first.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.Text(
          'Les montants agrégés peuvent inclure plusieurs devises selon les filtres.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Page ${context.pageNumber} / ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  static String _safeCell(String value, {int maxChars = 56}) {
    final singleLine = value
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    if (singleLine.isEmpty) return '-';
    if (singleLine.length <= maxChars) return singleLine;
    return '${singleLine.substring(0, maxChars - 1)}…';
  }

  static Future<pw.Document> _createPdfDocument() async {
    try {
      final baseFont = pw.Font.ttf(await _loadFontAsset('DejaVuSans.ttf'));
      final boldFont = pw.Font.ttf(await _loadFontAsset('DejaVuSans-Bold.ttf'));

      return pw.Document(
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
          italic: baseFont,
          boldItalic: boldFont,
        ),
      );
    } catch (_) {
      // Fallback if font assets are unavailable.
      return pw.Document();
    }
  }

  static Future<ByteData> _loadFontAsset(String fileName) async {
    try {
      return await rootBundle.load('assets/fonts/$fileName');
    } catch (_) {
      return rootBundle.load('packages/ikigabo/assets/fonts/$fileName');
    }
  }

  static Future<String> _savePdf(pw.Document pdf, String filename) async {
    try {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Sauvegarder le rapport PDF',
        fileName: '$filename.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: Uint8List.fromList(await pdf.save()),
      );

      if (outputFile == null) {
        throw Exception('Sauvegarde annulée par l\'utilisateur');
      }

      return outputFile;
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde PDF: $e');
    }
  }

  static void _sortTransactions(
    List<tx.TransactionModel> items,
    ReportSortBy sortBy,
  ) {
    items.sort((a, b) {
      return switch (sortBy) {
        ReportSortBy.newest => b.date.compareTo(a.date),
        ReportSortBy.oldest => a.date.compareTo(b.date),
        ReportSortBy.amountDesc => b.amount.compareTo(a.amount),
        ReportSortBy.amountAsc => a.amount.compareTo(b.amount),
        ReportSortBy.nameAsc => (a.sourceName ?? '').toLowerCase().compareTo(
          (b.sourceName ?? '').toLowerCase(),
        ),
        ReportSortBy.nameDesc => (b.sourceName ?? '').toLowerCase().compareTo(
          (a.sourceName ?? '').toLowerCase(),
        ),
      };
    });
  }

  static void _sortAssets(List<AssetModel> items, ReportSortBy sortBy) {
    items.sort((a, b) {
      return switch (sortBy) {
        ReportSortBy.newest => b.purchaseDate.compareTo(a.purchaseDate),
        ReportSortBy.oldest => a.purchaseDate.compareTo(b.purchaseDate),
        ReportSortBy.amountDesc => b.totalValue.compareTo(a.totalValue),
        ReportSortBy.amountAsc => a.totalValue.compareTo(b.totalValue),
        ReportSortBy.nameAsc => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        ReportSortBy.nameDesc => b.name.toLowerCase().compareTo(
          a.name.toLowerCase(),
        ),
      };
    });
  }

  static void _sortDebts(List<DebtModel> items, ReportSortBy sortBy) {
    items.sort((a, b) {
      return switch (sortBy) {
        ReportSortBy.newest => b.date.compareTo(a.date),
        ReportSortBy.oldest => a.date.compareTo(b.date),
        ReportSortBy.amountDesc => b.remainingAmount.compareTo(
          a.remainingAmount,
        ),
        ReportSortBy.amountAsc => a.remainingAmount.compareTo(
          b.remainingAmount,
        ),
        ReportSortBy.nameAsc => a.personName.toLowerCase().compareTo(
          b.personName.toLowerCase(),
        ),
        ReportSortBy.nameDesc => b.personName.toLowerCase().compareTo(
          a.personName.toLowerCase(),
        ),
      };
    });
  }

  static void _sortBanks(List<BankModel> items, ReportSortBy sortBy) {
    items.sort((a, b) {
      return switch (sortBy) {
        ReportSortBy.newest => b.createdAt.compareTo(a.createdAt),
        ReportSortBy.oldest => a.createdAt.compareTo(b.createdAt),
        ReportSortBy.amountDesc => b.balance.compareTo(a.balance),
        ReportSortBy.amountAsc => a.balance.compareTo(b.balance),
        ReportSortBy.nameAsc => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        ReportSortBy.nameDesc => b.name.toLowerCase().compareTo(
          a.name.toLowerCase(),
        ),
      };
    });
  }

  static void _sortSources(List<src.SourceModel> items, ReportSortBy sortBy) {
    items.sort((a, b) {
      return switch (sortBy) {
        ReportSortBy.newest => b.createdAt.compareTo(a.createdAt),
        ReportSortBy.oldest => a.createdAt.compareTo(b.createdAt),
        ReportSortBy.amountDesc => b.amount.compareTo(a.amount),
        ReportSortBy.amountAsc => a.amount.compareTo(b.amount),
        ReportSortBy.nameAsc => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        ReportSortBy.nameDesc => b.name.toLowerCase().compareTo(
          a.name.toLowerCase(),
        ),
      };
    });
  }

  static String _transactionTypeLabel(tx.TransactionType type) {
    return switch (type) {
      tx.TransactionType.income => 'Entrée',
      tx.TransactionType.expense => 'Sortie',
      tx.TransactionType.transfer => 'Transfert',
    };
  }

  static String _transactionStatusLabel(tx.TransactionStatus status) {
    return switch (status) {
      tx.TransactionStatus.active => 'Active',
      tx.TransactionStatus.cancelled => 'Annulée',
    };
  }

  static String _assetTypeLabel(AssetType type) {
    return switch (type) {
      AssetType.livestock => 'Bétail',
      AssetType.crop => 'Récolte',
      AssetType.land => 'Terrain',
      AssetType.vehicle => 'Véhicule',
      AssetType.equipment => 'Équipement',
      AssetType.jewelry => 'Bijoux',
      AssetType.other => 'Autre',
    };
  }

  static String _assetStatusLabel(AssetStatus status) {
    return switch (status) {
      AssetStatus.owned => 'Possédé',
      AssetStatus.sold => 'Vendu',
      AssetStatus.lost => 'Perdu',
      AssetStatus.donated => 'Donné',
    };
  }

  static String _debtStatusLabel(DebtStatus status) {
    return switch (status) {
      DebtStatus.pending => 'En attente',
      DebtStatus.partiallyPaid => 'Partiel',
      DebtStatus.fullyPaid => 'Payée',
      DebtStatus.cancelled => 'Annulée',
    };
  }

  static String _sourceTypeLabel(src.SourceType type) {
    return switch (type) {
      src.SourceType.pocket => 'Poche',
      src.SourceType.safe => 'Coffre',
      src.SourceType.cash => 'Cash',
      src.SourceType.custom => 'Custom',
    };
  }

  static String _formatAmount(double amount, String currencyCode) {
    final currency =
        AppCurrencies.findByCode(currencyCode) ?? AppCurrencies.bif;
    return CurrencyFormatter.formatAmount(amount, currency);
  }
}
