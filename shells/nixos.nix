{ pkgs , ... }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    nixd
    statix
    deadnix
  ];
}