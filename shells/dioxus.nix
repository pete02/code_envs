
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
    pkg-config
    lld
    gcc
  ];

  buildInputs = with pkgs; [
    openssl
  ];

  shellHook = ''
    echo "Dioxus environment ready!"
  '';
  
}