{ pkgs, shells }:

pkgs.mkShell {
  inputsFrom = [
    shells.dioxus
    shells.go
    shells.ollama
    shells.rust
  ];
}
