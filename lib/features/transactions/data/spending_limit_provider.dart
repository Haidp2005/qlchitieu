import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../auth/domain/auth_provider.dart';
import '../domain/transaction_entry.dart';

class SpendingLimit {
  const SpendingLimit({
    required this.docId,
    required this.userId,
    required this.yearMonth,
    required this.category,
    required this.limitAmount,
    required this.warningPercent,
    required this.spentAmount,
  });

  final String docId;
  final String userId;
  final String yearMonth;
  final String category;
  final double limitAmount;
  final double warningPercent;
  final double spentAmount;

  bool get isValid => limitAmount > 0;
}

class SpendingLimitProvider extends ChangeNotifier {
  SpendingLimitProvider({required AuthProvider authProvider})
      : _authProvider = authProvider {
    _authProvider.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  final AuthProvider _authProvider;
  final CollectionReference<Map<String, dynamic>> _limitsRef =
      FirebaseFirestore.instance.collection('monthly_category_limits');

  Map<String, SpendingLimit> _limitsByDocId = {};
  bool _isLoading = true;
  bool _syncingSpent = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  bool get isLoading => _isLoading;
  List<SpendingLimit> get limits => _limitsByDocId.values.toList();

  void _handleAuthChanged() {
    _subscription?.cancel();

    final user = _authProvider.currentUser;
    if (!_authProvider.isAuthenticated || user == null) {
      _limitsByDocId = {};
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _subscription = _limitsRef.where('userId', isEqualTo: user.id).snapshots().listen(
      (snapshot) {
        final map = <String, SpendingLimit>{};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final category = (data['category'] as String?) ?? '';
          final amount = (data['limitAmount'] as num?)?.toDouble() ?? 0;
          final warningPercent =
              (data['warningPercent'] as num?)?.toDouble() ?? 80;
          final spentAmount = (data['spentAmount'] as num?)?.toDouble() ?? 0;
          final yearMonth = (data['yearMonth'] as String?) ?? '';
          final userId = (data['userId'] as String?) ?? '';

          if (category.isNotEmpty && amount > 0) {
            map[doc.id] = SpendingLimit(
              docId: doc.id,
              userId: userId,
              yearMonth: yearMonth,
              category: category,
              limitAmount: amount,
              warningPercent: warningPercent,
              spentAmount: spentAmount,
            );
          }
        }

        _limitsByDocId = map;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  SpendingLimit? getLimit({
    required String category,
    required String yearMonth,
  }) {
    for (final limit in _limitsByDocId.values) {
      if (limit.category == category && limit.yearMonth == yearMonth) {
        return limit;
      }
    }
    return null;
  }

  List<SpendingLimit> getLimitsByMonth(String yearMonth) {
    return _limitsByDocId.values
        .where((limit) => limit.yearMonth == yearMonth)
        .toList()
      ..sort((a, b) => a.category.compareTo(b.category));
  }

  Future<void> upsertLimit({
    required String category,
    required double amount,
    required double warningPercent,
    required String yearMonth,
  }) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      throw Exception('Bạn chưa đăng nhập');
    }

    if (amount <= 0) {
      await removeLimit(category: category, yearMonth: yearMonth);
      return;
    }

    final clampedWarning = warningPercent.clamp(1, 100).toDouble();
    final docId = '${user.id}_${yearMonth}_$category';
    await _limitsRef.doc(docId).set({
      'userId': user.id,
      'yearMonth': yearMonth,
      'category': category,
      'limitAmount': amount,
      'warningPercent': clampedWarning,
      'spentAmount': getLimit(category: category, yearMonth: yearMonth)?.spentAmount ?? 0,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeLimit({
    required String category,
    required String yearMonth,
  }) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      throw Exception('Bạn chưa đăng nhập');
    }

    final docId = '${user.id}_${yearMonth}_$category';
    await _limitsRef.doc(docId).delete();
  }

  Future<void> syncSpentFromTransactions(
    List<TransactionEntry> transactions,
  ) async {
    if (_syncingSpent) return;
    final user = _authProvider.currentUser;
    if (user == null || _limitsByDocId.isEmpty) return;

    final spentByMonthCategory = <String, double>{};
    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;
      final ym = DateFormat('yyyy-MM').format(tx.date);
      final key = '$ym|${tx.category}';
      spentByMonthCategory[key] = (spentByMonthCategory[key] ?? 0) + tx.amount;
    }

    final batch = FirebaseFirestore.instance.batch();
    var hasChange = false;

    for (final limit in _limitsByDocId.values) {
      final key = '${limit.yearMonth}|${limit.category}';
      final spent = spentByMonthCategory[key] ?? 0;
      if ((spent - limit.spentAmount).abs() < 0.001) {
        continue;
      }

      hasChange = true;
      final ref = _limitsRef.doc(limit.docId);
      batch.set(ref, {
        'spentAmount': spent,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (!hasChange) return;

    _syncingSpent = true;
    try {
      await batch.commit();
    } finally {
      _syncingSpent = false;
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    _subscription?.cancel();
    super.dispose();
  }
}
