import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_settings.dart';

class AiException implements Exception {
  AiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The heart of the app. Tune this prompt; it defines what a "good tiny step" is.
const String stepsSystemPrompt = '''
You help people with ADHD get started on things.
Turn the user's notes into a flat, ordered list of tiny, concrete, physical steps.

Rules:
- Each step takes 1-5 minutes and is a single action.
- Start every step with a verb.
- No decisions required inside a step. Make the decision for the person.
- The FIRST step must be almost effortless (for example: "Stand up and put your phone down").
- Maximum 15 steps. Group related tasks together.
- Warm, neutral tone. Never shame, never use words like "just" or "simply".
- Return ONLY a JSON array of strings. No commentary, no markdown.
''';

const String smallerSystemPrompt = '''
Split the given step into 2-4 even tinier steps.
Each must take under 2 minutes, be one physical action, start with a verb, and need no decisions.
Return ONLY a JSON array of strings. No commentary, no markdown.
''';

/// Extracts a list of strings from a model response, tolerating code fences
/// and extra text around the JSON array.
List<String> parseSteps(String raw) {
  final start = raw.indexOf('[');
  final end = raw.lastIndexOf(']');
  if (start == -1 || end <= start) {
    throw AiException('The AI reply was not a list. Try again.');
  }
  final decoded = jsonDecode(raw.substring(start, end + 1));
  if (decoded is! List) {
    throw AiException('The AI reply was not a list. Try again.');
  }
  final steps = decoded
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (steps.isEmpty) throw AiException('No steps came back. Try again.');
  return steps;
}

class AiService {
  AiService(this.settings, {http.Client? client})
      : _client = client ?? http.Client();

  final AiSettings settings;
  final http.Client _client;

  Future<List<String>> breakDown(String notes) async =>
      parseSteps(await _complete(stepsSystemPrompt, notes));

  Future<List<String>> makeSmaller(String step) async =>
      parseSteps(await _complete(smallerSystemPrompt, step));

  Future<String> _complete(String system, String user) async {
    switch (settings.provider) {
      case AiProvider.anthropic:
        return _anthropic(system, user);
      case AiProvider.openAiCompatible:
        return _openAiCompatible(system, user);
    }
  }

  Future<String> _anthropic(String system, String user) async {
    if (settings.apiKey.isEmpty) {
      throw AiException('Add your API key in Settings first.');
    }
    final res = await _client
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'content-type': 'application/json',
            'x-api-key': settings.apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': settings.model,
            'max_tokens': 1024,
            'system': system,
            'messages': [
              {'role': 'user', 'content': user},
            ],
          }),
        )
        .timeout(const Duration(seconds: 45));
    if (res.statusCode != 200) {
      throw AiException('AI request failed (${res.statusCode}).');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final blocks = (data['content'] as List).cast<Map<String, dynamic>>();
    return blocks
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join();
  }

  Future<String> _openAiCompatible(String system, String user) async {
    final base = settings.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw AiException('Add a base URL in Settings first.');
    }
    final headers = {'content-type': 'application/json'};
    if (settings.apiKey.isNotEmpty) {
      headers['authorization'] = 'Bearer ${settings.apiKey}';
    }
    final res = await _client
        .post(
          Uri.parse('$base/chat/completions'),
          headers: headers,
          body: jsonEncode({
            'model': settings.model,
            'temperature': 0.3,
            'messages': [
              {'role': 'system', 'content': system},
              {'role': 'user', 'content': user},
            ],
          }),
        )
        .timeout(const Duration(seconds: 90));
    if (res.statusCode != 200) {
      throw AiException('AI request failed (${res.statusCode}).');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final choices = data['choices'] as List;
    return (choices.first as Map<String, dynamic>)['message']['content']
        as String;
  }
}
