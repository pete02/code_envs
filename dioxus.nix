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

    dioxus-cli
  ];

  buildInputs = with pkgs; [
    openssl
  ];

  RUST_SRC_PATH =
    "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

  shellHook = ''
    export CARGO_HOME="$PWD/.cargo"
    export PATH="$CARGO_HOME/bin:$PATH"

    echo "Dioxus environment ready!"
  '';
}