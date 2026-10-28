import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../services/voice_service.dart';
import '../state/app_state.dart';

class FocusView extends StatefulWidget {
  const FocusView({super.key});

  @override
  State<FocusView> createState() => _FocusViewState();
}

class _FocusViewState extends State<FocusView> {
  final _tts = FlutterTts();
  late final VoiceService _voice;
  bool _voiceCommands = false;

  @override
  void initState() {
    super.initState();
    _voice = context.read<VoiceService>();
  }

  @override
  void dispose() {
    _voice.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleCommands() async {
    final state = context.read<AppState>();
    if (_voiceCommands) {
      await _voice.stop();
      setState(() => _voiceCommands = false);
      return;
    }
    final ok = await _voice.startCommands(state.handleVoiceCommand);
    if (!mounted) return;
    setState(() => _voiceCommands = ok);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice is not available on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final current = state.current;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: state.progress, minHeight: 8),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              children: [
                Text(
                  current == null
                      ? 'ALL DONE'
                      : 'STEP ${state.doneCount + 1} OF ${state.steps.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  current?.text ?? 'You did it. That was real progress. 🎉',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (current != null) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.read<AppState>().complete(),
                    child: const Text('OK, doing it',
                        style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.busy
                              ? null
                              : () => context.read<AppState>().makeSmaller(),
                          child: state.busy
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Make it smaller'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.read<AppState>().skip(),
                          child: const Text('Skip for now'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _tts.speak(current.text),
                          icon: const Icon(Icons.volume_up_outlined),
                          label: const Text('Read aloud'),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _toggleCommands,
                          icon: Icon(_voiceCommands ? Icons.mic : Icons.mic_none),
                          label: Text(_voiceCommands ? 'Listening…' : 'Say "ok"'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Text(state.error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 16),
        for (var i = 0; i < state.steps.length; i++)
          ListTile(
            dense: true,
            leading: Icon(
              state.steps[i].done
                  ? Icons.check_circle
                  : (i == state.currentIndex
                      ? Icons.arrow_circle_right_outlined
                      : Icons.circle_outlined),
              color: theme.colorScheme.primary,
            ),
            title: Text(
              state.steps[i].text,
              style: TextStyle(
                decoration:
                    state.steps[i].done ? TextDecoration.lineThrough : null,
                color: state.steps[i].done
                    ? theme.colorScheme.onSurfaceVariant
                    : null,
                fontWeight: i == state.currentIndex ? FontWeight.w600 : null,
              ),
            ),
          ),
      ],
    );
  }
}
