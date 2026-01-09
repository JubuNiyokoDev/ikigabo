import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_rn.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('rn'),
    Locale('sw'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Ikigabo'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  // Banks
  String get banks;
  String get addBank;
  String get bankBalance;
  String get totalAmount;
  String get bankFees;
  String get save;

  // Assets
  String get assets;
  String get addAsset;
  String get convertibleAsset;
  String get totalAssets;
  String get totalValue;
  String get information;
  String get actions;
  String get editAsset;
  String get deleteAsset;
  String get confirmDeleteAsset;
  String get assetDeletedSuccessfully;
  String get financialDetails;
  String get status;
  String get owned;
  String get sold;
  String get lost;
  String get donated;

  // Dashboard
  String get dashboard;
  String get personalWealth;
  String get totalWealth;
  String get monthlyGrowth;
  String get weeklyActivity;
  String get thisWeek;
  String get income;
  String get expense;
  String get assetDistribution;
  String get debtsLoans;
  String get lent;
  String get borrowed;
  String get recentTransactions;
  String get seeAll;
  String get noRecentTransactions;
  String get loadingError;

  // Quick Actions
  String get goods;
  String get debts;

  // Banks
  String get noBanks;
  String get addFirstBank;
  String get error;
  String get feesToDeduct;
  String get free;
  String get paid;
  String get fees;
  String get toDeduct;
  String get month;
  String get year;

  // Notifications
  String get notifications;

  // Currencies
  String get burundianFranc;
  String get usDollar;
  String get euro;
  String get tanzanianShilling;
  String get kenyanShilling;
  String get ugandanShilling;
  String get rwandanFranc;
  String get congoleseFranc;

  // Main Screen
  String get management;
  String get accessAllYourData;

  // Settings
  String get chooseLanguage;
  String get defaultCurrency;
  String get security;
  String get pinCode;
  String get changePinCode;
  String get biometricAuth;
  String get fingerprint;
  String get manageNotifications;
  String get data;
  String get autoBackup;
  String get enableBackup;
  String get backupRestore;
  String get manageBackups;
  String get about;
  String get version;
  String get help;
  String get helpCenter;
  String get privacy;
  String get privacyPolicy;
  String get terms;
  String get termsOfService;

  // Add Bank Screen
  String get newBank;
  String get editBank;
  String get bankName;
  String get bankNameHint;
  String get accountNumber;
  String get accountNumberHint;
  String get currentBalance;
  String get currency;
  String get bankType;
  String get feeConfiguration;
  String get feeAmount;
  String get type;
  String get period;
  String get fixedAmount;
  String get percentage;
  String get monthly;
  String get annual;
  String get description;
  String get descriptionHint;
  String get activeAccount;
  String get includeInCalculations;
  String get bankNameRequired;
  String get invalidBalance;
  String get balanceRequired;
  String get feesRequiredForPaidBank;
  String get invalidAmount;
  String get bankAddedSuccess;
  String get bankUpdatedSuccess;

  // Add Source Screen
  String get newSource;
  String get editSource;
  String get sourceName;
  String get sourceNameHint;
  String get sourceType;
  String get amount;
  String get activeSource;
  String get sourceNameRequired;
  String get amountRequired;
  String get sourceAddedSuccess;
  String get sourceUpdatedSuccess;

  // Source Types
  String get pocket;
  String get safe;
  String get debtGiven;
  String get debtReceived;
  String get custom;
  String get cash;

  // Sources List Screen
  String get mySources;
  String get manageYourMoneySources;
  String get searchSource;
  String get noSources;
  String get addFirstSource;
  String get active;
  String get inactive;

  // Assets
  String get noAssets;
  String get addFirstAsset;
  String get profitLoss;
  String get revaluate;
  String get sell;
  String get revaluateAsset;
  String get newValue;
  String get sellAsset;
  String get sellPrice;
  String get cancel;
  String get confirm;

  // Add Asset Screen
  String get newAsset;
  String get assetName;
  String get assetNameHint;
  String get assetType;
  String get purchasePrice;
  String get currentValue;
  String get quantity;
  String get unit;
  String get purchaseDate;
  String get location;
  String get assetNameRequired;
  String get purchasePriceRequired;
  String get currentValueRequired;
  String get invalidPrice;
  String get invalidValue;
  String get assetAddedSuccess;
  String get assetUpdatedSuccess;

  // Asset Types
  String get livestock;
  String get crop;
  String get land;
  String get vehicle;
  String get equipment;
  String get jewelry;
  String get other;

  // Debts
  String get myDebts;
  String get loansAndBorrows;
  String get searchDebt;
  String get overdueDebts;
  String get upcomingDue;
  String get all;
  String get noDebts;
  String get addFirstDebt;
  String get lentTo;
  String get borrowedFrom;
  String get overdue;
  String get daysRemaining;

  // Add Debt Screen
  String get newDebt;
  String get editDebt;
  String get debtType;
  String get borrowerName;
  String get lenderName;
  String get contact;
  String get contactHint;
  String get date;
  String get dueDate;
  String get dueDateOptional;
  String get none;
  String get withInterest;
  String get addInterestRate;
  String get interestRate;
  String get interestRateHint;
  String get interestRateRequired;
  String get collateral;
  String get collateralHint;
  String get addDebt;
  String get nameRequired;
  String get debtAddedSuccess;
  String get debtUpdatedSuccess;

  // Statistics Screen
  String get statistics;
  String get analyzeYourFinances;
  String get week;
  String get balance;
  String get entries;
  String get exits;
  String get distribution;
  String get noData;
  String get trend;
  String get byCategory;
  String get food;
  String get transport;
  String get health;
  String get entertainment;

  // Notifications Screen
  String get debtReminders;
  String get debtRemindersSubtitle;
  String get overdueAlerts;
  String get overdueAlertsSubtitle;
  String get bankFeesSubtitle;
  String get wealth;
  String get wealthMilestones;
  String get wealthMilestonesSubtitle;
  String get maintenance;
  String get backupReminders;
  String get backupRemindersSubtitle;
  String get manageYourApp;
  String get dangerZone;
  String get deleteAllData;
  String get support;
  String get contactUs;

  // PIN Security
  String get createPin;
  String get confirmPin;
  String get enterPin;
  String get enterNewPin;
  String get createPinDescription;
  String get confirmYourPin;
  String get enterPinToContinue;
  String get enterNewPinDescription;
  String get incorrectPin;
  String get skipForNow;
  String get changePin;
  String get disablePin;
  String get setupPin;
  String get confirmDisablePin;
  String get disable;

  // Backup
  String get backup;
  String get createBackup;
  String get exportAllData;
  String get restoreBackup;
  String get importFromFile;
  String get protectWithPassword;
  String get password;
  String get export;
  String get backupCreatedSuccess;
  String get restoreFeatureComingSoon;

  // Backup additional translations
  String get selectBackupFile;
  String get backupLocationHint;
  String get select;
  String get selectJsonFileError;
  String get chooseBackup;
  String get dataImportedSuccess;
  String get unknownError;
  String get ok;
  String get conflictsDetected;
  String get existingDataMessage;
  String get dataImportedIgnored;
  String get ignore;
  String get dataImportedOverwritten;
  String get overwrite;
  String get fileSavedIn;
  String get downloadsIkigaboPath;
  String get success;
  String get browseOtherFolder;
  String get selectFile;
  String get deleteAllDataConfirmation;
  String get delete;
  String get allDataDeleted;

  // Bank Creation
  String get selectMoneySource;
  String get noMoneySourceAvailable;
  String get createSourceFirst;
  String get moneyAlreadyInAccount;
  String get moneyExistsInRealBank;
  String get transactionsCreated;
  String get twoTransactionsCreated;
  String get withdrawalFrom;
  String get depositTo;
  String get pleaseSelectSource;
  String get insufficientBalance;
  String get currencyMismatch;

  // Transaction Detail
  String get transactionDetail;
  String get informations;
  String get sourceAndDestination;
  String get source;
  String get destination;
  String get note;
  String get category;
  String get entry;
  String get exit;

  // Transaction List
  String get transactions;
  String get noTransactions;
  String get transactionsWillAppear;
  String get deleteTransaction;
  String get confirmDeleteTransaction;
  String get transactionDeleted;
  String get editTransactionSoon;
  String get today;
  String get yesterday;

  // Edit Transaction
  String get editTransaction;
  String get transactionUpdated;

  // Days of week (short)
  String get mondayShort;
  String get tuesdayShort;
  String get wednesdayShort;
  String get thursdayShort;
  String get fridayShort;
  String get saturdayShort;
  String get sundayShort;

  // Debt warnings
  String debtsOverdue(int count);
  String debtsDueSoon(int count);

  // Additional translations
  String get liabilities;

  // Bank Detail Screen
  String get currentBalanceLabel;
  String get inactiveAccount;
  String get bankTypeLabel;
  String get freeBank;
  String get paidBank;
  String get currencyLabel;
  String get descriptionLabel;
  String get createdOn;
  String get bankFeesLabel;
  String get feeAmountLabel;
  String get calculatedFees;
  String get frequencyLabel;
  String get monthlyFreq;
  String get annualFreq;
  String get nextDeduction;
  String get actionsLabel;
  String get deleteBank;
  String get deleteBankTitle;
  String get deleteBankConfirmation;
  String get thisActionIsIrreversible;
  String get bankDeletedSuccess;
  String get assetAlreadyOwned;
  String get assetWasAlreadyOwned;

  // Additional hint translations
  String get locationHint;
  String get unitHint;
  String get personNameHint;
  String get debtGivenSourceHint;
  String get debtReceivedSourceHint;
  String get externalMoney;
  String get noCurrencySourceAvailable;
  String get remainingAmount;
  String get progression;
  String get paidLabel;
  String get totalLabel;
  
  // Debt Detail Screen additional translations
  String get informationsLabel;
  String get contactLabel;
  String get dateLabel;
  String get dueDateLabel;
  String get debtOverdueWarning;
  String get collateralLabel;
  String get interestLabel;
  String get interestRateLabel;
  String get interestAmountLabel;
  String get totalWithInterestLabel;
  String get paymentHistoryLabel;
  String get noPaymentsRecorded;
  String get recordPayment;
  String get deleteDebt;
  String get deleteDebtConfirmation;
  String get debtDeletedSuccess;
  String get recordPaymentTitle;
  String get remainingAmountLabel;
  String get paymentAmount;
  String get whereToReceiveMoney;
  String get whereToTakeMoney;
  String get externalMoneyLabel;
  String get paymentRecorded;
  String get cumulativePayments;
  String get payment;

  // Transaction Creation
  String get newTransaction;
  String get addIncomeOrExpense;
  String get transactionAddedSuccess;
  String get noSourcesCreateFirst;
  String get addNote;
  String get salary;
  String get sale;
  String get gift;
  String get investment;
  String get purchase;
  String get utilities;
  String get education;

  // Debt Reminders
  String get debtReminder;
  String get selectReminderDateTime;

  // PDF Export
  String get exportPdf;
  String get fullReport;
  String get allFinancialData;
  String get assetReport;
  String get debtReport;
  String get exportInProgress;
  String get assetExportInProgress;
  String get debtExportInProgress;

  // Onboarding
  String get onboardingTitle1;
  String get onboardingDesc1;
  String get onboardingTitle2;
  String get onboardingDesc2;
  String get onboardingTitle3;
  String get onboardingDesc3;
  String get skip;
  String get next;
  String get getStarted;

  // About Section (nouvelles clés seulement)
  String get termsAndConditions;
  String get reportProblem;
  String get rateThisApp;
  String get shareThisApp;
  String get moreApps;
  String get appInfo;
  String get legal;

  // Nouvelles traductions pour settings
  String get manageCategoriesSubtitle;
  String get budgetsAndGoals;
  String get manageFinancialGoals;
  String get reportProblemSubtitle;
  String get rateOnPlayStore;
  String get shareWithFriends;
  String get discoverOtherApps;
  String get termsOfUse;
  String get privacyPolicySubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'rn', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'rn':
      return AppLocalizationsRn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
