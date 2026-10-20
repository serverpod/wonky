import '../common/models.dart';
import 'llm/ai_client.dart';

export 'llm/ai_client.dart' show AiEffort;

/// Default model ids per provider (suite 10 §1). The only place model ids
/// are written down; `config/<runMode>.yaml` (`wonky: ai: models:`) can
/// override them, everything else asks [AiTier] and `AiConfig.modelFor`.
abstract final class AiModels {
  /// Anthropic: Best and Balanced.
  static const opus = 'claude-opus-5-5';

  /// Anthropic: Fast and inline completions.
  static const haiku = 'claude-haiku-5-5';

  static const gpt = 'gpt-5';
  static const gptMini = 'gpt-5-mini';
  static const geminiPro = 'gemini-3.1-pro-preview';
  static const geminiFlash = 'gemini-3.8-flash';

  /// The default `(model, fastModel)` of [provider].
  static (String, String) defaults(AiProvider provider) => switch (provider) {
    AiProvider.anthropic => (opus, haiku),
    AiProvider.openai => (gpt, gptMini),
    AiProvider.gemini => (geminiPro, geminiFlash),
  };
}

/// Which of the provider's two configured models a feature uses.
enum AiModelSize {
  /// `model`: Best and Balanced.
  large,

  /// `fastModel`: Fast and inline completions.
  small,
}

/// A model size plus effort level.
class AiTier {
  const AiTier(this.size, this.effort);

  final AiModelSize size;
  final String effort;

  /// The assistant panel (suite 10 §1 table).
  static AiTier chat(AiQuality q) => switch (q) {
    AiQuality.best => const AiTier(AiModelSize.large, AiEffort.high),
    AiQuality.balanced => const AiTier(AiModelSize.large, AiEffort.medium),
    AiQuality.fast => const AiTier(AiModelSize.small, AiEffort.low),
  };

  /// Inline rewrite / translate / tone (Write 09 §5.1): the user's setting
  /// with effort capped at `medium`.
  static AiTier rewrite(AiQuality q) => switch (q) {
    AiQuality.best || AiQuality.balanced => const AiTier(
      AiModelSize.large,
      AiEffort.medium,
    ),
    AiQuality.fast => const AiTier(AiModelSize.small, AiEffort.low),
  };

  /// Continue writing: the fast model when Fast, else the large one at
  /// `low`.
  static AiTier continueWriting(AiQuality q) => switch (q) {
    AiQuality.fast => const AiTier(AiModelSize.small, AiEffort.low),
    _ => const AiTier(AiModelSize.large, AiEffort.low),
  };

  /// Summarize, outline, explain and proofread: the user's setting.
  static AiTier document(AiQuality q) => chat(q);

  @override
  bool operator ==(Object other) =>
      other is AiTier && other.size == size && other.effort == effort;

  @override
  int get hashCode => Object.hash(size, effort);

  @override
  String toString() => '${size.name}/$effort';
}
