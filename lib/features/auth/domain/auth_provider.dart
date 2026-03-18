import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String email, String password) async {
    // Simulate login
    await Future.delayed(const Duration(milliseconds: 500));
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    // Simulate logout
    await Future.delayed(const Duration(milliseconds: 200));
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    // Simulate register
    await Future.delayed(const Duration(milliseconds: 500));
    _isAuthenticated = true;
    notifyListeners();
  }
}
