import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  // Singleton pattern
  SharedPrefsService._privateConstructor();
  static final SharedPrefsService instance = SharedPrefsService._privateConstructor();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> saveDataList<T>(
      String key, List<T> items, Map<String, dynamic> Function(T) toJson) async {
    if (_prefs == null) return false;
    try {
      List<Map<String, dynamic>> mapList = items.map((e) => toJson(e)).toList();
      String jsonString = jsonEncode(mapList);
      return await _prefs!.setString(key, jsonString);
    } catch (e) {
      debugPrint("Lỗi khi lưu dữ liệu với key '$key': $e");
      return false;
    }
  }

  List<T> getDataList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    if (_prefs == null) return [];
    try {
      String? jsonString = _prefs!.getString(key);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("Lỗi khi đọc dữ liệu với key '$key': $e");
      return [];
    }
  }

  Future<bool> removeData(String key) async {
    if (_prefs == null) return false;
    return await _prefs!.remove(key);
  }

  Future<bool> clearAll() async {
    if (_prefs == null) return false;
    return await _prefs!.clear();
  }
}
