
{
  description = "Collection of development shells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    strata-src = {
      url = "github:Niko1221/Strata";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, strata-src, ... }:
    let
      systems = [ "x86_64-linux" ];

      forAllSystems = f: builtins.listToAttrs (
        map (system: {
          name = system;
          value = f system;
        }) systems
      );

      nixFilesIn = directory:
        builtins.filter
          (file: builtins.match ".*\\.nix" file != null)
          (builtins.attrNames (builtins.readDir directory));

      nameOf = file:
        builtins.substring 0
          (builtins.stringLength file - 4)
          file;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          inputs = {
            inherit strata-src;
          };

          shells = builtins.listToAttrs (
            map (file:
              let
                name = nameOf file;
              in
              {
                inherit name;
                value = import (./shells + "/${file}") {
                  inherit pkgs inputs;
                };
              }
            ) (nixFilesIn ./shells)
          );

          projects = builtins.listToAttrs (
            map (file:
              let
                name = nameOf file;
              in
              {
                inherit name;
                value = import (./projects + "/${file}") {
                  inherit pkgs shells inputs;
                };
              }
            ) (nixFilesIn ./projects)
          );
        in
          shells // projects
      );
    };
}
