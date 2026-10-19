
{
  description = "Collection of development shells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, rust-overlay, ... }:
    let
      systems = [ "x86_64-linux" ];

      forAllSystems = f: builtins.listToAttrs (
        map (system: {
          name = system;
          value = f system;
        }) systems
      );
    in {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ (import rust-overlay) ];
            config.allowUnfree = true;
          };

          shells = {
            rust = import ./shells/rust.nix { inherit pkgs; };
            svelte = import ./shells/svelte.nix { inherit pkgs; };
            python = import ./shells/python.nix { inherit pkgs; };
            python-ml = import ./shells/python-ml.nix { inherit pkgs; };
            llama = import ./shells/llama.nix { inherit pkgs; };
            dioxus = import ./shells/dioxus.nix { inherit pkgs; };
            go = import ./shells/go.nix { inherit pkgs; };
          };
        in
          shells // {

          }
      );
    };
}
