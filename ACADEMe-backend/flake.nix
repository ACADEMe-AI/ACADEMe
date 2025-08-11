{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        name = "ACADEMe";
        venvDir = ".venv";
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
          pkgs.libxcrypt-legacy
          pkgs.zlib
          pkgs.stdenv.cc.cc
        ];
        nativeBuildInputs = [
          pkgs.pkg-config
        ];
        packages = [
          pkgs.ngrok
          pkgs.python310
          pkgs.python310Packages.venvShellHook
          pkgs.uv
        ];
      };
    };
}
