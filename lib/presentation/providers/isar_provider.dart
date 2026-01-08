import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/services/isar_service.dart';

final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

final isarProvider = FutureProvider<Isar>((ref) async {
  final service = ref.watch(isarServiceProvider);
  return await service.isar;
});
