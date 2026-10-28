enum AiProvider { anthropic, openAiCompatible }

/// Settings for the AI backend.
///
/// `openAiCompatible` works with Ollama, LM Studio, OpenAI, OpenRouter and any
/// server that exposes `/chat/completions`.
class AiSettings {
  const AiSettings({
    required this.provider,
    required this.model,
    required this.baseUrl,
    required this.apiKey,
  });

  final AiProvider provider;
  final String model;
  final String baseUrl;
  final String apiKey;

  factory AiSettings.defaults() => const AiSettings(
        provider: AiProvider.anthropic,
        model: 'claude-haiku-5-5',
        baseUrl: '',
        apiKey: '',
      );

  AiSettings copyWith({
    AiProvider? provider,
    String? model,
    String? baseUrl,
    String? apiKey,
  }) =>
      AiSettings(
        provider: provider ?? this.provider,
        model: model ?? this.model,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
      );

  /// The API key is deliberately excluded: it goes to secure storage.
  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'model': model,
        'baseUrl': baseUrl,
      };

  factory AiSettings.fromJson(Map<String, dynamic> json, String apiKey) =>
      AiSettings(
        provider: AiProvider.values.firstWhere(
          (p) => p.name == json['provider'],
          orElse: () => AiProvider.anthropic,
        ),
        model: json['model'] as String? ?? 'claude-haiku-5-5',
        baseUrl: json['baseUrl'] as String? ?? '',
        apiKey: apiKey,
      );
}
