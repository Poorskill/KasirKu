import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/transaction.dart';
import '../../../repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return HybridTransactionRepository();
});

final transactionsStreamProvider = StreamProvider<List<TransactionRecord>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchTransactions();
});

final transactionSearchQueryProvider = StateProvider<String>((ref) => '');
final transactionPaymentFilterProvider = StateProvider<String>((ref) => 'all');

enum DateFilterRange { all, today, thisWeek, thisMonth }

final transactionDateFilterProvider =
    StateProvider<DateFilterRange>((ref) => DateFilterRange.all);

final filteredTransactionsProvider = Provider<List<TransactionRecord>>((ref) {
  final trxAsync = ref.watch(transactionsStreamProvider);
  final search = ref.watch(transactionSearchQueryProvider).trim().toLowerCase();
  final payment = ref.watch(transactionPaymentFilterProvider);
  final dateRange = ref.watch(transactionDateFilterProvider);

  return trxAsync.maybeWhen(
    data: (records) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      return records.where((trx) {
        // Date filter
        switch (dateRange) {
          case DateFilterRange.today:
            if (trx.createdAt.isBefore(todayStart)) return false;
          case DateFilterRange.thisWeek:
            if (trx.createdAt.isBefore(weekStart)) return false;
          case DateFilterRange.thisMonth:
            if (trx.createdAt.isBefore(monthStart)) return false;
          case DateFilterRange.all:
            break;
        }

        // Payment filter
        if (payment != 'all' && trx.paymentMethod.name != payment) {
          return false;
        }

        // Search query
        if (search.isNotEmpty) {
          final matchesId = trx.id.toLowerCase().contains(search);
          final matchesCashier = trx.cashierName.toLowerCase().contains(search);
          final matchesItem = trx.items
              .any((i) => i.productName.toLowerCase().contains(search));
          if (!matchesId && !matchesCashier && !matchesItem) return false;
        }

        return true;
      }).toList();
    },
    orElse: () => [],
  );
});
