{ pkgs, shells }:

pkgs.mkShell {
  inputsFrom = [
    shells.python
  ];
}
