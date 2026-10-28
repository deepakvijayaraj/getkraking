# GetKraking

_Get cracking, one tiny step at a time._

A voice-first, open source mobile app (Android + iOS, built with Flutter) that turns
messy thoughts into **one tiny step at a time** for people with ADHD.

Speak or type what's on your mind -> AI splits it into 1-5 minute actions -> you see
one step and tap (or say) **"OK"** to continue. Too big? **"Make it smaller"**.

## Quick start

```bash
# 1. Install Flutter: https://docs.flutter.dev/get-started/install
cd getkraking

# 2. Generate the android/ and ios/ platform folders (keeps lib/ and pubspec.yaml)
flutter create . --platforms=android,ios --org com.example --project-name getkraking

# 3. Add permissions (see below), then:
flutter pub get
flutter test
flutter run
```

In the app, open **Settings** and add an API key (Anthropic) or point it at a local
OpenAI-compatible server such as Ollama.

> This is an initial scaffold. It has not been compiled on a device yet, so expect to
> fix small issues (package versions, platform config) on first run.

## Required platform configuration

### Android

`android/app/src/main/AndroidManifest.xml` (inside `<manifest>`, above `<application>`):

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<queries>
  <intent><action android:name="android.speech.RecognitionService"/></intent>
  <intent><action android:name="android.intent.action.TTS_SERVICE"/></intent>
</queries>
```

For a local Ollama server over plain HTTP, also add
`android:usesCleartextTraffic="true"` to `<application>` (development only).

In `android/app/build.gradle(.kts)` set `minSdk = 23`.

### iOS

`ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>GetKraking listens so you can speak your tasks instead of typing.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>GetKraking turns your speech into text to build your step list.</string>
```

In `ios/Podfile`, set `platform :ios, '13.0'`. Speech recognition works best on a real
device.

## Project layout

```
lib/
  main.dart                  app + theme + providers
  models/                    StepItem, AiSettings
  services/
    ai_service.dart          prompts + Anthropic / OpenAI-compatible clients
    voice_service.dart       dictation + voice-command modes
    storage_service.dart     local storage, key in secure storage
  state/app_state.dart       app logic (ChangeNotifier)
  screens/                   capture, focus (one step), settings
test/ai_parse_test.dart
```

## Using a local model (privacy mode)

1. Install [Ollama](https://ollama.com) and run `ollama pull llama3.1`.
2. In Settings choose **OpenAI-compatible**, base URL `http://10.0.2.2:11434/v1`
   (Android emulator) or `http://<your-computer-ip>:11434/v1` (real device), model
   `llama3.1`, leave the key empty.

## Design principles

- One step on screen, one obvious button.
- First step is nearly effortless. No decisions inside steps.
- No shame: no overdue counters, no broken streaks.
- Local-first, with data kept on the device by default.

## Roadmap / good first issues

- [ ] Per-step 5-minute timer
- [ ] Gentle, varied reminder notifications
- [ ] "Energy level" setting that changes step size
- [ ] Forgiving progress view / celebrations
- [ ] On-device speech model fallback (Whisper)
- [ ] Prompt evaluation suite with messy real-world notes
- [ ] Backend proxy example so API keys never ship in the app
- [ ] Localization and accessibility audit (screen readers, dynamic type)

## Contributing

PRs welcome, especially from people with lived ADHD experience. The prompt in
`lib/services/ai_service.dart` defines what a good tiny step is; improvements there
are some of the most valuable contributions.

## License

MIT
