import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum ThemeModeOption { light, dark, system }

class SettingsProvider extends ChangeNotifier {
  static const String settingsBoxName = 'settings';
  static const Duration _widthSaveDelay = Duration(milliseconds: 250);

  ThemeModeOption _themeMode = ThemeModeOption.dark;
  bool _isDiffPanelVisible = true;
  double _diffPanelWidth = 450.0;
  bool _isSettingsBoxReady = false;
  bool _isWidthSaveScheduled = false;

  ThemeModeOption get themeMode => _themeMode;
  bool get isDiffPanelVisible => _isDiffPanelVisible;
  double get diffPanelWidth => _diffPanelWidth;

  Future<void> init() async {
    final box = await Hive.openBox(settingsBoxName);
    _isSettingsBoxReady = true;
    final themeIndex = box.get(
      'themeMode',
      defaultValue: ThemeModeOption.dark.index,
    );
    _themeMode = ThemeModeOption.values[themeIndex];
    _isDiffPanelVisible = box.get('isDiffPanelVisible', defaultValue: true);
    _diffPanelWidth = box.get('diffPanelWidth', defaultValue: 450.0);
    notifyListeners();
  }

  void setThemeMode(ThemeModeOption mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    _persist('themeMode', mode.index);
  }

  void toggleDiffPanel() {
    setDiffPanelVisible(!_isDiffPanelVisible);
  }

  void setDiffPanelVisible(bool isVisible) {
    if (_isDiffPanelVisible == isVisible) return;
    _isDiffPanelVisible = isVisible;
    notifyListeners();
    _persist('isDiffPanelVisible', _isDiffPanelVisible);
  }

  void updateDiffPanelWidth(double delta) {
    final nextWidth = (_diffPanelWidth - delta).clamp(300.0, 800.0);
    if (nextWidth == _diffPanelWidth) return;
    _diffPanelWidth = nextWidth;
    notifyListeners();
    _persistWidthSoon();
  }

  void _persist(String key, Object value) {
    if (!_isSettingsBoxReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Hive.box(settingsBoxName).put(key, value);
    });
  }

  void _persistWidthSoon() {
    if (_isWidthSaveScheduled) return;
    _isWidthSaveScheduled = true;
    Future.delayed(_widthSaveDelay, () {
      _isWidthSaveScheduled = false;
      _persist('diffPanelWidth', _diffPanelWidth);
    });
  }
}
