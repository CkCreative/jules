import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthProvider extends ChangeNotifier {
  static const String authBoxName = 'auth_box';
  String? _apiKey;
  bool _isAuthenticated = false;

  String? get apiKey => _apiKey;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> init() async {
    final box = await Hive.openBox(authBoxName);
    _apiKey = box.get('api_key');
    if (_apiKey != null) {
      _isAuthenticated = true;
    }
    notifyListeners();
  }

  Future<void> login(String apiKey) async {
    _apiKey = apiKey;
    _isAuthenticated = true;
    final box = await Hive.openBox(authBoxName);
    await box.put('api_key', apiKey);
    notifyListeners();
  }

  Future<void> logout() async {
    _apiKey = null;
    _isAuthenticated = false;
    final box = await Hive.openBox(authBoxName);
    await box.delete('api_key');
    notifyListeners();
  }
}
