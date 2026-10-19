{ pkgs }:

pkgs.mkShell {
  allowUnfree = true;

  buildInputs = with pkgs; [
    cudatoolkit
    cmake
    ninja
  ];

  shellHook = ''
    export CUDA_PATH="${pkgs.cudatoolkit}"
  '';
}
