{ pkgs, inputs, ... }:
let
  lib = pkgs.lib;

  # Pin to a toolkit the 595 driver (max CUDA 13.2) can run.
  # Check what you get: nix eval --raw nixpkgs#cudaPackages_13_2.cudaMajorMinorVersion
  cuda = pkgs.cudaPackages_13_2 or pkgs.cudaPackages;

  # One merged tree with bin/include/lib/stubs from all needed outputs
  cudaToolkit = pkgs.symlinkJoin {
    name = "cuda-toolkit-merged";
    paths = lib.unique (lib.concatMap
      (p: [
        (lib.getOutput "out" p)
        (lib.getOutput "dev" p)
        (lib.getOutput "lib" p)
        (lib.getOutput "static" p)
        (lib.getOutput "stubs" p)
      ])
      [ cuda.cuda_nvcc cuda.cuda_cudart cuda.cccl cuda.libcublas ]);
  };

  hostCxx = "${cuda.backendStdenv.cc}/bin/g++";

  runtimeLibs = lib.makeLibraryPath [
    cuda.cuda_cudart
    cuda.libcublas
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
    pkgs.openssl
    pkgs.libffi
  ];

  cudaEnv = ''
    export STRATA_UV=1

    export CUDA_HOME="${cudaToolkit}"
    export CUDA_PATH="$CUDA_HOME"
    export STRATA_NVCC="$CUDA_HOME/bin/nvcc"
    export CUDACXX="$STRATA_NVCC"
    export CUDAHOSTCXX="${hostCxx}"
    export CMAKE_CUDA_COMPILER="$STRATA_NVCC"
    export CMAKE_CUDA_HOST_COMPILER="${hostCxx}"

    export STRATA_CUDA_ARCH=89
    export CMAKE_CUDA_ARCHITECTURES=89

    # nvcc finds headers relative to its real path, so tell it explicitly
    export CPATH="$CUDA_HOME/include''${CPATH:+:$CPATH}"
    export LIBRARY_PATH="$CUDA_HOME/lib:$CUDA_HOME/lib/stubs''${LIBRARY_PATH:+:$LIBRARY_PATH}"
    export NVCC_APPEND_FLAGS="-I$CUDA_HOME/include -L$CUDA_HOME/lib -L$CUDA_HOME/lib/stubs"

    # /run/opengl-driver/lib provides the real libcuda.so (NixOS driver)
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:${runtimeLibs}:$CUDA_HOME/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';

  strataSource = inputs.strata-src;
  strataRevision = inputs.strata-src.rev;

  strataLauncher = pkgs.writeShellScriptBin "strata" ''
    set -euo pipefail

    stateRoot="''${XDG_DATA_HOME:-$HOME/.local/share}/strata"
    sourceDir="$stateRoot/source-${strataRevision}"
    dataDir="''${STRATA_DATA_DIR:-$stateRoot/models}"

    mkdir -p "$stateRoot" "$dataDir"

    if [ ! -f "$sourceDir/setup.sh" ]; then
      echo "Installing Strata source (${strataRevision})..."
      rm -rf "$sourceDir"
      mkdir -p "$sourceDir"
      cp -a ${strataSource}/. "$sourceDir/"
      chmod -R u+rwX "$sourceDir"
    fi

    ${cudaEnv}

    cd "$sourceDir"

    echo ""
    echo "Starting Qwen 3.8 Flash Next Coder (IQ1_M, 32K ctx, sm_89)"
    echo "Data: $dataDir"
    echo ""

  exec ./setup.sh \
    --family qwen \
    --model IQ3_S \
    --kv int8 \
    --resident-budget-gib 18 \
    --vision no \
    --gguf-dir "$HOME/models/Qwen3.8-Flash-Next-IQ3_S/IQ3_S" \
    --data-dir "$dataDir" \
    --yes \
    "$@"
  '';
in
pkgs.mkShell {
  name = "strata";

  packages = with pkgs; [
    git curl wget cacert pciutils procps
    python312 python312Packages.pip python312Packages.virtualenv
    python312Packages.setuptools python312Packages.wheel uv
    gnumake cmake ninja pkg-config
    cuda.backendStdenv.cc
    cudaToolkit
    zlib openssl libffi stdenv.cc.cc.lib
    strataLauncher
  ];

  shellHook = ''
    ${cudaEnv}

    echo ""
    echo "Strata dev shell | CUDA toolkit $(nvcc --version | tail -n 1) | sm_89"
    echo "Run 'strata' to start the inference server."
    echo ""
  '';
}