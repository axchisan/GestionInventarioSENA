import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../presentation/providers/auth_provider.dart';

class UserSettingsService extends ChangeNotifier {
  static final UserSettingsService _instance = UserSettingsService._internal();
  static UserSettingsService get instance => _instance;
  UserSettingsService._internal();

  late ApiService _apiService;
  Map<String, dynamic>? _settings;
  bool _isLoading = false;

  // Settings properties
  String get language => _settings?['language'] ?? 'es';
  String get theme => _settings?['theme'] ?? 'light';
  String get timezone => _settings?['timezone'] ?? 'America/Bogota';
  bool get notificationsEnabled => _settings?['notifications_enabled'] ?? true;
  bool get emailNotifications => _settings?['email_notifications'] ?? true;
  bool get pushNotifications => _settings?['push_notifications'] ?? true;
  bool get autoSave => _settings?['auto_save'] ?? true;
  bool get isDarkMode => theme == 'dark';
  bool get isLoading => _isLoading;

  void initialize(AuthProvider authProvider) {
    _apiService = ApiService(authProvider: authProvider);
  }

  Future<void> loadSettings() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      // Try to load from API first
      final response = await _apiService.get('$settingsEndpoint/');
      _settings = response as Map<String, dynamic>?;
      
      // Cache settings locally
      await _cacheSettings(_settings!);
    } catch (e) {
      // Fallback to cached settings
      await _loadCachedSettings();
      debugPrint('Failed to load settings from API, using cached: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings(Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Update API
      final response = await _apiService.put('$settingsEndpoint/', updates);
      _settings = response;
      
      // Cache updated settings
      await _cacheSettings(_settings!);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update settings: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLanguage(String language) async {
    await updateSettings({'language': language});
  }

  Future<void> updateTheme(String theme) async {
    await updateSettings({'theme': theme});
  }

  Future<void> toggleDarkMode() async {
    final newTheme = isDarkMode ? 'light' : 'dark';
    await updateTheme(newTheme);
  }

  Future<void> updateNotificationSettings({
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
  }) async {
    final updates = <String, dynamic>{};
    if (notificationsEnabled != null) updates['notifications_enabled'] = notificationsEnabled;
    if (emailNotifications != null) updates['email_notifications'] = emailNotifications;
    if (pushNotifications != null) updates['push_notifications'] = pushNotifications;
    
    if (updates.isNotEmpty) {
      await updateSettings(updates);
    }
  }

  Future<void> _cacheSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_settings', jsonEncode(settings));
    } catch (e) {
      debugPrint('Failed to cache settings: $e');
    }
  }

  Future<void> _loadCachedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedSettings = prefs.getString('user_settings');
      if (cachedSettings != null) {
        _settings = jsonDecode(cachedSettings);
      }
    } catch (e) {
      debugPrint('Failed to load cached settings: $e');
      _settings = _getDefaultSettings();
    }
  }

  Map<String, dynamic> _getDefaultSettings() {
    return {
      'language': 'es',
      'theme': 'light',
      'timezone': 'America/Bogota',
      'notifications_enabled': true,
      'email_notifications': true,
      'push_notifications': true,
      'auto_save': true,
    };
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_settings');
      _settings = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear settings cache: $e');
    }
  }
}
