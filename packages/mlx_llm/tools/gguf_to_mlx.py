#!/usr/bin/env python3
"""GGUFモデルをMLXフォーマットへ変換するスクリプト。

変換後のMLXモデルディレクトリ（safetensors + config.json + tokenizer.json）は
mlx-swift-lmが直接読み込めるフォーマットです。
assisbantアプリの「MLX Model Directory」設定に変換先パスを指定してください。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Qwen3-Coder-Next-UD-Q4_K_XL.gguf を使う場合
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
UD-Q4_K_XL は Unsloth の動的量子化フォーマットで、MLXが直接読み込める
Q4_0/Q4_1/Q8_0 とは異なります。そのため以下の2ステップが必要です:

  1. GGUFを一旦FP16に逆量子化 → MLX 4-bit に再量子化（推奨）
     python gguf_to_mlx.py \\
       --gguf ~/Downloads/Qwen3-Coder-Next-UD-Q4_K_XL.gguf \\
       --output ~/mlx_models/qwen3_coder_next/ \\
       --requantize 4

  2. または、Hugging Face から直接変換（元の精度を保てるため推奨）
     python gguf_to_mlx.py \\
       --hf-path Qwen/Qwen3-Coder-Next \\
       --output ~/mlx_models/qwen3_coder_next/ \\
       --bits 4

  3. mlx-communityの既製モデルをダウンロードするだけ（最も簡単）
     huggingface-cli download mlx-community/Qwen3-Coder-Next-4bit \\
       --local-dir ~/mlx_models/qwen3_coder_next/

注意: オプション1は約40GB以上のRAMが必要です（逆量子化のため）。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
依存関係のインストール
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  pip install -r requirements.txt

実行環境: Apple Silicon Mac (M-series) + macOS 14+
"""

import argparse
import json
import platform
import sys
from pathlib import Path


def _check_deps() -> None:
    missing = []
    try:
        import mlx.core as mx  # noqa: F401
    except ImportError:
        missing.append("mlx")
    try:
        import mlx_lm  # noqa: F401
    except ImportError:
        missing.append("mlx-lm")
    if missing:
        print(f"[ERROR] 必要なパッケージが見つかりません: {', '.join(missing)}")
        print("       pip install -r requirements.txt でインストールしてください")
        sys.exit(1)


def _write_info(directory: Path, source: str) -> None:
    info = {
        "source": source,
        "converted_by": "assisbant/packages/mlx_llm/tools/gguf_to_mlx.py",
        "mlx_swift_lm_compatible": True,
    }
    (directory / "mlx_model_info.json").write_text(json.dumps(info, indent=2))


def convert_from_gguf(gguf_path: str, output_dir: str, requantize: int | None) -> None:
    """GGUFファイルをMLXフォーマットへ変換する。

    mlx_lm.convert はQ4_0/Q4_1/Q8_0を直接サポートします。
    それ以外の量子化（UD-Q4_K_XL等）は一旦FP16に逆量子化してから
    再量子化するため、大量のRAMが必要です。
    """
    from mlx_lm import convert  # type: ignore[import]

    gguf = Path(gguf_path).expanduser().resolve()
    if not gguf.exists():
        print(f"[ERROR] GGUFファイルが見つかりません: {gguf}")
        sys.exit(1)

    out = Path(output_dir).expanduser()
    out.mkdir(parents=True, exist_ok=True)

    name = gguf.name
    is_k_quant = any(x in name for x in ("_K_", "Q4_K", "Q5_K", "Q6_K", "Q4_KXL", "Q4_K_XL"))
    if is_k_quant:
        print(
            f"\n[警告] {name} は K-量子化フォーマットです。"
            "\n       MLXが直接読み込めないため、一旦FP16に逆量子化してから"
            "\n       MLX量子化を行います。これには大量のRAM（32Bモデルで約40GB以上）が必要です。"
        )
        if requantize is None:
            requantize = 4
            print("       --requantize が未指定のため、4-bit再量子化をデフォルトで使用します。")

    quant_kwargs: dict = {}
    if requantize is not None:
        quant_kwargs = {"quantize": True, "q_bits": requantize}

    print(f"\n変換中: {gguf} → {out}")
    print("モデルサイズによっては数分〜数十分かかります...")

    convert(
        model=str(gguf),
        upload_repo=None,
        mlx_path=str(out),
        **quant_kwargs,
    )

    _write_info(out, source=str(gguf))
    print(f"\n[完了] MLXモデルディレクトリ: {out}")
    print("       assisbant設定の「MLX Model Directory」にこのパスを入力してください。")


def convert_from_huggingface(hf_path: str, output_dir: str, bits: int) -> None:
    """Hugging FaceモデルをMLXフォーマットへ変換する（品質が最も良い方法）。"""
    from mlx_lm import convert  # type: ignore[import]

    out = Path(output_dir).expanduser()
    out.mkdir(parents=True, exist_ok=True)

    print(f"\n変換中: {hf_path} → {out}  ({bits}-bit量子化)")
    print("非公開モデルには事前に `huggingface-cli login` が必要です。")
    print("モデルサイズによっては数分〜数十分かかります...")

    convert(
        model=hf_path,
        upload_repo=None,
        mlx_path=str(out),
        quantize=True,
        q_bits=bits,
    )

    _write_info(out, source=f"hf:{hf_path}")
    print(f"\n[完了] MLXモデルディレクトリ: {out}")
    print("       assisbant設定の「MLX Model Directory」にこのパスを入力してください。")


def download_preconverted(output_dir: str, bits: int) -> None:
    """mlx-communityの既製Qwen3-Coder-NextモデルをHFからダウンロードする。"""
    try:
        from huggingface_hub import snapshot_download  # type: ignore[import]
    except ImportError:
        print("[ERROR] huggingface_hub が必要です: pip install huggingface_hub")
        sys.exit(1)

    repo_map = {4: "mlx-community/Qwen3-Coder-Next-4bit", 8: "mlx-community/Qwen3-Coder-Next-8bit"}
    repo = repo_map.get(bits)
    if repo is None:
        print(f"[ERROR] 既製モデルは4-bitまたは8-bitのみです（指定値: {bits}）")
        sys.exit(1)

    out = Path(output_dir).expanduser()
    out.mkdir(parents=True, exist_ok=True)

    print(f"\nダウンロード中: {repo} → {out}")
    snapshot_download(repo_id=repo, local_dir=str(out))
    _write_info(out, source=f"hf:{repo}")
    print(f"\n[完了] MLXモデルディレクトリ: {out}")
    print("       assisbant設定の「MLX Model Directory」にこのパスを入力してください。")


def main() -> None:
    if platform.system() != "Darwin":
        print("[警告] MLXはApple Silicon Mac専用です。")
        print("       このスクリプトはmacOS上で実行してください。")

    parser = argparse.ArgumentParser(
        description="モデルをMLXフォーマットへ変換",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    src = parser.add_mutually_exclusive_group(required=True)
    src.add_argument(
        "--gguf", metavar="PATH",
        help="変換元の .gguf ファイルパス",
    )
    src.add_argument(
        "--hf-path", metavar="HF_ID",
        help="変換元のHugging Faceモデル ID（例: Qwen/Qwen3-Coder-Next）",
    )
    src.add_argument(
        "--download-qwen3-coder-next", action="store_true",
        help="mlx-communityの既製Qwen3-Coder-Nextをダウンロード（最も簡単）",
    )

    parser.add_argument(
        "--output", required=True, metavar="DIR",
        help="MLXモデルの出力ディレクトリ",
    )
    parser.add_argument(
        "--bits", type=int, choices=[2, 3, 4, 6, 8], default=4, metavar="BITS",
        help="量子化ビット数（デフォルト: 4）",
    )
    parser.add_argument(
        "--requantize", type=int, choices=[2, 3, 4, 6, 8], metavar="BITS",
        help="[GGUFのみ] 逆量子化後の再量子化ビット数（未指定時は--bitsを使用）",
    )

    args = parser.parse_args()

    _check_deps()

    if args.gguf:
        rq = args.requantize if args.requantize is not None else args.bits
        convert_from_gguf(args.gguf, args.output, rq)
    elif args.hf_path:
        convert_from_huggingface(args.hf_path, args.output, args.bits)
    else:
        download_preconverted(args.output, args.bits)


if __name__ == "__main__":
    main()
