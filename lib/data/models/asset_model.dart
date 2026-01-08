import 'package:isar/isar.dart';

part 'asset_model.g.dart';

enum AssetType {
  livestock,
  crop,
  land,
  vehicle,
  equipment,
  jewelry,
  other,
}

enum AssetStatus {
  owned,
  sold,
  lost,
  donated,
}

@collection
class AssetModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String name;

  @enumerated
  late AssetType type;

  late double purchasePrice;

  late double currentValue;

  late String currency;

  late DateTime purchaseDate;

  @enumerated
  late AssetStatus status;

  int? quantity;

  String? unit;

  late DateTime createdAt;

  DateTime? updatedAt;

  String? description;

  String? location;

  String? notes;

  @Index()
  late bool isDeleted;

  int? relatedTransactionId;

  DateTime? soldDate;

  double? soldPrice;

  List<String>? imagePaths;

  AssetModel({
    this.id = Isar.autoIncrement,
    required this.name,
    required this.type,
    required this.purchasePrice,
    required this.currentValue,
    this.currency = 'FBU',
    required this.purchaseDate,
    this.status = AssetStatus.owned,
    this.quantity,
    this.unit,
    required this.createdAt,
    this.updatedAt,
    this.description,
    this.location,
    this.notes,
    this.isDeleted = false,
    this.relatedTransactionId,
    this.soldDate,
    this.soldPrice,
    this.imagePaths,
  });

  double get totalValue {
    final qty = quantity ?? 1;
    return currentValue * qty;
  }

  double get profitLoss {
    return currentValue - purchasePrice;
  }

  double get profitLossPercentage {
    if (purchasePrice == 0) return 0;
    return ((currentValue - purchasePrice) / purchasePrice) * 100;
  }
}
