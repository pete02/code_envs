{
  description = "Collection of devShells for Rust, Python, etc.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, rust-overlay, ... }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: builtins.listToAttrs
        (map (system: { name = system; value = f system; }) systems);
    in
    {
      devShells = forAllSystems (system:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs { inherit system overlays; };
        in {
          rust = import ./rust.nix { inherit pkgs; };
          svelte= import ./svelte.nix { inherit pkgs;};
          python = import ./python.nix { inherit pkgs; };
          python-ml = import ./python-ml.nix {inherit pkgs; };
        }
      );
    };
}
