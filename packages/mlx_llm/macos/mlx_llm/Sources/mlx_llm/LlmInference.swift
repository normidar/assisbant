import MLXLLM
import MLXLMCommon
import Foundation

/// Loads and runs an MLX language model.
///
/// ## Requirements
/// - Apple Silicon Mac (M-series)
/// - macOS 14.0+
/// - An MLX model directory produced by `mlx_lm.convert` or `gguf_to_mlx.py`.
///   The directory must contain: `config.json`, `tokenizer.json`, `*.safetensors`.
///
/// ## Supported architectures
/// mlx-swift-lm supports Qwen3, Qwen3-MoE, **qwen3_next** (Qwen3-Coder-Next),
/// Llama, Mistral, Gemma, DeepSeek-V3, and many more.
///
/// ## Thread safety
/// `load()` and `generate()` are async and can be called from any context.
/// `cancel()` is thread-safe. `dispose()` must not be called concurrently with
/// `generate()`.
final class LlmInference: @unchecked Sendable {

    private var container: ModelContainer?

    // cancelLock ensures _cancelled is read/written atomically from any thread.
    private let cancelLock = NSLock()
    private var _cancelled = false
    private var cancelled: Bool {
        get { cancelLock.withLock { _cancelled } }
        set { cancelLock.withLock { _cancelled = newValue } }
    }

    // MARK: - Public API

    /// Load an MLX model from a local directory URL.
    func load(directory: URL) async throws {
        cancelled = false
        let config = ModelConfiguration(directory: directory)
        container = try await LLMModelFactory.shared.loadContainer(
            configuration: config
        )
    }

    /// Generate text for [prompt], calling [onToken] with each decoded chunk.
    ///
    /// - Parameter onToken: Called synchronously for each token batch.
    ///   The caller is responsible for dispatching to the correct thread.
    func generate(
        prompt: String,
        maxTokens: Int,
        temperature: Float,
        topP: Float,
        onToken: @escaping (String) -> Void
    ) async throws {
        guard let container else {
            throw LlmError.notLoaded
        }
        cancelled = false

        let params = GenerateParameters(
            maxTokens: maxTokens,
            temperature: temperature,
            topP: topP
        )

        // container.perform runs the closure on the model's dedicated background
        // actor, keeping the main thread free during inference.
        try await container.perform { [weak self] context in
            let userInput = UserInput(prompt: .text(prompt))
            // prepare() converts the raw UserInput into tokenised LMInput.
            // Some versions of mlx-swift-lm make this async; others synchronous.
            // Use `try await` — Swift will optimise away the suspension if needed.
            let prepared = try await context.processor.prepare(input: userInput)

            // `generate` is a global function exported from the MLXLLM module.
            // It runs a synchronous token loop, calling `didGenerate` per batch.
            let _ = generate(
                input: prepared,
                parameters: params,
                context: context
            ) { [weak self] tokenIds in
                guard let self, !self.cancelled else { return .stop }
                // decode() converts token IDs back to a UTF-8 string fragment.
                let text = context.tokenizer.decode(tokens: tokenIds)
                if !text.isEmpty {
                    onToken(text)
                }
                return .more
            }
        }
    }

    /// Signal the generation loop to stop at the next token boundary.
    func cancel() {
        cancelled = true
    }

    /// Unload the model and release all MLX memory.
    func dispose() {
        cancel()
        container = nil
    }
}

// MARK: - Errors

enum LlmError: LocalizedError {
    case notLoaded

    var errorDescription: String? {
        switch self {
        case .notLoaded:
            "No model loaded. Call loadModel first."
        }
    }
}
