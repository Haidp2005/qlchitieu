import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/domain/auth_provider.dart';
import '../domain/transaction_entry.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider({required AuthProvider authProvider})
      : _authProvider = authProvider {
    _listenTransactions();
  }

  final AuthProvider _authProvider;
  final CollectionReference<Map<String, dynamic>> _transactionsRef =
      FirebaseFirestore.instance.collection('transactions');

  List<TransactionEntry> _transactions = [];
  bool _isLoading = true;
  double _transactionNet = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<TransactionEntry> get transactions => _transactions;
  bool get isLoading => _isLoading;
  double get transactionNet => _transactionNet;

  void _listenTransactions() {
    _subscription = _transactionsRef
        .orderBy('transactionTime', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _transactions = snapshot.docs.map(_mapDocToEntry).toList();
        _transactionNet = _transactions.fold<double>(0, (total, entry) {
          final delta = entry.type == TransactionType.income ? entry.amount : -entry.amount;
          return total + delta;
        });

        if (_authProvider.isAuthenticated) {
          unawaited(_authProvider.syncCurrentAssetsFromTransactions(_transactionNet));
        }

        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening transactions: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  TransactionEntry _mapDocToEntry(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final rawType = (data['type'] ?? '').toString().toLowerCase();
    final isIncome = rawType == 'income' || rawType == 'in' || rawType == 'credit';
    final type = isIncome ? TransactionType.income : TransactionType.expense;

    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final title = (data['title'] as String?)?.trim().isNotEmpty == true
        ? data['title'] as String
        : ((data['description'] as String?)?.trim().isNotEmpty == true
            ? data['description'] as String
        : 'Giao dịch SePay');

    final category = (data['category'] as String?)?.trim().isNotEmpty == true
        ? data['category'] as String
        : 'Khac';

    DateTime date = DateTime.now();
    final txTime = data['transactionTime'];
    if (txTime is Timestamp) {
      date = txTime.toDate();
    }

    return TransactionEntry(
      id: doc.id,
      title: title,
      amount: amount,
      date: date,
      category: category,
      type: type,
    );
  }

  Future<void> addTransaction(TransactionEntry entry) async {
    await _transactionsRef.doc(entry.id).set({
      'title': entry.title,
      'amount': entry.amount,
      'category': entry.category,
      'type': entry.type.name,
      'source': 'manual',
      'description': entry.title,
      'transactionTime': Timestamp.fromDate(entry.date),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsRef.doc(id).delete();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
