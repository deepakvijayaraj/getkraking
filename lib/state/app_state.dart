import 'package:flutter/foundation.dart';

import '../models/ai_settings.dart';
import '../models/step_item.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  AppState(this._storage);

  final StorageService _storage;

  List<StepItem> steps = [];
  AiSettings settings = AiSettings.defaults();
  bool busy = false;
  String? error;

  int get currentIndex => steps.indexWhere((s) => !s.done);
  StepItem? get current => currentIndex == -1 ? null : steps[currentIndex];
  int get doneCount => steps.where((s) => s.done).length;
  bool get allDone => steps.isNotEmpty && currentIndex == -1;
  double get progress => steps.isEmpty ? 0 : doneCount / steps.length;

  Future<void> load() async {
    steps = await _storage.loadSteps();
    settings = await _storage.loadSettings();
    notifyListeners();
  }

  Future<void> saveSettings(AiSettings s) async {
    settings = s;
    await _storage.saveSettings(s);
    notifyListeners();
  }

  Future<void> breakDown(String notes) async {
    final text = notes.trim();
    if (text.isEmpty) {
      error = 'Say or type something first.';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await AiService(settings).breakDown(text);
      steps = result.map((t) => StepItem(text: t)).toList();
      await _storage.saveSteps(steps);
    } on AiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Something went wrong. Check your connection and settings.';
    }
    busy = false;
    notifyListeners();
  }

  Future<void> makeSmaller() async {
    final i = currentIndex;
    if (i == -1 || busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final parts = await AiService(settings).makeSmaller(steps[i].text);
      steps.replaceRange(i, i + 1, parts.map((t) => StepItem(text: t)));
      await _storage.saveSteps(steps);
    } on AiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not split that step. Try again.';
    }
    busy = false;
    notifyListeners();
  }

  void complete() {
    final i = currentIndex;
    if (i == -1) return;
    steps[i].done = true;
    _persist();
  }

  void skip() {
    final i = currentIndex;
    if (i == -1) return;
    steps.add(steps.removeAt(i));
    _persist();
  }

  void reset() {
    steps = [];
    error = null;
    _persist();
  }

  /// Handles phrases from voice command mode.
  void handleVoiceCommand(String phrase) {
    if (RegExp(r'\b(ok|okay|done|next)\b').hasMatch(phrase)) {
      complete();
    } else if (RegExp(r'\b(smaller|too big|tinier)\b').hasMatch(phrase)) {
      makeSmaller();
    } else if (RegExp(r'\bskip\b').hasMatch(phrase)) {
      skip();
    }
  }

  void _persist() {
    _storage.saveSteps(steps);
    notifyListeners();
  }
}
