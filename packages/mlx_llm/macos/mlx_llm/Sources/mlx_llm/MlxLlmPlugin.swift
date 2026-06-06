import FlutterMacOS
import Foundation

/// Flutter plugin entry point.
///
/// MethodChannel `dev.normidar.assisbant/mlx_llm`:
///   - loadModel(path: String)
///   - setGenerateRequest(prompt: String, maxTokens: Int, temperature: Double, topP: Double)
///   - cancelGeneration()
///   - disposeModel()
///
/// EventChannel `dev.normidar.assisbant/mlx_llm/tokens`:
///   - Streams decoded text tokens during generation.
///   - Sends FlutterEndOfEventStream when generation finishes.
public final class MlxLlmPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private let inference = LlmInference()
    private var eventSink: FlutterEventSink?
    private var pendingRequest: LlmRequest?

    // MARK: - Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "dev.normidar.assisbant/mlx_llm",
            binaryMessenger: registrar.messenger
        )
        let eventChannel = FlutterEventChannel(
            name: "dev.normidar.assisbant/mlx_llm/tokens",
            binaryMessenger: registrar.messenger
        )
        let instance = MlxLlmPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    // MARK: - FlutterPlugin

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "loadModel":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "loadModel: 'path' is required", details: nil))
                return
            }
            Task { @MainActor in
                do {
                    try await self.inference.load(directory: URL(fileURLWithPath: path))
                    result(nil)
                } catch {
                    result(FlutterError(code: "LOAD_ERROR", message: error.localizedDescription, details: nil))
                }
            }

        case "setGenerateRequest":
            guard let args = call.arguments as? [String: Any],
                  let prompt = args["prompt"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "setGenerateRequest: 'prompt' is required", details: nil))
                return
            }
            let req = LlmRequest(
                prompt: prompt,
                maxTokens: args["maxTokens"] as? Int ?? 2048,
                temperature: (args["temperature"] as? NSNumber)?.floatValue ?? 0.6,
                topP: (args["topP"] as? NSNumber)?.floatValue ?? 0.9
            )
            Task { @MainActor in
                self.pendingRequest = req
                // If onListen was already called before setGenerateRequest,
                // start generation immediately using the stored sink.
                if let sink = self.eventSink {
                    self.pendingRequest = nil
                    self.beginGeneration(request: req, sink: sink)
                }
                result(nil)
            }

        case "cancelGeneration":
            inference.cancel()
            result(nil)

        case "disposeModel":
            Task { @MainActor in
                self.inference.dispose()
                result(nil)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FlutterStreamHandler

    /// Called by Flutter when the Dart side subscribes to the EventChannel stream.
    /// If a pending generate request is already set, generation starts immediately.
    public func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        Task { @MainActor in
            self.eventSink = events
            if let req = self.pendingRequest {
                self.pendingRequest = nil
                self.beginGeneration(request: req, sink: events)
            }
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        Task { @MainActor in
            self.eventSink = nil
            self.inference.cancel()
        }
        return nil
    }

    // MARK: - Private

    @MainActor
    private func beginGeneration(request: LlmRequest, sink: @escaping FlutterEventSink) {
        Task {
            do {
                try await inference.generate(
                    prompt: request.prompt,
                    maxTokens: request.maxTokens,
                    temperature: request.temperature,
                    topP: request.topP
                ) { token in
                    // sink は必ずメインスレッドから呼び出す
                    DispatchQueue.main.async { sink(token) }
                }
                DispatchQueue.main.async { sink(FlutterEndOfEventStream) }
            } catch {
                DispatchQueue.main.async {
                    sink(FlutterError(
                        code: "GENERATE_ERROR",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
            await MainActor.run { self.eventSink = nil }
        }
    }
}

// MARK: - Supporting types

struct LlmRequest {
    let prompt: String
    let maxTokens: Int
    let temperature: Float
    let topP: Float
}
