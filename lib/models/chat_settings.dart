/// Chat settings for controlling AI model response quality and behavior.
/// These settings are persisted across app sessions and sent to the backend
/// when making chat API calls.
class ChatSettings {
  /// The AI model to use for generating responses
  final String model;

  /// The model provider ('groq' or 'local')
  final String modelProvider;

  /// Sampling temperature (0.0 - 2.0). Lower values make responses more focused and deterministic
  final double temperature;

  /// Nucleus sampling probability (0.1 - 1.0). Controls diversity of token selection
  final double topP;

  /// Maximum number of tokens the model can generate (1 - 8192)
  final int maxTokens;

  /// Whether to use debug mode (mock responses) instead of calling the actual model
  final bool debug;

  const ChatSettings({
    this.model = 'qwen/qwen3-32b',
    this.modelProvider = 'groq',
    this.temperature = 0.7,
    this.topP = 1.0,
    this.maxTokens = 1024,
    this.debug = false,
  });

  // Available model options based on backend API
  static const List<String> availableModels = [
    'qwen/qwen3-32b',
    'deepseek-r1-distill-llama-70b',
    'gemma2-9b-it',
    'compound-beta',
    'llama-3.1-8b-instant',
    'llama-3.3-70b-versatile',
    'meta-llama/llama-4-maverick-17b-128e-instruct',
    'meta-llama/llama-4-scout-17b-16e-instruct',
    'meta-llama/llama-guard-4-12b',
    'openai/gpt-oss-120b',
  ];

  static const List<String> availableProviders = ['groq', 'local'];

  ChatSettings copyWith({
    String? model,
    String? modelProvider,
    double? temperature,
    double? topP,
    int? maxTokens,
    bool? debug,
  }) {
    return ChatSettings(
      model: model ?? this.model,
      modelProvider: modelProvider ?? this.modelProvider,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      maxTokens: maxTokens ?? this.maxTokens,
      debug: debug ?? this.debug,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'model_provider': modelProvider,
      'temperature': temperature,
      'top_p': topP,
      'max_tokens': maxTokens,
      'debug': debug,
    };
  }

  factory ChatSettings.fromJson(Map<String, dynamic> json) {
    return ChatSettings(
      model: json['model'] ?? 'qwen/qwen3-32b',
      modelProvider: json['model_provider'] ?? 'groq',
      temperature: (json['temperature'] ?? 0.7).toDouble(),
      topP: (json['top_p'] ?? 1.0).toDouble(),
      maxTokens: json['max_tokens'] ?? 1024,
      debug: json['debug'] ?? false,
    );
  }

  // Convert to query parameters for API call
  Map<String, String> toQueryParameters() {
    return {
      'model': model,
      'model_provider': modelProvider,
      'temperature': temperature.toString(),
      'top_p': topP.toString(),
      'max_tokens': maxTokens.toString(),
      'debug': debug.toString(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSettings &&
          runtimeType == other.runtimeType &&
          model == other.model &&
          modelProvider == other.modelProvider &&
          temperature == other.temperature &&
          topP == other.topP &&
          maxTokens == other.maxTokens &&
          debug == other.debug;

  @override
  int get hashCode =>
      model.hashCode ^
      modelProvider.hashCode ^
      temperature.hashCode ^
      topP.hashCode ^
      maxTokens.hashCode ^
      debug.hashCode;

  @override
  String toString() {
    return 'ChatSettings(model: $model, provider: $modelProvider, temp: $temperature, topP: $topP, maxTokens: $maxTokens, debug: $debug)';
  }
}
