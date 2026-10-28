import 'package:flutter_test/flutter_test.dart';
import 'package:getkraking/services/ai_service.dart';

void main() {
  test('parses a plain JSON array', () {
    expect(parseSteps('["Stand up", "Fill the sink"]'),
        ['Stand up', 'Fill the sink']);
  });

  test('tolerates code fences and chatter', () {
    const raw =
        'Here you go:\n```json\n["Stand up", " Open the dishwasher "]\n```';
    expect(parseSteps(raw), ['Stand up', 'Open the dishwasher']);
  });

  test('throws on non-list replies', () {
    expect(() => parseSteps('Sorry, I cannot help.'),
        throwsA(isA<AiException>()));
  });
}
