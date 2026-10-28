import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_settings.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AiProvider _provider;
  late final TextEditingController _model;
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().settings;
    _provider = s.provider;
    _model = TextEditingController(text: s.model);
    _baseUrl = TextEditingController(text: s.baseUrl);
    _apiKey = TextEditingController(text: s.apiKey);
  }

  @override
  void dispose() {
    _model.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  void _onProviderChanged(AiProvider? p) {
    if (p == null) return;
    setState(() {
      _provider = p;
      if (p == AiProvider.anthropic) {
        _model.text = 'claude-haiku-5-5';
        _baseUrl.text = '';
      } else {
        _model.text = 'llama3.1';
        // 10.0.2.2 reaches your computer from the Android emulator.
        _baseUrl.text = 'http://10.0.2.2:11434/v1';
      }
    });
  }

  Future<void> _save() async {
    final nav = Navigator.of(context);
    await context.read<AppState>().saveSettings(
          AiSettings(
            provider: _provider,
            model: _model.text.trim(),
            baseUrl: _baseUrl.text.trim(),
            apiKey: _apiKey.text.trim(),
          ),
        );
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('AI provider', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<AiProvider>(
              value: _provider,
              items: const [
                DropdownMenuItem(
                  value: AiProvider.anthropic,
                  child: Text('Anthropic (Claude)'),
                ),
                DropdownMenuItem(
                  value: AiProvider.openAiCompatible,
                  child: Text('OpenAI-compatible (Ollama, LM Studio…)'),
                ),
              ],
              onChanged: _onProviderChanged,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _model,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
            ),
            if (_provider == AiProvider.openAiCompatible) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _baseUrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _apiKey,
              obscureText: true,
              decoration: InputDecoration(
                labelText: _provider == AiProvider.anthropic
                    ? 'API key'
                    : 'API key (optional for local models)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your key is stored in the device keychain/keystore. For a public '
              'release, route requests through your own backend instead of '
              'shipping keys in the app.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
