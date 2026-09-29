import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/waiter_call.dart';

abstract class WaiterRepository {
  Stream<List<WaiterCall>> watchWaiterCalls();
  Future<void> sendWaiterCall(WaiterCall call);
  Future<void> updateWaiterCallStatus(String callId, WaiterCallStatus status);
}

class HybridWaiterRepository implements WaiterRepository {
  final _controller = StreamController<List<WaiterCall>>.broadcast();
  final List<WaiterCall> _calls = [];
  bool _firebaseReady = false;

  HybridWaiterRepository() {
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
  }

  @override
  Stream<List<WaiterCall>> watchWaiterCalls() async* {
    if (_firebaseReady) {
      try {
        yield* FirebaseFirestore.instance
            .collection('waiter_calls')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snap) {
          return snap.docs
              .map((d) => WaiterCall.fromJson(d.data(), id: d.id))
              .toList();
        });
        return;
      } catch (_) {}
    }
    yield List.unmodifiable(_calls);
    yield* _controller.stream;
  }

  @override
  Future<void> sendWaiterCall(WaiterCall call) async {
    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('waiter_calls')
            .doc(call.id)
            .set(call.toJson());
        return;
      } catch (_) {}
    }

    _calls.insert(0, call);
    _controller.add(List.unmodifiable(_calls));
  }

  @override
  Future<void> updateWaiterCallStatus(String callId, WaiterCallStatus status) async {
    final now = DateTime.now();
    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('waiter_calls')
            .doc(callId)
            .update({
          'status': status.name,
          if (status == WaiterCallStatus.resolved)
            'resolvedAt': now.toIso8601String(),
        });
        return;
      } catch (_) {}
    }

    final index = _calls.indexWhere((c) => c.id == callId);
    if (index != -1) {
      _calls[index] = _calls[index].copyWith(
        status: status,
        resolvedAt: status == WaiterCallStatus.resolved ? now : null,
      );
      _controller.add(List.unmodifiable(_calls));
    }
  }
}
