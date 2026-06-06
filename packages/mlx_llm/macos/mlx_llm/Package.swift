// swift-tools-version: 5.9
// mlx_llm Flutter plugin — macOS 14+ / Apple Silicon required.
//
// mlx-swift-lm はApple MLXフレームワーク上でLLM推論を行うSwiftライブラリです。
// qwen3_next アーキテクチャ（Qwen3-Coder-Nextが使用）をサポートしています。
import PackageDescription

let package = Package(
    name: "mlx_llm",
    platforms: [.macOS("14.0")],
    products: [
        .library(name: "mlx_llm", targets: ["mlx_llm"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/ml-explore/mlx-swift-lm",
            .upToNextMajor(from: "3.31.3")
        ),
    ],
    targets: [
        .target(
            name: "mlx_llm",
            dependencies: [
                // FlutterMacOS はFlutterのビルドシステムが自動的に提供します。
                // .packageエントリは不要です。
                .product(name: "FlutterMacOS", package: "FlutterMacOS"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
            ],
            path: "Sources/mlx_llm"
        ),
    ]
)
