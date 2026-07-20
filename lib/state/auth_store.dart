import 'package:flutter/foundation.dart';

import '../data/app_storage.dart';
import '../data/mock_data.dart';
import '../models/user.dart';

/// Quản lý phiên đăng nhập hiện tại bằng email + mật khẩu (không có đăng ký,
/// tài khoản được Admin cấp sẵn - xem MockData.users).
class AuthStore extends ChangeNotifier {
  AuthStore(this._storage);

  final AppStorage _storage;
  AppUser? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  Future<void> restoreSession() async {
    final savedId = await _storage.getString(StorageKeys.currentUserId);
    if (savedId != null) {
      _currentUser = MockData.users.where((u) => u.id == savedId).firstOrNull;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = MockData.users
        .where((u) => u.email.toLowerCase() == normalizedEmail && u.password == password)
        .firstOrNull;

    if (user == null) {
      _errorMessage = 'Email hoặc mật khẩu không đúng';
      notifyListeners();
      return false;
    }
    if (!user.active) {
      _errorMessage = 'Tài khoản đã bị khoá, liên hệ Admin để được hỗ trợ';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    _currentUser = user;
    await _storage.setString(StorageKeys.currentUserId, user.id);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _storage.remove(StorageKeys.currentUserId);
    notifyListeners();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
