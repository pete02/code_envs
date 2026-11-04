{ pkgs, shells, ... }:

pkgs.mkShell {
  inputsFrom = [
    shells.svelte
    shells.strata
  ];
}
