import 'package:flutter/foundation.dart';

import '../data/app_storage.dart';
import '../data/mock_data.dart';
import '../models/enums.dart';
import '../models/user.dart';

/// Quản lý phiên đăng nhập hiện tại (mock - chọn role, lưu lại giữa các lần mở app).
class AuthStore extends ChangeNotifier {
  AuthStore(this._storage);

  final AppStorage _storage;
  AppUser? _currentUser;
  bool _isLoading = true;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  Future<void> restoreSession() async {
    final savedId = await _storage.getString(StorageKeys.currentUserId);
    if (savedId != null) {
      _currentUser = MockData.users.where((u) => u.id == savedId).firstOrNull;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loginAs(UserRole role) async {
    final user = MockData.users.firstWhere((u) => u.role == role);
    _currentUser = user;
    await _storage.setString(StorageKeys.currentUserId, user.id);
    notifyListeners();
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
