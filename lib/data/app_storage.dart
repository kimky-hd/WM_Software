import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lớp bọc SharedPreferences để lưu/đọc danh sách JSON (lưu trữ tạm thời theo README).
class AppStorage {
  static const _seededKey = 'wm_seeded_v1';

  Future<bool> isSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seededKey) ?? false;
  }

  Future<void> markSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seededKey, true);
  }

  Future<void> saveList(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>> loadList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

/// Khoá lưu trữ dùng chung.
class StorageKeys {
  static const currentUserId = 'wm_current_user_id';
  static const products = 'wm_products';
  static const units = 'wm_units';
  static const suppliers = 'wm_suppliers';
  static const batches = 'wm_batches';
  static const inboundNotes = 'wm_inbound_notes';
  static const outboundNotes = 'wm_outbound_notes';
  static const stockCheckNotes = 'wm_stock_check_notes';
  static const adjustmentNotes = 'wm_adjustment_notes';
  static const returnSupplierNotes = 'wm_return_supplier_notes';
  static const damageExpiredNotes = 'wm_damage_expired_notes';
}
