import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wraps speech_to_text for two modes:
///  - dictation: long-form, streams partial text (capture screen)
///  - commands: short phrases like "ok", "smaller", "skip" (focus screen)
class VoiceService {
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _ready = false;
  bool _commandMode = false;
  void Function(String phrase)? _onCommand;

  bool get isListening => _stt.isListening;

  Future<bool> init() async {
    if (_ready) return true;
    _ready = await _stt.initialize(
      onStatus: _onStatus,
      onError: (_) => _restartCommandsSoon(),
    );
    return _ready;
  }

  Future<bool> startDictation({required void Function(String text) onText}) async {
    if (!await init()) return false;
    _commandMode = false;
    await _stt.listen(
      onResult: (r) => onText(r.recognizedWords),
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 6),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
    return true;
  }

  Future<bool> startCommands(void Function(String phrase) onCommand) async {
    if (!await init()) return false;
    _commandMode = true;
    _onCommand = onCommand;
    await _listenForCommand();
    return true;
  }

  Future<void> stop() async {
    _commandMode = false;
    await _stt.stop();
  }

  Future<void> _listenForCommand() async {
    await _stt.listen(
      onResult: (r) {
        if (r.finalResult && r.recognizedWords.isNotEmpty) {
          _onCommand?.call(r.recognizedWords.toLowerCase());
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      listenOptions: stt.SpeechListenOptions(
        partialResults: false,
        listenMode: stt.ListenMode.confirmation,
      ),
    );
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') _restartCommandsSoon();
  }

  void _restartCommandsSoon() {
    if (!_commandMode) return;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_commandMode && !_stt.isListening) _listenForCommand();
    });
  }
}
