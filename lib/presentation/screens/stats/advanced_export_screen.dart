import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/asset_model.dart';
import '../../../data/models/bank_model.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/models/source_model.dart';
import '../../../data/models/transaction_model.dart' as tx;
import '../../../data/services/pdf_export_service.dart';
import '../../widgets/searchable_selection_field.dart';

enum _Domain { transactions, assets, debts, banks, sources }

enum _FilterStage { selection, amount, options }

class AdvancedExportResult {
  final ReportExportFilters filters;
  final String? customTitle;

  const AdvancedExportResult({required this.filters, this.customTitle});
}

class AdvancedExportScreen extends StatefulWidget {
  final List<SourceModel> sources;
  final List<BankModel> banks;
  final List<AssetModel> assets;
  final List<DebtModel> debts;

  const AdvancedExportScreen({
    super.key,
    required this.sources,
    required this.banks,
    required this.assets,
    required this.debts,
  });

  @override
  State<AdvancedExportScreen> createState() => _AdvancedExportScreenState();
}

class _AdvancedExportScreenState extends State<AdvancedExportScreen> {
  int _step = 0;

  bool _includeTransactions = true;
  bool _includeAssets = true;
  bool _includeDebts = true;
  bool _includeBanks = true;
  bool _includeSources = true;

  bool _includeDeleted = false;
  bool _includeCancelledTransactions = true;

  ReportDatePreset _datePreset = ReportDatePreset.all;
  DateTime? _startDate;
  DateTime? _endDate;
  ReportSortBy _sortBy = ReportSortBy.newest;

  _Domain _activeDomain = _Domain.transactions;
  _FilterStage _filterStage = _FilterStage.selection;

  final _customTitleController = TextEditingController();
  final _maxTransactionsController = TextEditingController();

  final _txMinController = TextEditingController();
  final _txMaxController = TextEditingController();
  final _txKeywordController = TextEditingController();

  final _debtMinController = TextEditingController();
  final _debtMaxController = TextEditingController();
  final _debtDueDaysController = TextEditingController();
  final _debtKeywordController = TextEditingController();

  final _assetMinController = TextEditingController();
  final _assetMaxController = TextEditingController();
  final _assetKeywordController = TextEditingController();

  final _bankMinController = TextEditingController();
  final _bankMaxController = TextEditingController();
  final _bankKeywordController = TextEditingController();

  final _sourceMinController = TextEditingController();
  final _sourceMaxController = TextEditingController();
  final _sourceKeywordController = TextEditingController();

  final Set<tx.TransactionType> _transactionTypes = {};
  final Set<tx.TransactionStatus> _transactionStatuses = {};
  final Set<tx.SourceType> _transactionSourceTypes = {};

  tx.IncomeCategory? _incomeCategory;
  tx.ExpenseCategory? _expenseCategory;
  int? _selectedTxSourceId;
  int? _selectedTxTargetId;
  bool _recurringOnly = false;
  bool _nonRecurringOnly = false;

  DebtType? _debtType;
  DebtStatus? _debtStatus;
  int? _selectedDebtId;
  bool _debtOverdueOnly = false;
  bool _debtHasReminderOnly = false;

  AssetType? _assetType;
  AssetStatus? _assetStatus;
  int? _selectedAssetId;

  BankType? _bankType;
  InterestType? _bankInterestType;
  int? _selectedBankId;
  bool _bankActiveOnly = false;

  SourceType? _sourceType;
  int? _selectedSourceId;
  bool _sourceActiveOnly = false;
  bool _sourcePassiveOnly = false;

  @override
  void dispose() {
    _customTitleController.dispose();
    _maxTransactionsController.dispose();

    _txMinController.dispose();
    _txMaxController.dispose();
    _txKeywordController.dispose();

    _debtMinController.dispose();
    _debtMaxController.dispose();
    _debtDueDaysController.dispose();
    _debtKeywordController.dispose();

    _assetMinController.dispose();
    _assetMaxController.dispose();
    _assetKeywordController.dispose();

    _bankMinController.dispose();
    _bankMaxController.dispose();
    _bankKeywordController.dispose();

    _sourceMinController.dispose();
    _sourceMaxController.dispose();
    _sourceKeywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _l(
            fr: 'Export PDF Avance',
            en: 'Advanced PDF Export',
            rn: 'Kohereza PDF Bitezwe',
            sw: 'Hamisha PDF ya Kina',
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStepTabs(isDark),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: switch (_step) {
                0 => _buildScopeStep(isDark),
                1 => _buildPeriodStep(isDark),
                2 => _buildFiltersStep(isDark),
                _ => _buildReviewStep(isDark),
              },
            ),
          ),
          _buildBottomActions(isDark),
        ],
      ),
    );
  }

  Widget _buildStepTabs(bool isDark) {
    final labels = [
      _l(fr: 'Portee', en: 'Scope', rn: 'Igipimo', sw: 'Wigo'),
      _l(fr: 'Periode', en: 'Period', rn: 'Igihe', sw: 'Muda'),
      _l(fr: 'Filtres', en: 'Filters', rn: 'Akayunguruzo', sw: 'Vichujio'),
      _l(fr: 'Resume', en: 'Summary', rn: 'Incamake', sw: 'Muhtasari'),
    ];
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = _step == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () => setState(() => _step = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.textSecondaryDark
                              : Colors.grey.shade700),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ).animate().fadeIn(duration: 180.ms);
  }

  Widget _buildScopeStep(bool isDark) {
    return ListView(
      key: const ValueKey('scope_step'),
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      children: [
        _buildCard(
          isDark,
          title: _l(
            fr: 'Que veux-tu exporter ?',
            en: 'What do you want to export?',
            rn: 'Ushaka kohereza iki?',
            sw: 'Unataka kuhamisha nini?',
          ),
          subtitle: _l(
            fr: 'Par defaut tout est inclus. Tu peux garder tout ou choisir une partie.',
            en: 'By default, everything is included. You can keep all or select part.',
            rn: 'Mburabuzi vyose birajamwo. Ushobora gusiga vyose canke ugahitamo igice.',
            sw: 'Kwa chaguo-msingi kila kitu kimejumuishwa. Unaweza kuacha vyote au kuchagua sehemu.',
          ),
          child: _staggeredColumn([
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: Icon(AppIcons.menu, size: 16.sp),
                  label: Text(
                    _l(fr: 'Tout', en: 'All', rn: 'Vyose', sw: 'Vyote'),
                  ),
                  side: BorderSide.none,
                  backgroundColor: isDark
                      ? AppColors.backgroundDark
                      : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  onPressed: _selectAllSections,
                ),
                ActionChip(
                  avatar: Icon(AppIcons.income, size: 16.sp),
                  label: Text(
                    _l(
                      fr: 'Transactions seulement',
                      en: 'Transactions only',
                      rn: 'Ivyo kwinjiza gusa',
                      sw: 'Miamala tu',
                    ),
                  ),
                  side: BorderSide.none,
                  backgroundColor: isDark
                      ? AppColors.backgroundDark
                      : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  onPressed: () => _selectOnly(_Domain.transactions),
                ),
                ActionChip(
                  avatar: Icon(AppIcons.wallet, size: 16.sp),
                  label: Text(
                    _l(
                      fr: 'Sources seulement',
                      en: 'Sources only',
                      rn: 'Amasoko gusa',
                      sw: 'Vyanzo tu',
                    ),
                  ),
                  side: BorderSide.none,
                  backgroundColor: isDark
                      ? AppColors.backgroundDark
                      : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  onPressed: () => _selectOnly(_Domain.sources),
                ),
                ActionChip(
                  avatar: Icon(AppIcons.bank, size: 16.sp),
                  label: Text(
                    _l(
                      fr: 'Banques seulement',
                      en: 'Banks only',
                      rn: 'Amabanki gusa',
                      sw: 'Benki tu',
                    ),
                  ),
                  side: BorderSide.none,
                  backgroundColor: isDark
                      ? AppColors.backgroundDark
                      : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  onPressed: () => _selectOnly(_Domain.banks),
                ),
                ActionChip(
                  avatar: Icon(AppIcons.assets, size: 16.sp),
                  label: Text(
                    _l(
                      fr: 'Actifs seulement',
                      en: 'Assets only',
                      rn: 'Itunga gusa',
                      sw: 'Mali tu',
                    ),
                  ),
                  side: BorderSide.none,
                  backgroundColor: isDark
                      ? AppColors.backgroundDark
                      : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  onPressed: () => _selectOnly(_Domain.assets),
                ),
                ActionChip(
                  avatar: Icon(AppIcons.debt, size: 16.sp),
                  label: Text(
                    _l(
                      fr: 'Dettes seulement',
                      en: 'Debts only',
                      rn: 'Imyenda gusa',
                      sw: 'Madeni tu',
                    ),
                  ),
                  side: BorderSide.none,
                  backgroundColor: isDark
                      ? AppColors.backgroundDark
                      : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  onPressed: () => _selectOnly(_Domain.debts),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _sectionSwitch(
              isDark,
              icon: AppIcons.income,
              title: _domainLabel(_Domain.transactions),
              subtitle: _l(
                fr: 'Entrees, sorties et transferts',
                en: 'Income, expenses and transfers',
                rn: 'Ivyo winjije, ukoresheje n\'ukwimurira',
                sw: 'Mapato, matumizi na uhamisho',
              ),
              value: _includeTransactions,
              onChanged: (value) => _toggleSection(_Domain.transactions, value),
            ),
            _sectionSwitch(
              isDark,
              icon: AppIcons.assets,
              title: _domainLabel(_Domain.assets),
              subtitle: _l(
                fr: 'Tous les actifs et leurs valeurs',
                en: 'All assets and their values',
                rn: 'Itunga ryose n\'agaciro karyo',
                sw: 'Mali zote na thamani zake',
              ),
              value: _includeAssets,
              onChanged: (value) => _toggleSection(_Domain.assets, value),
            ),
            _sectionSwitch(
              isDark,
              icon: AppIcons.debt,
              title: _domainLabel(_Domain.debts),
              subtitle: _l(
                fr: 'Dettes pretees/empruntees',
                en: 'Lent and borrowed debts',
                rn: 'Imyenda watanze canke wasavye',
                sw: 'Madeni uliyotoa au kukopa',
              ),
              value: _includeDebts,
              onChanged: (value) => _toggleSection(_Domain.debts, value),
            ),
            _sectionSwitch(
              isDark,
              icon: AppIcons.bank,
              title: _domainLabel(_Domain.banks),
              subtitle: _l(
                fr: 'Comptes bancaires et soldes',
                en: 'Bank accounts and balances',
                rn: 'Konti za banki n\'amafaranga ariho',
                sw: 'Akaunti za benki na salio',
              ),
              value: _includeBanks,
              onChanged: (value) => _toggleSection(_Domain.banks, value),
            ),
            _sectionSwitch(
              isDark,
              icon: AppIcons.wallet,
              title: _domainLabel(_Domain.sources),
              subtitle: _l(
                fr: 'Poche, coffre, cash, personnalise',
                en: 'Pocket, safe, cash, custom',
                rn: 'Mu mufuko, ikigega, cash, ico wishakiye',
                sw: 'Mfuko, salama, fedha taslimu, maalum',
              ),
              value: _includeSources,
              onChanged: (value) => _toggleSection(_Domain.sources, value),
            ),
          ], baseDelayMs: 20),
        ),
      ],
    );
  }

  Widget _buildPeriodStep(bool isDark) {
    final isCustom = _datePreset == ReportDatePreset.custom;
    final presetOptions = [
      (ReportDatePreset.all, _datePresetLabel(ReportDatePreset.all)),
      (ReportDatePreset.today, _datePresetLabel(ReportDatePreset.today)),
      (
        ReportDatePreset.yesterday,
        _datePresetLabel(ReportDatePreset.yesterday),
      ),
      (
        ReportDatePreset.last7Days,
        _datePresetLabel(ReportDatePreset.last7Days),
      ),
      (
        ReportDatePreset.thisMonth,
        _datePresetLabel(ReportDatePreset.thisMonth),
      ),
      (
        ReportDatePreset.lastMonth,
        _datePresetLabel(ReportDatePreset.lastMonth),
      ),
      (ReportDatePreset.thisYear, _datePresetLabel(ReportDatePreset.thisYear)),
      (ReportDatePreset.custom, _datePresetLabel(ReportDatePreset.custom)),
    ];

    return ListView(
      key: const ValueKey('period_step'),
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      children: [
        _buildCard(
          isDark,
          title: _l(
            fr: 'Periode et tri',
            en: 'Period and sorting',
            rn: 'Igihe n\'urutonde',
            sw: 'Muda na mpangilio',
          ),
          subtitle: _l(
            fr: 'Configure la duree et l\'ordre du rapport.',
            en: 'Set the period and report order.',
            rn: 'Shiraho igihe n\'ukuntu raporo itondekwa.',
            sw: 'Weka muda na mpangilio wa ripoti.',
          ),
          child: _staggeredColumn([
            _textField(
              controller: _customTitleController,
              label: _l(
                fr: 'Titre personnalise (optionnel)',
                en: 'Custom title (optional)',
                rn: 'Umutwe wihariye (si ngombwa)',
                sw: 'Kichwa maalum (si lazima)',
              ),
              hint: _l(
                fr: 'Ex: Rapport Poche Janvier',
                en: 'Ex: Pocket report January',
                rn: 'Akarorero: Raporo y\'umufuko Nzero',
                sw: 'Mfano: Ripoti ya mfuko Januari',
              ),
            ),
            SizedBox(height: 12.h),
            _chipGroup(
              isDark,
              title: _l(fr: 'Periode', en: 'Period', rn: 'Igihe', sw: 'Muda'),
              options: presetOptions,
              current: _datePreset,
              onTap: (value) => setState(() => _datePreset = value),
            ),
            if (isCustom) ...[
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: _dateButton(
                      isDark,
                      label: _l(
                        fr: 'Debut',
                        en: 'Start',
                        rn: 'Intango',
                        sw: 'Mwanzo',
                      ),
                      value: _startDate,
                      onPressed: () => _pickDate(isStart: true),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _dateButton(
                      isDark,
                      label: _l(
                        fr: 'Fin',
                        en: 'End',
                        rn: 'Iherezo',
                        sw: 'Mwisho',
                      ),
                      value: _endDate,
                      onPressed: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12.h),
            SearchableSelectionField<ReportSortBy>(
              label: _l(
                fr: 'Tri principal',
                en: 'Main sorting',
                rn: 'Itondekwa nyamukuru',
                sw: 'Upangaji mkuu',
              ),
              hint: _l(
                fr: 'Tri principal',
                en: 'Main sorting',
                rn: 'Itondekwa nyamukuru',
                sw: 'Upangaji mkuu',
              ),
              searchHint: _l(
                fr: 'Rechercher un tri...',
                en: 'Search sorting...',
                rn: 'Rondera uburyo bwo gutondeka...',
                sw: 'Tafuta mpangilio...',
              ),
              options: [
                SelectionOption(
                  value: ReportSortBy.newest,
                  label: _l(
                    fr: 'Plus recent',
                    en: 'Newest first',
                    rn: 'Ibishasha imbere',
                    sw: 'Vipya kwanza',
                  ),
                ),
                SelectionOption(
                  value: ReportSortBy.oldest,
                  label: _l(
                    fr: 'Plus ancien',
                    en: 'Oldest first',
                    rn: 'Ibikera imbere',
                    sw: 'Vya zamani kwanza',
                  ),
                ),
                SelectionOption(
                  value: ReportSortBy.amountDesc,
                  label: _l(
                    fr: 'Montant decroissant',
                    en: 'Amount descending',
                    rn: 'Igiciro gimanuka',
                    sw: 'Kiasi kushuka',
                  ),
                ),
                SelectionOption(
                  value: ReportSortBy.amountAsc,
                  label: _l(
                    fr: 'Montant croissant',
                    en: 'Amount ascending',
                    rn: 'Igiciro kiduga',
                    sw: 'Kiasi kupanda',
                  ),
                ),
                SelectionOption(
                  value: ReportSortBy.nameAsc,
                  label: _l(
                    fr: 'Nom A-Z',
                    en: 'Name A-Z',
                    rn: 'Izina A-Z',
                    sw: 'Jina A-Z',
                  ),
                ),
                SelectionOption(
                  value: ReportSortBy.nameDesc,
                  label: _l(
                    fr: 'Nom Z-A',
                    en: 'Name Z-A',
                    rn: 'Izina Z-A',
                    sw: 'Jina Z-A',
                  ),
                ),
              ],
              selectedValue: _sortBy,
              onChanged: (value) => setState(() => _sortBy = value),
              prefixIcon: AppIcons.sort,
            ),
            SizedBox(height: 8.h),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _includeDeleted,
              title: Text(
                _l(
                  fr: 'Inclure elements supprimes',
                  en: 'Include deleted items',
                  rn: 'Shiramwo ivyahanaguwe',
                  sw: 'Jumuisha vilivyofutwa',
                ),
              ),
              onChanged: (value) => setState(() => _includeDeleted = value),
            ),
            if (_includeTransactions)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _includeCancelledTransactions,
                title: Text(
                  _l(
                    fr: 'Inclure transactions annulees',
                    en: 'Include cancelled transactions',
                    rn: 'Shiramwo ivyo gucuruzwa vyahagaritswe',
                    sw: 'Jumuisha miamala iliyofutwa',
                  ),
                ),
                onChanged: (value) =>
                    setState(() => _includeCancelledTransactions = value),
              ),
          ], baseDelayMs: 20),
        ),
      ],
    );
  }

  Widget _buildFiltersStep(bool isDark) {
    final enabledDomains = _enabledDomains;

    if (enabledDomains.isEmpty) {
      return Center(
        child: Text(
          _l(
            fr: 'Active au moins une section.',
            en: 'Enable at least one section.',
            rn: 'Shiramwo nibura igice kimwe.',
            sw: 'Washa angalau sehemu moja.',
          ),
          style: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
            fontSize: 13.sp,
          ),
        ),
      );
    }

    if (!enabledDomains.contains(_activeDomain)) {
      _activeDomain = enabledDomains.first;
    }

    final stageLabels = {
      _FilterStage.selection: _l(
        fr: 'Selection',
        en: 'Selection',
        rn: 'Uguhitamwo',
        sw: 'Uteuzi',
      ),
      _FilterStage.amount: _l(
        fr: 'Montants',
        en: 'Amounts',
        rn: 'Amahera',
        sw: 'Kiasi',
      ),
      _FilterStage.options: _l(
        fr: 'Options',
        en: 'Options',
        rn: 'Amahitamwo',
        sw: 'Chaguo',
      ),
    };

    return ListView(
      key: const ValueKey('filters_step'),
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      children: [
        _buildCard(
          isDark,
          title: _l(
            fr: 'Filtres detailles',
            en: 'Detailed filters',
            rn: 'Akayunguruzo karambuye',
            sw: 'Vichujio vya kina',
          ),
          subtitle: _l(
            fr: 'Choisis une section puis avance etape par etape. Sans changement, tout est exporte.',
            en: 'Pick a section then continue step by step. Without changes, everything is exported.',
            rn: 'Hitamwo igice hanyuma ubandanye intambwe ku yindi. Utahinduye, vyose birasohorwa.',
            sw: 'Chagua sehemu kisha endelea hatua kwa hatua. Bila mabadiliko, kila kitu kitahamishwa.',
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: enabledDomains.map((domain) {
                  final selected = domain == _activeDomain;
                  return ChoiceChip(
                    label: Text(_domainLabel(domain)),
                    selected: selected,
                    side: BorderSide.none,
                    backgroundColor: isDark
                        ? AppColors.backgroundDark
                        : Colors.grey.shade100,
                    selectedColor: AppColors.primary.withValues(alpha: 0.16),
                    onSelected: (_) => setState(() {
                      _activeDomain = domain;
                      _filterStage = _FilterStage.selection;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _FilterStage.values.map((stage) {
                  final selected = stage == _filterStage;
                  return ChoiceChip(
                    label: Text(stageLabels[stage]!),
                    selected: selected,
                    side: BorderSide.none,
                    backgroundColor: isDark
                        ? AppColors.backgroundDark
                        : Colors.grey.shade100,
                    selectedColor: AppColors.primary.withValues(alpha: 0.16),
                    onSelected: (_) => setState(() => _filterStage = stage),
                  );
                }).toList(),
              ),
              SizedBox(height: 12.h),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0.0, 0.04),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey('${_activeDomain.name}_${_filterStage.name}'),
                  child: switch (_activeDomain) {
                    _Domain.transactions => _buildTransactionsFilters(
                      isDark,
                      _filterStage,
                    ),
                    _Domain.assets => _buildAssetsFilters(isDark, _filterStage),
                    _Domain.debts => _buildDebtsFilters(isDark, _filterStage),
                    _Domain.banks => _buildBanksFilters(isDark, _filterStage),
                    _Domain.sources => _buildSourcesFilters(
                      isDark,
                      _filterStage,
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsFilters(bool isDark, _FilterStage stage) {
    final sourceOptions = [
      SelectionOption<int?>(
        value: null,
        label: _l(
          fr: 'Toutes les sources',
          en: 'All sources',
          rn: 'Amasoko yose',
          sw: 'Vyanzo vyote',
        ),
      ),
      ...widget.sources.map(
        (item) => SelectionOption<int?>(value: item.id, label: item.name),
      ),
    ];

    return switch (stage) {
      _FilterStage.selection => Column(
        children: [
          _multiSelectEnumChips<tx.TransactionType>(
            title: _l(
              fr: 'Type transaction',
              en: 'Transaction type',
              rn: 'Ubwoko bw\'igikorwa',
              sw: 'Aina ya muamala',
            ),
            allValues: tx.TransactionType.values,
            selectedValues: _transactionTypes,
            toLabel: (value) => _enumLabel(value.name),
            onChanged: (value, selected) {
              setState(() {
                if (selected) {
                  _transactionTypes.add(value);
                } else {
                  _transactionTypes.remove(value);
                }
              });
            },
          ),
          SizedBox(height: 10.h),
          _multiSelectEnumChips<tx.TransactionStatus>(
            title: _l(fr: 'Statut', en: 'Status', rn: 'Uko bimeze', sw: 'Hali'),
            allValues: tx.TransactionStatus.values,
            selectedValues: _transactionStatuses,
            toLabel: (value) => _enumLabel(value.name),
            onChanged: (value, selected) {
              setState(() {
                if (selected) {
                  _transactionStatuses.add(value);
                } else {
                  _transactionStatuses.remove(value);
                }
              });
            },
          ),
          SizedBox(height: 10.h),
          _multiSelectEnumChips<tx.SourceType>(
            title: _l(
              fr: 'Type source',
              en: 'Source type',
              rn: 'Ubwoko bw\'isoko',
              sw: 'Aina ya chanzo',
            ),
            allValues: tx.SourceType.values,
            selectedValues: _transactionSourceTypes,
            toLabel: (value) => _enumLabel(value.name),
            onChanged: (value, selected) {
              setState(() {
                if (selected) {
                  _transactionSourceTypes.add(value);
                } else {
                  _transactionSourceTypes.remove(value);
                }
              });
            },
          ),
          SizedBox(height: 10.h),
          SearchableSelectionField<int?>(
            label: _l(
              fr: 'Source precise',
              en: 'Specific source',
              rn: 'Isoko rimwe',
              sw: 'Chanzo maalum',
            ),
            hint: _l(
              fr: 'Toutes les sources',
              en: 'All sources',
              rn: 'Amasoko yose',
              sw: 'Vyanzo vyote',
            ),
            options: sourceOptions,
            selectedValue: _selectedTxSourceId,
            onChanged: (value) => setState(() => _selectedTxSourceId = value),
            prefixIcon: AppIcons.wallet,
            searchHint: _l(
              fr: 'Rechercher une source...',
              en: 'Search source...',
              rn: 'Rondera isoko...',
              sw: 'Tafuta chanzo...',
            ),
            noResultsText: _l(
              fr: 'Aucune source trouvee',
              en: 'No source found',
              rn: 'Nta soko ribonetse',
              sw: 'Hakuna chanzo kilichopatikana',
            ),
          ),
          SizedBox(height: 10.h),
          SearchableSelectionField<int?>(
            label: _l(
              fr: 'Cible precise',
              en: 'Specific target',
              rn: 'Ico ugana',
              sw: 'Lengo maalum',
            ),
            hint: _l(
              fr: 'Toutes les cibles',
              en: 'All targets',
              rn: 'Ivyerekezo vyose',
              sw: 'Malengo yote',
            ),
            options: sourceOptions,
            selectedValue: _selectedTxTargetId,
            onChanged: (value) => setState(() => _selectedTxTargetId = value),
            prefixIcon: AppIcons.filter,
            searchHint: _l(
              fr: 'Rechercher une cible...',
              en: 'Search target...',
              rn: 'Rondera aho ugana...',
              sw: 'Tafuta lengo...',
            ),
          ),
          SizedBox(height: 10.h),
          SearchableSelectionField<tx.IncomeCategory?>(
            label: _l(
              fr: 'Categorie revenu',
              en: 'Income category',
              rn: 'Icyiciro c\'inyungu',
              sw: 'Kategoria ya mapato',
            ),
            hint: _l(fr: 'Toutes', en: 'All', rn: 'Vyose', sw: 'Vyote'),
            options: [
              SelectionOption<tx.IncomeCategory?>(
                value: null,
                label: _l(fr: 'Toutes', en: 'All', rn: 'Vyose', sw: 'Vyote'),
              ),
              ...tx.IncomeCategory.values.map(
                (item) => SelectionOption<tx.IncomeCategory?>(
                  value: item,
                  label: _enumLabel(item.name),
                ),
              ),
            ],
            selectedValue: _incomeCategory,
            onChanged: (value) => setState(() => _incomeCategory = value),
            prefixIcon: AppIcons.income,
            searchHint: _l(
              fr: 'Rechercher categorie revenu...',
              en: 'Search income category...',
              rn: 'Rondera icyiciro c\'inyungu...',
              sw: 'Tafuta kategoria ya mapato...',
            ),
          ),
          SizedBox(height: 10.h),
          SearchableSelectionField<tx.ExpenseCategory?>(
            label: _l(
              fr: 'Categorie depense',
              en: 'Expense category',
              rn: 'Icyiciro c\'ivyo ukoresha',
              sw: 'Kategoria ya matumizi',
            ),
            hint: _l(fr: 'Toutes', en: 'All', rn: 'Vyose', sw: 'Vyote'),
            options: [
              SelectionOption<tx.ExpenseCategory?>(
                value: null,
                label: _l(fr: 'Toutes', en: 'All', rn: 'Vyose', sw: 'Vyote'),
              ),
              ...tx.ExpenseCategory.values.map(
                (item) => SelectionOption<tx.ExpenseCategory?>(
                  value: item,
                  label: _enumLabel(item.name),
                ),
              ),
            ],
            selectedValue: _expenseCategory,
            onChanged: (value) => setState(() => _expenseCategory = value),
            prefixIcon: AppIcons.expense,
            searchHint: _l(
              fr: 'Rechercher categorie depense...',
              en: 'Search expense category...',
              rn: 'Rondera icyiciro c\'ivyakozwe...',
              sw: 'Tafuta kategoria ya matumizi...',
            ),
          ),
        ],
      ),
      _FilterStage.amount => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _textField(
                  controller: _txMinController,
                  label: _l(
                    fr: 'Montant min',
                    en: 'Min amount',
                    rn: 'Amahera make',
                    sw: 'Kiasi cha chini',
                  ),
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _textField(
                  controller: _txMaxController,
                  label: _l(
                    fr: 'Montant max',
                    en: 'Max amount',
                    rn: 'Amahera menshi',
                    sw: 'Kiasi cha juu',
                  ),
                  hint: '100000',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _textField(
            controller: _maxTransactionsController,
            label: _l(
              fr: 'Limiter les transactions (optionnel)',
              en: 'Limit transactions (optional)',
              rn: 'Gabanya ibikorwa (si ngombwa)',
              sw: 'Punguza miamala (si lazima)',
            ),
            hint: _l(
              fr: 'Ex: 100',
              en: 'Ex: 100',
              rn: 'Akarorero: 100',
              sw: 'Mfano: 100',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      _FilterStage.options => Column(
        children: [
          _textField(
            controller: _txKeywordController,
            label: _l(
              fr: 'Mot-cle transaction',
              en: 'Transaction keyword',
              rn: 'Ijambo nyamukuru ry\'igikorwa',
              sw: 'Neno kuu la muamala',
            ),
            hint: _l(
              fr: 'Description, note, source...',
              en: 'Description, note, source...',
              rn: 'Insiguro, icitonderwa, isoko...',
              sw: 'Maelezo, dokezo, chanzo...',
            ),
          ),
          SizedBox(height: 6.h),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _recurringOnly,
            title: Text(
              _l(
                fr: 'Recurrentes uniquement',
                en: 'Recurring only',
                rn: 'Bihora bisubira gusa',
                sw: 'Yanayojirudia tu',
              ),
            ),
            onChanged: (value) => setState(() {
              _recurringOnly = value;
              if (value) _nonRecurringOnly = false;
            }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _nonRecurringOnly,
            title: Text(
              _l(
                fr: 'Non-recurrentes uniquement',
                en: 'Non-recurring only',
                rn: 'Bitisubira gusa',
                sw: 'Yasiyojirudia tu',
              ),
            ),
            onChanged: (value) => setState(() {
              _nonRecurringOnly = value;
              if (value) _recurringOnly = false;
            }),
          ),
        ],
      ),
    };
  }

  Widget _buildAssetsFilters(bool isDark, _FilterStage stage) {
    final options = [
      SelectionOption<int?>(
        value: null,
        label: _l(
          fr: 'Tous les actifs',
          en: 'All assets',
          rn: 'Itunga ryose',
          sw: 'Mali zote',
        ),
      ),
      ...widget.assets.map(
        (item) => SelectionOption<int?>(value: item.id, label: item.name),
      ),
    ];

    return switch (stage) {
      _FilterStage.selection => Column(
        children: [
          SearchableSelectionField<AssetType?>(
            label: _l(
              fr: 'Type actif',
              en: 'Asset type',
              rn: 'Ubwoko bw\'itunga',
              sw: 'Aina ya mali',
            ),
            hint: _l(fr: 'Tous', en: 'All', rn: 'Vyose', sw: 'Vyote'),
            options: [
              SelectionOption<AssetType?>(
                value: null,
                label: _l(fr: 'Tous', en: 'All', rn: 'Vyose', sw: 'Vyote'),
              ),
              ...AssetType.values.map(
                (item) => SelectionOption<AssetType?>(
                  value: item,
                  label: _enumLabel(item.name),
                ),
              ),
            ],
            selectedValue: _assetType,
            onChanged: (value) => setState(() => _assetType = value),
            prefixIcon: AppIcons.assets,
            searchHint: _l(
              fr: 'Rechercher type actif...',
              en: 'Search asset type...',
              rn: 'Rondera ubwoko bw\'itunga...',
              sw: 'Tafuta aina ya mali...',
            ),
          ),
          SizedBox(height: 10.h),
          SearchableSelectionField<AssetStatus?>(
            label: _l(
              fr: 'Statut actif',
              en: 'Asset status',
              rn: 'Uko itunga rimeze',
              sw: 'Hali ya mali',
            ),
            hint: _l(fr: 'Tous', en: 'All', rn: 'Vyose', sw: 'Vyote'),
            options: [
              SelectionOption<AssetStatus?>(
                value: null,
                label: _l(fr: 'Tous', en: 'All', rn: 'Vyose', sw: 'Vyote'),
              ),
              ...AssetStatus.values.map(
                (item) => SelectionOption<AssetStatus?>(
                  value: item,
                  label: _enumLabel(item.name),
                ),
              ),
            ],
            selectedValue: _assetStatus,
            onChanged: (value) => setState(() => _assetStatus = value),
            prefixIcon: AppIcons.chart,
            searchHint: _l(
              fr: 'Rechercher statut actif...',
              en: 'Search asset status...',
              rn: 'Rondera uko itunga rimeze...',
              sw: 'Tafuta hali ya mali...',
            ),
          ),
          SizedBox(height: 10.h),
          SearchableSelectionField<int?>(
            label: _l(
              fr: 'Actif precis',
              en: 'Specific asset',
              rn: 'Itunga rimwe',
              sw: 'Mali maalum',
            ),
            hint: _l(
              fr: 'Tous les actifs',
              en: 'All assets',
              rn: 'Itunga ryose',
              sw: 'Mali zote',
            ),
            options: options,
            selectedValue: _selectedAssetId,
            onChanged: (value) => setState(() => _selectedAssetId = value),
            prefixIcon: AppIcons.assets,
            searchHint: _l(
              fr: 'Rechercher un actif...',
              en: 'Search asset...',
              rn: 'Rondera itunga...',
              sw: 'Tafuta mali...',
            ),
          ),
        ],
      ),
      _FilterStage.amount => Row(
        children: [
          Expanded(
            child: _textField(
              controller: _assetMinController,
              label: _l(
                fr: 'Valeur min',
                en: 'Min value',
                rn: 'Agaciro gatoyi',
                sw: 'Thamani ya chini',
              ),
              hint: '0',
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _textField(
              controller: _assetMaxController,
              label: _l(
                fr: 'Valeur max',
                en: 'Max value',
                rn: 'Agaciro kanini',
                sw: 'Thamani ya juu',
              ),
              hint: '100000',
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
      _FilterStage.options => _textField(
        controller: _assetKeywordController,
        label: _l(
          fr: 'Mot-cle actif',
          en: 'Asset keyword',
          rn: 'Ijambo ry\'itunga',
          sw: 'Neno kuu la mali',
        ),
        hint: _l(
          fr: 'Nom, localisation, description...',
          en: 'Name, location, description...',
          rn: 'Izina, ahantu, insiguro...',
          sw: 'Jina, eneo, maelezo...',
        ),
      ),
    };
  }

  Widget _buildDebtsFilters(bool isDark, _FilterStage stage) {
    final options = [
      SelectionOption<int?>(
        value: null,
        label: _l(
          fr: 'Toutes les dettes',
          en: 'All debts',
          rn: 'Imyenda yose',
          sw: 'Madeni yote',
        ),
      ),
      ...widget.debts.map(
        (item) => SelectionOption<int?>(
          value: item.id,
          label: '${item.personName} (#${item.id})',
        ),
      ),
    ];

    return switch (stage) {
      _FilterStage.selection => Column(
        children: [
          SearchableSelectionField<DebtType?>(
            label: _l(
              fr: 'Type dette',
              en: 'Debt type',
              rn: 'Ubwoko bw\'umwenda',
              sw: 'Aina ya deni',
            ),
            hint: _l(fr: 'Tous', en: 'All', rn: 'Vyose', sw: 'Vyote'),
            options: [
              SelectionOption<DebtType?>(
                value: null,
                label: _l(fr: 'Tous', en: 'All', rn: 'Vyose', sw: 'Vyote'),
              ),
              ...DebtType.values.map(
                (item) => SelectionOption<DebtType?>(
                  value: item,
                  label: _enumLabel(item.name),
                ),
              ),
            ],
            selectedValue: _debtType,
            onChanged: (value) => setState(() => _debtType = value),
            prefixIcon: AppIcons.debt,
            searchHint: _l(
              fr: 'Rechercher type dette...',
              en: 'Search debt type...',
              rn: 'Rondera ubwoko bw\'umwenda...',
              sw: 'Tafuta aina ya deni...',
            ),
          ),
          SizedBox(height: 10.h),
          SearchableSelectionField<DebtStatus?>(
            label: _l(
              fr: 'Statut dette',
              en: 'Debt status',
              rn: 'Uko umwenda umeze',
              sw: 'Hali ya deni',
            ),
            hint: _l(fr: 'Tous', en: 'All', rn: 'Vyose', sw: 'Vyote'),
            options: [
              SelectionOption<DebtStatus?>(
                value: null,
                label: _l(fr: 'Tous', en: 'All', rn: 'Vyose', sw: 'Vyote'),
              ),
              ...DebtStatus.values.map(
                (item) => SelectionOption<DebtStatus?>(
                  value: item,
                  label: _enumLabel(item.name),
                ),
              ),
            ],
            selectedValue: _debtStatus,
            onChanged: (value) => setState(() => _debtStatus = value),
            prefixIcon: AppIcons.info,
            searchHint: _l(
              fr: 'Rechercher statut dette...',
              en: 'Search debt status...',
              rn: 'Rondera uko umwenda umeze...',
              sw: 'Tafuta hali ya deni...',
            ),
          ),
          SizedBox(height: 10.h),
          SearchableSelectionField<int?>(
            label: _l(
              fr: 'Dette precise',
              en: 'Specific debt',
              rn: 'Umwenda umwe',
              sw: 'Deni maalum',
            ),
            hint: _l(
              fr: 'Toutes les dettes',
              en: 'All debts',
              rn: 'Imyenda yose',
              sw: 'Madeni yote',
            ),
            options: options,
            selectedValue: _selectedDebtId,
            onChanged: (value) => setState(() => _selectedDebtId = value),
            prefixIcon: AppIcons.debt,
            searchHint: _l(
              fr: 'Rechercher une dette...',
              en: 'Search debt...',
              rn: 'Rondera umwenda...',
              sw: 'Tafuta deni...',
            ),
          ),
        ],
      ),
      _FilterStage.amount => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _textField(
                  controller: _debtMinController,
                  label: _l(
                    fr: 'Reste min',
                    en: 'Remaining min',
                    rn: 'Igisigaye gito',
                    sw: 'Kiasi kilichobaki cha chini',
                  ),
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _textField(
                  controller: _debtMaxController,
                  label: _l(
                    fr: 'Reste max',
                    en: 'Remaining max',
                    rn: 'Igisigaye kinini',
                    sw: 'Kiasi kilichobaki cha juu',
                  ),
                  hint: '100000',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _textField(
            controller: _debtDueDaysController,
            label: _l(
              fr: 'Echeance dans X jours (optionnel)',
              en: 'Due in X days (optional)',
              rn: 'Itariki ntarengwa mu minsi X (si ngombwa)',
              sw: 'Muda wa mwisho ndani ya siku X (si lazima)',
            ),
            hint: _l(
              fr: 'Ex: 30',
              en: 'Ex: 30',
              rn: 'Akarorero: 30',
              sw: 'Mfano: 30',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      _FilterStage.options => Column(
        children: [
          _textField(
            controller: _debtKeywordController,
            label: _l(
              fr: 'Mot-cle dette',
              en: 'Debt keyword',
              rn: 'Ijambo nyamukuru ry\'umwenda',
              sw: 'Neno kuu la deni',
            ),
            hint: _l(
              fr: 'Nom, contact, description...',
              en: 'Name, contact, description...',
              rn: 'Izina, uwo twovugana, insiguro...',
              sw: 'Jina, mawasiliano, maelezo...',
            ),
          ),
          SizedBox(height: 6.h),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _debtOverdueOnly,
            title: Text(
              _l(
                fr: 'En retard uniquement',
                en: 'Overdue only',
                rn: 'Vyarengeje igihe gusa',
                sw: 'Yaliyochelewa tu',
              ),
            ),
            onChanged: (value) => setState(() => _debtOverdueOnly = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _debtHasReminderOnly,
            title: Text(
              _l(
                fr: 'Avec rappel uniquement',
                en: 'With reminder only',
                rn: 'Bifise ukwibutsa gusa',
                sw: 'Yenye ukumbusho tu',
              ),
            ),
            onChanged: (value) => setState(() => _debtHasReminderOnly = value),
          ),
        ],
      ),
    };
  }

  Widget _buildBanksFilters(bool isDark, _FilterStage stage) {
    final options = [
      SelectionOption<int?>(
        value: null,
        label: _l(
          fr: 'Toutes les banques',
          en: 'All banks',
          rn: 'Amabanki yose',
          sw: 'Benki zote',
        ),
      ),
      ...widget.banks.map(
        (item) => SelectionOption<int?>(value: item.id, label: item.name),
      ),
    ];

    return switch (stage) {
      _FilterStage.selection => Column(
        children: [
          SearchableSelectionField<BankType?>(
            label: _l(
              fr: 'Type banque',
              en: 'Bank type',
              rn: 'Ubwoko bwa banki',
              sw: 'Aina ya benki',
            ),
            hint: _l(fr: 'Tous', en: 'All', rn: 'Vyose', sw: 'Vyote'),
            options: [
              SelectionOption<BankType?>(
                value: null,
                label: _l(fr: 'Tous', en: 'All', rn: 'Vyose', sw: 'Vyote'),
              ),
              ...BankType.values.map(
                (item) => SelectionOption<BankType?>(
                  value: item,
                  label: _enumLabel(item.name),
                ),
              ),
            ],
            selectedValue: _bankType,
            onChanged: (value) => setState(() => _bankType = value),
            prefixIcon: AppIcons.bank,
            searchHint: _l(
              fr: 'Rechercher type banque...',
              en: 'Search bank type...',
              rn: 'Rondera ubwoko bwa banki...',
              sw: 'Tafuta aina ya benki...',
            ),
          ),
          SizedBox(height: 10.h),
          SearchableSelectionField<InterestType?>(
            label: _l(
              fr: 'Type interet',
              en: 'Interest type',
              rn: 'Ubwoko bw\'inyungu',
              sw: 'Aina ya riba',
            ),
            hint: _l(fr: 'Tous', en: 'All', rn: 'Vyose', sw: 'Vyote'),
            options: [
              SelectionOption<InterestType?>(
                value: null,
                label: _l(fr: 'Tous', en: 'All', rn: 'Vyose', sw: 'Vyote'),
              ),
              ...InterestType.values.map(
                (item) => SelectionOption<InterestType?>(
                  value: item,
                  label: _enumLabel(item.name),
                ),
              ),
            ],
            selectedValue: _bankInterestType,
            onChanged: (value) => setState(() => _bankInterestType = value),
            prefixIcon: AppIcons.chart,
            searchHint: _l(
              fr: 'Rechercher type interet...',
              en: 'Search interest type...',
              rn: 'Rondera ubwoko bw\'inyungu...',
              sw: 'Tafuta aina ya riba...',
            ),
          ),
          SizedBox(height: 10.h),
          SearchableSelectionField<int?>(
            label: _l(
              fr: 'Banque precise',
              en: 'Specific bank',
              rn: 'Banki imwe',
              sw: 'Benki maalum',
            ),
            hint: _l(
              fr: 'Toutes les banques',
              en: 'All banks',
              rn: 'Amabanki yose',
              sw: 'Benki zote',
            ),
            options: options,
            selectedValue: _selectedBankId,
            onChanged: (value) => setState(() => _selectedBankId = value),
            prefixIcon: AppIcons.bank,
            searchHint: _l(
              fr: 'Rechercher une banque...',
              en: 'Search bank...',
              rn: 'Rondera banki...',
              sw: 'Tafuta benki...',
            ),
          ),
        ],
      ),
      _FilterStage.amount => Row(
        children: [
          Expanded(
            child: _textField(
              controller: _bankMinController,
              label: _l(
                fr: 'Solde min',
                en: 'Min balance',
                rn: 'Amahera make kuri konti',
                sw: 'Salio la chini',
              ),
              hint: '0',
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _textField(
              controller: _bankMaxController,
              label: _l(
                fr: 'Solde max',
                en: 'Max balance',
                rn: 'Amahera menshi kuri konti',
                sw: 'Salio la juu',
              ),
              hint: '100000',
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
      _FilterStage.options => Column(
        children: [
          _textField(
            controller: _bankKeywordController,
            label: _l(
              fr: 'Mot-cle banque',
              en: 'Bank keyword',
              rn: 'Ijambo rya banki',
              sw: 'Neno kuu la benki',
            ),
            hint: _l(
              fr: 'Nom, compte, description...',
              en: 'Name, account, description...',
              rn: 'Izina, konti, insiguro...',
              sw: 'Jina, akaunti, maelezo...',
            ),
          ),
          SizedBox(height: 6.h),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _bankActiveOnly,
            title: Text(
              _l(
                fr: 'Banques actives uniquement',
                en: 'Active banks only',
                rn: 'Amabanki akora gusa',
                sw: 'Benki hai tu',
              ),
            ),
            onChanged: (value) => setState(() => _bankActiveOnly = value),
          ),
        ],
      ),
    };
  }

  Widget _buildSourcesFilters(bool isDark, _FilterStage stage) {
    final options = [
      SelectionOption<int?>(
        value: null,
        label: _l(
          fr: 'Toutes les sources',
          en: 'All sources',
          rn: 'Amasoko yose',
          sw: 'Vyanzo vyote',
        ),
      ),
      ...widget.sources.map(
        (item) => SelectionOption<int?>(value: item.id, label: item.name),
      ),
    ];

    return switch (stage) {
      _FilterStage.selection => Column(
        children: [
          SearchableSelectionField<SourceType?>(
            label: _l(
              fr: 'Type source',
              en: 'Source type',
              rn: 'Ubwoko bw\'isoko',
              sw: 'Aina ya chanzo',
            ),
            hint: _l(fr: 'Tous', en: 'All', rn: 'Vyose', sw: 'Vyote'),
            options: [
              SelectionOption<SourceType?>(
                value: null,
                label: _l(fr: 'Tous', en: 'All', rn: 'Vyose', sw: 'Vyote'),
              ),
              ...SourceType.values.map(
                (item) => SelectionOption<SourceType?>(
                  value: item,
                  label: _enumLabel(item.name),
                ),
              ),
            ],
            selectedValue: _sourceType,
            onChanged: (value) => setState(() => _sourceType = value),
            prefixIcon: AppIcons.wallet,
            searchHint: _l(
              fr: 'Rechercher type source...',
              en: 'Search source type...',
              rn: 'Rondera ubwoko bw\'isoko...',
              sw: 'Tafuta aina ya chanzo...',
            ),
          ),
          SizedBox(height: 10.h),
          SearchableSelectionField<int?>(
            label: _l(
              fr: 'Source precise',
              en: 'Specific source',
              rn: 'Isoko rimwe',
              sw: 'Chanzo maalum',
            ),
            hint: _l(
              fr: 'Toutes les sources',
              en: 'All sources',
              rn: 'Amasoko yose',
              sw: 'Vyanzo vyote',
            ),
            options: options,
            selectedValue: _selectedSourceId,
            onChanged: (value) => setState(() => _selectedSourceId = value),
            prefixIcon: AppIcons.wallet,
            searchHint: _l(
              fr: 'Rechercher une source...',
              en: 'Search source...',
              rn: 'Rondera isoko...',
              sw: 'Tafuta chanzo...',
            ),
          ),
        ],
      ),
      _FilterStage.amount => Row(
        children: [
          Expanded(
            child: _textField(
              controller: _sourceMinController,
              label: _l(
                fr: 'Montant min',
                en: 'Min amount',
                rn: 'Amahera make',
                sw: 'Kiasi cha chini',
              ),
              hint: '0',
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _textField(
              controller: _sourceMaxController,
              label: _l(
                fr: 'Montant max',
                en: 'Max amount',
                rn: 'Amahera menshi',
                sw: 'Kiasi cha juu',
              ),
              hint: '100000',
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
      _FilterStage.options => Column(
        children: [
          _textField(
            controller: _sourceKeywordController,
            label: _l(
              fr: 'Mot-cle source',
              en: 'Source keyword',
              rn: 'Ijambo ry\'isoko',
              sw: 'Neno kuu la chanzo',
            ),
            hint: _l(
              fr: 'Nom, description...',
              en: 'Name, description...',
              rn: 'Izina, insiguro...',
              sw: 'Jina, maelezo...',
            ),
          ),
          SizedBox(height: 6.h),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _sourceActiveOnly,
            title: Text(
              _l(
                fr: 'Sources actives uniquement',
                en: 'Active sources only',
                rn: 'Amasoko akora gusa',
                sw: 'Vyanzo hai tu',
              ),
            ),
            onChanged: (value) => setState(() {
              _sourceActiveOnly = value;
              if (value) _sourcePassiveOnly = false;
            }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _sourcePassiveOnly,
            title: Text(
              _l(
                fr: 'Sources passives uniquement',
                en: 'Passive sources only',
                rn: 'Amasoko adakora gusa',
                sw: 'Vyanzo visivyo hai tu',
              ),
            ),
            onChanged: (value) => setState(() {
              _sourcePassiveOnly = value;
              if (value) _sourceActiveOnly = false;
            }),
          ),
        ],
      ),
    };
  }

  Widget _buildReviewStep(bool isDark) {
    final filters = _buildFilters();
    final items = <String>[
      '${_l(fr: 'Sections', en: 'Sections', rn: 'Ibice', sw: 'Sehemu')}: ${_enabledDomains.map(_domainLabel).join(', ')}',
      '${_l(fr: 'Periode', en: 'Period', rn: 'Igihe', sw: 'Muda')}: ${_periodSummary()}',
      '${_l(fr: 'Tri', en: 'Sort', rn: 'Itondekwa', sw: 'Mpangilio')}: ${_enumLabel(_sortBy.name)}',
      if (_customTitleController.text.trim().isNotEmpty)
        '${_l(fr: 'Titre', en: 'Title', rn: 'Umutwe', sw: 'Kichwa')}: ${_customTitleController.text.trim()}',
      if (_parseInt(_maxTransactionsController.text) != null)
        '${_l(fr: 'Limite transactions', en: 'Transaction limit', rn: 'Aho ibikorwa bigarukira', sw: 'Kikomo cha miamala')}: ${_parseInt(_maxTransactionsController.text)}',
      '${_l(fr: 'Filtres avances', en: 'Advanced filters', rn: 'Akayunguruzo gateye imbere', sw: 'Vichujio vya hali ya juu')}: ${filters.hasAdvancedFilters ? _l(fr: 'Oui', en: 'Yes', rn: 'Ego', sw: 'Ndio') : _l(fr: 'Non', en: 'No', rn: 'Oya', sw: 'Hapana')}',
    ];

    return ListView(
      key: const ValueKey('review_step'),
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      children: [
        _buildCard(
          isDark,
          title: _l(
            fr: 'Resume avant export',
            en: 'Summary before export',
            rn: 'Incamake imbere yo kohereza',
            sw: 'Muhtasari kabla ya kuhamisha',
          ),
          subtitle: _l(
            fr: 'Si tu ne changes rien, l\'export reste complet (par defaut).',
            en: 'If you change nothing, full export stays enabled by default.',
            rn: 'Nta gihinduwe, kohereza kwuzuye kugumaho nk\'uko bisanzwe.',
            sw: 'Usipobadilisha chochote, uhamishaji kamili hubaki chaguo-msingi.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...items.asMap().entries.map(
                (entry) =>
                    Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 2.h),
                                child: Icon(
                                  AppIcons.success,
                                  size: 14.sp,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate(delay: (entry.key * 40).ms)
                        .fadeIn(duration: 220.ms)
                        .slideX(begin: 0.02, end: 0, duration: 220.ms),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(bool isDark) {
    final isLast = _step == 3;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonal(
              onPressed: _step == 0
                  ? () => Navigator.pop(context)
                  : _previousStep,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                _step == 0
                    ? _l(fr: 'Fermer', en: 'Close', rn: 'Funga', sw: 'Funga')
                    : _l(
                        fr: 'Precedent',
                        en: 'Previous',
                        rn: 'Ibanje',
                        sw: 'Nyuma',
                      ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: FilledButton(
              onPressed: isLast ? _finish : _nextStep,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                isLast
                    ? _l(
                        fr: 'Exporter',
                        en: 'Export',
                        rn: 'Sohora',
                        sw: 'Hamisha',
                      )
                    : _l(
                        fr: 'Suivant',
                        en: 'Next',
                        rn: 'Ibikurikira',
                        sw: 'Ifuatayo',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_step == 1 && _datePreset == ReportDatePreset.custom) {
      if (_startDate == null || _endDate == null) {
        _showMessage(
          _l(
            fr: 'Choisis une date debut et fin.',
            en: 'Please select both start and end dates.',
            rn: 'Hitamwo itariki yo gutangura n\'iyo guheraheza.',
            sw: 'Tafadhali chagua tarehe ya mwanzo na mwisho.',
          ),
          icon: AppIcons.calendar,
        );
        return;
      }
      if (_endDate!.isBefore(_startDate!)) {
        _showMessage(
          _l(
            fr: 'La date de fin doit etre apres la date de debut.',
            en: 'End date must be after start date.',
            rn: 'Itariki y\'ihero itegerezwa kuba inyuma y\'itanguriro.',
            sw: 'Tarehe ya mwisho lazima iwe baada ya tarehe ya mwanzo.',
          ),
          icon: AppIcons.warning,
        );
        return;
      }
    }

    if (_step < 3) {
      setState(() => _step++);
    }
  }

  void _previousStep() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  void _finish() {
    if (_enabledDomains.isEmpty) {
      _showMessage(
        _l(
          fr: 'Active au moins une section a exporter.',
          en: 'Enable at least one section to export.',
          rn: 'Shiramwo nibura igice kimwe co gusohora.',
          sw: 'Washa angalau sehemu moja ya kuhamisha.',
        ),
        icon: AppIcons.warning,
      );
      return;
    }

    Navigator.pop(
      context,
      AdvancedExportResult(
        filters: _buildFilters(),
        customTitle: _customTitleController.text.trim().isEmpty
            ? null
            : _customTitleController.text.trim(),
      ),
    );
  }

  ReportExportFilters _buildFilters() {
    return ReportExportFilters(
      datePreset: _datePreset,
      customStartDate: _startDate,
      customEndDate: _endDate,
      includeTransactions: _includeTransactions,
      includeAssets: _includeAssets,
      includeDebts: _includeDebts,
      includeBanks: _includeBanks,
      includeSources: _includeSources,
      includeDeleted: _includeDeleted,
      includeCancelledTransactions: _includeCancelledTransactions,
      transactionTypes: _transactionTypes,
      transactionStatuses: _transactionStatuses,
      transactionSourceTypes: _transactionSourceTypes,
      incomeCategories: _incomeCategory == null ? const {} : {_incomeCategory!},
      expenseCategories: _expenseCategory == null
          ? const {}
          : {_expenseCategory!},
      selectedTransactionSourceIds: _selectedTxSourceId == null
          ? const {}
          : {_selectedTxSourceId!},
      selectedTransactionTargetIds: _selectedTxTargetId == null
          ? const {}
          : {_selectedTxTargetId!},
      transactionKeyword: _txKeywordController.text.trim(),
      recurringOnly: _recurringOnly,
      nonRecurringOnly: _nonRecurringOnly,
      transactionMinAmount: _parseDouble(_txMinController.text),
      transactionMaxAmount: _parseDouble(_txMaxController.text),
      assetTypes: _assetType == null ? const {} : {_assetType!},
      assetStatuses: _assetStatus == null ? const {} : {_assetStatus!},
      selectedAssetIds: _selectedAssetId == null
          ? const {}
          : {_selectedAssetId!},
      assetKeyword: _assetKeywordController.text.trim(),
      assetMinValue: _parseDouble(_assetMinController.text),
      assetMaxValue: _parseDouble(_assetMaxController.text),
      debtTypes: _debtType == null ? const {} : {_debtType!},
      debtStatuses: _debtStatus == null ? const {} : {_debtStatus!},
      selectedDebtIds: _selectedDebtId == null ? const {} : {_selectedDebtId!},
      debtPersonKeyword: _debtKeywordController.text.trim(),
      debtOverdueOnly: _debtOverdueOnly,
      debtHasReminderOnly: _debtHasReminderOnly,
      debtDueInDays: _parseInt(_debtDueDaysController.text),
      debtMinAmount: _parseDouble(_debtMinController.text),
      debtMaxAmount: _parseDouble(_debtMaxController.text),
      bankTypes: _bankType == null ? const {} : {_bankType!},
      bankInterestTypes: _bankInterestType == null
          ? const {}
          : {_bankInterestType!},
      selectedBankIds: _selectedBankId == null ? const {} : {_selectedBankId!},
      bankKeyword: _bankKeywordController.text.trim(),
      bankActiveOnly: _bankActiveOnly,
      bankMinBalance: _parseDouble(_bankMinController.text),
      bankMaxBalance: _parseDouble(_bankMaxController.text),
      sourceTypes: _sourceType == null ? const {} : {_sourceType!},
      selectedSourceIds: _selectedSourceId == null
          ? const {}
          : {_selectedSourceId!},
      sourceKeyword: _sourceKeywordController.text.trim(),
      sourceActiveOnly: _sourceActiveOnly,
      sourcePassiveOnly: _sourcePassiveOnly,
      sourceMinAmount: _parseDouble(_sourceMinController.text),
      sourceMaxAmount: _parseDouble(_sourceMaxController.text),
      sortBy: _sortBy,
      maxTransactions: _parseInt(_maxTransactionsController.text),
    );
  }

  List<_Domain> get _enabledDomains {
    final items = <_Domain>[];
    if (_includeTransactions) items.add(_Domain.transactions);
    if (_includeAssets) items.add(_Domain.assets);
    if (_includeDebts) items.add(_Domain.debts);
    if (_includeBanks) items.add(_Domain.banks);
    if (_includeSources) items.add(_Domain.sources);
    return items;
  }

  void _selectAllSections() {
    setState(() {
      _includeTransactions = true;
      _includeAssets = true;
      _includeDebts = true;
      _includeBanks = true;
      _includeSources = true;
      _activeDomain = _Domain.transactions;
      _filterStage = _FilterStage.selection;
    });
  }

  void _selectOnly(_Domain domain) {
    setState(() {
      _includeTransactions = domain == _Domain.transactions;
      _includeAssets = domain == _Domain.assets;
      _includeDebts = domain == _Domain.debts;
      _includeBanks = domain == _Domain.banks;
      _includeSources = domain == _Domain.sources;
      _activeDomain = domain;
      _filterStage = _FilterStage.selection;
    });
  }

  void _toggleSection(_Domain domain, bool value) {
    final previousEnabled = _enabledDomains;

    setState(() {
      switch (domain) {
        case _Domain.transactions:
          _includeTransactions = value;
        case _Domain.assets:
          _includeAssets = value;
        case _Domain.debts:
          _includeDebts = value;
        case _Domain.banks:
          _includeBanks = value;
        case _Domain.sources:
          _includeSources = value;
      }

      if (_enabledDomains.isEmpty) {
        // Keep at least one section active and notify clearly.
        switch (domain) {
          case _Domain.transactions:
            _includeTransactions = true;
          case _Domain.assets:
            _includeAssets = true;
          case _Domain.debts:
            _includeDebts = true;
          case _Domain.banks:
            _includeBanks = true;
          case _Domain.sources:
            _includeSources = true;
        }
      }

      if (!_enabledDomains.contains(_activeDomain)) {
        _activeDomain = _enabledDomains.first;
        _filterStage = _FilterStage.selection;
      }
    });

    if (!value &&
        previousEnabled.length == 1 &&
        previousEnabled.first == domain) {
      _showMessage(
        _l(
          fr: 'Au moins une section doit rester active.',
          en: 'At least one section must stay enabled.',
          rn: 'Nibura igice kimwe kigume gikora.',
          sw: 'Angalau sehemu moja lazima ibaki imewashwa.',
        ),
        icon: AppIcons.info,
      );
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_startDate ?? now)
        : (_endDate ?? (_startDate ?? now));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  String _periodSummary() {
    return switch (_datePreset) {
      ReportDatePreset.all => _datePresetLabel(ReportDatePreset.all),
      ReportDatePreset.today => _datePresetLabel(ReportDatePreset.today),
      ReportDatePreset.yesterday => _datePresetLabel(
        ReportDatePreset.yesterday,
      ),
      ReportDatePreset.last7Days => _datePresetLabel(
        ReportDatePreset.last7Days,
      ),
      ReportDatePreset.thisMonth => _datePresetLabel(
        ReportDatePreset.thisMonth,
      ),
      ReportDatePreset.lastMonth => _datePresetLabel(
        ReportDatePreset.lastMonth,
      ),
      ReportDatePreset.thisYear => _datePresetLabel(ReportDatePreset.thisYear),
      ReportDatePreset.custom =>
        (_startDate != null && _endDate != null)
            ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
            : _datePresetLabel(ReportDatePreset.custom),
    };
  }

  String _domainLabel(_Domain domain) {
    return switch (domain) {
      _Domain.transactions => _l(
        fr: 'Transactions',
        en: 'Transactions',
        rn: 'Ibikorwa',
        sw: 'Miamala',
      ),
      _Domain.assets => _l(
        fr: 'Actifs',
        en: 'Assets',
        rn: 'Itunga',
        sw: 'Mali',
      ),
      _Domain.debts => _l(
        fr: 'Dettes',
        en: 'Debts',
        rn: 'Imyenda',
        sw: 'Madeni',
      ),
      _Domain.banks => _l(
        fr: 'Banques',
        en: 'Banks',
        rn: 'Amabanki',
        sw: 'Benki',
      ),
      _Domain.sources => _l(
        fr: 'Sources',
        en: 'Sources',
        rn: 'Amasoko',
        sw: 'Vyanzo',
      ),
    };
  }

  String _datePresetLabel(ReportDatePreset preset) {
    return switch (preset) {
      ReportDatePreset.all => _l(
        fr: 'Tout',
        en: 'All',
        rn: 'Vyose',
        sw: 'Vyote',
      ),
      ReportDatePreset.today => _l(
        fr: 'Aujourd\'hui',
        en: 'Today',
        rn: 'Uno munsi',
        sw: 'Leo',
      ),
      ReportDatePreset.yesterday => _l(
        fr: 'Hier',
        en: 'Yesterday',
        rn: 'Ejo',
        sw: 'Jana',
      ),
      ReportDatePreset.last7Days => _l(
        fr: '7 jours',
        en: 'Last 7 days',
        rn: 'Iminsi 7 iheze',
        sw: 'Siku 7 zilizopita',
      ),
      ReportDatePreset.thisMonth => _l(
        fr: 'Ce mois',
        en: 'This month',
        rn: 'Uku kwezi',
        sw: 'Mwezi huu',
      ),
      ReportDatePreset.lastMonth => _l(
        fr: 'Mois dernier',
        en: 'Last month',
        rn: 'Ukwezi guheze',
        sw: 'Mwezi uliopita',
      ),
      ReportDatePreset.thisYear => _l(
        fr: 'Cette annee',
        en: 'This year',
        rn: 'Uyu mwaka',
        sw: 'Mwaka huu',
      ),
      ReportDatePreset.custom => _l(
        fr: 'Personnalisee',
        en: 'Custom',
        rn: 'Wihariye',
        sw: 'Maalum',
      ),
    };
  }

  String _enumLabel(String value) {
    final words = value
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .split(RegExp(r'[_\s]+'))
        .where((item) => item.isNotEmpty)
        .toList();

    return words
        .map(
          (word) =>
              word.substring(0, 1).toUpperCase() +
              word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  String _l({
    required String fr,
    required String en,
    required String rn,
    required String sw,
  }) {
    final localeCode = Localizations.localeOf(context).languageCode;
    return switch (localeCode) {
      'en' => en,
      'rn' => rn,
      'sw' => sw,
      _ => fr,
    };
  }

  void _showMessage(
    String message, {
    Color? color,
    IconData icon = AppIcons.warning,
  }) {
    final bgColor = color ?? AppColors.warning;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        backgroundColor: bgColor,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? _parseInt(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  double? _parseDouble(String value) {
    final cleaned = value.replaceAll(',', '.').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  Widget _staggeredColumn(List<Widget> children, {int baseDelayMs = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int index = 0; index < children.length; index++)
          children[index]
              .animate(delay: (baseDelayMs + (index * 35)).ms)
              .fadeIn(duration: 220.ms)
              .slideY(begin: 0.03, end: 0, duration: 220.ms),
      ],
    );
  }

  Widget _buildCard(
    bool isDark, {
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : Colors.grey.shade600,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.03, end: 0);
  }

  Widget _sectionSwitch(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: value
            ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1)
            : (isDark ? AppColors.backgroundDark : Colors.grey.shade50),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: AppColors.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _chipGroup<T>(
    bool isDark, {
    required String title,
    required List<(T, String)> options,
    required T current,
    required ValueChanged<T> onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((entry) {
            final selected = current == entry.$1;
            return ChoiceChip(
              label: Text(entry.$2),
              selected: selected,
              side: BorderSide.none,
              backgroundColor: isDark
                  ? AppColors.backgroundDark
                  : Colors.grey.shade100,
              selectedColor: AppColors.primary.withValues(alpha: 0.16),
              onSelected: (_) => onTap(entry.$1),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _dateButton(
    bool isDark, {
    required String label,
    required DateTime? value,
    required VoidCallback onPressed,
  }) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Text(
        value == null ? label : DateFormat('dd/MM/yyyy').format(value),
        style: TextStyle(fontSize: 12.sp),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13.sp),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: isDark ? AppColors.backgroundDark : Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _multiSelectEnumChips<T extends Enum>({
    required String title,
    required List<T> allValues,
    required Set<T> selectedValues,
    required String Function(T value) toLabel,
    required void Function(T value, bool selected) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allValues.map((value) {
            final selected = selectedValues.contains(value);
            return FilterChip(
              label: Text(toLabel(value)),
              selected: selected,
              side: BorderSide.none,
              backgroundColor: isDark
                  ? AppColors.backgroundDark
                  : Colors.grey.shade100,
              selectedColor: AppColors.primary.withValues(alpha: 0.16),
              onSelected: (next) => onChanged(value, next),
            );
          }).toList(),
        ),
      ],
    );
  }
}
