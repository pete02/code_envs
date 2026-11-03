{ pkgs, shells }:

pkgs.mkShell {
  inputsFrom = [
    shells.strata
  ];
}
