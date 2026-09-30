import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import '../models/restaurant_table.dart';
import '../models/table_session.dart';

abstract class TableRepository {
  Stream<List<RestaurantTable>> watchTables();
  Future<List<RestaurantTable>> getTables();
  Future<RestaurantTable?> getTableById(String id);
  Future<RestaurantTable?> getTableByToken(String qrToken);
  Future<void> addTable(RestaurantTable table);
  Future<void> updateTable(RestaurantTable table);
  Future<void> updateTableStatus(String tableId, TableStatus status);
  Future<String> regenerateQrToken(String tableId);
  Future<void> deleteTable(String tableId);

  // Sessions
  Stream<List<TableSession>> watchSessions();
  Future<TableSession?> getSessionById(String id);
  Future<TableSession> openTableSession(String tableId, {String createdBy = 'Staff'});
  Future<void> updateSessionAmounts(String sessionId, {required double totalAmount, required double paidAmount, List<String>? orderIds});
  Future<bool> closeTableSession(String sessionId);
}

class HybridTableRepository implements TableRepository {
  final _uuid = const Uuid();
  final _tablesController = StreamController<List<RestaurantTable>>.broadcast();
  final _sessionsController = StreamController<List<TableSession>>.broadcast();

  List<RestaurantTable> _inMemoryTables = [];
  List<TableSession> _inMemorySessions = [];
  bool _firebaseReady = false;

  HybridTableRepository() {
    _init();
  }

  void _init() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firebaseReady = true;
      }
    } catch (_) {
      _firebaseReady = false;
    }

    if (!_firebaseReady) {
      _seedTables();
    }
  }

  void _seedTables() {
    final now = DateTime.now();
    _inMemoryTables = [
      RestaurantTable(
        id: 'tbl-01',
        tableNumber: '01',
        name: 'Meja 01 (Indoor Depan)',
        capacity: 2,
        status: TableStatus.available,
        qrToken: 'tbl_tok_01_a9f82d',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      ),
      RestaurantTable(
        id: 'tbl-02',
        tableNumber: '02',
        name: 'Meja 02 (Indoor Tengah)',
        capacity: 4,
        status: TableStatus.occupied,
        qrToken: 'tbl_tok_02_e4c19b',
        currentSessionId: 'sess-02',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      ),
      RestaurantTable(
        id: 'tbl-03',
        tableNumber: '03',
        name: 'Meja 03 (Sofa Keluarga)',
        capacity: 6,
        status: TableStatus.reserved,
        qrToken: 'tbl_tok_03_8f0a31',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      ),
      RestaurantTable(
        id: 'tbl-04',
        tableNumber: '04',
        name: 'Meja 04 (Outdoor Taman)',
        capacity: 4,
        status: TableStatus.available,
        qrToken: 'tbl_tok_04_37b8c2',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      ),
      RestaurantTable(
        id: 'tbl-05',
        tableNumber: '05',
        name: 'Meja 05 (Outdoor Balcony)',
        capacity: 4,
        status: TableStatus.cleaning,
        qrToken: 'tbl_tok_05_91ad44',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      ),
      RestaurantTable(
        id: 'tbl-06',
        tableNumber: '06',
        name: 'Meja 06 (Bar Counter)',
        capacity: 2,
        status: TableStatus.available,
        qrToken: 'tbl_tok_06_66f10c',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      ),
    ];

    _inMemorySessions = [
      TableSession(
        id: 'sess-02',
        tableId: 'tbl-02',
        tableNumber: '02',
        status: SessionStatus.open,
        totalAmount: 78000,
        paidAmount: 78000,
        orderIds: const ['ORD-1028'],
        startedAt: now.subtract(const Duration(minutes: 45)),
        createdBy: 'Customer QR',
      ),
    ];

    _tablesController.add(List.unmodifiable(_inMemoryTables));
    _sessionsController.add(List.unmodifiable(_inMemorySessions));
  }

  @override
  Stream<List<RestaurantTable>> watchTables() async* {
    if (_firebaseReady) {
      try {
        yield* FirebaseFirestore.instance
            .collection('tables')
            .orderBy('tableNumber')
            .snapshots()
            .map((snap) {
          if (snap.docs.isEmpty) {
            return List.unmodifiable(_inMemoryTables);
          }
          return snap.docs
              .map((d) => RestaurantTable.fromJson(d.data(), id: d.id))
              .toList();
        });
        return;
      } catch (_) {}
    }
    yield List.unmodifiable(_inMemoryTables);
    yield* _tablesController.stream;
  }

  @override
  Future<List<RestaurantTable>> getTables() async {
    if (_firebaseReady) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('tables')
            .orderBy('tableNumber')
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => RestaurantTable.fromJson(d.data(), id: d.id))
              .toList();
        }
      } catch (_) {}
    }
    return List.unmodifiable(_inMemoryTables);
  }

  @override
  Future<RestaurantTable?> getTableById(String id) async {
    final list = await getTables();
    final matches = list.where((t) => t.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Future<RestaurantTable?> getTableByToken(String qrToken) async {
    final list = await getTables();
    final trimmed = qrToken.trim();
    if (trimmed.isEmpty) return null;
    final exact = list.where((t) => t.qrToken == trimmed);
    return exact.isNotEmpty ? exact.first : null;
  }

  @override
  Future<void> addTable(RestaurantTable table) async {
    if (_firebaseReady) {
      try {
        final doc = FirebaseFirestore.instance.collection('tables').doc();
        final toSave = table.copyWith(id: doc.id);
        await doc.set(toSave.toJson());
        return;
      } catch (_) {}
    }

    _inMemoryTables.add(table);
    _tablesController.add(List.unmodifiable(_inMemoryTables));
  }

  @override
  Future<void> updateTable(RestaurantTable table) async {
    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('tables')
            .doc(table.id)
            .update(table.toJson());
        return;
      } catch (_) {}
    }

    final index = _inMemoryTables.indexWhere((t) => t.id == table.id);
    if (index != -1) {
      _inMemoryTables[index] = table;
      _tablesController.add(List.unmodifiable(_inMemoryTables));
    }
  }

  @override
  Future<void> updateTableStatus(String tableId, TableStatus status) async {
    final table = await getTableById(tableId);
    if (table != null) {
      final updated = table.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      await updateTable(updated);
    }
  }

  @override
  Future<String> regenerateQrToken(String tableId) async {
    final table = await getTableById(tableId);
    if (table == null) return '';

    final newToken = 'tbl_tok_${table.tableNumber}_${_uuid.v4().substring(0, 8)}';
    final updated = table.copyWith(
      qrToken: newToken,
      updatedAt: DateTime.now(),
    );
    await updateTable(updated);
    return newToken;
  }

  @override
  Future<void> deleteTable(String tableId) async {
    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance.collection('tables').doc(tableId).delete();
        return;
      } catch (_) {}
    }

    _inMemoryTables.removeWhere((t) => t.id == tableId);
    _tablesController.add(List.unmodifiable(_inMemoryTables));
  }

  @override
  Stream<List<TableSession>> watchSessions() async* {
    if (_firebaseReady) {
      try {
        yield* FirebaseFirestore.instance
            .collection('table_sessions')
            .orderBy('startedAt', descending: true)
            .snapshots()
            .map((snap) {
          if (snap.docs.isEmpty) {
            return List.unmodifiable(_inMemorySessions);
          }
          return snap.docs
              .map((d) => TableSession.fromJson(d.data(), id: d.id))
              .toList();
        });
        return;
      } catch (_) {}
    }
    yield List.unmodifiable(_inMemorySessions);
    yield* _sessionsController.stream;
  }

  @override
  Future<TableSession?> getSessionById(String id) async {
    final matches = _inMemorySessions.where((s) => s.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Future<TableSession> openTableSession(String tableId, {String createdBy = 'Staff'}) async {
    final table = await getTableById(tableId);
    if (table == null) {
      throw Exception('Meja tidak ditemukan');
    }

    final now = DateTime.now();
    final sessionId = 'TS-${now.millisecondsSinceEpoch % 100000}';
    final session = TableSession(
      id: sessionId,
      tableId: table.id,
      tableNumber: table.tableNumber,
      status: SessionStatus.open,
      startedAt: now,
      createdBy: createdBy,
    );

    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('table_sessions')
            .doc(sessionId)
            .set(session.toJson());
      } catch (_) {}
    }

    _inMemorySessions.insert(0, session);
    _sessionsController.add(List.unmodifiable(_inMemorySessions));

    // Update table status to occupied
    final updatedTable = table.copyWith(
      status: TableStatus.occupied,
      currentSessionId: sessionId,
      updatedAt: now,
    );
    await updateTable(updatedTable);

    return session;
  }

  @override
  Future<void> updateSessionAmounts(
    String sessionId, {
    required double totalAmount,
    required double paidAmount,
    List<String>? orderIds,
  }) async {
    final idx = _inMemorySessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final updated = _inMemorySessions[idx].copyWith(
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        orderIds: orderIds ?? _inMemorySessions[idx].orderIds,
      );
      _inMemorySessions[idx] = updated;
      _sessionsController.add(List.unmodifiable(_inMemorySessions));
      if (_firebaseReady) {
        try {
          await FirebaseFirestore.instance
              .collection('table_sessions')
              .doc(sessionId)
              .update(updated.toJson());
        } catch (_) {}
      }
    }
  }

  @override
  Future<bool> closeTableSession(String sessionId) async {
    final sessionIndex = _inMemorySessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return false;

    final session = _inMemorySessions[sessionIndex];
    if (!session.canClose) {
      throw Exception('Sesi tidak dapat ditutup. Masih ada tagihan belum lunas.');
    }

    final now = DateTime.now();
    final closedSession = session.copyWith(
      status: SessionStatus.closed,
      closedAt: now,
    );

    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('table_sessions')
            .doc(sessionId)
            .update(closedSession.toJson());
      } catch (_) {}
    }

    _inMemorySessions[sessionIndex] = closedSession;
    _sessionsController.add(List.unmodifiable(_inMemorySessions));

    // Reset table to available
    final table = await getTableById(session.tableId);
    if (table != null) {
      final updatedTable = table.copyWith(
        status: TableStatus.available,
        clearSession: true,
        updatedAt: now,
      );
      await updateTable(updatedTable);
    }

    return true;
  }
}
