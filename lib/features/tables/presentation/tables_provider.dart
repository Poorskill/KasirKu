import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/restaurant_table.dart';
import '../../../models/table_session.dart';
import '../../../repositories/table_repository.dart';

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return HybridTableRepository();
});

final tablesStreamProvider = StreamProvider<List<RestaurantTable>>((ref) {
  final repo = ref.watch(tableRepositoryProvider);
  return repo.watchTables();
});

final tableSessionsStreamProvider = StreamProvider<List<TableSession>>((ref) {
  final repo = ref.watch(tableRepositoryProvider);
  return repo.watchSessions();
});

final selectedTableFilterProvider = StateProvider<String>((ref) => 'all');
final tableSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredTablesProvider = Provider<List<RestaurantTable>>((ref) {
  final tablesAsync = ref.watch(tablesStreamProvider);
  final filter = ref.watch(selectedTableFilterProvider);
  final search = ref.watch(tableSearchQueryProvider).trim().toLowerCase();

  return tablesAsync.maybeWhen(
    data: (tables) {
      return tables.where((t) {
        if (filter != 'all' && t.status.name != filter) {
          return false;
        }
        if (search.isNotEmpty) {
          final matchesNumber = t.tableNumber.toLowerCase().contains(search);
          final matchesName = t.name.toLowerCase().contains(search);
          if (!matchesNumber && !matchesName) return false;
        }
        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

class TableController extends StateNotifier<AsyncValue<void>> {
  final TableRepository _repo;

  TableController(this._repo) : super(const AsyncValue.data(null));

  Future<bool> createTable({
    required String tableNumber,
    required String name,
    required int capacity,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final uuid = const Uuid().v4().substring(0, 8);
      final table = RestaurantTable(
        id: 'tbl-${now.millisecondsSinceEpoch % 100000}',
        tableNumber: tableNumber.trim(),
        name: name.trim(),
        capacity: capacity,
        status: TableStatus.available,
        qrToken: 'tbl_tok_${tableNumber.trim()}_$uuid',
        createdAt: now,
        updatedAt: now,
      );
      await _repo.addTable(table);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateTable(RestaurantTable table) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateTable(table);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateStatus(String tableId, TableStatus status) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateTableStatus(tableId, status);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<String> regenerateQr(String tableId) async {
    state = const AsyncValue.loading();
    try {
      final token = await _repo.regenerateQrToken(tableId);
      state = const AsyncValue.data(null);
      return token;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return '';
    }
  }

  Future<bool> deleteTable(String tableId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteTable(tableId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> openSession(String tableId, {String staff = 'Staff'}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.openTableSession(tableId, createdBy: staff);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateSessionAmounts(
    String sessionId, {
    required double totalAmount,
    required double paidAmount,
    List<String>? orderIds,
  }) async {
    try {
      await _repo.updateSessionAmounts(
        sessionId,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        orderIds: orderIds,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> closeSession(String sessionId, {double? totalAmount, double? paidAmount}) async {
    state = const AsyncValue.loading();
    try {
      if (totalAmount != null && paidAmount != null) {
        await _repo.updateSessionAmounts(
          sessionId,
          totalAmount: totalAmount,
          paidAmount: paidAmount,
        );
      }
      await _repo.closeTableSession(sessionId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> closeTable(String tableId, {String? sessionId, double? totalAmount, double? paidAmount}) async {
    state = const AsyncValue.loading();
    try {
      if (sessionId != null && sessionId.isNotEmpty) {
        if (totalAmount != null && paidAmount != null) {
          await _repo.updateSessionAmounts(
            sessionId,
            totalAmount: totalAmount,
            paidAmount: paidAmount,
          );
        }
        await _repo.closeTableSession(sessionId);
      } else {
        await _repo.updateTableStatus(tableId, TableStatus.available);
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final tableControllerProvider =
    StateNotifierProvider<TableController, AsyncValue<void>>((ref) {
  final repo = ref.watch(tableRepositoryProvider);
  return TableController(repo);
});
