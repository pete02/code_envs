{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    go
    gopls
    gotools
    go-tools
  ];

  shellHook = ''
    export GOPATH="$PWD/.go"
    export GOMODCACHE="$GOPATH/pkg/mod"
    export PATH="$GOPATH/bin:$PATH"

    echo "Go environment ready!"
  '';
}