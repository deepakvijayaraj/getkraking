import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_settings.dart';
import '../models/step_item.dart';

class StorageService {
  static const _stepsKey = 'steps_v1';
  static const _settingsKey = 'ai_settings_v1';
  static const _apiKeyKey = 'ai_api_key_v1';

  final _secure = const FlutterSecureStorage();

  Future<List<StepItem>> loadSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stepsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => StepItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSteps(List<StepItem> steps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _stepsKey,
      jsonEncode(steps.map((s) => s.toJson()).toList()),
    );
  }

  Future<AiSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    final key = await _secure.read(key: _apiKeyKey) ?? '';
    if (raw == null) return AiSettings.defaults().copyWith(apiKey: key);
    try {
      return AiSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>, key);
    } catch (_) {
      return AiSettings.defaults().copyWith(apiKey: key);
    }
  }

  Future<void> saveSettings(AiSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(s.toJson()));
    await _secure.write(key: _apiKeyKey, value: s.apiKey);
  }
}
