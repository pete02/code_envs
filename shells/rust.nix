
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  strictDeps = true;

  nativeBuildInputs = with pkgs; [
    rustc
    cargo
    rust-analyzer
    rustfmt
    clippy
    gcc
    lld
    pkg-config
  ];

  buildInputs = with pkgs; [
    openssl
  ];

  RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
}
