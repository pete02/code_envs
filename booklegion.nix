{
  outputs = { self, nixpkgs, ... }: {
    devShells.x86_64-linux.book-legion =
      let
        pkgs = import nixpkgs { system = "x86_64-linux"; };
      in
      pkgs.mkShell {
        inputsFrom = [
          self.devShells.x86_64-linux.rust
          self.devShells.x86_64-linux.dioxus
          self.devShells.x86_64-linux.go
          self.devShells.x86_64-linux.llama
        ];
      };
  };
}