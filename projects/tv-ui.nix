{ pkgs, shells }:

pkgs.mkShell {
  inputsFrom = [
    shells.dioxus
    shells.rust
  ];
}
