{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [ rustc cargo gcc rustfmt clippy pkg-config pkgs.lld];


  buildInputs=[
    pkgs.openssl
  ];
  RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
  
}