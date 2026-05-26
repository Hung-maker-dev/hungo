// lib/core/providers/auth_provider.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import 'package:sqflite/sqflite.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String? get error => _error;

  String _hashPassword(String pw) =>
      sha256.convert(utf8.encode(pw)).toString();

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [userId]);

    if (rows.isNotEmpty) {
      _currentUser = UserModel.fromMap(rows.first);
      notifyListeners();
    }
  }

  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final db = await DatabaseHelper.instance.database;

      final existing = await db.query('users',
          where: 'email = ? OR username = ?',
          whereArgs: [email, username]);

      if (existing.isNotEmpty) {
        _setLoading(false);
        return 'Email hoặc username đã tồn tại!';
      }

      final now = DateTime.now().toIso8601String();

      final id = await db.insert('users', {
        'username': username,
        'email': email,
        'password': _hashPassword(password), // ✅ hash tại đây
        'role': 'user',
        'created_at': now,
      });

      for (final skill in ['vocabulary', 'reading', 'listening', 'grammar']) {
        await db.insert('scores', {
          'user_id': id,
          'skill': skill,
          'total_pts': 0,
          'streak': 0,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      final rows =
      await db.query('users', where: 'id = ?', whereArgs: [id]);

      _currentUser = UserModel.fromMap(rows.first);
      await _saveSession(id);

      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return 'Lỗi đăng ký: $e';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final db = await DatabaseHelper.instance.database;

      final hashed = _hashPassword(password);

      // 🔥 LẤY USER TRƯỚC
      final rows = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (rows.isEmpty) {
        _setLoading(false);
        return 'Email hoặc mật khẩu không đúng!';
      }

      final user = UserModel.fromMap(rows.first);

      // ✅ CASE 1: user thường
      if (user.password == hashed) {
        _currentUser = user;
      }
      // ✅ CASE 2: admin seed (fallback)
      else if (user.email == 'admin@englishapp.com' &&
          password == 'admin123') {
        _currentUser = user;
      } else {
        _setLoading(false);
        return 'Email hoặc mật khẩu không đúng!';
      }

      await db.update(
        'users',
        {'last_login': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [_currentUser!.id],
      );

      await _saveSession(_currentUser!.id!);

      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return 'Lỗi đăng nhập: $e';
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    notifyListeners();
  }

  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return 'Chưa đăng nhập';

    if (_hashPassword(oldPassword) != _currentUser!.password) {
      return 'Mật khẩu cũ không đúng!';
    }

    final db = await DatabaseHelper.instance.database;

    await db.update(
      'users',
      {'password': _hashPassword(newPassword)},
      where: 'id = ?',
      whereArgs: [_currentUser!.id],
    );

    return null;
  }

  Future<void> _saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}