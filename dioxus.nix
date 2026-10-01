{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    rustup
    pkg-config
    lld
    gcc
  ];

  buildInputs = with pkgs; [
    openssl
  ];

  shellHook = ''
    export CARGO_HOME="$PWD/.cargo"
    export RUSTUP_HOME="$PWD/.rustup"
    export PATH="$CARGO_HOME/bin:$PATH"

    echo "Dioxus environment ready!"
  '';
}