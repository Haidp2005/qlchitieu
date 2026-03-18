import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/transaction_entry.dart';

class TransactionProvider extends ChangeNotifier {
  static const String _storageKey = 'user_transactions';
  
  List<TransactionEntry> _transactions = [];
  bool _isLoading = true;

  List<TransactionEntry> get transactions => _transactions;
  bool get isLoading => _isLoading;

  TransactionProvider() {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _transactions = jsonList.map((json) => TransactionEntry.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Error loading transactions: $e');
        _transactions = [];
      }
    } else {
      _transactions = []; // Empty
    }

    // Sort by date descending
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(TransactionEntry entry) async {
    _transactions.add(entry);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await _saveTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((entry) => entry.id == id);
    notifyListeners();
    await _saveTransactions();
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_transactions.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }
}
