{ pkgs }:

let
  llama-overridden = pkgs.llama-cpp.override {
    cudaSupport = true;
  };

  ollama-serve = pkgs.writeShellScriptBin "ollama-serve" ''
    exec ${llama-overridden}/bin/llama-server \
      -hf unsloth/Qwen3.5-35B-A3B-GGUF:UD-Q4_K_XL \
      --port 8080 \
      --host 127.0.0.1 \
      --ctx-size 131072 \
      --parallel 1 \
      --batch-size 1024 \
      --ubatch-size 1024 \
      --reasoning-format none \
      --cache-type-k q8_0 \
      --cache-type-v q8_0 \
      --temp 0.6 \
      --top-p 0.95 \
      --top-k 20 \
      --min-p 0.00 \
      --flash-attn on \
      --threads 16 \
      --no-mmproj \
      -ngl 999 \
      --n-cpu-moe 24
  '';
in

pkgs.mkShell {
  buildInputs = [
    llama-overridden
    ollama-serve
  ];

  shellHook = ''
    echo "llama environment ready!"
  '';
}