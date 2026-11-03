
{ pkgs, inputs, ... }:
let
  cuda = pkgs.cudaPackages;

  strataSource = inputs.strata-src;
  strataRevision = inputs.strata-src.rev;

  strataLauncher = pkgs.writeShellScriptBin "strata" ''
    set -euo pipefail

    # Persistent writable installation
    stateRoot="''${XDG_DATA_HOME:-$HOME/.local/share}/strata"
    sourceDir="$stateRoot/source-${strataRevision}"
    dataDir="''${STRATA_DATA_DIR:-$stateRoot/models}"

    mkdir -p "$stateRoot" "$dataDir"

    # Materialize the Nix-pinned source into a writable directory.
    # Strata needs this for its venv, build products and configuration.
    if [ ! -f "$sourceDir/setup.sh" ]; then
      echo "Installing Strata source (${strataRevision})..."

      rm -rf "$sourceDir"
      mkdir -p "$sourceDir"

      cp -a ${strataSource}/. "$sourceDir/"
      chmod -R u+rwX "$sourceDir"
    fi

    export STRATA_UV=1

    export CUDA_HOME="${cuda.cuda_nvcc}"
    export CUDA_PATH="$CUDA_HOME"
    export CUDACXX="$CUDA_HOME/bin/nvcc"
    export CUDAHOSTCXX="${pkgs.gcc}/bin/g++"
    export CMAKE_CUDA_COMPILER="$CUDACXX"

    export STRATA_CUDA_ARCH=89
    export CMAKE_CUDA_ARCHITECTURES=89

    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
      cuda.cuda_cudart
      cuda.libcublas
      cuda.cuda_nvcc
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.openssl
      pkgs.libffi
    ]}:''${LD_LIBRARY_PATH:-}"

    cd "$sourceDir"

    echo ""
    echo "Starting Qwen 3.8 Flash Next Coder"
    echo "Model: IQ1_M"
    echo "Context: 32K"
    echo "CUDA: sm_89"
    echo "Data: $dataDir"
    echo ""

    exec ./setup.sh \
      --family coder \
      --model IQ1_M \
      --context 32768 \
      --vision no \
      --data-dir "$dataDir" \
      --yes \
      "$@"
  '';

in
pkgs.mkShell {
  name = "strata";

  packages = with pkgs; [
    # Utilities
    git
    curl
    wget
    cacert
    pciutils
    procps

    # Python
    python312
    python312Packages.pip
    python312Packages.virtualenv
    python312Packages.setuptools
    python312Packages.wheel
    uv

    # C++ compilation
    gcc
    gnumake
    cmake
    ninja
    pkg-config

    # CUDA
    cudaPackages.cuda_nvcc
    cudaPackages.cuda_cudart
    cudaPackages.libcublas

    # Build dependencies
    zlib
    openssl
    libffi
    stdenv.cc.cc.lib

    # Launcher
    strataLauncher
  ];

  shellHook = ''
    export STRATA_UV=1

    export CUDA_HOME="${cuda.cuda_nvcc}"
    export CUDA_PATH="$CUDA_HOME"
    export CUDACXX="$CUDA_HOME/bin/nvcc"
    export CUDAHOSTCXX="${pkgs.gcc}/bin/g++"
    export CMAKE_CUDA_COMPILER="$CUDACXX"

    export STRATA_CUDA_ARCH=89
    export CMAKE_CUDA_ARCHITECTURES=89

    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
      cuda.cuda_cudart
      cuda.libcublas
      cuda.cuda_nvcc
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.openssl
      pkgs.libffi
    ]}:''${LD_LIBRARY_PATH:-}"

    echo ""
    echo "======================================"
    echo "       Strata development shell"
    echo "======================================"
    echo "CUDA:       sm_89"
    echo "Compiler:   $(nvcc --version | tail -n 1)"
    echo "Python:     $(python3 --version)"
    echo "Model:      Qwen 3.8 Flash Next Coder"
    echo "Quant:      IQ1_M"
    echo ""
    echo "Run 'strata' to start the inference server."
    echo "======================================"
    echo ""
  '';
}
