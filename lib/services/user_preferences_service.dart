import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Kullanıcı tercihlerini yöneten servis
class UserPreferencesService {
  static const String _keyToolPanelCollapsed = 'tool_panel_collapsed';
  static const String _keyToolPanelPinned = 'tool_panel_pinned';
  static const String _keyToolPanelPositionX = 'tool_panel_position_x';
  static const String _keyToolPanelPositionY = 'tool_panel_position_y';
  static const String _keyToolPanelWidth = 'tool_panel_width';
  static const String _keyToolPanelHeight = 'tool_panel_height';
  static const String _keyToolMenuVisible = 'tool_menu_visible';

  static UserPreferencesService? _instance;
  SharedPreferences? _prefs;

  UserPreferencesService._();

  /// Singleton instance
  static Future<UserPreferencesService> getInstance() async {
    if (_instance == null) {
      _instance = UserPreferencesService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============== LEFT PANEL PREFERENCES ==============

  /// Sol panel küçültülmüş mü?
  bool get isLeftPanelCollapsed =>
      _prefs?.getBool(_keyToolPanelCollapsed) ?? false;

  Future<void> setLeftPanelCollapsed(bool value) async {
    await _prefs?.setBool(_keyToolPanelCollapsed, value);
  }

  /// Sol panel sabitlenmiş mi?
  bool get isLeftPanelPinned => _prefs?.getBool(_keyToolPanelPinned) ?? false;

  Future<void> setLeftPanelPinned(bool value) async {
    await _prefs?.setBool(_keyToolPanelPinned, value);
  }

  /// Sol panel pozisyonu
  Offset get leftPanelPosition {
    final x = _prefs?.getDouble(_keyToolPanelPositionX) ?? 20.0;
    final y = _prefs?.getDouble(_keyToolPanelPositionY) ?? 100.0;
    return Offset(x, y);
  }

  Future<void> setLeftPanelPosition(Offset position) async {
    await _prefs?.setDouble(_keyToolPanelPositionX, position.dx);
    await _prefs?.setDouble(_keyToolPanelPositionY, position.dy);
  }

  /// Sol panel genişliği
  double get leftPanelWidth => _prefs?.getDouble(_keyToolPanelWidth) ?? 200.0;

  Future<void> setLeftPanelWidth(double value) async {
    await _prefs?.setDouble(_keyToolPanelWidth, value);
  }

  /// Sol panel yüksekliği
  double get leftPanelHeight => _prefs?.getDouble(_keyToolPanelHeight) ?? 600.0;

  Future<void> setLeftPanelHeight(double value) async {
    await _prefs?.setDouble(_keyToolPanelHeight, value);
  }

  // ============== TOOL MENU PREFERENCES ==============

  /// Araç menüsü görünür mü?
  bool get isToolMenuVisible => _prefs?.getBool(_keyToolMenuVisible) ?? false;

  Future<void> setToolMenuVisible(bool value) async {
    await _prefs?.setBool(_keyToolMenuVisible, value);
  }

  // ============== CLEAR ALL ==============

  /// Tüm tercihleri temizle
  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  /// Belirli tercihleri temizle
  Future<void> clearLeftPanelPreferences() async {
    await _prefs?.remove(_keyToolPanelCollapsed);
    await _prefs?.remove(_keyToolPanelPinned);
    await _prefs?.remove(_keyToolPanelPositionX);
    await _prefs?.remove(_keyToolPanelPositionY);
    await _prefs?.remove(_keyToolPanelWidth);
    await _prefs?.remove(_keyToolPanelHeight);
  }
}
