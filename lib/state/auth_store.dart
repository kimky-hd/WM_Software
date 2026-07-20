import 'package:flutter/foundation.dart';

import '../data/app_storage.dart';
import '../data/mock_data.dart';
import '../models/user.dart';

class AuthStore extends ChangeNotifier {
  AuthStore(this._storage);

  final AppStorage _storage;
  AppUser? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  List<AppUser> _allUsers = [];

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;
  List<AppUser> get allUsers => _allUsers;

  Future<void> restoreSession() async {
    // 1. Tải danh sách user từ storage
    final loadedUsers = await _storage.loadList(StorageKeys.users);
    if (loadedUsers.isEmpty) {
      // Nếu lần đầu chưa có dữ liệu, dùng MockData
      _allUsers = MockData.users.toList();
      await _persistUsers();
    } else {
      _allUsers = loadedUsers.map(AppUser.fromJson).toList();
    }

    // 2. Khôi phục phiên đăng nhập
    final savedId = await _storage.getString(StorageKeys.currentUserId);
    if (savedId != null) {
      _currentUser = _allUsers.where((u) => u.id == savedId).firstOrNull;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    
    // Tìm trong danh sách TẤT CẢ user (bao gồm user do Admin tạo)
    final user = _allUsers
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

  // --- Chức năng dành cho Admin (Quản lý User) ---
  
  Future<void> _persistUsers() async {
    await _storage.saveList(StorageKeys.users, _allUsers.map((e) => e.toJson()).toList());
  }

  Future<void> addUser(AppUser user) async {
    _allUsers.add(user);
    await _persistUsers();
    notifyListeners();
  }

  Future<void> updateUser(AppUser updatedUser) async {
    final index = _allUsers.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _allUsers[index] = updatedUser;
      await _persistUsers();
      
      // Nếu đang sửa chính tài khoản đang đăng nhập
      if (_currentUser?.id == updatedUser.id) {
        _currentUser = updatedUser;
        if (!updatedUser.active) {
          // Bị khoá thì đăng xuất luôn
          await logout();
        }
      }
      notifyListeners();
    }
  }

  Future<void> deleteUser(String id) async {
    _allUsers.removeWhere((u) => u.id == id);
    await _persistUsers();
    notifyListeners();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
