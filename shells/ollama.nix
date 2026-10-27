{ pkgs }:

let
  llama-overridden = pkgs.llama-cpp.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      rev = "a37cc46104eb50900d5ab4a9ba02a0abdac039db";
      hash = "sha256-xK7GHR5ywEgrgLAP8DVp+RjOV5065LT7XmpzBDOWf/0=";
    };
  });

  llama-cuda = llama-overridden.override {
    cudaSupport = true;
  };

  ollama-serve = pkgs.writeShellScriptBin "ollama-serve" ''
    MODEL="''${MODEL:-qwen}"

    case "$MODEL" in
      qwen-3.5)
        HF_MODEL="unsloth/Qwen3.5-35B-A3B-GGUF:UD-Q4_K_XL"  #Size 26.4 GB
        ;;
      qwen-3.8)
        HF_MODEL="unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL" #Size 17.6 GB
        ;;
      flint)
        HF_MODEL="unsloth/flint-GGUF:UD-Q4_K_XL" #Size 25.1 GB
        ;;
      *)
        echo "Unknown model: $MODEL" >&2
        echo "Available models: qwen-3.5, qwen-3.8, flint" >&2
        exit 1
        ;;
    esac

    echo "Starting model: $MODEL ($HF_MODEL)"

    exec ${llama-cuda}/bin/llama-server \
      -hf "$HF_MODEL" \
      --verbose \
      --port 8080 \
      --host 127.0.0.1 \
      --ctx-size 131072 \
      --parallel 1 \
      --batch-size 1024 \
      --ubatch-size 1024 \
      --reasoning-format none \
      --cache-type-k q4_0 \
      --cache-type-v q4_0 \
      --temp 0.6 \
      --top-p 0.95 \
      --top-k 20 \
      --min-p 0.00 \
      --flash-attn on \
      --threads 16 \
      --no-mmproj \
      --n-cpu-moe 23 \
      --no-host
  '';
in

pkgs.mkShell {
  buildInputs = [
    llama-overridden
    ollama-serve
  ];

  shellHook = ''
    echo "CUDA llama-server: ${llama-cuda}/bin/llama-server"
    ${llama-cuda}/bin/llama-server --list-devices
    echo "Select model with: MODEL=qwen3.5, MODEL=qwen3.8  or MODEL=flint"
  '';
}