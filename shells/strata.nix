
{ pkgs,... }:
strata = pkgs.mkShell {
  name = "strata";

  packages = with pkgs; [
    git
    curl
    wget
    cacert

    # Python environment
    python312
    python312Packages.pip
    python312Packages.virtualenv
    python312Packages.setuptools
    python312Packages.wheel

    # C++ / CUDA compilation
    gcc
    gnumake
    cmake
    ninja
    pkg-config
    cudaPackages.cuda_nvcc
    cudaPackages.cuda_cudart
    cudaPackages.libcublas

    # Build dependencies
    zlib
    openssl
    libffi
    stdenv.cc.cc.lib

    # Utilities
    pciutils
    procps
  ];

  shellHook = ''
    export CUDA_HOME="${pkgs.cudaPackages.cuda_nvcc}"
    export CUDA_PATH="$CUDA_HOME"
    export CUDACXX="$CUDA_HOME/bin/nvcc"

    export CUDAHOSTCXX="${pkgs.gcc}/bin/g++"
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
      pkgs.cudaPackages.cuda_cudart
      pkgs.cudaPackages.libcublas
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.openssl
      pkgs.libffi
    ]}:''${LD_LIBRARY_PATH:-}"

    export STRATA_CUDA_ARCH=89

    echo "Strata development environment"
    echo "CUDA architecture: Ada Lovelace (sm_89)"
    echo "CUDA compiler: $(nvcc --version | tail -n 1)"
    echo "Run ./setup.sh to initialize Strata."
  '';
};
