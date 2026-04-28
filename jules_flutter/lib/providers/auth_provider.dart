import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  static const String authBoxName = 'auth_box';
  static const String _legacyApiKeyKey = 'api_key';
  static const String _accountsKey = 'accounts';
  static const String _activeAccountIdKey = 'active_account_id';

  List<JulesAccount> _accounts = [];
  String? _activeAccountId;

  List<JulesAccount> get accounts => List.unmodifiable(_accounts);
  JulesAccount? get activeAccount {
    final accountId = _activeAccountId;
    if (accountId == null) return null;
    for (final account in _accounts) {
      if (account.id == accountId) return account;
    }
    return null;
  }

  String? get activeAccountId => activeAccount?.id;
  String? get apiKey => activeAccount?.apiKey;
  bool get isAuthenticated => activeAccount != null;

  Future<void> init() async {
    final box = await Hive.openBox(authBoxName);
    await _migrateLegacyApiKey(box);
    _accounts = _readAccounts(box);
    _activeAccountId = box.get(_activeAccountIdKey) as String?;
    if (activeAccount == null && _accounts.isNotEmpty) {
      _activeAccountId = _accounts.first.id;
      await box.put(_activeAccountIdKey, _activeAccountId);
    }
    notifyListeners();
  }

  Future<void> login(String apiKey, {String? name}) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) return;

    final account = JulesAccount(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _normalizeName(
        name,
        fallback: 'Jules Account ${_accounts.length + 1}',
      ),
      apiKey: trimmedKey,
      createdAt: DateTime.now(),
    );
    _accounts = [..._accounts, account];
    _activeAccountId = account.id;
    await _save();
    notifyListeners();
  }

  Future<void> switchAccount(String accountId) async {
    if (_activeAccountId == accountId) return;
    if (!_accounts.any((account) => account.id == accountId)) return;
    _activeAccountId = accountId;
    final box = await Hive.openBox(authBoxName);
    await box.put(_activeAccountIdKey, accountId);
    notifyListeners();
  }

  Future<void> deleteAccount(String accountId) async {
    _accounts = _accounts.where((account) => account.id != accountId).toList();
    if (_activeAccountId == accountId) {
      _activeAccountId = _accounts.isNotEmpty ? _accounts.first.id : null;
    }
    await _save();
    notifyListeners();
  }

  Future<void> logout() async {
    _activeAccountId = null;
    final box = await Hive.openBox(authBoxName);
    await box.delete(_activeAccountIdKey);
    notifyListeners();
  }

  List<JulesAccount> _readAccounts(Box box) {
    final data = box.get(_accountsKey);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => JulesAccount.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<void> _save() async {
    final box = await Hive.openBox(authBoxName);
    await box.put(
      _accountsKey,
      _accounts.map((account) => account.toJson()).toList(),
    );
    if (_activeAccountId == null) {
      await box.delete(_activeAccountIdKey);
    } else {
      await box.put(_activeAccountIdKey, _activeAccountId);
    }
  }

  Future<void> _migrateLegacyApiKey(Box box) async {
    final legacyApiKey = box.get(_legacyApiKeyKey) as String?;
    if (legacyApiKey == null || legacyApiKey.trim().isEmpty) return;
    if (box.get(_accountsKey) is List) return;

    final account = JulesAccount(
      id: '',
      name: 'Default Account',
      apiKey: legacyApiKey,
      createdAt: DateTime.now(),
    );
    await box.put(_accountsKey, [account.toJson()]);
    await box.put(_activeAccountIdKey, account.id);
    await box.delete(_legacyApiKeyKey);
  }

  String _normalizeName(String? name, {required String fallback}) {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed;
  }
}
