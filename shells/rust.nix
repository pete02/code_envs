{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [ rustc cargo gcc rustfmt clippy pkg-config pkgs.lld];
  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";


  buildInputs=[
    pkgs.openssl
  ];

  shellHook = ''
    export CARGO_HOME=$PWD/.cargo
    export RUSTUP_HOME=$PWD/.rustup
    export PATH="$PATH:/home/pete/.cargo/bin"
  '';
}