import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/asset_model.dart';
import '../models/debt_model.dart';
import '../models/bank_model.dart';
import '../models/source_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/constants/currencies.dart';

class PdfExportService {
  static Future<String> exportFinancialReport({
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
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(customTitle ?? 'Rapport Financier', period),
          pw.SizedBox(height: 20),
          _buildSummarySection(totalWealth, totalIncome, totalExpense),
          pw.SizedBox(height: 20),
          _buildAssetsSection(assets),
          pw.SizedBox(height: 20),
          _buildDebtsSection(debts),
          pw.SizedBox(height: 20),
          _buildTransactionsSection(transactions),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    // Créer un nom de fichier lisible : rapport_financier_25-Jan-2026_14h30.pdf
    final now = DateTime.now();
    final dateFormat = DateFormat('dd-MMM-yyyy_HH\'h\'mm');
    final readableDate = dateFormat.format(now);
    return await _savePdf(pdf, 'rapport_financier_$readableDate');
  }

  static pw.Widget _buildHeader(String title, String period) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'IKIGABO',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'Période: $period',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Text(
          'Généré le: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  static pw.Widget _buildSummarySection(double totalWealth, double totalIncome, double totalExpense) {
    final balance = totalIncome - totalExpense;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RÉSUMÉ FINANCIER',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryCard('Patrimoine Total', totalWealth, PdfColors.blue),
            _buildSummaryCard('Revenus', totalIncome, PdfColors.green),
            _buildSummaryCard('Dépenses', totalExpense, PdfColors.red),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: balance >= 0 ? PdfColors.green50 : PdfColors.red50,
            border: pw.Border.all(
              color: balance >= 0 ? PdfColors.green : PdfColors.red,
            ),
          ),
          child: pw.Text(
            'Balance: ${CurrencyFormatter.formatAmount(balance, AppCurrencies.findByCode('BIF')!)}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: balance >= 0 ? PdfColors.green800 : PdfColors.red800,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryCard(String title, double amount, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            CurrencyFormatter.formatAmount(amount, AppCurrencies.bif),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAssetsSection(List<AssetModel> assets) {
    if (assets.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ACTIFS',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Aucun actif enregistré'),
        ],
      );
    }

    final totalValue = assets.fold(0.0, (sum, asset) => sum + asset.totalValue);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ACTIFS (${CurrencyFormatter.formatAmount(totalValue, AppCurrencies.findByCode('BIF')!)})',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Nom', isHeader: true),
                _buildTableCell('Type', isHeader: true),
                _buildTableCell('Valeur', isHeader: true),
                _buildTableCell('P&L', isHeader: true),
              ],
            ),
            ...assets.take(10).map((asset) => pw.TableRow(
              children: [
                _buildTableCell(asset.name),
                _buildTableCell(_getAssetTypeLabel(asset.type)),
                _buildTableCell(CurrencyFormatter.formatAmount(asset.totalValue, AppCurrencies.findByCode(asset.currency)!)),
                _buildTableCell(
                  '${asset.profitLoss >= 0 ? '+' : ''}${asset.profitLossPercentage.toStringAsFixed(1)}%',
                  color: asset.profitLoss >= 0 ? PdfColors.green : PdfColors.red,
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildDebtsSection(List<DebtModel> debts) {
    if (debts.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DETTES',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Aucune dette enregistrée'),
        ],
      );
    }

    final totalGiven = debts.where((d) => d.type == DebtType.given).fold(0.0, (sum, d) => sum + d.remainingAmount);
    final totalReceived = debts.where((d) => d.type == DebtType.received).fold(0.0, (sum, d) => sum + d.remainingAmount);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DETTES',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green),
                ),
                child: pw.Column(
                  children: [
                    pw.Text('Prêtées', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      CurrencyFormatter.formatAmount(totalGiven, AppCurrencies.findByCode('BIF')!),
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  border: pw.Border.all(color: PdfColors.red),
                ),
                child: pw.Column(
                  children: [
                    pw.Text('Empruntées', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      CurrencyFormatter.formatAmount(totalReceived, AppCurrencies.findByCode('BIF')!),
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Personne', isHeader: true),
                _buildTableCell('Type', isHeader: true),
                _buildTableCell('Montant', isHeader: true),
                _buildTableCell('Statut', isHeader: true),
              ],
            ),
            ...debts.take(10).map((debt) => pw.TableRow(
              children: [
                _buildTableCell(debt.personName),
                _buildTableCell(debt.type == DebtType.given ? 'Prêtée' : 'Empruntée'),
                _buildTableCell(CurrencyFormatter.formatAmount(debt.remainingAmount, AppCurrencies.findByCode(debt.currency)!)),
                _buildTableCell(_getDebtStatusLabel(debt.status)),
              ],
            )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionsSection(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TRANSACTIONS RÉCENTES',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Aucune transaction'),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TRANSACTIONS RÉCENTES (${transactions.length})',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Type', isHeader: true),
                _buildTableCell('Catégorie', isHeader: true),
                _buildTableCell('Montant', isHeader: true),
              ],
            ),
            ...transactions.take(15).map((tx) => pw.TableRow(
              children: [
                _buildTableCell('${tx.date.day}/${tx.date.month}/${tx.date.year}'),
                _buildTableCell(tx.type == TransactionType.income ? 'Entrée' : 'Sortie'),
                _buildTableCell(tx.categoryName),
                _buildTableCell(
                  CurrencyFormatter.formatAmount(tx.amount, AppCurrencies.findByCode(tx.currency)!),
                  color: tx.type == TransactionType.income ? PdfColors.green : PdfColors.red,
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.black : PdfColors.grey800),
        ),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Text(
          'Rapport généré par Ikigabo - Application de gestion de patrimoine',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          'Ce document est confidentiel et destiné uniquement à l\'usage personnel',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static String _getAssetTypeLabel(AssetType type) {
    switch (type) {
      case AssetType.livestock: return 'Bétail';
      case AssetType.crop: return 'Récolte';
      case AssetType.land: return 'Terrain';
      case AssetType.vehicle: return 'Véhicule';
      case AssetType.equipment: return 'Équipement';
      case AssetType.jewelry: return 'Bijoux';
      case AssetType.other: return 'Autre';
    }
  }

  static String _getDebtStatusLabel(DebtStatus status) {
    switch (status) {
      case DebtStatus.pending: return 'En attente';
      case DebtStatus.partiallyPaid: return 'Partiellement payé';
      case DebtStatus.fullyPaid: return 'Payé';
      case DebtStatus.cancelled: return 'Annulé';
    }
  }

  static Future<String> _savePdf(pw.Document pdf, String filename) async {
    try {
      // Utiliser file_picker pour choisir l'emplacement
      String? outputFile = await FilePicker.platform.saveFile(
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

  static Future<String> exportAssetReport(List<AssetModel> assets) async {
    final pdf = pw.Document();
    final totalValue = assets.fold(0.0, (sum, asset) => sum + asset.totalValue);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader('Rapport des Actifs', 'Tous les actifs'),
          pw.SizedBox(height: 20),
          _buildAssetsSection(assets),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    // Créer un nom de fichier lisible pour le rapport d'actifs
    final now1 = DateTime.now();
    final dateFormat1 = DateFormat('dd-MMM-yyyy_HH\'h\'mm');
    final readableDate1 = dateFormat1.format(now1);
    return await _savePdf(pdf, 'rapport_actifs_$readableDate1');
  }

  static Future<String> exportDebtReport(List<DebtModel> debts) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader('Rapport des Dettes', 'Toutes les dettes'),
          pw.SizedBox(height: 20),
          _buildDebtsSection(debts),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    // Créer un nom de fichier lisible pour le rapport de dettes
    final now2 = DateTime.now();
    final dateFormat2 = DateFormat('dd-MMM-yyyy_HH\'h\'mm');
    final readableDate2 = dateFormat2.format(now2);
    return await _savePdf(pdf, 'rapport_dettes_$readableDate2');
  }
}