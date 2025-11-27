{ pkgs }:

pkgs.mkShell {
  allowUnfree = true;

  buildInputs = with pkgs; [
    python311
    uv
    pythonManylinuxPackages.manylinux2014Package
    imagemagick
    sox
  ];

  shellHook = ''
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:${pkgs.stdenv.cc.cc.lib.outPath}/lib:${pkgs.pythonManylinuxPackages.manylinux2014Package}/lib:$LD_LIBRARY_PATH"
    clear
    echo "python shell activated"
  '';
}
