import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.password,
    required this.phone,
    required this.fullName,
    required this.openingAssets,
    required this.currentAssets,
    required this.avatarUrl,
  });

  final String id;
  final String email;
  final String password;
  final String phone;
  final String fullName;
  final double openingAssets;
  final double currentAssets;
  final String avatarUrl;

  AuthUser copyWith({
    String? id,
    String? email,
    String? password,
    String? phone,
    String? fullName,
    double? openingAssets,
    double? currentAssets,
    String? avatarUrl,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      openingAssets: openingAssets ?? this.openingAssets,
      currentAssets: currentAssets ?? this.currentAssets,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  AuthUser? _currentUser;

  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');

  bool get isAuthenticated => _isAuthenticated;
  AuthUser? get currentUser => _currentUser;

  Future<void> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw Exception('Vui lòng nhập đầy đủ email và mật khẩu');
    }

    final query = await _usersRef
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Email chưa được đăng ký');
    }

    final doc = query.docs.first;
    final data = doc.data();
    final storedPassword = (data['password'] as String?) ?? '';

    if (storedPassword != password) {
      throw Exception('Mật khẩu không đúng');
    }

    _currentUser = AuthUser(
      id: doc.id,
      email: (data['email'] as String?) ?? normalizedEmail,
      password: storedPassword,
      phone: (data['phone'] as String?) ?? '',
      fullName: (data['fullName'] as String?) ?? '',
      openingAssets: (data['openingAssets'] as num?)?.toDouble() ?? 0,
      currentAssets: (data['currentAssets'] as num?)?.toDouble() ?? 0,
      avatarUrl: (data['avatarUrl'] as String?) ?? '',
    );

    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String phone,
    required String fullName,
    required double currentAssets,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = phone.trim();
    final normalizedName = fullName.trim();

    if (normalizedEmail.isEmpty ||
        password.isEmpty ||
        normalizedPhone.isEmpty ||
        normalizedName.isEmpty) {
      throw Exception('Vui lòng nhập đầy đủ thông tin');
    }

    final existing = await _usersRef
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Email đã tồn tại');
    }

    final ref = await _usersRef.add({
      'email': normalizedEmail,
      'password': password,
      'phone': normalizedPhone,
      'fullName': normalizedName,
      'openingAssets': currentAssets,
      'currentAssets': currentAssets,
      'avatarUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _currentUser = AuthUser(
      id: ref.id,
      email: normalizedEmail,
      password: password,
      phone: normalizedPhone,
      fullName: normalizedName,
      openingAssets: currentAssets,
      currentAssets: currentAssets,
      avatarUrl: '',
    );

    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> syncCurrentAssetsFromTransactions(double transactionNet) async {
    final user = _currentUser;
    if (user == null) return;

    final computedCurrentAssets = user.openingAssets + transactionNet;
    final diff = (computedCurrentAssets - user.currentAssets).abs();
    if (diff < 0.001) return;

    await _usersRef.doc(user.id).set({
      'currentAssets': computedCurrentAssets,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _currentUser = user.copyWith(currentAssets: computedCurrentAssets);
    notifyListeners();
  }

  Future<void> updateCurrentAssetsManually({
    required double currentAssets,
    required double transactionNet,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw Exception('Bạn chưa đăng nhập');
    }

    final openingAssets = currentAssets - transactionNet;

    await _usersRef.doc(user.id).set({
      'openingAssets': openingAssets,
      'currentAssets': currentAssets,
      'avatarUrl': user.avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _currentUser = user.copyWith(
      openingAssets: openingAssets,
      currentAssets: currentAssets,
    );
    notifyListeners();
  }

  Future<void> updateProfile({
    required String email,
    required String fullName,
    required String phone,
    required String password,
    required double currentAssets,
    required double transactionNet,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw Exception('Bạn chưa đăng nhập');
    }

    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = fullName.trim();
    final normalizedPhone = phone.trim();

    if (normalizedEmail.isEmpty ||
        normalizedName.isEmpty ||
        normalizedPhone.isEmpty ||
        password.isEmpty) {
      throw Exception('Vui lòng nhập đầy đủ thông tin');
    }

    if (normalizedEmail != user.email) {
      final existing = await _usersRef
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty && existing.docs.first.id != user.id) {
        throw Exception('Email đã được sử dụng bởi tài khoản khác');
      }
    }

    final openingAssets = currentAssets - transactionNet;

    await _usersRef.doc(user.id).set({
      'email': normalizedEmail,
      'fullName': normalizedName,
      'phone': normalizedPhone,
      'password': password,
      'openingAssets': openingAssets,
      'currentAssets': currentAssets,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _currentUser = user.copyWith(
      email: normalizedEmail,
      fullName: normalizedName,
      phone: normalizedPhone,
      password: password,
      openingAssets: openingAssets,
      currentAssets: currentAssets,
      avatarUrl: user.avatarUrl,
    );
    notifyListeners();
  }

  Future<void> updateAvatarUrl(String avatarUrl) async {
    final user = _currentUser;
    if (user == null) {
      throw Exception('Bạn chưa đăng nhập');
    }

    await _usersRef.doc(user.id).set({
      'avatarUrl': avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _currentUser = user.copyWith(avatarUrl: avatarUrl);
    notifyListeners();
  }
}
