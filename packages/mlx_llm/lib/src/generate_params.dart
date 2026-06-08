/// Parameters passed to the MLX generation engine.
class GenerateParams {
  const GenerateParams({
    this.maxTokens = 2048,
    this.temperature = 0.6,
    this.topP = 0.9,
  });

  final int maxTokens;
  final double temperature;
  final double topP;

  Map<String, dynamic> toMap() => {
    'maxTokens': maxTokens,
    'temperature': temperature,
    'topP': topP,
  };
}
