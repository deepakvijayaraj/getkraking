import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/voice_service.dart';
import '../state/app_state.dart';

class CaptureView extends StatefulWidget {
  const CaptureView({super.key});

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView> {
  final _controller = TextEditingController();
  late final VoiceService _voice;
  bool _listening = false;
  String? _voiceMessage;

  @override
  void initState() {
    super.initState();
    _voice = context.read<VoiceService>();
  }

  @override
  void dispose() {
    _voice.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _voice.stop();
      setState(() => _listening = false);
      return;
    }
    final base = _controller.text.trim();
    final ok = await _voice.startDictation(onText: (text) {
      if (!mounted) return;
      setState(() {
        _controller.text = base.isEmpty ? text : '$base $text';
        _controller.selection =
            TextSelection.collapsed(offset: _controller.text.length);
        if (!_voice.isListening) _listening = false;
      });
    });
    if (!mounted) return;
    setState(() {
      _listening = ok;
      _voiceMessage = ok
          ? null
          : 'Voice is not available. Check microphone permission, or type instead.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text("What's on your mind?", style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          "Say it or type it, messy is fine. I'll turn it into one small step at a time.",
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          minLines: 5,
          maxLines: 10,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText:
                'e.g. I need to clean the kitchen, call the dentist and finish my report…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleMic,
                icon: Icon(_listening ? Icons.stop_circle : Icons.mic),
                label: Text(_listening ? 'Stop' : 'Speak'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  foregroundColor: _listening ? theme.colorScheme.error : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: state.busy
                    ? null
                    : () async {
                        await _voice.stop();
                        if (!context.mounted) return;
                        await context
                            .read<AppState>()
                            .breakDown(_controller.text);
                      },
                child: state.busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Break it down'),
              ),
            ),
          ],
        ),
        if (_voiceMessage != null || state.error != null) ...[
          const SizedBox(height: 14),
          Text(
            state.error ?? _voiceMessage!,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }
}
