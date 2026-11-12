{ pkgs, shells, ... }:

pkgs.mkShell {
  inputsFrom = [
    shells.dioxus
    shells.go
    shells.strata
    shells.rust
  ];

  RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

}
